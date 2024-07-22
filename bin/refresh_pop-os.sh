#!/bin/sh 
# pop-osのリフレッシュインストール後のセットアップ用

set -eu

# アップデート
sudo apt update -y && sudo apt upgrade -y && sudo apt autoremove

# CLIツールのインストール
sudo apt install -y yash ksh mksh bash-completion mawk busybox w3m ranger imagemagick \

tig shellcheck mpd mpc neomutt barcode bc ed dc rename neofetch lame htop ncmpcpp info \

ncat nmap nc nfs-common pandoc ripgrep sc tree tmux qrencode lm-sensors fbterm curl apt-transport-https gnupg2 fonts-vlgothic \

pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev python3

# rustとcargoをインストール
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# braveのインストールの準備
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list

# icecatのインストールの準備
echo 'deb https://download.opensuse.org/repositories/home:/losuler:/icecat/Debian_11/ /' | sudo tee /etc/apt/sources.list.d/home:losuler:icecat.list
curl -fsSL https://download.opensuse.org/repositories/home:losuler:icecat/Debian_11/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_losuler_icecat.gpg > /dev/null


cd "${HOME}"

# GUIツールのインストール
sudo apt install -y xfce4 i3 i3-wm suckless-tools stterm arandr feh i3-dmenu-desktop vlc menulibre xfce4-popup-whiskermenu \

brave-browser chromium-browser icecat rofi \

openscad meshlab cool-retro-term asunder easytag luakit steam thunar arandr obs-studio stterm

# vscodeのインストール
cd "${HOME}"/Downloads

wget -O code.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"

sudo dpkg -i code.deb
# fusion360のインストール
mkdir -p "$HOME/.fusion360/bin" && cd "$HOME/.fusion360/bin" && wget -N https://raw.githubusercontent.com/cryinkfly/Autodesk-Fusion-360-for-Linux/main/files/builds/stable-branch/bin/install.sh && chmod +x install.sh && ./install.sh

