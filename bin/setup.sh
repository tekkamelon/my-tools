#!/bin/sh -eu

# GNU coreutilsの挙動をPOSIXに準拠
export POSIXLY_CORRECT=1

# アップデート
sudo apt update -y && sudo apt upgrade -y && sudo apt autoremove

mkfifo /tmp/git.fifo

{

	# gitをインストール,成功時に名前付きパイプに書き込み
	sudo apt install git -y && echo "" > /tmp/git.fifo

	# CLIツールのインストール
	sudo apt install -y yash ksh mksh bash-completion mawk busybox w3m ranger imagemagick \

		tig shellcheck mpd mpc neomutt barcode bc ed dc rename neofetch lame htop ncmpcpp info \

		ncat nmap nc nfs-common pandoc ripgrep sc tree tmux wget curl qrencode lm-sensors fbterm

	# GUIツールのインストール
	sudo apt install -y i3 i3-wm suckless-tools stterm arandr feh i3-dmenu-desktop vlc menulibre \

		brave-browser chromium-browser rofi


} &

# gitのインストール後に実行
{

	cat /tmp/git.fifo /dev/null &&

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

	# 名前付きパイプの削除
	rm /tmp/git.fifo

} &
