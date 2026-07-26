from __future__ import annotations

from pathlib import Path
import re
import unittest


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]


def read_repository_file(relative_path: str) -> str:
    return (REPOSITORY_ROOT / relative_path).read_text(encoding="utf-8")


def read_active_module_configuration(deployment_path: str) -> str:
    deployment_file = REPOSITORY_ROOT / deployment_path
    deployment = deployment_file.read_text(encoding="utf-8")
    sources = re.findall(
        r'(?m)^\s*source\s*=\s*"(\.\./\.\./modules/[^"]+)"\s*$',
        deployment,
    )
    module_files = [
        terraform_file
        for source in sources
        for terraform_file in sorted(
            (deployment_file.parent / source).resolve().glob("*.tf")
        )
    ]
    return "\n".join(
        terraform_file.read_text(encoding="utf-8")
        for terraform_file in module_files
    )


class RecoveryDocumentationTests(unittest.TestCase):
    def assert_module_source(self, configuration: str, source: str) -> None:
        self.assertRegex(
            configuration,
            rf'(?m)^\s*source\s*=\s*"{re.escape(source)}"\s*$',
        )

    def test_active_azure_recovery_capabilities_match_documentation(self) -> None:
        deployment = read_repository_file(
            "infrastructure/deployments/azure/main.tf"
        )
        database = read_repository_file(
            "infrastructure/modules/azure/database/main.tf"
        )
        deployment_variables = read_repository_file(
            "infrastructure/deployments/azure/variables.tf"
        )
        storage_variables = read_repository_file(
            "infrastructure/modules/azure/storage/variables.tf"
        )
        active_modules = read_active_module_configuration(
            "infrastructure/deployments/azure/main.tf"
        )

        for source in (
            "../../modules/azure/database",
            "../../modules/azure/storage",
            "../../modules/azure/compute",
        ):
            self.assert_module_source(deployment, source)
        self.assertNotRegex(
            deployment,
            r'(?m)^\s*source\s*=\s*"\.\./\.\./modules/azure"\s*$',
        )

        self.assertIn(
            "backup_retention_days        = var.backup_retention_days",
            database,
        )
        self.assertIn(
            "geo_redundant_backup_enabled = "
            "var.geo_redundant_backup_enabled",
            database,
        )
        self.assertRegex(
            deployment_variables,
            r'(?s)variable "backup_retention_days"\s*{[^}]*'
            r"default\s*=\s*35",
        )
        self.assertRegex(
            deployment_variables,
            r'(?s)variable "geo_redundant_backup_enabled"\s*{[^}]*'
            r"default\s*=\s*true",
        )
        self.assertRegex(
            storage_variables,
            r'(?s)variable "account_replication_type"\s*{[^}]*'
            r'default\s*=\s*"GZRS"',
        )

        for unsupported_capability in (
            "azurerm_recovery_services_vault",
            "azurerm_backup_protected_vm",
            "azurerm_snapshot",
            "versioning_enabled",
            "delete_retention_policy",
        ):
            self.assertNotIn(unsupported_capability, active_modules)

    def test_active_gcp_recovery_capabilities_match_documentation(self) -> None:
        deployment = read_repository_file("infrastructure/deployments/gcp/main.tf")
        cloud_sql = read_repository_file(
            "infrastructure/modules/gcp-cloudsql/main.tf"
        )
        storage = read_repository_file(
            "infrastructure/modules/gcp-storage/main.tf"
        )
        compute = read_repository_file(
            "infrastructure/modules/gcp-compute/main.tf"
        )
        active_modules = read_active_module_configuration(
            "infrastructure/deployments/gcp/main.tf"
        )

        for source in (
            "../../modules/gcp-cloudsql",
            "../../modules/gcp-storage",
            "../../modules/gcp-compute",
        ):
            self.assert_module_source(deployment, source)
        self.assertNotRegex(
            deployment,
            r'(?m)^\s*source\s*=\s*"\.\./\.\./modules/gcp"\s*$',
        )

        self.assertIn("backup_configuration {", cloud_sql)
        self.assertIn("point_in_time_recovery_enabled = true", cloud_sql)
        self.assertIn("retained_backups = 30", cloud_sql)
        enabled_versioning_blocks = re.findall(
            r"(?s)versioning\s*{[^}]*enabled\s*=\s*true",
            storage,
        )
        self.assertGreaterEqual(len(enabled_versioning_blocks), 3)
        self.assertIn('type            = "PERSISTENT"', compute)
        self.assertIn("auto_delete     = false", compute)
        for unsupported_capability in (
            "google_compute_resource_policy",
            "google_compute_disk_resource_policy_attachment",
            "resource_policies",
        ):
            self.assertNotIn(unsupported_capability, active_modules)

    def test_recovery_comparison_states_active_compute_disk_gaps(self) -> None:
        comparison = read_repository_file(
            "docs/DEPLOYMENT_MODEL_COMPARISON.md"
        )
        recovery_row = next(
            line
            for line in comparison.splitlines()
            if line.startswith("| Recovery posture |")
        )

        self.assertIn(
            "35-day, geo-redundant Flexible Server backups and GZRS "
            "object storage by default",
            recovery_row,
        )
        self.assertIn(
            "no blob versioning/soft delete or Recovery Services VM/disk "
            "backup in the active deployment",
            recovery_row,
        )
        self.assertIn(
            "Cloud SQL automated backups/PITR and versioned Cloud Storage "
            "buckets",
            recovery_row,
        )
        self.assertIn(
            "a daily cron archives \\`/opt/foundry/data\\` to the backups "
            "bucket",
            recovery_row,
        )
        self.assertIn("live file-level archive", recovery_row)
        self.assertIn("no snapshot policy is attached", recovery_row)
        self.assertNotIn(
            "DB backup controls plus Recovery Services VM backup",
            recovery_row,
        )
        self.assertIn(
            "Database backups and object-storage redundancy/versioning do "
            "not protect",
            comparison,
        )
        self.assertIn("scheduled 02:00 archive", comparison)
        self.assertIn("script does not quiesce the application", comparison)
        self.assertIn("Treat Azure compute data as unprotected", comparison)
        self.assertIn("GCP archive as a limited recovery path", comparison)


if __name__ == "__main__":
    unittest.main()
