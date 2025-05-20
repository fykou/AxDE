#!/usr/bin/env zsh
#!          ░▒▓
#!        ░▒▒░▓▓
#!      ░▒▒▒░░░▓▓           ___________
#!    ░░▒▒▒░░░░░▓▓        //___________/
#!   ░░▒▒▒░░░░░▓▓     _   _ _    _ _____
#!   ░░▒▒░░░░░▓▓▓▓▓ | | | | |  | |  __/
#!    ░▒▒░░░░▓▓   ▓▓ | |_| | |_/ /| |___
#!     ░▒▒░░▓▓   ▓▓   \__  |____/ |____/    ▀█ █▀ █░█
#!       ░▒▓▓   ▓▓  //____/                █▄ ▄█ █▀█

# HyDE's ZSH env configuration
# This file is sourced by ZSH on startup
# And ensures that we have an obstruction-free ~/.zshrc file
# This also ensures that the proper HyDE $ENVs are loaded

function command_not_found_handler {
    local purple='\e[1;35m' bright='\e[0;1m' green='\e[1;32m' reset='\e[0m'
    printf "${green}zsh${reset}: command ${purple}NOT${reset} found: ${bright}'%s'${reset}\n" "$1"

    if ! ${PM_COMMAND[@]} -h &>/dev/null; then
        return 127
    fi

    printf "${bright}Searching for packages that provide '${bright}%s${green}'...\n${reset}" "${1}"

    if ! "${PM_COMMAND[@]}" fq "/usr/bin/$1"; then
        printf "${bright}${green}[ ${1} ]${reset} ${purple}NOT${reset} found in the system and no package provides it.\n"
        return 127
    else
        printf "${green}[ ${1} ] ${reset} might be provided by the above packages.\n"
        for entry in $entries; do
            # Assuming the entry already has ANSI color codes, we don't add more colors
            printf "  %s\n" "${entry}"
        done

    fi
    return 127
}

# Function to handle initialization errors
function handle_init_error {
    if [[ $? -ne 0 ]]; then
        echo "Error during initialization. Please check your configuration."
    fi
}

function no_such_file_or_directory_handler {
    local red='\e[1;31m' reset='\e[0m'
    printf "${red}zsh: no such file or directory: %s${reset}\n" "$1"
    return 127
}

# best fzf aliases ever
_fuzzy_change_directory() {
    local initial_query="$1"
    local selected_dir
    local fzf_options=('--preview=ls -p {}' '--preview-window=right:60%')
    fzf_options+=(--height "80%" --layout=reverse --preview-window right:60% --cycle)
    local max_depth=7

    if [[ -n "$initial_query" ]]; then
        fzf_options+=("--query=$initial_query")
    fi

    #type -d
    selected_dir=$(find . -maxdepth $max_depth \( -name .git -o -name node_modules -o -name .venv -o -name target -o -name .cache \) -prune -o -type d -print 2>/dev/null | fzf "${fzf_options[@]}")

    if [[ -n "$selected_dir" && -d "$selected_dir" ]]; then
        cd "$selected_dir" || return 1
    else
        return 1
    fi
}

_fuzzy_edit_search_file_content() {
    # [f]uzzy [e]dit  [s]earch [f]ile [c]ontent
    local selected_file
    selected_file=$(grep -irl "${1:-}" ./ | fzf --height "80%" --layout=reverse --preview-window right:60% --cycle --preview 'cat {}' --preview-window right:60%)

    if [[ -n "$selected_file" ]]; then
        if command -v "$EDITOR" &>/dev/null; then
            "$EDITOR" "$selected_file"
        else
            echo "EDITOR is not specified. using vim.  (you can export EDITOR in ~/.zshrc)"
            vim "$selected_file"
        fi

    else
        echo "No file selected or search returned no results."
    fi
}

_fuzzy_edit_search_file() {
    local initial_query="$1"
    local selected_file
    local fzf_options=()
    fzf_options+=(--height "80%" --layout=reverse --preview-window right:60% --cycle)
    local max_depth=5

    if [[ -n "$initial_query" ]]; then
        fzf_options+=("--query=$initial_query")
    fi

    # -type f: only find files
    selected_file=$(find . -maxdepth $max_depth -type f 2>/dev/null | fzf "${fzf_options[@]}")

    if [[ -n "$selected_file" && -f "$selected_file" ]]; then
        if command -v "$EDITOR" &>/dev/null; then
            "$EDITOR" "$selected_file"
        else
            echo "EDITOR is not specified. using vim.  (you can export EDITOR in ~/.zshrc)"
            vim "$selected_file"
        fi
    else
        return 1
    fi
}

function _load_post_init() {
    #! Never load time consuming functions here
    
    autoload -U compinit && compinit

    # Load hydectl completion
    if command -v hydectl &>/dev/null; then
        compdef _hydectl hydectl
        eval "$(hydectl completion zsh)"
    fi

    # Initiate fzf
    if command -v fzf &>/dev/null; then
        eval "$(fzf --zsh)"
    fi

    # zsh-autosuggestions won't work on first prompt when deferred
    if typeset -f _zsh_autosuggest_start > /dev/null; then
      _zsh_autosuggest_start
    fi

    # User rc file always overrides
    [[ -f $HOME/.zshrc ]] && source $HOME/.zshrc

}

