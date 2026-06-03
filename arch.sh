#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
#  Variables
# ─────────────────────────────────────────────
GREEN="\e[32m"
WHITE="\e[0m"
YELLOW="\e[33m"

echo -e "
                    ${GREEN}\e[1mWELCOME!${GREEN}
    Now we will customize Arch-based Terminal
              Created by \e[1;4mdiazhdez
${WHITE}"

cd ~

# ─────────────────────────────────────────────
# [1/8] Actualizar sistema
# (puede omitirse si ya se corrió hyprland.sh paso 1)
# ─────────────────────────────────────────────
echo -e "${GREEN}\n---------------------------------------------------------------------\n${YELLOW}[1/8]${GREEN} ==> Updating system packages\n---------------------------------------------------------------------\n${WHITE}"
sudo pacman -Syu --noconfirm

# ─────────────────────────────────────────────
# [2/8] Configurar locale
# ─────────────────────────────────────────────
echo -e "${GREEN}\n---------------------------------------------------------------------\n${YELLOW}[2/8]${GREEN} ==> Setting locale\n---------------------------------------------------------------------\n${WHITE}"
sudo sed -i '/^#en_US.UTF-8 UTF-8/s/^#//' /etc/locale.gen
sudo locale-gen
sudo localectl set-locale LANG=en_US.UTF-8

# ─────────────────────────────────────────────
# [3/8] Instalar yay (AUR helper)
# ─────────────────────────────────────────────
echo -e "${GREEN}\n---------------------------------------------------------------------\n${YELLOW}[3/8]${GREEN} ==> Installing yay\n---------------------------------------------------------------------\n${WHITE}"
sudo pacman -S --noconfirm --needed base-devel git
git clone https://aur.archlinux.org/yay.git ~/yay
cd ~/yay
makepkg -si --noconfirm
cd ~
rm -rf ~/yay

# ─────────────────────────────────────────────
# [4/8] Instalar paquetes pacman
# ─────────────────────────────────────────────
echo -e "${GREEN}\n---------------------------------------------------------------------\n${YELLOW}[4/8]${GREEN} ==> Installing pacman packages\n---------------------------------------------------------------------\n${WHITE}"

pacman_packages=(
    # Monitor del sistema
    btop

    # Herramientas CLI esenciales
    wget unzip ripgrep fd tree man-db openssh
    fzf eza bat zoxide neovim stow imagemagick rsync
    github-cli yt-dlp

    # Utilidades del sistema
    reflector pacman-contrib

    # Lenguajes de programación
    python python-pip python-pipx nodejs npm

    # Shell
    zsh
)

sudo pacman -S --noconfirm --needed "${pacman_packages[@]}"

# ─────────────────────────────────────────────
# [5/8] Instalar paquetes AUR
# ─────────────────────────────────────────────
echo -e "${GREEN}\n---------------------------------------------------------------------\n${YELLOW}[5/8]${GREEN} ==> Installing AUR packages\n---------------------------------------------------------------------\n${WHITE}"

aur_packages=(
    oh-my-posh
)

yay -S --noconfirm "${aur_packages[@]}"

# ─────────────────────────────────────────────
# [5.5/8] Instalar kitten (image preview en terminal)
# ─────────────────────────────────────────────
echo -e "${GREEN}\n---------------------------------------------------------------------\n${YELLOW}[5.5/8]${GREEN} ==> Installing kitten binary\n---------------------------------------------------------------------\n${WHITE}"
mkdir -p "$HOME/.local/bin"
curl -L https://github.com/kovidgoyal/kitty/releases/latest/download/kitten-linux-amd64 \
    -o "$HOME/.local/bin/kitten"
chmod +x "$HOME/.local/bin/kitten"
echo 'export PATH="$PATH:$HOME/.local/bin"' >> "$HOME/.zprofile"

# ─────────────────────────────────────────────
# [6/8] Clonar dotfiles
# ─────────────────────────────────────────────
echo -e "${GREEN}\n---------------------------------------------------------------------\n${YELLOW}[6/8]${GREEN} ==> Cloning dotfiles\n---------------------------------------------------------------------\n${WHITE}"
git clone --depth=1 https://github.com/diazhdez/dotfiles.git ~/dotfiles

# ─────────────────────────────────────────────
# [7/8] Backup y copia de dotfiles a ~/.config
# ─────────────────────────────────────────────
echo -e "${GREEN}\n---------------------------------------------------------------------\n${YELLOW}[7/8]${GREEN} ==> Backing up existing config and deploying dotfiles\n---------------------------------------------------------------------\n${WHITE}"

# Hacer ejecutables los scripts antes de usarlos
chmod +x "$HOME/dotfiles/scripts/"*

# Backup: mueve configs existentes a ~/.backup-<timestamp>
# El script detecta automáticamente las carpetas del repo
bash "$HOME/dotfiles/scripts/backup_config.sh"

# Copiar configs del repo a ~/.config/
mkdir -p "$HOME/.config"
while IFS= read -r -d '' dir; do
    dirname="$(basename "$dir")"
    cp -r "$dir" "$HOME/.config/"
    echo "  -> Deployed: .config/$dirname"
done < <(find "$HOME/dotfiles" -mindepth 1 -maxdepth 1 -type d \
    -not -name ".*" -print0)

cp "$HOME/dotfiles/.zshrc" "$HOME/"
echo "  -> Deployed: .zshrc"

# ─────────────────────────────────────────────
# [8/8] Cambiar shell a zsh
# ─────────────────────────────────────────────
echo -e "${GREEN}\n---------------------------------------------------------------------\n${YELLOW}[8/8]${GREEN} ==> Changing default shell to zsh\n---------------------------------------------------------------------\n${WHITE}"
ZSH_PATH="$(which zsh)"
grep -qxF "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" | sudo tee -a /etc/shells
chsh -s "$ZSH_PATH"

echo -e "\n${GREEN}
 **************************************************
 *                    \e[1;4mDone\e[0m${GREEN}!!!                     *
 *       Please relogin to apply new config.      *
 **************************************************

"
