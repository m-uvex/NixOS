# ❄️ OrbitOS

Declarative, multi-host, multi-dots, feature-full, flake based NixOS configs.

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
/orbitos/
├── config/                 # Modular user dotfiles & app configurations
│   ├── cursor/             # Dynamic wallpaper-matching cursor generator
│   ├── fish/               # Fish shell configuration & environment
│   ├── gtk-3.0/            # GTK 3 custom stylesheets
│   ├── gtk-4.0/            # GTK 4 custom stylesheets
│   ├── hypr/               # Hyprland lua configurations & rules
│   └── kitty/              # Kitty terminal configuration
├── flake.nix               # Flake inputs, outputs, and system definitions
├── hosts/                  # Per-host NixOS machine definitions
│   ├── lt-hp15-nix/        # Orion (Laptop)
│   ├── pc-main-nix/        # Andromeda (Main PC)
│   └── srv-c4030-nix/      # Lunar (Server & WoL Relay)
├── modules/                # Modular system & hardware configurations
│   ├── app-configs/        # Per-app integration hooks (fish, gtk, hypr, kitty)
│   ├── app-configs.nix     # Modular app layer & overwrite engine
│   ├── apps.nix            # System-wide GUI apps and tools
│   ├── assets/             # Wallpapers and media
│   ├── core.nix            # Base system, OpenSSH, nh, and networking
│   ├── desktop.nix         # Hyprland, audio, display managers
│   ├── docker.nix          # Docker daemon configuration
│   ├── gaming.nix          # Steam, GameMode, Minecraft, controller drivers
│   ├── hardware/           # Modular CPU & GPU hardware profiles
│   ├── rebuild.nix         # OrbitOS rebuild CLI & SSH key tools
│   ├── remote-desktop/     # Sunshine streaming host & Moonlight client
│   └── server/             # Server stacks, storage, and filesystem profiles
├── secrets/
│   └── ssh.tar.age         # Passphrase-encrypted ~/.ssh archive bundle
└── users/                  # Modular user accounts & user environments
    ├── m_uvex/             # Musa Murad (NixOS account & Home Manager environment)
    │   ├── default.nix     # System user account, groups, password & SSH keys
    │   └── home.nix        # Desktop Home Manager dotfiles, themes & services
    └── oliver/             # Oliver (Pocketbase dev user)
        └── default.nix     # System user account & restricted developer groups
```

---

## ✨ Key Features

* **Modular User Management:** User accounts and their respective desktop/service environments live under `users/`, allowing any host to reference only the users it needs.
* **Dynamic material cursors:** Cursors are dynamically colored based on the wallpaper, allowing for an overhauled and visually consistent experience.
* **Masterized SSH across devices:** `~/.ssh` is encrypted with age passphrase and committed. On first rebuild, it extracts all keys using the passphrase.
* **Visual Rebuild Tool:** Custom `rebuild` CLI tool for quick and easy system rebuild with visual package diffs, flake updating (`rebuild update`), SSH key syncing and more.
* **Remote Kiosk Specialisation:** Selectable boot-entry on Orion (`remote-kiosk`) boots directly into Moonlight sending a background Wake-on-LAN magic packet via Lunar to Andromeda.
* **Tailscale WoL Relay:** Built-in alias (`wake-pc`) and scripts allowing remote devices to trigger Wake-on-LAN on Andromeda via the always-on Lunar server node.
* **One config for all:** Single modular repository configuring desktops, laptops and servers seamlessly.
---

## 🚀 Quick Install (Fresh System)

(!) It is advised to fork this repo into your own and edit the config as you like, especially the user as the password is hashed and with this exact config you won't be able to get in!

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

# Clone repo to /orbitos and create symlink for compatibility
sudo git clone https://github.com/m-uvex/NixOS.git /orbitos
sudo ln -s /orbitos /etc/nixos

# Generate hardware profile into host (e.g. lt-hp15-nix)
sudo nixos-generate-config --root /orbitos/hosts/lt-hp15-nix/
```
### 3. Build
***PLEASE EDIT THE CONFIG BEFORE GENERATING! with my exact config, you won't be able to log in or do much of anything because of the hashed password. It is advised that you fork the repo into your own first!***

```bash
cd /orbitos
sudo git add .
sudo nixos-install --flake .#lt-hp15-nix
# Enter age decryption passphrase when prompted to restore ~/.ssh

sudo reboot
```

Note: After first rebuild, you can simply use the "rebuild" command. Run `rebuild -h` for more info.


## Have issues or question?
OrbitOS is still in alpha stages and is full of bugs but I'm making it better each day. If you want to report a bug or ask a question, feel free to DM me on;

Discord:    m_uvex

Instagram:  m.uvex

Signal:     m_uvex.01

Note: I'll be setting up proper github issues and a discord server soon but in the meantime js DM me on one of thoseissues st