# Plan: VRAM-003 — VRAM Limit Enforcement via LD_PRELOAD Shim

## Phase 1: Create Shim Source & Build (1 hr)

### Step 1.1: Create Directory & Source
```bash
mkdir -p shim
# Write libvram_limit.c per spec
# Write Makefile per spec
```

### Step 1.2: Build & Test Locally
```bash
make -C shim
# Test with minimal CUDA program:
cat > /tmp/test_cuda.c <<'EOF'
#include <cuda_runtime.h>
#include <stdio.h>
int main() {
    void* ptr;
    cudaError_t err = cudaMalloc(&ptr, 1024*1024*1024); // 1GB
    printf("cudaMalloc: %d\n", err);
    return 0;
}
EOF
gcc -o /tmp/test_cuda /tmp/test_cuda.c -lcudart
VRAM_LIMIT_MB=512 LD_PRELOAD=./shim/libvram_limit.so /tmp/test_cuda
# Expect: cudaMalloc: 2 (cudaErrorMemoryAllocation)
```

## Phase 2: Integrate with Installer (30 min)

### Step 2.1: Add Build Step to `install.sh`
```bash
# In install.sh, after main deploy:
build_vram_shim() {
    if command -v gcc >/dev/null && [[ -f shim/libvram_limit.c ]]; then
        make -C shim
        mkdir -p "$HOME/.local/lib"
        cp shim/libvram_limit.so "$HOME/.local/lib/"
        echo "[OK] VRAM limit shim built and installed"
    else
        echo "[SKIP] VRAM shim (gcc not found or source missing)"
    fi
}
```

### Step 2.2: Update `steam-gpu-wrap`
```bash
# In steam-gpu-wrap, before final exec:
if [[ -n "${VRAM_LIMIT_MB:-}" && "$VRAM_LIMIT_MB" -gt 0 ]]; then
    SHIM="$HOME/.local/lib/libvram_limit.so"
    if [[ -f "$SHIM" ]]; then
        export LD_PRELOAD="$SHIM${LD_PRELOAD:+:$LD_PRELOAD}"
    fi
fi
```

### Step 2.3: Update `uninstall.sh`
```bash
rm -f "$HOME/.local/lib/libvram_limit.so"
```

## Phase 3: End-to-End Test (30 min)

```bash
# 1. Install with shim
./install.sh

# 2. Verify shim exists
ls -la ~/.local/lib/libvram_limit.so

# 3. Test with game (or synthetic)
VRAM_LIMIT_MB=4000 ~/.local/bin/steam-gpu-wrap /path/to/proton run game.exe
# Monitor ~/.local/state/vram-manager.log for limit enforcement

# 4. Test without limit (should work normally)
unset VRAM_LIMIT_MB
~/.local/bin/steam-gpu-wrap /path/to/proton run game.exe
```

## Rollback
```bash
git checkout HEAD -- shim/ install.sh steam-gpu-wrap uninstall.sh
./install.sh  # re-deploy without shim
```

## Success Criteria
- [ ] `make -C shim` succeeds
- [ ] Synthetic test returns `cudaErrorMemoryAllocation` (2) when limit exceeded
- [ ] Game launches with shim loaded (no segfault)
- [ ] `install.sh` builds shim automatically
- [ ] `uninstall.sh` removes shim

---

*Plan version: 1.0*
*Date: 2026-09-20*