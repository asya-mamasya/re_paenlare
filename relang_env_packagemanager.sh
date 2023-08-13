#!/usr/bin/env bash
#
# Copyright (C) 2023 Ronald Record <ronaldrecord@gmail.com>
# Copyright (C) 2022 Michael Peter <michaeljohannpeter@gmail.com>
#
# Install Neovim and all dependencies for the Neovim config at:
#     https://github.com/doctorfree/nvim-lazyman
#
# shellcheck disable=SC2001,SC2016,SC2006,SC2086,SC2181,SC2129,SC2059,SC2164

RC='\e[0m'
RED='\e[31m'
# YELLOW='\e[33m'
# GREEN='\e[32m'
# GREEN2='[32;1m'
# WHITE='[37;1m'
# BLUE='[34;1m'

RV='\u001b[7m'

THIS_REPO_PATH="$(dirname "$(realpath "$0")")"
# THIS_REPO_PATH=$HOME/REPOS/reinst
DOT_CFG_PATH=$THIS_REPO_PATH/config
DOT_HOME_PATH=$THIS_REPO_PATH/home
USR_CFG_PATH=$HOME/.config
SRC_DIR=$HOME/src
# FONT_DIR=$HOME/.local/share/fonts
# USR_CFG_PATH=$THIS_REPO_PATH/test

BREW_EXE="brew"
HOMEBREW_HOME=
# PYTHON=
# export PATH=${HOME}/.local/bin:${PATH}

configExists() {
	[[ -e "$1" ]] && [[ ! -L "$1" ]]
}

command_exists() {
	command -v $1 >/dev/null 2>&1
}

abort() {
	printf "\nERROR: %s\n" "$@" >&2
	exit 1
}

log() {
	[ "$quiet" ] || {
		printf "\n\t%s" "$@"
	}
}

calc_elapsed() {
	FINISH_SECONDS=$(date +%s)
	ELAPSECS=$((FINISH_SECONDS - START_SECONDS))
	ELAPSED=$(eval "echo $(date -ud "@$ELAPSECS" +'$((%s/3600/24)) days %H hr %M min %S sec')")
}

check_prerequisites() {
	if [ "${BASH_VERSION:-}" = "" ]; then
		abort "Bash is required to interpret this script."
	fi
	# [ "${BASH_VERSINFO:-0}" -ge 4 ] || install_bash=1

	if [[ $EUID -eq 0 ]]; then
		abort "Script must not be run as root user"
	fi

	architecture=$(uname -m)
	if [[ $architecture =~ "arm" || $architecture =~ "aarch64" ]]; then
		abort "Only amd64/x86_64 is supported"
	fi
}
check_prerequisites

checkEnv() {
	## Check Package Handeler
	PACKAGEMANAGER='apt dnf'
	for pgm in ${PACKAGEMANAGER}; do
		if command_exists ${pgm}; then
			PACKAGER=${pgm}
			echo -e ${RV}"Using ${pgm}"
		fi
	done

	if [ -z "${PACKAGER}" ]; then
		echo -e "${RED}Can't find a supported package manager"
		exit 1
	fi

	## Check if the current directory is writable.
	PATHs="$THIS_REPO_PATH $USR_CFG_PATH "
	for path in $PATHs; do
		if [[ ! -w ${path} ]]; then
			echo -e "${RED}Can't write to ${path}${RC}"
			exit 1
		fi
	done
}
checkEnv

function install_packages {
	DEPENDENCIES='curl wget python3 pipx aptitude nala libxml2-dev luakit'

	sudo ${PACKAGER} install -yq ${DEPENDENCIES}
}

