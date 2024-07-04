#!/usr/bin/env bash

#################################
# LOGIN TERMINAL CONFIGURATIONS #
#################################

##
## System Initialization
##

function initialize_system() {
	local profile_variable="${USER^^}_PROFILE"
	local profile=${!profile_variable}

	case $profile in
		general-*|universal-*) 	source "$HOME/.dotfiles/scripts/greeter.sh"		;;
		smartphone-*) 			source "$HOME/.dotfiles/scripts/smartphone.sh"	;;
	esac
}; initialize_system

##
## Dotfiles Bootstrapping
##

source "$HOME/.dotfiles/scripts/bootstrap.sh"

##
## Common Configuration
##

source "$HOME/.dotfiles/shell"
