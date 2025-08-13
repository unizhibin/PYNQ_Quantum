# Weekly Maintenance Checklist

1. **Issues/PRs triage**
   - `gh issue list --state open`
   - `gh pr list --state open`
2. **Dependencies**
   - Python: `uv pip compile && uv pip sync` or `pip-tools` / `poetry update`
   - Node: `npm outdated && npm update`
   - Merge Dependabot PRs after CI passes
3. **CI & Lint**
   - Check latest runs: Actions tab
   - Fix failing jobs; ensure caches are effective
4. **Security**
   - `scripts/python_security_audit.sh`
   - `scripts/node_security_audit.sh`
   - Review Dependabot/CodeQL alerts
5. **Hygiene**
   - README badges, LICENSE, .gitignore, CODEOWNERS
   - Remove stale branches: `git branch -r --merged`
6. **Planning**
   - Update milestones & project board
7. **Changelog**
   - Maintain `CHANGELOG.md` and release notes
