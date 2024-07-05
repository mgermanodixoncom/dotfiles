#!/usr/bin/env bash

function main() {
	if [[ -n $SSH_CLIENT || -n $SUDO_USER ]]; then
		return 0
	fi

	local session_variable="${USER^^}_SESSION"
	local current_session=${!session_variable}

	if [[ -z $current_session ]]; then
		eval "export $session_variable=plasmamobile"
		startplasmamobile
	fi
}

main "$@"

unset main