function _load_if_terminal {
    if [ -t 1 ]; then

        unset -f _load_if_terminal


        if command -v starship &>/dev/null; then
            # ===== START Initialize Starship prompt =====
            eval "$(starship init zsh)"
            export STARSHIP_CACHE=$XDG_CACHE_HOME/starship
            export STARSHIP_CONFIG=$XDG_CONFIG_HOME/starship/starship.toml
        fi

        # Optionally load user configuration // useful for customizing the shell without modifying the main file
        if [[ -f $HOME/.hyde.zshrc ]]; then
            source $HOME/.hyde.zshrc # for backward compatibility
        elif [[ -f $HOME/.user.zsh ]]; then
            source $HOME/.user.zsh # renamed to .user.zsh for intuitiveness that it is a user config
        fi


        #  Below this line are the commands that are executed after the prompt appears

        autoload -Uz add-zsh-hook
        # add-zsh-hook zshaddhistory load_omz_deferred # loads after the first command is added to history
        # add-zsh-hook precmd load_omz_deferred # Loads when shell is ready to accept commands
        # add-zsh-hook preexec load_omz_deferred # Loads before the first command executes

        # TODO: add handlers in pm.sh
        # for these aliases please manually add the following lines to your .zshrc file.(Using yay as the aur helper)
        # pc='yay -Sc' # remove all cached packages
        # po='yay -Qtdq | ${PM_COMMAND[@]} -Rns -' # remove orphaned packages

        alias c='clear' \
            in='${PM_COMMAND[@]} install' \
            un='${PM_COMMAND[@]} remove' \
            up='${PM_COMMAND[@]} upgrade' \
            pl='${PM_COMMAND[@]} search installed' \
            pa='${PM_COMMAND[@]} search all' \
            vc='code' \
            fastfetch='fastfetch --logo-type kitty' \
            ..='cd ..' \
            ...='cd ../..' \
            .3='cd ../../..' \
            .4='cd ../../../..' \
            .5='cd ../../../../..' \
            mkdir='mkdir -p' \
            ffec='_fuzzy_edit_search_file_content' \
            ffcd='_fuzzy_change_directory' \
            ffe='_fuzzy_edit_search_file'

        # Some binds won't work on first prompt when deferred
        bindkey '\e[H' beginning-of-line
        bindkey '\e[F' end-of-line

    fi

}

#? Override this environment variable in ~/.zshrc

# # cleaning up home folder
# PATH="$HOME/.local/bin:$PATH"
# XDG_CONFIG_DIR="${XDG_CONFIG_DIR:-"$(xdg-user-dir CONFIG)"}"
# XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
# XDG_DATA_DIRS="${XDG_DATA_DIRS:-$XDG_DATA_HOME:/usr/local/share:/usr/share}"
# XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
# XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# # XDG User Directories
# XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-"$(xdg-user-dir CONFIG)"}"
# XDG_DESKTOP_DIR="${XDG_DESKTOP_DIR:-"$(xdg-user-dir DESKTOP)"}"
# XDG_DOWNLOAD_DIR="${XDG_DOWNLOAD_DIR:-"$(xdg-user-dir DOWNLOAD)"}"
# XDG_TEMPLATES_DIR="${XDG_TEMPLATES_DIR:-"$(xdg-user-dir TEMPLATES)"}"
# XDG_PUBLICSHARE_DIR="${XDG_PUBLICSHARE_DIR:-"$(xdg-user-dir PUBLICSHARE)"}"
# XDG_DOCUMENTS_DIR="${XDG_DOCUMENTS_DIR:-"$(xdg-user-dir DOCUMENTS)"}"
# XDG_MUSIC_DIR="${XDG_MUSIC_DIR:-"$(xdg-user-dir MUSIC)"}"
# XDG_PICTURES_DIR="${XDG_PICTURES_DIR:-"$(xdg-user-dir PICTURES)"}"
# XDG_VIDEOS_DIR="${XDG_VIDEOS_DIR:-"$(xdg-user-dir VIDEOS)"}"

LESSHISTFILE=${LESSHISTFILE:-/tmp/less-hist}
PARALLEL_HOME="$XDG_CONFIG_HOME/parallel"
SCREENRC="$XDG_CONFIG_HOME"/screen/screenrc

ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# History configuration // explicit to not nuke history
HISTFILE=${HISTFILE:-$HOME/.zsh_history}
HISTSIZE=10000
SAVEHIST=10000
setopt EXTENDED_HISTORY       # Write the history file in the ':start:elapsed;command' format
setopt INC_APPEND_HISTORY     # Write to the history file immediately, not when the shell exits
setopt SHARE_HISTORY          # Share history between all sessions
setopt HIST_EXPIRE_DUPS_FIRST # Expire a duplicate event first when trimming history
setopt HIST_IGNORE_DUPS       # Do not record an event that was just recorded again
setopt HIST_IGNORE_ALL_DUPS   # Delete an old recorded event if a new event is a duplicate

# HyDE Package Manager
PM_COMMAND=(hyde-shell pm)

export XDG_CONFIG_HOME XDG_CONFIG_DIR XDG_DATA_HOME XDG_STATE_HOME \
    XDG_CACHE_HOME XDG_DESKTOP_DIR XDG_DOWNLOAD_DIR \
    XDG_TEMPLATES_DIR XDG_PUBLICSHARE_DIR XDG_DOCUMENTS_DIR \
    XDG_MUSIC_DIR XDG_PICTURES_DIR XDG_VIDEOS_DIR \
    SCREENRC ZSH_AUTOSUGGEST_STRATEGY HISTFILE

_load_if_terminal
