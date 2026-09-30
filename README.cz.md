# Správce GPU VRAM a lokálních AI modelů pro Steam (`steam-vram-manager`)

[![Platform: Linux](https://img.shields.io/badge/Platform-Linux-orange.svg)](https://www.kernel.org/)
[![GPU: NVIDIA](https://img.shields.io/badge/GPU-NVIDIA%20GTX%201060-76B900.svg)](https://www.nvidia.com/)
[![Desktop: Agnostic](https://img.shields.io/badge/Desktop-Agnostic-blue.svg)](https://github.com/milhy545/Steam-VRAM-Manager)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)  
[🇬🇧 English version available here](./README.md)

Inteligentní, **desktopově agnostický** orchestrátor grafické paměti (VRAM) a zátěže lokálních jazykových modelů pro Linuxové pracovní stanice s kartami NVIDIA, které provozují lokální LLM (`llama.cpp` / `llama-server`) souběžně s hraním her přes Steam Proton.

Funguje napříč **jakýmkoliv desktopovým prostředím**: KDE Plasma, GNOME, XFCE, MATE, Cinnamon, LXQt, Sway, i3, Hyprland atd.

---

## 🎯 Problém

Při provozu lokálních LLM (např. Mistral 7B, Qwen 2.5 Coder) přes `llama.cpp` s téměř kompletním offloadem vrstev do grafické karty (`--n-gpu-layers 99`) zabírá samotný model **~5.38 GB VRAM**.

Na **6GB grafické kartě (jako je GTX 1060)** vede spuštění jakékoliv moderní hry ve Steamu k okamžitému selhání alokace VRAM (Out-Of-Memory / OOM), chybám inicializace Vulkanu nebo masivnímu zasekávání.

---

## 💡 Řešení

`steam-vram-manager` vytváří synchronní, spolehlivý most mezi životním cyklem hry ve Steamu a systémovým démonem `llama.service` (systemd):

```mermaid
sequenceDiagram
    autonumber
    actor Uživatel
    participant Steam as Steam Game Launcher
    participant Wrapper as steam-gpu-wrap
    participant Llama as llama.service (systemd)
    participant GPU as NVIDIA GTX 1060 (6GB)
    participant Dialog as Univerzální GUI (kdialog / zenity / yad)

    Uživatel->>Steam: Spustit hru
    Steam->>Wrapper: Provede hru přes wrapper
    Wrapper->>Llama: systemctl --user stop llama.service
    Llama-->>GPU: Uvolní CUDA kontext (5.4GB uvolněno)
    Wrapper->>GPU: Nastaví PRIME Offload (__NV_PRIME_RENDER_OFFLOAD=1)
    Wrapper->>Steam: Spustí hru s plnou 6GB VRAM
    Note over Steam,GPU: Herní relace aktivní
    Steam-->>Wrapper: Hra skončí (návratový kód $EXIT_CODE)
    
    alt Čisté ukončení ($EXIT_CODE == 0)
        Wrapper->>Dialog: Zobrazí výzvu s 60sekundovým odpočtem
        alt Uživatel klikne 'Ano' nebo vyprší 60s
            Wrapper->>Llama: systemctl --user start llama.service
            Llama-->>GPU: Model znovu načten do VRAM
        else Uživatel klikne 'Ne'
            Wrapper->>Uživatel: Ponechá VRAM volnou pro další hru
        end
    else Pád / Chyba ($EXIT_CODE != 0)
        Wrapper->>Dialog: Varovná výzva (bez automatického timeoutu)
        alt Uživatel klikne 'Ano'
            Wrapper->>Llama: systemctl --user start llama.service
        else Uživatel klikne 'Ne'
            Wrapper->>Uživatel: Režim ladění: Ponechá VRAM volnou
        end
    end
```

---

## ✨ Klíčové vlastnosti

- **Univerzální kompatibilita:** Automaticky detekuje grafické prostředí a naváže se na nativní GUI dialogy (`kdialog`, `zenity`, `yad`). Pokud běží bez GUI, spolehlivě funguje v terminálu.
- **Zero-Waste architektura:** Žádná trvalá alokace navíc, uvolňuje 100 % VRAM přesně ve chvíli, kdy ji hra potřebuje.
- **Odolnost proti chybám:** Ošetření pádů hry i neočekávaných stavů systemd démona.
