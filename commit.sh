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
                printf 'Commiting changes...\n'
                ;;
            *)
                if [[ -z $response ]]; then
                    printf '\n'
                fi
                return 0
                ;;
            esac
            shift
        fi
        
        local -i commit=$(git rev-list --count master)
        git add .
        git commit --message "commit $(( commit + 1 ))"
        git push origin --quiet &> /dev/null
    fi
    cd "$OLDPWD"
}

main "$@"