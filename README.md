# Project LUCID – First Run v1.0

Post-installation setup tool for a custom Windows 11 (24H2 / 25H2) ISO. Run it once after a clean install: one launcher applies the system tweaks, the other installs and updates the apps.

## Launchers

Both launchers request administrator rights (UAC) on their own.

1. **`Autorun.bat`** runs `core/LUCID_First_Run.ps1` (system tweaks only):
   privacy and telemetry policies, Cortana, Windows Search, Explorer and visual performance, Hardware-Accelerated GPU Scheduling (HAGS), OneDrive removal.
2. **`Apps.bat`** runs `core/LUCID_Apps_Run.ps1` (applications only):
   installs the apps in `core/config/packages.json`, then runs `winget upgrade --all`.

## App install policy

1. **Microsoft Store first**, using the exact Store ID from `packages.json`.
2. If the app is not on the Store (Steam) or the Store install fails, the **official installer** is installed through the winget community repository. Winget downloads it from the vendor's own URL and verifies its hash.

| App | Store ID | winget ID |
|---|---|---|
| Brave | `XP8C9QZMS2PC1T` | `Brave.Brave` |
| NanaZip | `9N8G7TSCL18R` | `M2Team.NanaZip` |
| QuickLook | `9NV4BS3L1H4S` | `QL-Win.QuickLook` |
| ShareX | `9NBLGGH4Z1SP` | `ShareX.ShareX` |
| Spotify | `9NCBCSZSJRSB` | `Spotify.Spotify` |
| Steam | not on the Store | `Valve.Steam` |

If winget is missing on a fresh install, the tool first requests the App Installer registration documented by Microsoft.

## Structure

```text
LUCID-FirstRun/
├── Autorun.bat            launcher: system tweaks
├── Apps.bat               launcher: apps
├── core/
│   ├── LUCID_First_Run.ps1
│   ├── LUCID_Apps_Run.ps1
│   ├── config/            config.json (tweak switches), packages.json, lang.json (EN/TR)
│   └── modules/           one PowerShell module per area
└── logs/                  run logs (created on first run, not tracked in git)
```

Turn individual tweak groups on or off in `core/config/config.json`.

## How to run

1. Double-click **`Autorun.bat`** for the system tweaks, or **`Apps.bat`** for the apps.
2. Click **Yes** on the UAC prompt.
3. Choose the language: `1` English (default), `2` Turkce.
4. Read the summary at the end and press any key to close. A restart is recommended after the system tweaks.

Note: `Apps.bat` also updates every app that winget can upgrade on the machine.
