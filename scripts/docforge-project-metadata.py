#!/usr/bin/env python3
from __future__ import annotations

import sys

from app_template_metadata import main


if __name__ == "__main__":
    print(
        "AVERTISSEMENT: scripts/docforge-project-metadata.py est déprécié. "
        "Utilisez scripts/materialize-application.py.",
        file=sys.stderr,
    )
    raise SystemExit(main())
