# Plan: VRAM-005 — CI Pipeline

## Phase 1: Create Workflow & Test Structure (1 hr)

### Step 1.1: Create Workflow Directory & File
```bash
mkdir -p .github/workflows
# Write .github/workflows/ci.yml per spec
```

### Step 1.2: Create Test Directory & Helpers
```bash
mkdir -p tests
# Write tests/helpers.bash per spec
```

### Step 1.3: Create Unit Tests
```bash
# Write tests/vram-wrapper.bats (requires VRAM-001 functions)
# Write tests/install-sh.bats (requires VRAM-004 flags)
# Write tests/steam-gpu-wrap.bats (basic env var tests)
```

## Phase 2: Validate Locally (45 min)

### Step 2.1: Run Shellcheck
```bash
shellcheck -x bin/steam-gpu-wrap
shellcheck -x compatibilitytool/vram-wrapper
shellcheck -x driver-fix/fix-nvidia-pascal.sh
shellcheck -x install.sh
shellcheck -x uninstall.sh
# Fix any warnings
```

### Step 2.2: Run Bats
```bash
# Install bats if needed
sudo apt-get install -y bats

# Run tests
bats tests/
# Fix any failures
```

## Phase 3: Push & Verify CI (30 min)

```bash
git add .github/workflows/ci.yml tests/ .shellcheckrc
git commit -m "VRAM-005: Add CI pipeline with shellcheck + bats"
git push origin feature/vram-005-ci-pipeline
# Check GitHub Actions UI
# Verify workflow runs and passes
```

## Phase 4: Merge & Protect Main (15 min)

```bash
# Create PR, ensure CI passes
# Merge to main
# Enable branch protection: require CI pass on PRs to main
```

## Rollback
```bash
git rm -r .github/workflows/ci.yml tests/ .shellcheckrc
git commit -m "Revert VRAM-005: CI pipeline"
```

## Success Criteria
- [ ] GitHub Actions workflow triggers on push/PR
- [ ] `shellcheck -x` passes on all scripts (0 warnings)
- [ ] `bats tests/` passes (all tests green)
- [ ] Failed shellcheck or bats → workflow fails (red)
- [ ] Branch protection enabled on main

---

*Plan version: 1.0*
*Date: 2026-09-20*