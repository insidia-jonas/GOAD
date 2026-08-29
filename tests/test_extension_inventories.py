#!/usr/bin/env python3
"""Inventory helper used so edr.yml sees elastic_edr after the extension is enabled."""
import os
import tempfile
import unittest


def list_extension_inventories(instance_path):
    inventories = []
    if not instance_path or not os.path.isdir(instance_path):
        return inventories
    for fname in sorted(os.listdir(instance_path)):
        if not fname.endswith("_inventory"):
            continue
        path = os.path.join(instance_path, fname)
        if os.path.isfile(path):
            inventories.append(path)
    return inventories


class TestExtensionInventories(unittest.TestCase):
    def test_empty_path(self):
        self.assertEqual(list_extension_inventories(""), [])
        self.assertEqual(list_extension_inventories("/no/such/dir"), [])

    def test_picks_extension_inventory_only(self):
        with tempfile.TemporaryDirectory() as tmp:
            open(os.path.join(tmp, "inventory"), "w").close()
            open(os.path.join(tmp, "elastic_edr_inventory"), "w").close()
            open(os.path.join(tmp, "notes.txt"), "w").close()
            os.mkdir(os.path.join(tmp, "not_inventory"))
            found = [os.path.basename(p) for p in list_extension_inventories(tmp)]
            self.assertEqual(found, ["elastic_edr_inventory"])


if __name__ == "__main__":
    unittest.main()
