#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
TEMPLATE_METADATA_FILE = ROOT / "docforge.template.json"
PROJECT_METADATA_FILE = ROOT / "docforge.project.json"
ENV_TEMPLATE_FILE = ROOT / ".env.template"
MAKEFILE_FILE = ROOT / "Makefile"
PLACEHOLDER_APP_NAME = "__APP" + "_NAME__"
PLACEHOLDER_APP_SLUG = "__APP" + "_SLUG__"
KNOWN_PLACEHOLDERS = {
    PLACEHOLDER_APP_NAME: "APP_NAME",
    PLACEHOLDER_APP_SLUG: "APP_SLUG",
}
TEXT_SUFFIXES = {
    ".md",
    ".py",
    ".js",
    ".jsx",
    ".ts",
    ".tsx",
    ".mjs",
    ".json",
    ".html",
    ".yml",
    ".yaml",
    ".txt",
    ".css",
    ".example",
    ".sh",
}
IGNORED_DIRS = {
    ".git",
    ".docforge",
    "node_modules",
    "dist",
    "build",
    "backup",
    "__pycache__",
}
IGNORED_FILES = {"docforge.template.json", "docforge.project.json", "docforge-project-metadata.py"}

REQUIRED_IDENTITY_KEYS = (
    "APP_NAME",
    "APP_SLUG",
    "APP_DEPOT",
    "APP_NO",
    "ADMIN_USERNAME",
    "ADMIN_EMAIL",
    "ADMIN_PASSWORD",
)


class MetadataError(RuntimeError):
    pass


@dataclass(slots=True)
class LocalMetadataState:
    mode: str
    payload: dict[str, Any]
    source_path: Path


