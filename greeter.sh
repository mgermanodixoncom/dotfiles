#!/usr/bin/env bash

# TODO: Upon finishing M.I.C.H.A.L., use $SORUCODER_CONFIGURATION instead of relying on $HOSTNAME
function main() {
	if [[ -z $SSH_CLIENT && -z $SUDO_USER ]]; then
		while [[ -z $SORUCODER_SESSION ]]; do
            local default_selection
            case $SORUCODER_DEFAULT_SESSION in
            plasma-x11)
                default_selection=1
                ;;
            plasma-wayland)
                default_selection=2
                ;;
            none)
                default_selection=3
                ;;
            *)
                default_selection='<not set>'
                ;;
            esac

			printf 'Available Desktop Sessions:\n'
			printf '\t1. KDE Plasma Desktop under X11\n'
			printf '\t2. KDE Plasma Desktop under Wayland\n'
			printf '\t3. None\n\n'
			
			printf 'Available Quick Actions:\n'
			printf '\ta. Fix Broken Wayland Session\n'
			printf '\tb. Toggle SSH Password Authentication\n\n'

			local selection
			printf "Please enter your selection (default %s): " "$default_selection"
			read -rn1 selection
			if [[ -z $selection ]]; then
                if [[ $default_selection == '<not set>' ]]; then
                    printf 'Default session is not configured. Please enter a valid entry.\n'
                    continue
                fi
                selection="$default_selection"
            else
                printf '\n'
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
				;;
			a)
				printf 'Fixing Broken Wayland Session...\n'

				loginctl unlock-session 1
				
				local current_tty_file=$(tty)
                if [[ $current_tty_file =~ ^/dev/tty ]]; then
                    local -i current_tty="${current_tty_file##/dev/tty}"
                    chvt $(( current_tty > 1 ? current_tty - 1 : 1 ))
                fi
				
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
				)" /tmp/sshd_config | sudo tee /etc/ssh/sshd_config > /dev/null
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