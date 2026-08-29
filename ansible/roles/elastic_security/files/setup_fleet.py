#!/usr/bin/env python3
"""Configure Kibana Fleet and an Elastic Defend policy for the GOAD lab.

Stdlib only. Secrets come from the environment and are never written to
the script or the git repo. Intended to run on the Elastic Security VM
after Elasticsearch + Kibana are up and a trial license is active.
"""
from __future__ import print_function

import base64
import json
import os
import ssl
import sys
import time
import urllib.error
import urllib.request


class FleetError(RuntimeError):
    """HTTP or Fleet API failure (message must not include secrets)."""


def env(name, default=""):
    return os.environ.get(name, default).strip()


def basic_auth_header(user, password):
    token = base64.b64encode(("%s:%s" % (user, password)).encode("utf-8")).decode("ascii")
    return "Basic %s" % token


def request_json(base_url, method, path, user, password, body=None, timeout=60, kibana_version=""):
    url = base_url.rstrip("/") + path
    data = None if body is None else json.dumps(body).encode("utf-8")
    headers = {
        "kbn-xsrf": "true",
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": basic_auth_header(user, password),
    }
    if kibana_version:
        headers["kbn-version"] = kibana_version
    req = urllib.request.Request(url, data=data, method=method, headers=headers)
    ctx = ssl._create_unverified_context()
    try:
        with urllib.request.urlopen(req, context=ctx, timeout=timeout) as resp:
            raw = resp.read()
            if not raw:
                return {}
            return json.loads(raw.decode("utf-8"))
    except urllib.error.HTTPError as exc:
        err_body = exc.read().decode("utf-8", errors="replace")
        raise FleetError("%s %s -> %s: %s" % (method, path, exc.code, err_body[:2000]))


def wait_kibana(base_url, user, password, attempts=60, delay=5):
    last = None
    for _ in range(attempts):
        try:
            status = request_json(base_url, "GET", "/api/status", user, password, timeout=15)
            level = (
                status.get("status", {}).get("overall", {}).get("level")
                or status.get("status", {}).get("overall", {}).get("state")
            )
            if level in ("available", "green", "yellow"):
                version = (
                    status.get("version", {}).get("number")
                    or status.get("version", {}).get("build_number")
                    or ""
                )
                if isinstance(version, int):
                    version = str(version)
                return status, str(version)
            last = "kibana level=%s" % level
        except Exception as exc:
            last = str(exc)
        time.sleep(delay)
    raise FleetError("Kibana did not become ready: %s" % last)


def extract_package_version(payload):
    """Return the Elastic Defend (endpoint) package version from an EPM response."""
    if not isinstance(payload, dict):
        return ""
    for key in ("item", "response", "package"):
        inner = payload.get(key)
        if isinstance(inner, dict) and inner.get("version"):
            return str(inner.get("version"))
    if payload.get("version"):
        return str(payload.get("version"))
    items = payload.get("items") or payload.get("packages") or []
    if isinstance(items, list):
        for item in items:
            if isinstance(item, dict) and item.get("name") == "endpoint" and item.get("version"):
                return str(item.get("version"))
    return ""


def find_named_item(payload, name, items_key="items"):
    if not isinstance(payload, dict):
        return None
    items = payload.get(items_key)
    if items is None and isinstance(payload.get("item"), dict):
        items = [payload["item"]]
    if not isinstance(items, list):
        return None
    for item in items:
        if isinstance(item, dict) and item.get("name") == name:
            return item
    return None


def find_enrollment_api_key(payload, policy_id):
    items = []
    if isinstance(payload, dict):
        items = payload.get("items") or payload.get("list") or []
        if isinstance(payload.get("item"), dict):
            items = [payload["item"]] + list(items)
    for item in items:
        if not isinstance(item, dict):
            continue
        if item.get("policy_id") == policy_id and item.get("active", True):
            return item.get("api_key") or item.get("api_key_id") or ""
    return ""


def build_defend_package_policy(policy_id, package_version, name, preset, config_key="_config"):
    return {
        "name": name,
        "description": "GOAD lab Elastic Defend (EDR)",
        "namespace": "default",
        "policy_id": policy_id,
        "enabled": True,
        "inputs": [
            {
                "enabled": True,
                "streams": [],
                "type": "ENDPOINT_INTEGRATION_CONFIG",
                "config": {
                    config_key: {
                        "value": {
                            "type": "endpoint",
                            "endpointConfig": {"preset": preset},
                        }
                    }
                },
            }
        ],
        "package": {
            "name": "endpoint",
            "title": "Elastic Defend",
            "version": package_version,
        },
    }