# перед создание линков делает бекапы только тех пользовательских конфикураций,
# файлы которых есть в ./config ./home
function back_sym {
	mkdir -p "$USR_CFG_PATH"
	echo -e "${RV}${YELLOW} Backing up existing files... ${RC}"
	for config in $(command ls ${DOT_CFG_PATH}); do
		if configExists "${USR_CFG_PATH}/${config}"; then
			echo -e "${YELLOW}Moving old config ${USR_CFG_PATH}/${config} to ${USR_CFG_PATH}/${config}.old${RC}"
			if ! mv "${USR_CFG_PATH}/${config}" "${USR_CFG_PATH}/${config}.old"; then
				echo -e "${RED}Can't move the old config!${RC}"
				exit 1
			fi
			echo -e "${WHITE} Remove backups with 'rm -ir ~/.*.old && rm -ir ~/.config/*.old' ${RC}"
		fi
		echo -e "${GREEN}Linking ${DOT_CFG_PATH}/${config} to ${USR_CFG_PATH}/${config}${RC}"
		if ! ln -snf "${DOT_CFG_PATH}/${config}" "${USR_CFG_PATH}/${config}"; then
			echo echo -e "${RED}Can't link the config!${RC}"
			exit 1
		fi
	done

	for config in $(command ls ${DOT_HOME_PATH}); do
		if configExists "$HOME/.${config}"; then
			echo -e "${YELLOW}Moving old config ${HOME}/.${config} to ${HOME}/.${config}.old${RC}"
			if ! mv "${HOME}/.${config}" "${HOME}/.${config}.old"; then
				echo -e "${RED}Can't move the old config!${RC}"
				exit 1
			fi
			echo -e "${WHITE} Remove backups with 'rm -ir ~/.*.old && rm -ir ~/.config/*.old' ${RC}"
		fi
		echo -e "${GREEN}Linking ${DOT_HOME_PATH}/${config} to ${HOME}/.${config}${RC}"
		if ! ln -snf "${DOT_HOME_PATH}/${config}" "${HOME}/.${config}"; then
			echo echo -e "${RED}Can't link the config!${RC}"
			exit 1
		fi
	done

}

SRC_LUA_DIR="${SRC_DIR}/lua"
SRC_LUAROCKS_DIR="${SRC_DIR}/luarocks"

lua_version="5.4.6"
luarocks_version="3.9.2"

# Lua
function install_lua {
	if ! command_exists lua; then
		echo -e "${RV} Installing Lua ${RC}"
		mkdir -p "$SRC_LUA_DIR"
		cd "$SRC_DIR" || return
		curl -R -O http://www.lua.org/ftp/lua-"$lua_version".tar.gz
		tar -zxf lua-"$lua_version".tar.gz
		cd lua-"$lua_version" || return
		make linux test
		sudo make install
		rm -rf lua-"$lua_version".tar.gz
	else
		echo -e "${RV} Lua is installed ${RC}"
	fi
}

# Luarocks
function install_luarocks {
	if command_exists lua; then
		if ! command_exists luarocks; then
			echo -e "${RV} Installing Luarocks... ${RC}"
			mkdir -p "$SRC_LUAROCKS_DIR"
			cd "$SRC_LUAROCKS_DIR" || return
			wget https://luarocks.org/releases/luarocks-"$luarocks_version".tar.gz
			tar -zxpf luarocks-"$luarocks_version".tar.gz
			rm -rf luarocks-"$luarocks_version".tar.gz
			cd luarocks-"$luarocks_version" || return
			./configure --with-lua-include=/usr/local/include
			make
			sudo make install
		else
			echo -e "${RV} Luarocks is installed${RC}"
		fi
	else
		echo -e "${RED}Lua is not installed!${RC}"
		install_lua
		install_luarocks
	fi
}
function install_r {
	echo -e "${RV} Installing R... ${RC}"
	#R
	wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
	# gpg --show-keys /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
	sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu jammy-cran40/"
	sudo apt-get update
	sudo apt-get install r-base
	sudo apt-get install r-base-dev libxml2-dev
	sudo add-apt-repository ppa:c2d4u.team/c2d4u4.0+
	# sudo apt install --no-install-recommends r-cran-tidyverse
	# deb https://<my.favorite.ubuntu.mirror>/ focal-backports main restricted universe
	R --version
}

function install_conda {
	echo -e "${RV} Installing R... ${RC}"

	wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -P $SRC_DIR
	bash $SRC_DIR/Miniconda3-latest-Linux-x86_64.sh
}

function install_cargo {
	## Check for dependencies.
	# DEPEND='libfontconfig1-dev libxcb-shape0-dev libxcb-xfixes0-dev libxkbcommon-dev'
	# echo -e "${RV}${YELLOW} Installing dependencies${RC}"
	# sudo "${PACKAGER}" install -yq "${DEPEND}"
	# Rust,Cargo
	if ! command_exists cargo; then
		echo -e "${RV} Installing Cargo ${RC}"
		curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
	else
		echo -e "${RV} Rust is installed${RC}"
	fi
}

function install_nodejs {
	echo -e "\u001b[7m Installing NodeJS... \u001b[0m"
	# nodejs
	sudo apt remove nodejs
	sudo apt autoremove
	curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
	sudo apt install -y nodejs
	node -v
	npm -v
}

function install_debget {
	echo -e "${RV} Installing deb-get ${RC}"
	#deb-get
	curl -sL https://raw.githubusercontent.com/wimpysworld/deb-get/main/deb-get | sudo -E bash -s install deb-get
	# deb-get install google-chrome-stable zoom exodus discord flameshot balena-etcher-electron whatsapp-for-linux
}

