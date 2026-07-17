from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
SCRIPT_FILES = [
    "scripts/app_template_metadata.py",
    "scripts/materialize-application.py",
    "scripts/docforge-project-metadata.py",
    "scripts/init.sh",
    "scripts/check-invariants.sh",
    "scripts/generate-env.sh",
    "scripts/generate-secrets.sh",
]


class AppTemplateMaterializationTests(unittest.TestCase):
    maxDiff = None

    def make_repo(
        self,
        *,
        repo_name: str = "my-app",
        legacy_template: bool = False,
        application_metadata: bool = False,
        legacy_application: bool = False,
        include_env_template: bool = True,
        with_placeholders: bool = True,
    ) -> Path:
        temp_dir = Path(tempfile.mkdtemp(prefix="app-template-tests-"))
        self.addCleanup(shutil.rmtree, temp_dir)
        repo_dir = temp_dir / repo_name
        repo_dir.mkdir()
        (repo_dir / "scripts").mkdir()
        (repo_dir / ".app-template").mkdir()

        for relative_path in SCRIPT_FILES:
            source = REPO_ROOT / relative_path
            target = repo_dir / relative_path
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)

        shutil.copy2(REPO_ROOT / "Makefile", repo_dir / "Makefile")
        shutil.copy2(REPO_ROOT / "INVARIANTS.md", repo_dir / "INVARIANTS.md")
        shutil.copy2(REPO_ROOT / ".gitignore", repo_dir / ".gitignore")
        shutil.copy2(REPO_ROOT / "docker-compose.dev.yml", repo_dir / "docker-compose.dev.yml")
        shutil.copy2(REPO_ROOT / "docker-compose.prod.yml", repo_dir / "docker-compose.prod.yml")

        if application_metadata:
            makefile_path = repo_dir / "Makefile"
            makefile_path.write_text(
                makefile_path.read_text(encoding="utf-8").replace("__APP_SLUG__", "example-app"),
                encoding="utf-8",
            )

        readme_content = "# __APP_NAME__\nslug=__APP_SLUG__\n" if with_placeholders else "# Example\n"
        (repo_dir / "README.md").write_text(readme_content, encoding="utf-8")

        if include_env_template:
            (repo_dir / ".env.template").write_text(
                "\n".join(
                    [
                        "APP_NAME=Example App",
                        "APP_SLUG=example-app",
                        "APP_DEPOT=example-app",
                        "APP_NO=4",
                        "ADMIN_USERNAME=admin",
                        "ADMIN_PASSWORD=admin-secret",
                        "ADMIN_EMAIL=admin@example.test",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

        template_payload = json.loads((REPO_ROOT / ".app-template/template.json").read_text(encoding="utf-8"))
        if legacy_template:
            (repo_dir / "docforge.template.json").write_text(
                json.dumps(template_payload, indent=2, ensure_ascii=False) + "\n",
                encoding="utf-8",
            )
        else:
            (repo_dir / ".app-template/template.json").write_text(
                json.dumps(template_payload, indent=2, ensure_ascii=False) + "\n",
                encoding="utf-8",
            )

        if application_metadata:
            payload = {
                "schema_version": 1,
                "metadata_kind": "app-template-application",
                "project_kind": "application",
                "base_profile": "django-react",
                "origin_template": {
                    "template_id": "app-template",
                    "template_version": "0.1.0",
                    "metadata_path": ".app-template/template.json",
                    "source_metadata": ".app-template/template.json",
                },
                "application_identity": {
                    "app_name": "Example App",
                    "app_slug": "example-app",
                    "app_depot": "example-app",
                    "app_no": "4",
                    "app_host": None,
                },
                "materialization": {
                    "git_history_detached": False,
                },
                "inherited_make_targets": template_payload["make_targets"],
            }
            path = repo_dir / ("docforge.project.json" if legacy_application else ".app-template/origin.json")
            path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
            template_file = repo_dir / ".app-template/template.json"
            legacy_file = repo_dir / "docforge.template.json"
            if template_file.exists():
                template_file.unlink()
            if legacy_file.exists():
                legacy_file.unlink()

        os.symlink(".env.dev", repo_dir / ".env")
        (repo_dir / ".env.local").write_text("", encoding="utf-8")
        return repo_dir

    def run_cmd(self, repo_dir: Path, *args: str, env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
        merged_env = os.environ.copy()
        if env:
            merged_env.update(env)
        return subprocess.run(
            args,
            cwd=repo_dir,
            env=merged_env,
            text=True,
            capture_output=True,
            check=False,
        )

    def test_materialize_with_new_variables_generates_canonical_origin_metadata(self) -> None:
        repo_dir = self.make_repo()

        result = self.run_cmd(
            repo_dir,
            "./scripts/init.sh",
            env={
                "APP_TEMPLATE_MATERIALIZE": "1",
                "APP_TEMPLATE_SKIP_STARTUP": "1",
            },
        )

        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        origin_path = repo_dir / ".app-template/origin.json"
        self.assertTrue(origin_path.is_file())
        self.assertFalse((repo_dir / ".app-template/template.json").exists())
        self.assertFalse((repo_dir / "docforge.template.json").exists())
        metadata = json.loads(origin_path.read_text(encoding="utf-8"))
        self.assertEqual(metadata["origin_template"]["template_id"], "app-template")
        self.assertEqual(metadata["origin_template"]["template_version"], "0.1.0")
        self.assertEqual(metadata["application_identity"]["app_slug"], "example-app")
        self.assertFalse(metadata["materialization"]["git_history_detached"])
        self.assertNotIn("POSTGRES_PASSWORD", origin_path.read_text(encoding="utf-8"))
        self.assertIn("Example App", (repo_dir / "README.md").read_text(encoding="utf-8"))
        self.assertNotIn("__APP_NAME__", (repo_dir / "README.md").read_text(encoding="utf-8"))

    def test_refuses_materialization_in_source_repo_name(self) -> None:
        repo_dir = self.make_repo(repo_name="app-template")

        result = self.run_cmd(repo_dir, "./scripts/materialize-application.py", "materialize-application")

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Refus de matérialiser directement le dépôt source", result.stderr)
        self.assertTrue((repo_dir / ".app-template/template.json").is_file())
        self.assertFalse((repo_dir / ".app-template/origin.json").exists())

    def test_missing_env_template_is_rejected(self) -> None:
        repo_dir = self.make_repo(include_env_template=False)

        result = self.run_cmd(repo_dir, "./scripts/materialize-application.py", "materialize-application")

        self.assertNotEqual(result.returncode, 0)
        self.assertIn(".env.template introuvable", result.stderr)

    def test_legacy_variable_alias_is_accepted_with_warning(self) -> None:
        repo_dir = self.make_repo(legacy_template=True)

        result = self.run_cmd(
            repo_dir,
            "./scripts/init.sh",
            env={
                "DOCFORGE_INIT_APPLICATION": "1",
                "APP_TEMPLATE_SKIP_STARTUP": "1",
            },
        )

        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        self.assertIn("DOCFORGE_INIT_APPLICATION est dépréciée", result.stderr)
        self.assertTrue((repo_dir / ".app-template/origin.json").is_file())
        self.assertFalse((repo_dir / "docforge.template.json").exists())

    def test_new_variable_takes_priority_over_legacy_alias(self) -> None:
        repo_dir = self.make_repo()

        result = self.run_cmd(
            repo_dir,
            "./scripts/init.sh",
            env={
                "APP_TEMPLATE_MATERIALIZE": "0",
                "DOCFORGE_INIT_APPLICATION": "1",
                "APP_TEMPLATE_SKIP_STARTUP": "1",
            },
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("DOCFORGE_INIT_APPLICATION est ignorée", result.stderr)
        self.assertFalse((repo_dir / ".app-template/origin.json").exists())

    def test_materialization_without_detach_keeps_existing_git_directory(self) -> None:
        repo_dir = self.make_repo()
        (repo_dir / ".git").mkdir()
        config_path = repo_dir / ".git" / "config"
        config_path.write_text("[core]\n", encoding="utf-8")

        result = self.run_cmd(
            repo_dir,
            "./scripts/materialize-application.py",
            "materialize-application",
        )

        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        self.assertTrue(config_path.exists())
        self.assertFalse((repo_dir / ".git" / "HEAD").exists())
        metadata = json.loads((repo_dir / ".app-template/origin.json").read_text(encoding="utf-8"))
        self.assertFalse(metadata["materialization"]["git_history_detached"])

    def test_identity_cannot_keep_template_name(self) -> None:
        repo_dir = self.make_repo()
        (repo_dir / ".env.template").write_text(
            "\n".join(
                [
                    "APP_NAME=Example App",
                    "APP_SLUG=app-template",
                    "APP_DEPOT=example-app",
                    "APP_NO=4",
                    "ADMIN_USERNAME=admin",
                    "ADMIN_PASSWORD=admin-secret",
                    "ADMIN_EMAIL=admin@example.test",
                ]
            )
            + "\n",
            encoding="utf-8",
        )

        result = self.run_cmd(repo_dir, "./scripts/materialize-application.py", "materialize-application")

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("APP_SLUG et APP_DEPOT ne doivent pas conserver l'identité du modèle source app-template", result.stderr)

    def test_second_materialization_is_refused_once_application_exists(self) -> None:
        repo_dir = self.make_repo()
        first = self.run_cmd(repo_dir, "./scripts/materialize-application.py", "materialize-application")
        self.assertEqual(first.returncode, 0, first.stderr + first.stdout)

        second = self.run_cmd(repo_dir, "./scripts/materialize-application.py", "materialize-application")

        self.assertNotEqual(second.returncode, 0)
        self.assertIn(
            "La matérialisation n'est possible que depuis un dépôt source contenant une métadonnée de template.",
            second.stderr,
        )

    def test_legacy_project_metadata_is_validated_with_warning(self) -> None:
        repo_dir = self.make_repo(application_metadata=True, legacy_application=True, with_placeholders=False)
        self.run_cmd(repo_dir, "./scripts/generate-env.sh")

        result = self.run_cmd(repo_dir, "./scripts/check-invariants.sh")

        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        self.assertIn("docforge.project.json est déprécié", result.stderr)

    def test_contradictory_metadata_is_rejected(self) -> None:
        repo_dir = self.make_repo(application_metadata=True)
        (repo_dir / ".app-template/template.json").write_text(
            (REPO_ROOT / ".app-template/template.json").read_text(encoding="utf-8"),
            encoding="utf-8",
        )

        result = self.run_cmd(repo_dir, "./scripts/materialize-application.py", "validate")

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Etat ambigu", result.stderr)

    def test_detach_git_with_explicit_authorization(self) -> None:
        repo_dir = self.make_repo()
        (repo_dir / ".git").mkdir()
        (repo_dir / ".git" / "config").write_text("[core]\n", encoding="utf-8")

        result = self.run_cmd(
            repo_dir,
            "./scripts/materialize-application.py",
            "materialize-application",
            "--detach-git",
        )

        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        self.assertTrue((repo_dir / ".git" / "HEAD").exists())
        self.assertTrue((repo_dir / ".app-template/origin.json").exists())

    def test_validate_requires_git_repository_when_metadata_declares_detach(self) -> None:
        repo_dir = self.make_repo(application_metadata=True, with_placeholders=False)
        origin_path = repo_dir / ".app-template/origin.json"
        payload = json.loads(origin_path.read_text(encoding="utf-8"))
        payload["materialization"]["git_history_detached"] = True
        origin_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        self.run_cmd(repo_dir, "./scripts/generate-env.sh")

        result = self.run_cmd(repo_dir, "./scripts/check-invariants.sh")

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("aucun dépôt Git local n'est présent", result.stderr)

    def test_main_flow_has_no_direct_docforge_import_dependency(self) -> None:
        for relative_path in (
            "scripts/app_template_metadata.py",
            "scripts/materialize-application.py",
            "scripts/init.sh",
            "scripts/check-invariants.sh",
        ):
            content = (REPO_ROOT / relative_path).read_text(encoding="utf-8")
            self.assertNotIn("import docforge", content, relative_path)
            self.assertNotIn("from docforge", content, relative_path)
            self.assertNotIn('["docforge"', content, relative_path)
            self.assertNotIn("'docforge'", content, relative_path)


if __name__ == "__main__":
    unittest.main()