def write_text(path, value):
    parent = os.path.dirname(path)
    if parent and not os.path.isdir(parent):
        os.makedirs(parent, mode=0o700)
    with open(path, "w", encoding="utf-8") as handle:
        handle.write((value or "").strip() + "\n")
    os.chmod(path, 0o600)


def ensure_agent_policy(kbn, user, password, name, has_fleet_server, kbn_version):
    listing = request_json(
        kbn, "GET", "/api/fleet/agent_policies?perPage=100", user, password, kibana_version=kbn_version
    )
    existing = find_named_item(listing, name)
    if existing and existing.get("id"):
        return existing["id"]
    body = {
        "name": name,
        "description": "GOAD lab policy",
        "namespace": "default",
        "monitoring_enabled": ["logs", "metrics"],
        "inactivity_timeout": 1209600,
    }
    if has_fleet_server:
        body["has_fleet_server"] = True
    created = request_json(
        kbn, "POST", "/api/fleet/agent_policies", user, password, body=body, kibana_version=kbn_version
    )
    item = created.get("item") or created
    policy_id = item.get("id")
    if not policy_id:
        raise FleetError("agent policy %s created but no id: %s" % (name, json.dumps(created)[:500]))
    return policy_id


def ensure_fleet_server_host(kbn, user, password, fleet_url, kbn_version):
    try:
        listing = request_json(
            kbn, "GET", "/api/fleet/fleet_server_hosts", user, password, kibana_version=kbn_version
        )
        items = listing.get("items") or []
        for item in items:
            if item.get("is_default") or fleet_url in (item.get("host_urls") or []):
                host_id = item.get("id")
                request_json(
                    kbn,
                    "PUT",
                    "/api/fleet/fleet_server_hosts/%s" % host_id,
                    user,
                    password,
                    body={
                        "name": item.get("name") or "Default",
                        "host_urls": [fleet_url],
                        "is_default": True,
                    },
                    kibana_version=kbn_version,
                )
                return
        request_json(
            kbn,
            "POST",
            "/api/fleet/fleet_server_hosts",
            user,
            password,
            body={"name": "GOAD Fleet", "host_urls": [fleet_url], "is_default": True},
            kibana_version=kbn_version,
        )
        return
    except FleetError:
        request_json(
            kbn,
            "PUT",
            "/api/fleet/settings",
            user,
            password,
            body={"fleet_server_hosts": [fleet_url]},
            kibana_version=kbn_version,
        )


def ensure_es_output(kbn, user, password, es_url, ca_fingerprint, kbn_version):
    listing = request_json(kbn, "GET", "/api/fleet/outputs", user, password, kibana_version=kbn_version)
    items = listing.get("items") or []
    target = None
    for item in items:
        if item.get("is_default") or item.get("id") == "fleet-default-output":
            target = item
            break
    if target is None and items:
        target = items[0]
    if target is None:
        return
    body = {
        "name": target.get("name") or "default",
        "type": target.get("type") or "elasticsearch",
        "hosts": [es_url],
        "is_default": True,
        "is_default_monitoring": bool(target.get("is_default_monitoring", True)),
    }
    if ca_fingerprint:
        body["ca_trusted_fingerprint"] = ca_fingerprint
    request_json(
        kbn,
        "PUT",
        "/api/fleet/outputs/%s" % target["id"],
        user,
        password,
        body=body,
        kibana_version=kbn_version,
    )


def ensure_defend_policy(kbn, user, password, policy_id, package_version, name, preset, kbn_version):
    listing = request_json(
        kbn, "GET", "/api/fleet/package_policies?perPage=100", user, password, kibana_version=kbn_version
    )
    existing = find_named_item(listing, name)
    if existing:
        return existing.get("id")
    last_error = None
    for config_key in ("_config", "integration_config"):
        body = build_defend_package_policy(policy_id, package_version, name, preset, config_key=config_key)
        try:
            created = request_json(
                kbn,
                "POST",
                "/api/fleet/package_policies",
                user,
                password,
                body=body,
                kibana_version=kbn_version,
            )
            item = created.get("item") or created
            return item.get("id")
        except FleetError as exc:
            last_error = exc
    print("WARN: Elastic Defend package policy was not created: %s" % last_error, file=sys.stderr)
    return ""


def ensure_enrollment_token(kbn, user, password, policy_id, kbn_version):
    listing = request_json(
        kbn,
        "GET",
        "/api/fleet/enrollment_api_keys?perPage=100",
        user,
        password,
        kibana_version=kbn_version,
    )
    token = find_enrollment_api_key(listing, policy_id)
    if token and "." in token:
        return token
    created = request_json(
        kbn,
        "POST",
        "/api/fleet/enrollment_api_keys",
        user,
        password,
        body={"name": "GOAD Windows EDR", "policy_id": policy_id},
        kibana_version=kbn_version,
    )
    item = created.get("item") or created
    token = item.get("api_key") or ""
    if not token:
        raise FleetError("enrollment api key missing in response")
    return token


