"""Guard the standard deployment's policy controls and single routed backend."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]


class CloudArmorWiringTests(unittest.TestCase):
    def test_standard_deployment_forwards_each_independent_control(self):
        source = (ROOT / "infrastructure/deployments/gcp/main.tf").read_text()
        module = re.search(r'module "loadbalancer" \{(.*?)\n\}', source, re.S).group(1)
        for name in (
            "enable_cloud_armor", "enable_adaptive_protection", "cloud_armor_preview",
            "cloud_armor_rate_limit_count", "cloud_armor_rate_limit_interval_sec",
            "cloud_armor_ban_duration_sec",
        ):
            with self.subTest(control=name):
                self.assertRegex(module, rf"\b{name}\s*=\s*var\.{name}\b")

    def test_only_the_routed_backend_remains(self):
        source = (ROOT / "infrastructure/modules/gcp-loadbalancer/main.tf").read_text()
        self.assertEqual(re.findall(r'resource "google_compute_backend_service" "([^"]+)"', source), ["foundry"])


if __name__ == "__main__":
    unittest.main()
