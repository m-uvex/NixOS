# ❄️ NixOS Multi-Host Fleet

Declarative, flake-based NixOS configuration managing personal workstations, gaming rigs, and server nodes across a unified Tailscale mesh.

---

## 🖥️ Hosts

| Host | Codename | Role | Hardware |
| :--- | :--- | :--- | :--- |
| `lt-hp15-nix` | **Orion** | Coding & Remote desktop | HP 15 Laptop, Intel Core i5 8th gen, NVIDIA GeForce MX150, 24GB DDR4, 1.5TB Total Storage |
| `pc-main-nix` | **Andromeda** | Gaming & Workstation | Ryzen 5 5600, RTX 5050, 16 GB DDR4, 512 GB Total Storage |
| `srv-c4030-nix` | **Lunar** | Server & WoL Relay | Lenovo AIO C40-30, Intel Core i3-4005U, NVIDIA GeForce 820A, 4GB DDR3L, 4.5TB Total Storage |

---

## 📁 Repository Structure

```
.
├── flake.nix              # Flake inputs, outputs, and system definitions
├── hosts/
│   ├── lt-hp15-nix/       # Orion-specific config
│   ├── pc-main-nix/       # Andromeda-specific config
│   └── srv-c4030-nix/     # Lunar-specific config
├── modules/
│   ├── core.nix           # Users, SSH, auth, age-decryption, Tailscale & must-have cli tools
│   ├── desktop.nix        # DEs, WMs, GUI stuff, Audio and whatnot
│   ├── apps.nix           # Dev tools, productivity, Zen Browser, UI toolkits
│   ├── gaming.nix         # Steam, Gamescope, Prism/Heroic, controller drivers
│   ├── docker.nix         # Docker daemon & declarative OCI container stack # WIP, My server still runs on Ubuntu...
│   └── remote-host.nix    # Sunshine streaming host & Wake-on-LAN udev rules
└── secrets/
    └── ssh.tar.age        # Passphrase-encrypted ~/.ssh archive bundle
    

.
├── assets
│   └── Wallpapers
│       ├── Dark...
│       └── Light...
├── flake.nix
├── hosts
│   ├── lt-hp15-nix
│   │   ├── default.nix
│   │   └── hardware-configuration.nix
│   ├── pc-main-nix
│   │   └── default.nix
│   └── srv-c4030-nix
│       └── default.nix
├── modules
│   ├── apps.nix
│   ├── core.nix
│   ├── desktop.nix
│   ├── docker.nix
│   ├── gaming.nix
│   ├── home.nix
│   └── remote-host.nix
├── README.md
└── secrets
    └── ssh.tar.age
```

---

## ✨ Key Features

* **Secure Masterized SSH:** `~/.ssh` is encrypted and stored inside the repo. On a first-time boot it'd copy over the same dir using a passphrase, allowing all my devices to securely share the same SSH keys and always able to access one another.
* **Remote Kiosk Specialisation:** Selectable boot-entry on the laptop (`remote-kiosk`) boots directly into moonlight inside a minimal cage wayland compositor, sending a background Wake-on-LAN magic packet over Tailscale via Lunar to Andromeda.
* **Tailscale WoL Relay:** Built-in alias and scripts allowing remote devices to trigger Wake-on-LAN on Andromeda via the always-on Lunar server node.
* **One config for all:** This single repo is made to work for every single one of my machines in the exact way i want it to. No need to spend hours configuring a new server, a VM, VPS, PC, installation or whatever. It's all one single repo!
---

## 🚀 Quick Install (Fresh System)

! It is advised to fork this repo into your own and edit the config as you like, especially the user block as the password is hashed and with this exact config you won't be able to get in!

### 1. Install NixOS

- Visit `https://nixos.org/download/`
- Select and download your preferred ISO file (GUI Recommended, Use Minimal only if you're comfortable using the terminal, want a fast download and install and don't have enough space on a usb stick.)
- Flash the ISO file onto a USB drive, you can use Belena Etcher, or Rufus for Windows.
- After flashing complete, reboot and select your USB drive, then simply follow the instructions in the Installer. Most of the settings you input here aren't important and will change with the config files you provide.

### 2. Generate Hardware Config & Clone Repo

- Once you're in, launch any type of terminal window and run the following
```bash
# Get into a temporary shell with git installed
nix-shell -p git

# Generate hardware profile
sudo nixos-generate-config --root /mnt

# clone repo
sudo git clone https://github.com/m-uvex/NixOS.git /etc/nixos

# Move generated hardware config to target host (e.g., lt-hp15-nix)
sudo mv /etc/nixos/hardware-configuration.nix /etc/nixos/hosts/lt-hp15-nix/
```
### 3. Build
# PLEASE EDIT THE CONFIG BEFORE GENERATING! with my exact config, you won't be able to log in or do much of anything because of the hashed password. It is advised that you fork the repo into your own first!

```bash
cd /etc/nixos
sudo git add .
sudo nixos-install --flake .#lt-hp15-nix
# Enter age decryption passphrase when prompted to restore ~/.ssh

sudo reboot
```
