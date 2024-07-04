#!/usr/bin/env bash

function main() {
    cd "$HOME/.dotfiles"
    if [[ -n $(git status --porcelain) ]]; then
        if [[ $1 == -a ]]; then
            local response
            printf 'Would you like to commit your changes? (y/N) '
            read -rn1 response
            case $response in
            y|Y)
                printf '\nCommitting changes...\n'
                ;;
            *)
                if [[ -n $response ]]; then
                    printf '\n'
                fi
                return 0
                ;;
            esac
            shift
        fi
        
        local -i commit=$(git rev-list --count HEAD)
        git add .
        git commit --quiet --message "commit $(( commit + 1 ))"
        git push --quiet
    fi
    cd "$OLDPWD"
}

main "$@"