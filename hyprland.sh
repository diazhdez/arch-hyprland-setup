#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
#  Variables
# ─────────────────────────────────────────────
start=$(date +%s)

PINK="\e[35m"
WHITE="\e[0m"
YELLOW="\e[33m"
GREEN="\e[32m"
BLUE="\e[34m"

clear

echo -e "${PINK}\e[1m
 WELCOME!${PINK} Now we will install and setup Hyprland on an Arch-based system
                         Created by \e[1;4mdiazhdez
${WHITE}"

echo -e "${PINK}
 *********************************************************************
 *                         ⚠️  \e[1;4mWARNING\e[0m${PINK}:                              *
 *               This script will modify your system!                *
 *         It will install Hyprland and several dependencies.        *
 *      Make sure you know what you are doing before continuing.     *
 *********************************************************************
\n"

echo -e "${YELLOW} Do you still want to continue with Hyprland installation? [y/N]: \n"
read -r confirm
case "$confirm" in
    [yY][eE][sS]|[yY])
        echo -e "\n${GREEN}[OK]${PINK} ==> Continuing with installation..."
        ;;
    *)
        echo -e "${BLUE}[NOTE]${PINK} ==> You chose NOT to proceed. Exiting..."
        echo
        exit 1
        ;;
esac

cd ~

# ─────────────────────────────────────────────
# [1/8] Full system update
# ─────────────────────────────────────────────
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[1/8]${PINK} ==> Updating system packages\n---------------------------------------------------------------------\n${WHITE}"
sudo pacman -Syu --noconfirm

# ─────────────────────────────────────────────
# [2/8] Setup terminal
# ─────────────────────────────────────────────
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[2/8]${PINK} ==> Setup terminal\n---------------------------------------------------------------------\n${WHITE}"
sleep 0.5
bash -c "$(curl -fSL https://raw.githubusercontent.com/diazhdez/arch-hyprland-setup/main/arch.sh)"

# ─────────────────────────────────────────────
# [3/8] Descargar wallpapers
# ─────────────────────────────────────────────
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[3/8]${PINK} ==> Download wallpapers\n---------------------------------------------------------------------\n${WHITE}"
git clone --depth 1 https://github.com/diazhdez/wallpapers.git ~/Wallpaper-Collection
mkdir -p ~/Pictures/Wallpapers
mv ~/Wallpaper-Collection/Wallpapers/* ~/Pictures/Wallpapers
rm -rf ~/Wallpaper-Collection

# ─────────────────────────────────────────────
# [4/8] Instalar paquetes de Hyprland
# ─────────────────────────────────────────────
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[4/8]${PINK} ==> Install packages\n---------------------------------------------------------------------\n${WHITE}"
sleep 0.5
~/dotfiles/scripts/install_archpkg.sh

# ─────────────────────────────────────────────
# [5/8] Habilitar bluetooth y NetworkManager
# ─────────────────────────────────────────────
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[5/8]${PINK} ==> Enable bluetooth & NetworkManager\n---------------------------------------------------------------------\n${WHITE}"
sudo systemctl enable --now bluetooth
sudo systemctl enable --now NetworkManager

# ─────────────────────────────────────────────
# [6/8] Aplicar fuentes
# ─────────────────────────────────────────────
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[6/8]${PINK} ==> Apply fonts\n---------------------------------------------------------------------\n${WHITE}"
fc-cache -fv

# ─────────────────────────────────────────────
# [7/8] Configurar cursor
# ─────────────────────────────────────────────
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[7/8]${PINK} ==> Set cursor\n---------------------------------------------------------------------\n${WHITE}"
~/dotfiles/scripts/setcursor.sh

# ─────────────────────────────────────────────
# [8/8] Verificar display manager y aplicar temas GTK
# ─────────────────────────────────────────────
echo -e "${PINK}\n---------------------------------------------------------------------\n${YELLOW}[8/8]${PINK} ==> Display manager & GTK themes\n---------------------------------------------------------------------\n${WHITE}"

if [[ ! -e /etc/systemd/system/display-manager.service ]]; then
    sudo tee /etc/greetd/config.toml >/dev/null <<'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --remember --time --cmd Hyprland"
user = "greeter"
EOF
    sudo systemctl enable greetd.service
    echo -e "\n${PINK}greetd (tuigreet) has been enabled."
fi

~/dotfiles/scripts/gtkthemes.sh

# ─────────────────────────────────────────────
#  Final
# ─────────────────────────────────────────────
sleep 0.7
clear

end=$(date +%s)
duration=$((end - start))
hours=$((duration / 3600))
minutes=$(((duration % 3600) / 60))
seconds=$((duration % 60))
printf -v minutes "%02d" "$minutes"
printf -v seconds "%02d" "$seconds"

echo -e "\n
 *********************************************************************
 *                    Hyprland setup is complete!                    *
 *                                                                   *
 *             Duration : $hours hours, $minutes minutes, $seconds seconds            *
 *                                                                   *
 *   It is recommended to \e[1;4mREBOOT\e[0m your system to apply all changes.   *
 *                                                                   *
 *                 \e[4mHave a great time with Hyprland!!${WHITE}                 *
 *********************************************************************
\n"
