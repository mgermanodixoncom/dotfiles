#!/usr/bin/env bash

# TODO: Upon finishing M.I.C.H.A.L., use $SORUCODER_CONFIGURATION instead of relying on $HOSTNAME

function fix_broken_wayland_session() {
	loginctl unlock-session 1
	
	local current_tty_file=$(tty)
	if [[ $current_tty_file =~ ^/dev/tty ]]; then
		local -i current_tty="${current_tty_file##/dev/tty}"
		chvt $(( current_tty > 1 ? current_tty - 1 : 1 ))
	fi
	
	logout
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

	logout
}

function main() {
	if [[ -z $SSH_CLIENT && -z $SUDO_USER ]]; then
		local -A selection_to_session
		selection_to_session[1]=plasma-x11
		selection_to_session[2]=plasma-wayland
		selection_to_session[3]=none

		local -A session_to_selection
		session_to_selection[plasma-x11]=1
		session_to_selection[plasma-wayland]=2
		session_to_selection[none]=3

		local session_variable="${USER^^}_SESSION"
		local default_session_variable="${USER^^}_DEFAULT_SESSION"
		local current_session=${!session_variable}
		local default_session=${!default_session_variable}

		local current_selection
		local default_selection='<not set>'
		local session
		local selection
		for session in "${!session_to_selection[@]}"; do
			selection=${session_to_selection[$session]}
			if [[ "$session" == "$default_session" ]]; then
				default_selection=$selection
				break
			fi
		done

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

		while [[ -z $current_session ]]; do
			printf 'Available Desktop Sessions:\n'
			printf '\t1. KDE Plasma Desktop under X11\n'
			printf '\t2. KDE Plasma Desktop under Wayland\n'
			printf '\t3. None\n\n'
			
			printf 'Available Quick Actions:\n'
			printf '\ta. Fix Broken Wayland Session\n'
			printf '\tb. Toggle SSH Authentication (currently using %s)\n\n' "$current_ssh_authentication"

			printf 'Please enter your selection (default %s): ' "$default_selection"
			read -rn1 current_selection
			if [[ -z $current_selection ]]; then
                if [[ $default_selection == '<not set>' ]]; then
                    printf '\nDefault session is not configured properly. Please enter a valid entry.\n'
                    continue
                fi
                current_selection="$default_selection"
            else
                printf '\n'
            fi

			if [[ $current_selection =~ [0-9] ]]; then
				current_session=${selection_to_session[$current_selection]}
				eval "export $session_variable=$current_session"
				if [[ $current_session == plasma-x11 ]]; then
					exec startx
				elif [[ $current_session == plasma-wayland ]]; then
					exec /usr/lib/plasma-dbus-run-session-if-needed startplasma-wayland
				fi
			elif [[ $current_selection == a ]]; then
				fix_broken_wayland_session
			elif [[ $current_selection == b ]]; then
				toggle_ssh_authentication
			fi
		done
	fi
}

main "$@"