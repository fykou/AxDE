#!/usr/bin/env bash

if ! source "${SCR_DIR}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

# # dolphin
# if pkg_installed dolphin && pkg_installed xdg-utils; then
#     print_log -c "[FILEMANAGER] " -b "detected :: " "dolphin"
#     xdg-mime default org.kde.dolphin.desktop inode/directory
#     print_log -g "[FILEMANAGER] " -b " :: " "setting $(xdg-mime query default "inode/directory") as default file explorer..."

# else
#     print_log -y "[FILEMANAGER] " -b " :: " "dolphin is not installed..."
#     print_log -y "[FILEMANAGER] " -b " :: " "Setting $(xdg-mime query default "inode/directory") as default file explorer..."
# fi

# # shell
# "${SCR_DIR}/restore_shl.sh"

# flatpak
if ! pkg_installed flatpak; then
    print_log -r "[FLATPAK]" -b "list :: " "flatpak application"
    awk -F '#' '$1 != "" {print "["++count"]", $1}' "${SCR_DIR}/extra/custom_flat.lst"
    prompt_timer 60 "Install these flatpaks? [Y/n]"
    fpkopt=${PROMPT_INPUT,,}

    if [ "${fpkopt}" = "y" ]; then
        print_log -g "[FLATPAK]" -b "install :: " "flatpaks"
        "${SCR_DIR}/extra/install_fpk.sh"
    else
        print_log -y "[FLATPAK]" -b "skip :: " "flatpak installation"
    fi

else
    print_log -y "[FLATPAK]" -b " :: " "flatpak is already installed"
fi