install_homebrew() {
	if ! command -v brew >/dev/null 2>&1; then
		[ "$debug" ] && START_SECONDS=$(date +%s)
		log "Installing Homebrew ..."
		# BREW_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
		# curl -fsSL "$BREW_URL" >/tmp/brew-$$.sh
		# [ $? -eq 0 ] || {
		# 	rm -f /tmp/brew-$$.sh
		# 	curl -kfsSL "$BREW_URL" >/tmp/brew-$$.sh
		# }
		# [ -f /tmp/brew-$$.sh ] || abort "Brew install script download failed"
		# chmod 755 /tmp/brew-$$.sh
		# NONINTERACTIVE=1 /bin/bash -c "/tmp/brew-$$.sh" >/dev/null 2>&1
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		# rm -f /tmp/brew-$$.sh
		export HOMEBREW_NO_INSTALL_CLEANUP=1
		export HOMEBREW_NO_ENV_HINTS=1
		export HOMEBREW_NO_AUTO_UPDATE=1
		[ "$quiet" ] || printf " done"
		if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
			HOMEBREW_HOME="/home/linuxbrew/.linuxbrew"
			BREW_EXE="${HOMEBREW_HOME}/bin/brew"
		else
			if [ -x /usr/local/bin/brew ]; then
				HOMEBREW_HOME="/usr/local"
				BREW_EXE="${HOMEBREW_HOME}/bin/brew"
			else
				if [ -x /opt/homebrew/bin/brew ]; then
					HOMEBREW_HOME="/opt/homebrew"
					BREW_EXE="${HOMEBREW_HOME}/bin/brew"
				else
					abort "Homebrew brew executable could not be located"
				fi
			fi
		fi

		[ "$debug" ] && {
			calc_elapsed
			printf "\nHomebrew install elapsed time = ${ELAPSED}\n"
		}
		log "Homebrew installed in ${HOMEBREW_HOME}"
	fi
	eval "$("$BREW_EXE" shellenv)"
	have_brew=$(type -p brew)
	[ "$have_brew" ] && BREW_EXE="brew"
	[ "$HOMEBREW_HOME" ] || {
		brewpath=$(command -v brew)
		if [ $? -eq 0 ]; then
			HOMEBREW_HOME=$(dirname "$brewpath" | sed -e "s%/bin$%%")
		else
			HOMEBREW_HOME="Unknown"
		fi
	}
}

function all {
	echo -e "\u001b[7m Setting up Dotfiles... \u001b[0m"
	install_packages
	back_sym
	install_lua
	install_luarocks
	install_r
	install_conda
	install_cargo
	install_nodejs
	install_homebrew
	install_debget
	echo -e "\u001b[7m Done! \u001b[0m"
}

if [ "$1" = "--backsym" ] || [ "$1" = "-b" ]; then
	back_sym
	exit 0
fi

if [ "$1" = "--all" -o "$1" = "-a" ]; then
	all
	exit 0
fi

# Menu TUI
echo -e "\u001b[32;1m Setting up Dotfiles...\u001b[0m"

echo -e " \u001b[37;1m\u001b[4mSelect an option:\u001b[0m"
echo -e "  \u001b[34;1m (a) ALL \u001b[0m"
echo -e "  \u001b[34;1m (p) install packages \u001b[0m"
echo -e "  \u001b[34;1m (s) backup and symlink \u001b[0m"
echo -e "  \u001b[34;1m (l) install lua \u001b[0m"
echo -e "  \u001b[34;1m (r) install luarocks (5,6,13) \u001b[0m"
echo -e "  \u001b[34;1m (R) install R \u001b[0m"
echo -e "  \u001b[34;1m (c) install conda \u001b[0m"
echo -e "  \u001b[34;1m (C) install cargo \u001b[0m"
echo -e "  \u001b[34;1m (n) install NodeJS \u001b[0m"
echo -e "  \u001b[34;1m (b) install brew \u001b[0m"
echo -e "  \u001b[34;1m (d) install deb-get \u001b[0m"

echo -e "  \u001b[31;1m (*) Anything else to exit \u001b[0m"

echo -en "\u001b[32;1m ==> \u001b[0m"

read -r option

case $option in

"a")
	all
	;;

"p")
	install_packages
	;;

"s")
	back_sym
	;;

"l")
	install_lua
	;;

"r")
	install_luarocks
	;;

"R")
	install_r
	;;

"c")
	install_conda
	;;

"C")
	install_cargo
	;;

"n")
	install_nodejs
	;;

"b")
	install_homebrew
	;;

"d")
	install_debget
	;;

*)
	echo -e "\u001b[31;1m Invalid option entered, Bye! \u001b[0m"
	exit 0
	;;
esac

exit 0
