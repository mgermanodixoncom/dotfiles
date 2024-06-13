#!/usr/bin/env bash

# TODO: Upon finishing M.I.C.H.A.L., use $SORUCODER_CONFIGURATION instead of relying on $HOSTNAME
if [[ $HOSTNAME != sorucoder-server && -z $SSH_CLIENT ]]; then
    while [[ -z $SORUCODER_SESSION ]]; do
		printf 'Available Desktop Sessions:\n'
        printf '\t1. KDE Plasma Desktop under X11\n'
        printf '\t2. KDE Plasma Desktop under Wayland\n'
        printf '\t3. None\n\n'
        
        printf 'Available Quick Actions:\n'
        printf '\ta. Restore Broken Wayland Session\n\n'

		printf "Please enter your selection (default ${SORUCODER_DEFAULT_SESSION:-1}): "
		read -n 1 SORUCODER_SESSION
        if [[ -z $SORUCODER_SESSION ]]; then
            SORUCODER_SESSION=${SORUCODER_DEFAULT_SESSION:-1}
        fi

        case $SORUCODER_SESSION in
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
            loginctl unlock-session 1
            chvt 1
            logout
            ;;
        *)
            unset SORUCODER_SESSION
            printf 'Invalid entry. Please try again.\n\n'
            ;;
        esac
	done
fi
