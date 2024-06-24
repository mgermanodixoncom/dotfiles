#!/usr/bin/env bash

function fix_broken_wayland_session() {
	loginctl unlock-session 1

	local current_tty_file=$(tty)
	if [[ $current_tty_file =~ ^/dev/tty ]]; then
		local -i current_tty="${current_tty_file##/dev/tty}"
		chvt $(( current_tty > 1 ? current_tty - 1 : 1 ))
	fi
}

function toggle_ssh_authentication() {
	if [[ ! -p /tmp/sshd_config ]]; then
		if [[ -e /tmp/sshd_config ]]; then
			rm -f /tmp/sshd_config
		fi
		mkfifo /tmp/sshd_config
	fi

	cat /etc/ssh/sshd_config > /tmp/sshd_config &
	awk "$(cat <<- 'EOF'
	{
		switch ($1) {
		case "PasswordAuthentication":
			if ($2 == "yes")
				print "PasswordAuthentication no";
			else
				print "PasswordAuthentication yes";
			break;
		default:
			print;
		}
	}
	EOF
	)" /tmp/sshd_config | sudo tee /etc/ssh/sshd_config > /dev/null

	sudo systemctl reload sshd
}

function main() {
	local dry_run=false
	if [[ $1 == -d || $1 == --dry-run ]]; then
		dry_run=true
		shift
	fi

	if ! $dry_run && [[ -n $SSH_CLIENT || -n $SUDO_USER ]]; then
		exit 0
	fi

	local index selection session quick_action label

	local full_username=$(awk -v FS=':' -v user="$USER" "$(cat <<- 'EOF'
	{
		if ($1 == user) {
			print $5;
		}
	}
	EOF
	)" /etc/passwd)
	local current_ssh_authentication=$(awk "$(cat <<- 'EOF'
	{
		if ($1 == "PasswordAuthentication") {
			if ($2 == "yes") {
				print "passwords"
			} else {
				print "cryptographic keys"
			}
		}
	}
	EOF
	)" /etc/ssh/sshd_config)

	local -A selection_to_session
	selection_to_session[1]=plasma-x11
	selection_to_session[2]=plasma-wayland
	selection_to_session[3]=none

	local -A selection_to_quick_action
	selection_to_quick_action[a]=fix_broken_wayland_session
	selection_to_quick_action[b]=toggle_ssh_authentication

	local -A session_labels
	session_labels[1]='KDE Plasma Desktop under X11'
	session_labels[2]='KDE Plasma Desktop under Wayland'
	session_labels[3]='None'
	local -i session_count=${#session_labels[@]}

	local -A quick_action_labels
	quick_action_labels[a]='Fix Broken Wayland Session'
	quick_action_labels[b]="Toggle SSH Authentication (currently using $current_ssh_authentication)"
	local -i quick_action_count=${#quick_action_labels[@]}

	local session_variable="${USER^^}_SESSION"
	local default_session_variable="${USER^^}_DEFAULT_SESSION"
	
	local default_session=${!default_session_variable}
	
	local current_session
	if ! $dry_run; then
		current_session=${!session_variable}
	fi
	local current_quick_action

	local current_selection
	local default_selection='<not set>'
	for selection in "${!selection_to_session[@]}"; do
		session=${selection_to_session[$selection]}
		if [[ "$session" == "$default_session" ]]; then
			default_selection=$selection
			break
		fi
	done

	while [[ -z $current_session ]]; do
		clear

		printf 'Welcome, %s\n\n' "$full_username"

		printf 'Available Desktop Sessions:\n'
		for selection in $(seq 1 $session_count); do
			label=${session_labels[$selection]}
			printf '\t%s. %s\n' "$selection" "$label"
		done
		printf '\n'

		printf 'Available Quick Actions:\n'
		for selection in $(seq 1 $quick_action_count | awk '{ printf "%c\n", 96 + $1; }'); do
			label=${quick_action_labels[$selection]}
			printf '\t%s. %s\n' "$selection" "$label"
		done
		printf '\n'

		printf 'Please enter your selection (default %s): ' "$default_selection"
		read -rn1 current_selection
		if [[ -z $current_selection ]]; then
			if [[ $default_selection == '<not set>' ]]; then
				printf 'Default session is not configured properly. Please enter a valid session or quick action selection.\n'
				read
				continue
			fi
			current_selection="$default_selection"
		else
			printf '\n'
		fi

		if [[ $current_selection =~ [0-9] ]]; then
			for selection in "${!selection_to_session[@]}"; do
				session=${selection_to_session[$selection]}
				if [[ "$selection" == "$current_selection" ]]; then
					current_session=$session
					break
				fi
			done
			if [[ -z $current_session ]]; then
				printf '\nInvalid selection. Please try again.'
				read -n1
				continue
			fi

			if ! $dry_run; then
				eval "export $session_variable=$current_session"
				if [[ $current_session == plasma-x11 ]]; then
					exec startx
				elif [[ $current_session == plasma-wayland ]]; then
					exec /usr/lib/plasma-dbus-run-session-if-needed startplasma-wayland
				fi
			else
				printf '\n$current_session=%s\n' "$current_session"
				exit 0
			fi
		elif [[ $current_selection =~ [a-z] ]]; then
			for selection in "${!selection_to_quick_action[@]}"; do
				quick_action=${selection_to_quick_action[$selection]}
				if [[ "$selection" == "$current_selection" ]]; then
					current_quick_action=$quick_action
					break
				fi
			done
			if [[ -z $current_quick_action ]]; then
				printf '\nInvalid selection. Please try again.'
				read -n1
				continue
			fi

			if ! $dry_run; then
				$current_quick_action
				logout
			else
				printf '\n$current_quick_action=%s\n' "$current_quick_action"
				exit 0
			fi
		else
			printf '\nInvalid selection. Please try again.'
			read -n1
		fi
	done
}

main "$@"
