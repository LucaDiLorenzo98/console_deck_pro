# Supporto multi-piattaforma (Windows, macOS, Linux)

Lo script Python e l’UI Flutter sono pensati per funzionare su **Windows**, **macOS** e **Linux**. L’esperienza è la stessa; alcune funzioni usano API di sistema diverse.

## Cosa funziona uguale ovunque

- **Serial/Arduino**: connessione, lettura pulsanti, encoder, moduli (slider, knob, media, piano). Le porte sono diverse (`COM3` su Windows, `/dev/cu.usbserial-*` su macOS, `/dev/ttyUSB*` su Linux); l’app le elenca dal backend.
- **Config**: path unificati (vedi sotto). Stesso file `config.json` e stesse voci (serial, mappings, special_modules).
- **Azioni**: URL, app, hotkey, digitazione testo, mute e volume (tastiera) funzionano su tutte le piattaforme.
- **Media deck e piano**: backend audio con `pygame` (pip, senza runtime esterno).

## Differenze per piattaforma

| Funzione            | Windows              | macOS                    | Linux                         |
|---------------------|----------------------|---------------------------|-------------------------------|
| **Volume** | Tasti volume (WinAPI/APPCOMMAND) | Tasti volume (simulazione) | Tasti volume (simulazione)    |
| **Temperatura CPU** | psutil o WMI         | psutil                    | psutil                        |
| **GPU / nvidia-smi**| Opzionale            | N/A                       | Se presente, usata per stats  |
| **Piano (nota default)** | pygame o winsound   | pygame o afplay              | pygame o aplay                   |


## Path di configurazione

- **Windows**: `%APPDATA%\ConsoleDeckPro\config.json`
- **macOS**: `~/Library/Application Support/ConsoleDeckPro/config.json`
- **Linux**: `$XDG_CONFIG_HOME/ConsoleDeckPro/config.json` oppure `~/.config/ConsoleDeckPro/config.json`

L’UI Flutter usa gli stessi path (e migra da eventuali path legacy se presenti).

## Dipendenze Python

- **Comuni**: `fastapi`, `uvicorn`, `pyserial`, `pyautogui`, `psutil`, `pygame`
- **Solo Windows** (opzionali): `GPUtil` (GPU)

## Requisiti extra su Linux

- **Piano (fallback)**: `aplay` (pacchetto `alsa-utils`) per le note predefinite se `pygame` non è disponibile.

In sintesi: sì, puoi usarlo su macOS e Linux allo stesso modo; il volume ha i fallback o limiti descritti sopra.