def main(argv=None):
    argv = argv if argv is not None else sys.argv[1:]
    kbn = env("KIBANA_URL", "http://127.0.0.1:5601")
    user = env("ELASTIC_USER", "elastic")
    password = env("ELASTIC_PASSWORD")
    fleet_url = env("FLEET_URL")
    es_url = env("ES_URL")
    ca_fingerprint = env("ES_CA_FINGERPRINT").replace(":", "").upper()
    out_dir = env("OUTPUT_DIR", "/opt/elastic")
    preset = env("ELASTIC_DEFEND_PRESET", "EDRComplete")
    windows_policy_name = env("ELASTIC_WINDOWS_POLICY_NAME", "GOAD Windows EDR")
    fleet_policy_name = env("ELASTIC_FLEET_POLICY_NAME", "GOAD Fleet Server")
    defend_policy_name = env("ELASTIC_DEFEND_POLICY_NAME", "GOAD Elastic Defend")

    if not password:
        raise FleetError("ELASTIC_PASSWORD is empty")
    if not fleet_url or not es_url:
        raise FleetError("FLEET_URL and ES_URL are required")

    _status, kbn_version = wait_kibana(kbn, user, password)
    request_json(kbn, "POST", "/api/fleet/setup", user, password, body={}, kibana_version=kbn_version)
    try:
        request_json(kbn, "POST", "/api/fleet/agents/setup", user, password, body={}, kibana_version=kbn_version)
    except FleetError as exc:
        print("WARN: /api/fleet/agents/setup: %s" % exc, file=sys.stderr)

    ensure_fleet_server_host(kbn, user, password, fleet_url, kbn_version)
    try:
        ensure_es_output(kbn, user, password, es_url, ca_fingerprint, kbn_version)
    except FleetError as exc:
        print("WARN: Fleet Elasticsearch output was not updated: %s" % exc, file=sys.stderr)

    fleet_policy_id = ensure_agent_policy(
        kbn, user, password, fleet_policy_name, has_fleet_server=True, kbn_version=kbn_version
    )
    windows_policy_id = ensure_agent_policy(
        kbn, user, password, windows_policy_name, has_fleet_server=False, kbn_version=kbn_version
    )

    service_token = ""
    try:
        token_resp = request_json(
            kbn, "POST", "/api/fleet/service_tokens", user, password, body={}, kibana_version=kbn_version
        )
        service_token = token_resp.get("value") or token_resp.get("item", {}).get("value") or ""
    except FleetError as exc:
        print("WARN: Fleet service token: %s" % exc, file=sys.stderr)

    package_version = ""
    try:
        pkg = request_json(
            kbn, "GET", "/api/fleet/epm/packages/endpoint", user, password, kibana_version=kbn_version
        )
        package_version = extract_package_version(pkg)
    except FleetError as exc:
        print("WARN: endpoint package lookup: %s" % exc, file=sys.stderr)

    if package_version:
        try:
            request_json(
                kbn,
                "POST",
                "/api/fleet/epm/packages/endpoint/%s" % package_version,
                user,
                password,
                body={"force": True},
                kibana_version=kbn_version,
            )
        except FleetError as exc:
            print("WARN: endpoint package install: %s" % exc, file=sys.stderr)
        ensure_defend_policy(
            kbn,
            user,
            password,
            windows_policy_id,
            package_version,
            defend_policy_name,
            preset,
            kbn_version,
        )

    enrollment_token = ensure_enrollment_token(kbn, user, password, windows_policy_id, kbn_version)

    write_text(os.path.join(out_dir, "fleet_url"), fleet_url)
    write_text(os.path.join(out_dir, "fleet_server_policy_id"), fleet_policy_id)
    write_text(os.path.join(out_dir, "windows_policy_id"), windows_policy_id)
    write_text(os.path.join(out_dir, "windows_enrollment_token"), enrollment_token)
    if service_token:
        write_text(os.path.join(out_dir, "fleet_server_service_token"), service_token)
    if package_version:
        write_text(os.path.join(out_dir, "endpoint_package_version"), package_version)
    write_text(os.path.join(out_dir, ".fleet_configured"), "ok")
    print("Fleet configured: windows_policy=%s fleet_policy=%s" % (windows_policy_id, fleet_policy_id))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except FleetError as exc:
        print("ERROR: %s" % exc, file=sys.stderr)
        sys.exit(1)