def _read_json(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise MetadataError(f"Fichier absent: {path.name}") from exc
    except json.JSONDecodeError as exc:
        raise MetadataError(f"JSON invalide dans {path.name}: {exc}") from exc


def _parse_env_template(path: Path) -> dict[str, str]:
    if not path.is_file():
        raise MetadataError(
            ".env.template introuvable. Copiez d'abord .env.template.example vers .env.template"
        )

    values: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip()
    return values


def _template_contract() -> dict[str, Any]:
    payload = _read_json(TEMPLATE_METADATA_FILE)
    if payload.get("project_kind") != "application-template":
        raise MetadataError(
            "docforge.template.json doit déclarer project_kind=application-template"
        )
    if not payload.get("template_id"):
        raise MetadataError("docforge.template.json doit déclarer template_id")
    if not payload.get("template_version"):
        raise MetadataError("docforge.template.json doit déclarer template_version")
    targets = payload.get("make_targets")
    if not isinstance(targets, list) or not targets:
        raise MetadataError("docforge.template.json doit déclarer make_targets")
    return payload


def _project_metadata() -> dict[str, Any]:
    payload = _read_json(PROJECT_METADATA_FILE)
    if payload.get("project_kind") != "application":
        raise MetadataError(
            "docforge.project.json doit déclarer project_kind=application"
        )
    origin = payload.get("origin_template")
    if not isinstance(origin, dict) or not origin.get("template_id"):
        raise MetadataError(
            "docforge.project.json doit déclarer origin_template.template_id"
        )
    if not origin.get("template_version"):
        raise MetadataError(
            "docforge.project.json doit déclarer origin_template.template_version"
        )
    inherited_targets = payload.get("inherited_make_targets")
    if not isinstance(inherited_targets, list) or not inherited_targets:
        raise MetadataError(
            "docforge.project.json doit déclarer inherited_make_targets"
        )
    return payload


def detect_local_metadata() -> LocalMetadataState:
    template_exists = TEMPLATE_METADATA_FILE.is_file()
    project_exists = PROJECT_METADATA_FILE.is_file()

    if template_exists and project_exists:
        raise MetadataError(
            "Le dépôt ne doit pas contenir à la fois docforge.template.json et docforge.project.json"
        )
    if template_exists:
        return LocalMetadataState(
            mode="template",
            payload=_template_contract(),
            source_path=TEMPLATE_METADATA_FILE,
        )
    if project_exists:
        return LocalMetadataState(
            mode="application",
            payload=_project_metadata(),
            source_path=PROJECT_METADATA_FILE,
        )
    raise MetadataError(
        "Aucune métadonnée DocForge locale détectée. Le dépôt doit contenir docforge.template.json ou docforge.project.json"
    )


def _iter_text_files(root: Path) -> list[Path]:
    files: list[Path] = []
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if any(part in IGNORED_DIRS for part in path.relative_to(root).parts[:-1]):
            continue
        if path.name in {".env", ".env.local", ".env.dev", ".env.prod", ".env.template"}:
            continue
        if path.name in IGNORED_FILES:
            continue
        if path.name != "Makefile" and path.suffix.lower() not in TEXT_SUFFIXES:
            continue
        files.append(path)
    return sorted(files)


def _replace_placeholders(identity: dict[str, str]) -> list[str]:
    replaced: list[str] = []
    replacements = {
        placeholder: identity[source_key]
        for placeholder, source_key in KNOWN_PLACEHOLDERS.items()
    }

    for path in _iter_text_files(ROOT):
        content = path.read_text(encoding="utf-8")
        updated = content
        for placeholder, replacement in replacements.items():
            updated = updated.replace(placeholder, replacement)
        if updated != content:
            path.write_text(updated, encoding="utf-8")
            replaced.append(path.relative_to(ROOT).as_posix())
    return replaced


def _find_remaining_placeholders() -> dict[str, list[str]]:
    remaining = {placeholder: [] for placeholder in KNOWN_PLACEHOLDERS}
    for path in _iter_text_files(ROOT):
        content = path.read_text(encoding="utf-8")
        rel = path.relative_to(ROOT).as_posix()
        for placeholder in KNOWN_PLACEHOLDERS:
            if placeholder in content:
                remaining[placeholder].append(rel)
    return {key: value for key, value in remaining.items() if value}


def _extract_make_targets() -> set[str]:
    if not MAKEFILE_FILE.is_file():
        raise MetadataError("Makefile introuvable")

    targets: set[str] = set()
    for raw_line in MAKEFILE_FILE.read_text(encoding="utf-8").splitlines():
        if not raw_line or raw_line[0].isspace():
            continue
        stripped = raw_line.strip()
        if not stripped or stripped.startswith("#") or stripped.startswith("."):
            continue
        head = raw_line.split(":", 1)[0].strip()
        if ":" not in raw_line or any(token in raw_line for token in (":=", "?=", "+=")) or "=" in head:
            continue
        targets.add(head)
    return targets


def _validate_manifest_targets(target_entries: list[dict[str, Any]]) -> None:
    actual_targets = _extract_make_targets()
    declared = [item.get("name") for item in target_entries if isinstance(item, dict) and item.get("name")]
    missing = sorted(name for name in declared if name not in actual_targets)
    if missing:
        raise MetadataError(
            "Des cibles déclarées dans les métadonnées DocForge sont absentes du Makefile: "
            + ", ".join(missing)
        )


def _build_project_metadata(template_contract: dict[str, Any], identity: dict[str, str]) -> dict[str, Any]:
    return {
        "schema_version": 1,
        "project_kind": "application",
        "base_profile": template_contract.get("base_profile", "django-react"),
        "origin_template": {
            "template_id": template_contract["template_id"],
            "template_version": template_contract["template_version"],
            "manifest_source": "docforge.template.json",
        },
        "application_identity": {
            "app_name": identity["APP_NAME"],
            "app_slug": identity["APP_SLUG"],
            "app_depot": identity["APP_DEPOT"],
            "app_no": identity["APP_NO"],
            "app_host": identity.get("APP_HOST") or None,
        },
        "inherited_make_targets": template_contract["make_targets"],
    }


def _validate_required_identity(values: dict[str, str], template_id: str) -> dict[str, str]:
    missing = [key for key in REQUIRED_IDENTITY_KEYS if not values.get(key, "").strip()]
    if missing:
        raise MetadataError(
            "Identifiants ou bootstrap admin manquants dans .env.template: " + ", ".join(missing)
        )

    identity = {key: values[key].strip() for key in REQUIRED_IDENTITY_KEYS}
    if identity["APP_SLUG"] == template_id or identity["APP_DEPOT"] == template_id:
        raise MetadataError(
            "APP_SLUG et APP_DEPOT ne doivent pas conserver l'identité du modèle source app-template"
        )
    if identity["APP_NAME"] in KNOWN_PLACEHOLDERS or identity["APP_SLUG"] in KNOWN_PLACEHOLDERS:
        raise MetadataError("Les valeurs d'identité ne doivent pas reprendre les placeholders du template")
    optional_host = (values.get("APP_HOST") or "").strip()
    if optional_host:
        identity["APP_HOST"] = optional_host
    return identity


def _guard_git_detach(template_id: str, allow_source_name: bool) -> None:
    if ROOT.name == template_id and not allow_source_name:
        raise MetadataError(
            "Refus de détacher l'historique Git dans un répertoire portant encore le nom du modèle source. "
            "Copiez le dépôt dans un nouveau répertoire, ou relancez explicitement avec --allow-source-name si c'est volontaire."
        )


def _detach_git_history(template_id: str, allow_source_name: bool) -> None:
    git_dir = ROOT / ".git"
    if not git_dir.exists():
        subprocess.run(["git", "init", "-b", "main"], cwd=ROOT, check=True)
        return

    _guard_git_detach(template_id, allow_source_name)
    shutil.rmtree(git_dir)
    subprocess.run(["git", "init", "-b", "main"], cwd=ROOT, check=True)


def materialize_application(*, detach_git: bool, allow_source_name: bool) -> None:
    state = detect_local_metadata()
    if state.mode != "template":
        raise MetadataError(
            "La matérialisation n'est possible que depuis un dépôt source contenant docforge.template.json"
        )

    identity_values = _parse_env_template(ENV_TEMPLATE_FILE)
    identity = _validate_required_identity(identity_values, state.payload["template_id"])
    _validate_manifest_targets(state.payload["make_targets"])
    _replace_placeholders(identity)

    metadata = _build_project_metadata(state.payload, identity)
    PROJECT_METADATA_FILE.write_text(
        json.dumps(metadata, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    TEMPLATE_METADATA_FILE.unlink()

    remaining = _find_remaining_placeholders()
    if remaining:
        raise MetadataError(
            "Des placeholders subsistent après matérialisation: "
            + "; ".join(f"{key} -> {', '.join(paths)}" for key, paths in sorted(remaining.items()))
        )

    if detach_git:
        _detach_git_history(state.payload["template_id"], allow_source_name)

    validate_metadata_state(expect_application=True)


def validate_metadata_state(*, expect_application: bool = False) -> None:
    state = detect_local_metadata()
    if state.mode == "template":
        _validate_manifest_targets(state.payload["make_targets"])
        if expect_application:
            raise MetadataError(
                "Le projet conserve docforge.template.json. Relancez make init avec DOCFORGE_INIT_APPLICATION=1 pour matérialiser une application."
            )
        return

    origin = state.payload["origin_template"]
    _validate_manifest_targets(state.payload["inherited_make_targets"])
    identity = state.payload.get("application_identity") or {}
    missing_identity = [
        key
        for key in ("app_name", "app_slug", "app_depot", "app_no")
        if not str(identity.get(key) or "").strip()
    ]
    if missing_identity:
        raise MetadataError(
            "docforge.project.json doit conserver l'identité de l'application: " + ", ".join(missing_identity)
        )
    if state.payload.get("project_kind") != "application":
        raise MetadataError("docforge.project.json ne doit pas conserver project_kind=application-template")
    if origin.get("template_id") == identity.get("app_slug") or origin.get("template_id") == identity.get("app_depot"):
        raise MetadataError(
            "Le projet créé conserve accidentellement l'identité du modèle source dans son slug ou son dépôt"
        )
    remaining = _find_remaining_placeholders()
    if remaining:
        raise MetadataError(
            "Des placeholders connus subsistent: "
            + "; ".join(f"{key} -> {', '.join(paths)}" for key, paths in sorted(remaining.items()))
        )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Gérer les métadonnées DocForge d'un dépôt app-template ou d'une application issue du modèle."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    materialize_parser = subparsers.add_parser(
        "materialize-application",
        help="Transformer un dépôt source app-template en application générée.",
    )
    materialize_parser.add_argument(
        "--detach-git",
        action="store_true",
        help="Supprimer explicitement l'historique Git actuel puis réinitialiser un nouveau dépôt Git.",
    )
    materialize_parser.add_argument(
        "--allow-source-name",
        action="store_true",
        help="Autoriser le détachement Git même si le répertoire porte encore le nom du modèle source.",
    )

    validate_parser = subparsers.add_parser(
        "validate",
        help="Valider l'état courant des métadonnées DocForge et des placeholders.",
    )
    validate_parser.add_argument(
        "--expect-application",
        action="store_true",
        help="Échouer si le dépôt n'a pas encore été matérialisé comme application.",
    )

    args = parser.parse_args(argv)

    try:
        if args.command == "materialize-application":
            materialize_application(
                detach_git=args.detach_git,
                allow_source_name=args.allow_source_name,
            )
        elif args.command == "validate":
            validate_metadata_state(
                expect_application=args.expect_application,
            )
        else:
            raise MetadataError(f"Commande inconnue: {args.command}")
    except MetadataError as exc:
        print(f"ERREUR: {exc}", file=sys.stderr)
        return 1
    except subprocess.CalledProcessError as exc:
        print(f"ERREUR: commande externe échouée ({exc})", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
