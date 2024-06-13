#!/usr/bin/env bash

function main() {
	if [[ $(nmcli --colors no networking connectivity) == 'full' ]]; then
        cd "$HOME/.dotfiles/"
		git pull --quiet origin master
        cd "$OLDPWD"
	fi

    local dotfile
	for dotfile in $(find $HOME/.dotfiles -type f -exec realpath --relative-base $HOME/.dotfiles {} \;); do
        if [[ ! $dotfile =~ ^\. || $dotfile =~ ^.git/ || $dotfile == .gitignore ]]; then
            continue
        fi
        
        local link_path="$HOME/$dotfile"
        if [[ -h $link_path ]]; then
            continue
        fi
        
        local link_directory=$(dirname "$link_path")
        if [[ ! -d $link_directory ]]; then
            if [[ -e $link_directory ]]; then
                rm -f "$link_directory"
            fi
            mkdir -p "$link_directory"
        fi
        if [[ -e $link_path ]]; then
            rm -f "$link_path"
        fi

        local target_path="$HOME/.dotfiles/$dotfile"
        ln -s "$target_path" "$link_path"
	done

	return 0
}

main "$@"
