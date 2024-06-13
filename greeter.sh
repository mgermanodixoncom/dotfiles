#!/usr/bin/env bash

# TODO: Upon finishing M.I.C.H.A.L., use $SORUCODER_CONFIGURATION instead of relying on $HOSTNAME
function main() {
	if [[ $HOSTNAME != sorucoder-server && -z $SSH_CLIENT ]]; then
		while [[ -z $SORUCODER_SESSION ]]; do
			printf 'Available Desktop Sessions:\n'
			printf '\t1. KDE Plasma Desktop under X11\n'
			printf '\t2. KDE Plasma Desktop under Wayland\n'
			printf '\t3. None\n\n'
			
			printf 'Available Quick Actions:\n'
			printf '\ta. Fix Broken Wayland Session\n'
			printf '\tb. Toggle SSH Password Authentication\n\n'

			local selection
			printf "Please enter your selection (default %s): " "${SORUCODER_DEFAULT_SESSION:-not set}"
			read -rn1 selection
			if [[ -z $selection ]]; then
				printf '\n'
				if [[ -z $SORUCODER_DEFAULT_SESSION ]]; then
					printf 'No default entry. Please enter a valid selection.\n'
					continue
				fi
				case $SORUCODER_DEFAULT_SESSION in
				plasma-x11)
					selection=1
					;;
				plasma-wayland)
					selection=2
					;;
				*)
					selection=3
					;;
				esac
			fi

			case $selection in
			1)
				export SORUCODER_SESSION=plasma-x11
				exec startx
				;;
			2)
				export SORUCODER_SESSION=plasma-wayland
				exec /usr/lib/plasma-dbus-run-session-if-needed /usr/bin/startplasma-wayland
				;;
			3)
				export SORUCODER_SESSION=none
				printf '\n'
				;;
			a)
				printf 'Fixing Broken Wayland Session...\n'

				loginctl unlock-session 1
				
				chvt 1
				
				logout
				;;
			b)
				printf 'Toggling SSH Password Authentication...\n'
				
				mkfifo /tmp/sshd_config
				sudo cat /etc/ssh/sshd_config | tee /tmp/sshd_config > /dev/null &
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
				)" /tmp/sshd_config | sudo tee /etc/sshd_config > /dev/null
				rm /tmp/sshd_config

				sudo systemctl reload sshd

				logout
				;;
			*)
				unset SORUCODER_SESSION
				printf 'Invalid entry. Please try again.\n\n'
				;;
			esac
		done
	fi
}

main "$@"