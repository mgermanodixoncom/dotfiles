#!/usr/bin/env bash

function main() {
	local session_variable="${USER^^}_SESSION"
	local current_session=${!session_variable}

	if [[ -z $current_session ]]; then
		eval "export $session_variable=plasmamobile"
		startplasmamobile
	fi
}

main "$@"

unset fix_broken_wayland_session toggle_ssh_authentication reboot_system shutdown_system main
