# Spec: VRAM-003 — VRAM Limit Enforcement via LD_PRELOAD Shim

## Shim: `shim/libvram_limit.c`

```c
#define _GNU_SOURCE
#include <cuda_runtime.h>
#include <dlfcn.h>
#include <stdlib.h>
#include <stdio.h>
#include <pthread.h>

static size_t g_limit_bytes = 0;
static size_t g_allocated = 0;
static pthread_mutex_t g_mutex = PTHREAD_MUTEX_INITIALIZER;
static cudaError_t (*real_cudaMalloc)(void**, size_t) = NULL;
static cudaError_t (*real_cudaFree)(void*) = NULL;

__attribute__((constructor)) static void init() {
    const char* env = getenv("VRAM_LIMIT_MB");
    if (env) {
        long mb = strtol(env, NULL, 10);
        if (mb > 0) g_limit_bytes = (size_t)mb * 1024 * 1024;
    }
    real_cudaMalloc = dlsym(RTLD_NEXT, "cudaMalloc");
    real_cudaFree = dlsym(RTLD_NEXT, "cudaFree");
}

cudaError_t cudaMalloc(void** devPtr, size_t size) {
    if (!real_cudaMalloc) return cudaErrorInitializationError;
    if (g_limit_bytes == 0) return real_cudaMalloc(devPtr, size);
    
    pthread_mutex_lock(&g_mutex);
    if (g_allocated + size > g_limit_bytes) {
        pthread_mutex_unlock(&g_mutex);
        return cudaErrorMemoryAllocation; // 2
    }
    g_allocated += size;
    pthread_mutex_unlock(&g_mutex);
    
    cudaError_t err = real_cudaMalloc(devPtr, size);
    if (err != cudaSuccess) {
        pthread_mutex_lock(&g_mutex);
        g_allocated -= size;
        pthread_mutex_unlock(&g_mutex);
    }
    return err;
}

cudaError_t cudaFree(void* devPtr) {
    if (!real_cudaFree) return cudaErrorInitializationError;
    // Conservative: don't decrement (v1). v2: addr->size map.
    return real_cudaFree(devPtr);
}
```

---

## Build: `shim/Makefile`

```makefile
CC = gcc
CFLAGS = -shared -fPIC -O2 -Wall -Wextra
LDFLAGS = -ldl
TARGET = libvram_limit.so
SRC = libvram_limit.c

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

install: $(TARGET)
	install -Dm755 $(TARGET) $(DESTDIR)$(HOME)/.local/lib/$(TARGET)

clean:
	rm -f $(TARGET)

.PHONY: all install clean
```

---

## Integration in `steam-gpu-wrap`

```bash
# In steam-gpu-wrap, before exec:
if [[ -n "${VRAM_LIMIT_MB:-}" && "$VRAM_LIMIT_MB" -gt 0 ]]; then
    SHIM="$HOME/.local/lib/libvram_limit.so"
    if [[ -f "$SHIM" ]]; then
        export LD_PRELOAD="$SHIM${LD_PRELOAD:+:$LD_PRELOAD}"
    fi
fi
```

---

## Integration in `install.sh`

```bash
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

---

## Acceptance Criteria
- [ ] `make -C shim` produces `libvram_limit.so`
- [ ] Shim loads via `LD_PRELOAD` without crashing simple CUDA test
- [ ] Allocation > `VRAM_LIMIT_MB` returns `cudaErrorMemoryAllocation`
- [ ] `install.sh` builds and installs shim to `~/.local/lib/`
- [ ] `steam-gpu-wrap` injects `LD_PRELOAD` when `VRAM_LIMIT_MB>0`
- [ ] Graceful fallback if shim missing or CUDA not loaded

---

*Spec version: 1.0*
*Date: 2026-09-20*