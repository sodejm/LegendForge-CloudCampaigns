from __future__ import annotations

from pathlib import Path
import re
import unittest


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
GCP_DEPLOYMENT = REPOSITORY_ROOT / "infrastructure" / "deployments" / "gcp"
GCP_COMPUTE_MODULE = REPOSITORY_ROOT / "infrastructure" / "modules" / "gcp-compute"
COMPARISON_GUIDE = REPOSITORY_ROOT / "docs" / "DEPLOYMENT_MODEL_COMPARISON.md"
ARCHITECTURE_GUIDE = GCP_DEPLOYMENT / "ARCHITECTURE.md"
GCP_README = GCP_DEPLOYMENT / "README.md"


def numeric_variable_default(source: str, variable_name: str) -> int:
    variable = re.search(
        rf'variable\s+"{re.escape(variable_name)}"\s*\{{(?P<body>.*?)^\}}',
        source,
        flags=re.DOTALL | re.MULTILINE,
    )
    if variable is None:
        raise AssertionError(f"Variable {variable_name!r} was not found")

    default = re.search(
        r"^\s*default\s*=\s*(?P<value>\d+)\s*$",
        variable.group("body"),
        flags=re.MULTILINE,
    )
    if default is None:
        raise AssertionError(f"Numeric default for {variable_name!r} was not found")

    return int(default.group("value"))


class GcpStorageBillOfMaterialsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.deployment_variables = (GCP_DEPLOYMENT / "variables.tf").read_text(
            encoding="utf-8"
        )
        cls.deployment_main = (GCP_DEPLOYMENT / "main.tf").read_text(encoding="utf-8")
        cls.compute_main = (GCP_COMPUTE_MODULE / "main.tf").read_text(encoding="utf-8")
        cls.comparison = COMPARISON_GUIDE.read_text(encoding="utf-8")
        cls.architecture = ARCHITECTURE_GUIDE.read_text(encoding="utf-8")
        cls.gcp_readme = GCP_README.read_text(encoding="utf-8")
        cls.comparison_flat = " ".join(cls.comparison.split())
        cls.architecture_flat = " ".join(cls.architecture.split())
        cls.gcp_readme_flat = " ".join(cls.gcp_readme.split())

    def test_active_deployment_defaults_require_two_500_gb_disks(self) -> None:
        self.assertEqual(
            500,
            numeric_variable_default(self.deployment_variables, "data_disk_size_gb"),
        )
        self.assertEqual(
            2,
            numeric_variable_default(self.deployment_variables, "min_instances"),
        )
        self.assertEqual(
            5,
            numeric_variable_default(self.deployment_variables, "max_instances"),
        )
        self.assertIn('source = "../../modules/gcp-compute"', self.deployment_main)
        for variable_name in ("data_disk_size_gb", "min_instances", "max_instances"):
            with self.subTest(variable_name=variable_name):
                self.assertRegex(
                    self.deployment_main,
                    rf"{variable_name}\s*=\s*var\.{variable_name}",
                )

    def test_each_active_group_member_has_a_non_auto_delete_pd_ssd(self) -> None:
        self.assertRegex(
            self.compute_main,
            re.compile(
                r"# Persistent data disk.*?"
                r'disk_type\s*=\s*"pd-ssd".*?'
                r"disk_size_gb\s*=\s*var\.data_disk_size_gb.*?"
                r"auto_delete\s*=\s*false.*?"
                r"source_snapshot\s*=\s*null",
                flags=re.DOTALL,
            ),
        )
        self.assertIn("target_size = var.min_instances", self.compute_main)
        self.assertRegex(
            self.compute_main,
            r"min_replicas\s*=\s*var\.min_instances",
        )
        self.assertRegex(
            self.compute_main,
            r"max_replicas\s*=\s*var\.max_instances",
        )
        self.assertNotIn("google_compute_resource_policy", self.compute_main)
        self.assertNotIn(
            "google_compute_disk_resource_policy_attachment",
            self.compute_main,
        )

    def test_comparison_guide_counts_active_and_retained_storage_separately(
        self,
    ) -> None:
        required_language = (
            "at least 2 × 500 GB",
            "1 TB",
            "one 500 GB \\`pd-ssd\\` data disk",
            "Every additional active group member adds another 500 GB",
            "2.5 TB steady-state at five",
            "one possible 500 GB rolling-update surge disk",
            "retained disks from scale-in, replacement, or a completed surge",
            "remain separately billable until an operator removes them",
            "configures no snapshot policy",
            "operator-created snapshots are a separate storage cost",
        )
        for phrase in required_language:
            with self.subTest(phrase=phrase):
                self.assertIn(phrase, self.comparison_flat)

        self.assertNotIn("500 GB data disk/snapshots", self.comparison)

    def test_architecture_guide_describes_per_instance_scaling(self) -> None:
        required_language = (
            "500GB data disk per instance",
            "at least 2 × 500 GB",
            "each additional active replica adds another 500 GB",
            "default steady-state maximum of five",
            "sixth 500 GB disk",
            "raise active capacity to 3 TB",
            "disks retained after scale-in, replacement, or a completed surge",
            "does not configure a snapshot policy",
            "Data disk per instance",
        )
        for phrase in required_language:
            with self.subTest(phrase=phrase):
                self.assertIn(phrase, self.architecture_flat)

    def test_gcp_sizing_guides_use_capacity_inputs_instead_of_stale_prices(
        self,
    ) -> None:
        for guide in (self.architecture_flat, self.gcp_readme_flat):
            with self.subTest(guide=guide[:80]):
                self.assertIn("Steady-state active data disks", guide)
                self.assertIn("1-1.5 TB", guide)
                self.assertIn("4-10 TB", guide)
                self.assertIn("15-50 TB", guide)
                self.assertIn("One rolling-update surge disk", guide)
                self.assertIn("Google Cloud Pricing Calculator", guide)

        for stale_price in (
            "$20-30",
            "$350/mo",
            "$700/mo",
            "$1500/mo",
            "$350-400/month",
        ):
            with self.subTest(stale_price=stale_price):
                self.assertNotIn(stale_price, self.architecture)
                self.assertNotIn(stale_price, self.gcp_readme)


if __name__ == "__main__":
    unittest.main()
