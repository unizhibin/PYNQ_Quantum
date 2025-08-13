#!/usr/bin/env bash
set -euo pipefail
pip install pip-audit safety bandit
pip-audit -r requirements.txt || true
safety check -r requirements.txt || true
bandit -r . || true
