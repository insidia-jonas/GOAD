#!/usr/bin/env python3
"""Debian router is omitted when sophos_xgs is configured to replace it."""
import json
import os
import tempfile
import unittest

from jinja2 import Template


def sophos_replaces_debian_router(extensions, config=None):
    if "sophos_xgs" not in (extensions or []):
        return False
    if not config:
        return True
    return bool(config.get("lab_extension", {}).get("replace_debian_router", True))


SNIPPET = "{% if not replace_debian_router|default(false) %}ROUTER{% else %}SOPHOS{% endif %}"


class TestRouterReplacement(unittest.TestCase):
    def test_off_without_extension(self):
        self.assertFalse(sophos_replaces_debian_router([]))
        self.assertFalse(sophos_replaces_debian_router(["elastic_edr"]))

    def test_on_when_sophos_enabled(self):
        self.assertTrue(sophos_replaces_debian_router(["sophos_xgs"]))

    def test_config_can_disable_replace(self):
        cfg = {"lab_extension": {"replace_debian_router": False}}
        self.assertFalse(sophos_replaces_debian_router(["sophos_xgs"], cfg))

    def test_jinja_omits_debian_router(self):
        tpl = Template(SNIPPET)
        self.assertEqual(tpl.render(replace_debian_router=True), "SOPHOS")
        self.assertEqual(tpl.render(replace_debian_router=False), "ROUTER")
        self.assertEqual(tpl.render(), "ROUTER")

    def test_real_ludus_and_vagrant_templates(self):
        from jinja2 import Environment, FileSystemLoader
        root = os.path.join(os.path.dirname(__file__), "..")
        common = dict(lab_name="GOAD", ip_range="192.168.56", range_id="abc", extensions=[])
        ludus = Environment(loader=FileSystemLoader(os.path.join(root, "ad/GOAD/providers/ludus")))
        off = ludus.get_template("config.yml").render(replace_debian_router=False, **common)
        on = ludus.get_template("config.yml").render(replace_debian_router=True, **common)
        self.assertIn("GOAD-ROUTER", off)
        self.assertNotIn("GOAD-ROUTER", on)

    def test_extension_config_json_default(self):
        path = os.path.join(
            os.path.dirname(__file__),
            "..",
            "extensions",
            "sophos_xgs",
            "data",
            "config.json",
        )
        with open(path, encoding="utf-8") as handle:
            data = json.load(handle)
        self.assertTrue(data["lab_extension"]["replace_debian_router"])


if __name__ == "__main__":
    unittest.main()
