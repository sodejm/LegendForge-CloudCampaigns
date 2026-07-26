from __future__ import annotations

from dataclasses import dataclass
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
SMOKE_SCRIPT = REPOSITORY_ROOT / "scripts" / "post-deploy-smoke-test.sh"
PROVIDER_OUTPUT_FILES = {
    "aws": REPOSITORY_ROOT / "infrastructure" / "deployments" / "aws" / "main.tf",
    "azure": REPOSITORY_ROOT
    / "infrastructure"
    / "deployments"
    / "azure"
    / "outputs.tf",
    "gcp": REPOSITORY_ROOT / "infrastructure" / "deployments" / "gcp" / "main.tf",
    "hetzner": REPOSITORY_ROOT
    / "infrastructure"
    / "deployments"
    / "hetzner"
    / "outputs.tf",
}


@dataclass
class SmokeRun:
    result: subprocess.CompletedProcess[str]
    curl_calls: list[str]
    dns_calls: list[str]
    terraform_calls: list[str]


class PostDeploySmokeTestTests(unittest.TestCase):
    def write_executable(self, path: Path, body: str) -> None:
        path.write_text(body, encoding="utf-8")
        path.chmod(0o755)

    def run_smoke(
        self,
        *,
        url: str | None = "https://foundry.example.com",
        arguments: tuple[object, ...] = (),
        status: str = "204",
        latency: str = "0.050000",
        curl_mode: str = "success",
        dns_result: str = "success",
        timeout: str = "10",
        max_latency_ms: str = "5000",
        terraform_url: str = "https://terraform.example.com",
        include_terraform: bool = True,
    ) -> SmokeRun:
        with tempfile.TemporaryDirectory() as temporary:
            workspace = Path(temporary)
            fake_bin = workspace / "bin"
            fake_bin.mkdir()
            curl_log = workspace / "curl.log"
            dns_log = workspace / "dns.log"
            terraform_log = workspace / "terraform.log"

            self.write_executable(
                fake_bin / "curl",
                """#!/bin/bash
printf '%s\n' "$*" >>"${FAKE_CURL_LOG}"
case "${FAKE_CURL_MODE}" in
  success)
    printf '%s %s' "${FAKE_HTTP_STATUS}" "${FAKE_LATENCY}"
    ;;
  timeout)
    exit 28
    ;;
  tls)
    exit 60
    ;;
  network)
    exit 7
    ;;
  *)
    exit 64
    ;;
esac
""",
            )
            self.write_executable(
                fake_bin / "getent",
                """#!/bin/bash
printf '%s\n' "$*" >>"${FAKE_DNS_LOG}"
[[ "${FAKE_DNS_RESULT}" == "success" ]]
""",
            )
            if include_terraform:
                self.write_executable(
                    fake_bin / "terraform",
                    """#!/bin/bash
printf '%s\n' "$*" >>"${FAKE_TERRAFORM_LOG}"
printf '%s' "${FAKE_TERRAFORM_URL}"
""",
                )

            environment = {
                **os.environ,
                "PATH": str(fake_bin),
                "FAKE_CURL_LOG": str(curl_log),
                "FAKE_DNS_LOG": str(dns_log),
                "FAKE_TERRAFORM_LOG": str(terraform_log),
                "FAKE_CURL_MODE": curl_mode,
                "FAKE_HTTP_STATUS": status,
                "FAKE_LATENCY": latency,
                "FAKE_DNS_RESULT": dns_result,
                "FAKE_TERRAFORM_URL": terraform_url,
                "TIMEOUT": timeout,
                "MAX_LATENCY_MS": max_latency_ms,
            }
            if url is None:
                environment.pop("FOUNDRY_URL", None)
            else:
                environment["FOUNDRY_URL"] = url

            result = subprocess.run(
                ["/bin/bash", str(SMOKE_SCRIPT), *(str(arg) for arg in arguments)],
                check=False,
                capture_output=True,
                env=environment,
                text=True,
            )

            def read_calls(log: Path) -> list[str]:
                return log.read_text(encoding="utf-8").splitlines() if log.exists() else []

            return SmokeRun(
                result=result,
                curl_calls=read_calls(curl_log),
                dns_calls=read_calls(dns_log),
                terraform_calls=read_calls(terraform_log),
            )

    def test_foundry_url_environment_takes_precedence_over_terraform(self) -> None:
        run = self.run_smoke(
            url="https://override.example.com",
            arguments=("/deployment/that/does/not/exist",),
        )

        self.assertEqual(0, run.result.returncode, run.result.stderr)
        self.assertIn("https://override.example.com", run.result.stdout)
        self.assertEqual([], run.terraform_calls)

    def test_each_provider_directory_uses_only_foundry_url_output(self) -> None:
        for provider in PROVIDER_OUTPUT_FILES:
            with self.subTest(provider=provider):
                deployment_dir = (
                    REPOSITORY_ROOT / "infrastructure" / "deployments" / provider
                )
                run = self.run_smoke(url=None, arguments=(deployment_dir,))

                self.assertEqual(0, run.result.returncode, run.result.stderr)
                self.assertEqual(
                    [f"-chdir={deployment_dir} output -raw foundry_url"],
                    run.terraform_calls,
                )

    def test_all_provider_deployments_have_non_sensitive_foundry_url_output(
        self,
    ) -> None:
        for provider, output_file in PROVIDER_OUTPUT_FILES.items():
            with self.subTest(provider=provider):
                contents = output_file.read_text(encoding="utf-8")
                match = re.search(
                    r'^output "foundry_url" \{\n.*?^\}',
                    contents,
                    flags=re.MULTILINE | re.DOTALL,
                )
                self.assertIsNotNone(match, f"{provider} lacks foundry_url")
                output_block = match.group(0)
                self.assertNotRegex(output_block, r"(?m)^\s*sensitive\s*=\s*true")
                self.assertRegex(
                    output_block,
                    r'(?m)^\s*value\s*=\s*"https?://',
                )

    def test_gcp_foundry_url_matches_load_balancer_domain(self) -> None:
        contents = PROVIDER_OUTPUT_FILES["gcp"].read_text(encoding="utf-8")
        match = re.search(
            r'^output "foundry_url" \{\n.*?^\}',
            contents,
            flags=re.MULTILINE | re.DOTALL,
        )

        self.assertIsNotNone(match)
        self.assertIn('value       = "https://${var.domain_name}"', match.group(0))
        self.assertNotIn("var.foundry_hostname", match.group(0))

    def test_dns_hostname_is_resolved(self) -> None:
        run = self.run_smoke(url="https://foundry.example.com")

        self.assertEqual(0, run.result.returncode, run.result.stderr)
        self.assertEqual(["hosts foundry.example.com"], run.dns_calls)

    def test_dns_failure_fails_the_smoke_test(self) -> None:
        run = self.run_smoke(dns_result="failure")

        self.assertNotEqual(0, run.result.returncode)
        self.assertIn("DNS does not resolve", run.result.stdout)

    def test_literal_ip_addresses_skip_dns(self) -> None:
        for url in ("http://192.0.2.10:30000", "https://[2001:db8::10]:443"):
            with self.subTest(url=url):
                run = self.run_smoke(url=url)

                self.assertEqual(0, run.result.returncode, run.result.stderr)
                self.assertEqual([], run.dns_calls)
                self.assertIn("does not require DNS", run.result.stdout)

    def test_only_2xx_and_3xx_status_classes_succeed(self) -> None:
        for status in ("200", "204", "301", "399"):
            with self.subTest(status=status):
                run = self.run_smoke(status=status)
                self.assertEqual(0, run.result.returncode, run.result.stdout)

        for status in ("199", "400", "401", "403", "500", "503"):
            with self.subTest(status=status):
                run = self.run_smoke(status=status)
                self.assertNotEqual(0, run.result.returncode)
                self.assertIn(f"unsuccessful HTTP {status}", run.result.stdout)

    def test_timeout_is_reported_as_failure(self) -> None:
        run = self.run_smoke(curl_mode="timeout", timeout="7")

        self.assertNotEqual(0, run.result.returncode)
        self.assertIn("timed out after 7s", run.result.stdout)
        self.assertIn("--connect-timeout 7 --max-time 7", run.curl_calls[0])

    def test_tls_certificate_failure_is_reported(self) -> None:
        run = self.run_smoke(curl_mode="tls")

        self.assertNotEqual(0, run.result.returncode)
        self.assertIn("TLS certificate validation failed", run.result.stdout)

    def test_https_uses_normal_certificate_validation(self) -> None:
        run = self.run_smoke()

        self.assertEqual(0, run.result.returncode, run.result.stderr)
        curl_arguments = run.curl_calls[0].split()
        self.assertEqual("-q", curl_arguments[0])
        self.assertNotIn("-k", curl_arguments)
        self.assertNotIn("--insecure", curl_arguments)
        self.assertIn("HTTPS certificate validation passed", run.result.stdout)

    def test_latency_threshold_and_boundary(self) -> None:
        at_limit = self.run_smoke(latency="0.500000", max_latency_ms="500")
        over_limit = self.run_smoke(latency="0.500001", max_latency_ms="500")

        self.assertEqual(0, at_limit.result.returncode, at_limit.result.stdout)
        self.assertNotEqual(0, over_limit.result.returncode)
        self.assertIn("exceeds 500ms", over_limit.result.stdout)

    def test_invalid_urls_and_hostnames_are_rejected_before_curl(self) -> None:
        invalid_urls = (
            "",
            "ftp://foundry.example.com",
            "https://",
            "https://bad_host.example.com",
            "https://-bad.example.com",
            "https://999.0.0.1",
            "https://2001:db8::1",
        )
        for url in invalid_urls:
            with self.subTest(url=url):
                run = self.run_smoke(url=url)

                self.assertEqual(2, run.result.returncode)
                self.assertEqual([], run.curl_calls)
                self.assertIn("valid http:// or https://", run.result.stderr)

    def test_smoke_test_does_not_probe_setup_or_other_paths(self) -> None:
        run = self.run_smoke(url="https://foundry.example.com/custom")

        self.assertEqual(0, run.result.returncode, run.result.stderr)
        self.assertEqual(1, len(run.curl_calls))
        self.assertTrue(run.curl_calls[0].endswith("https://foundry.example.com/custom"))
        self.assertNotIn("/setup", SMOKE_SCRIPT.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
