#!/bin/env bash
BREW_EXE="brew"
HOMEBREW_HOME=
# PYTHON=
# export PATH=${HOME}/.local/bin:${PATH}

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
	else
		echo -e "Homebrew is installed"
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
install_homebrew
