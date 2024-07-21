#!/bin/sh -eu

# GNU coreutilsの挙動をPOSIXに準拠
export POSIXLY_CORRECT=1

# アップデート
sudo apt update -y && sudo apt upgrade -y && sudo apt autoremove

mkfifo /tmp/setup.fifo

{

	# git,wget,curlをインストール,成功時に名前付きパイプに書き込み
	sudo apt install git wget -y && echo "" > /tmp/setup.fifo

	# CLIツールのインストール
	sudo apt install -y yash ksh mksh bash-completion mawk busybox w3m ranger imagemagick \

		tig shellcheck mpd mpc neomutt barcode bc ed dc rename neofetch lame htop ncmpcpp info \

		ncat nmap nc nfs-common pandoc ripgrep sc tree tmux qrencode lm-sensors fbterm curl apt-transport-https gnupg2 \

	# braveのインストールの準備
	sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

	echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list

	# vscodiumのインストール
	curl https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor \
    | sudo tee /usr/share/keyrings/vscodium.gpg >/dev/null

	echo "deb [arch=amd64 signed-by=/usr/share/keyrings/vscodium.gpg] https://download.vscodium.com/debs vscodium main" |
    
	sudo tee /etc/apt/sources.list.d/vscodium.list

	sudo apt update

	# GUIツールのインストール
	sudo apt install -y i3 i3-wm suckless-tools stterm arandr feh i3-dmenu-desktop vlc menulibre \

		brave-browser chromium-browser rofi codium \

		openscad meshlab cool-retro-term asunder easytag luakit steam thunar arandr vlc obs-studio

} &

# gitのインストール後に実行
{

	cat /tmp/setup.fifo /dev/null &&

	mkdir -p "${HOME}"/.local/bin "${HOME}"/Documents/github/OUJ "${HOME}"/Documents/library \

		"${HOME}"/Downloads "${HOME}"/Desktop "${HOME}"/Music "${HOME}"/Pictures "${HOME}"/Templates "${HOME}"/Videos

	cd "${HOME}"/Documents/github

	git clone https://github.com/tekkamelon/sh-mpd.git
	git clone https://github.com/tekkamelon/book_manager.git
	git clone https://github.com/tekkamelon/dotfiles.git
	git clone https://github.com/tekkamelon/interactive-mpc.git
	git clone https://github.com/tekkamelon/my-tools.git

	cp dotfiles/.*shrc "${HOME}"/
	cp -r dotfiles/.config/* "${HOME}"/.config/
	cp -r dotfiles/bin/* "${HOME}"/.local/bin/
	cp dotfiles/.config/user-dirs.dirs "${HOME}"/.config/

	# neovimのダウンロード,セットアップ
	wget -q -O nvim https://github.com/neovim/neovim/releases/download/v0.9.2/nvim.appimage

	mv nvim "${HOME}"/.local/bin

	sudo chmod 755 "${HOME}"/.local/bin/nvim

	# *.vimファイルを削除
	find "${HOME}"/.config/nvim --name "*.vim" -exec + rm

	# 名前付きパイプの削除
	rm /tmp/setup.fifo

} &

