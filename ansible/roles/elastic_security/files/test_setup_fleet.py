#!/usr/bin/env python3
"""Unit tests for Fleet setup helpers (no live Elastic cluster)."""
import unittest

import setup_fleet


class TestSetupFleetHelpers(unittest.TestCase):
    def test_extract_package_version_item(self):
        self.assertEqual(
            setup_fleet.extract_package_version({"item": {"name": "endpoint", "version": "8.19.3"}}),
            "8.19.3",
        )

    def test_extract_package_version_items_list(self):
        payload = {
            "items": [
                {"name": "system", "version": "1.0.0"},
                {"name": "endpoint", "version": "8.18.1"},
            ]
        }
        self.assertEqual(setup_fleet.extract_package_version(payload), "8.18.1")

    def test_find_named_item(self):
        listing = {"items": [{"name": "other", "id": "1"}, {"name": "GOAD Windows EDR", "id": "abc"}]}
        self.assertEqual(setup_fleet.find_named_item(listing, "GOAD Windows EDR")["id"], "abc")

    def test_find_enrollment_api_key(self):
        payload = {
            "items": [
                {"policy_id": "other", "api_key": "nope", "active": True},
                {"policy_id": "win", "api_key": "tok.en.value", "active": True},
            ]
        }
        self.assertEqual(setup_fleet.find_enrollment_api_key(payload, "win"), "tok.en.value")

    def test_build_defend_package_policy_preset(self):
        body = setup_fleet.build_defend_package_policy(
            "policy-1", "8.19.3", "GOAD Elastic Defend", "EDRComplete"
        )
        self.assertEqual(body["policy_id"], "policy-1")
        self.assertEqual(body["package"]["name"], "endpoint")
        self.assertEqual(
            body["inputs"][0]["config"]["_config"]["value"]["endpointConfig"]["preset"],
            "EDRComplete",
        )

    def test_basic_auth_header_is_basic(self):
        header = setup_fleet.basic_auth_header("elastic", "secret")
        self.assertTrue(header.startswith("Basic "))
        self.assertNotIn("secret", header)


if __name__ == "__main__":
    unittest.main()
