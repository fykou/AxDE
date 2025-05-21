#!/usr/bin/env bash

cat <<"EOF"

-------------------------------------------------
        .
       / \         _              __           _____
      /^  \      _| |_      ____ |  | __ _____/ ____\
     /  _  \    |_   _|    /  _ \|  |/ // __ \   __\
    /  | | ~\     |_|     (  <_> )    <\  ___/|  |
   /.-'   '-.\             \____/|__|__\\____>___|

-------------------------------------------------

EOF

#--------------------------------#
# import variables and functions #
#--------------------------------#
SCR_DIR="$(dirname "$(realpath "$0")")"
AXDE_LOG="$(date +'%y%m%d_%Hh%Mm%Ss')"
getAur="paru"


if ! source "${SCR_DIR}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

#------------------#
# evaluate options #
#------------------#
flg_Install=0
flg_Restore=0
flg_Service=0
flg_DryRun=0
flg_Shell=0
flg_Nvidia=1
flg_ThemeInstall=1

while getopts idrstmnh: RunStep; do
    case $RunStep in
    i) flg_Install=1 ;;
    d)
        flg_Install=1
        export use_default="--noconfirm"
        ;;
    r) flg_Restore=1 ;;
    s) flg_Service=1 ;;
    n)
        export flg_Nvidia=0
        print_log -r "[nvidia] " -b "Ignored :: " "skipping Nvidia actions"
        ;;
    h)
        export flg_Shell=0
        print_log -r "[shell] " -b "Reevaluate :: " "shell options"
        ;;
    t) flg_DryRun=1 ;;
    m) flg_ThemeInstall=0 ;;
    *)
        cat <<EOF
Usage: $0 [options]
            i : [i]nstall hyprland without configs
            d : install hyprland [d]efaults without configs --noconfirm
            r : [r]estore config files
            s : enable system [s]ervices
            n : ignore/[n]o [n]vidia actions
            h : re-evaluate S[h]ell
            m : no the[m]e reinstallations
            t : [t]est run without executing (-irst to dry run all)
EOF
        exit 1
        ;;
    esac
done

export flg_DryRun flg_Nvidia flg_Shell flg_Install flg_ThemeInstall AXDE_LOG SCR_DIR getAur

if [ "${flg_DryRun}" -eq 1 ]; then
    print_log -n "[test-run] " -b "enabled :: " "Testing without executing"
elif [ $OPTIND -eq 1 ]; then
    flg_Install=1
    flg_Restore=1
    flg_Service=1
fi

#--------------------#
# pre-install script #
#--------------------#

# if [ ${flg_Install} -eq 1 ] && [ ${flg_Restore} -eq 1 ]; then
#     cat <<"EOF"
#                 _         _       _ _
#  ___ ___ ___   |_|___ ___| |_ ___| | |
# | . |  _| -_|  | |   |_ -|  _| .'| | |
# |  _|_| |___|  |_|_|_|___|_| |__,|_|_|
# |_|

# EOF

#     "${SCR_DIR}/install_pre.sh"
# fi

#------------#
# installing #
#------------#
if [ ${flg_Install} -eq 1 ]; then
    cat <<"EOF"

 _         _       _ _ _
|_|___ ___| |_ ___| | |_|___ ___
| |   |_ -|  _| .'| | | |   | . |
|_|_|_|___|_| |__,|_|_|_|_|_|_  |
                            |___|

EOF

    #-------------------#
    # 1Password GPG key #
    #-------------------#

    print_log -warn "1Password" " :: " "Trusting GPG key"
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --import



    #----------------------#
    # prepare package list #
    #----------------------#
    shift $((OPTIND - 1))
    custom_pkg=$1
    cp "${SCR_DIR}/pkg_core.lst" "${SCR_DIR}/install_pkg.lst"
    trap 'mv "${SCR_DIR}/install_pkg.lst" "${cacheDir}/logs/${AXDE_LOG}/install_pkg.lst"' EXIT

    if [ -f "${custom_pkg}" ] && [ -n "${custom_pkg}" ]; then
        cat "${custom_pkg}" >>"${SCR_DIR}/install_pkg.lst"
    fi
    echo -e "\n#user packages" >>"${SCR_DIR}/install_pkg.lst" # Add a marker for user packages
    #--------------------------------#
    # add nvidia drivers to the list #
    #--------------------------------#
    if nvidia_detect; then
        if [ ${flg_Nvidia} -eq 1 ]; then
            cat /usr/lib/modules/*/pkgbase | while read -r kernel; do
                echo "${kernel}-headers" >>"${SCR_DIR}/install_pkg.lst"
            done
            nvidia_detect --drivers >>"${SCR_DIR}/install_pkg.lst"
        else
            print_log -warn "Nvidia" " :: " "Nvidia GPU detected but ignored..."
        fi
    fi
    nvidia_detect --verbose

    #--------------------------------#
    # install packages from the list #
    #--------------------------------#
    [ ${flg_DryRun} -eq 1 ] || "${SCR_DIR}/install_pkg.sh" "${SCR_DIR}/install_pkg.lst"


    #----------------------------#
    # verify 1password signature #
    #----------------------------#

    PKG_FILE=$(pacman -Qip "1password" 2>/dev/null | grep "Filename" | awk '{print $2}')
    PKG_CACHE="/var/cache/pacman/pkg"

    if [[ -f "$PKG_CACHE/$PKG_FILE" ]]; then
        gpg --verify "$PKG_CACHE/$PKG_FILE.sig" "$PKG_CACHE/$PKG_FILE" || {
            print_log -err "1Password" " :: " "Signature verification failed!"
            exit 1
        }
        print_log -g "1Password" " :: " "Signature verifified!"
    fi
        
fi

#---------------------------#
# restore my custom configs #
#---------------------------#

# if [ ${flg_Restore} -eq 1 ]; then
#     cat <<"EOF"

#              _           _d
#  ___ ___ ___| |_ ___ ___|_|___ ___
# |  _| -_|_ -|  _| . |  _| |   | . |
# |_| |___|___|_| |___|_| |_|_|_|_  |
#                               |___|

# EOF

#     if [ "${flg_DryRun}" -ne 1 ] && [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
#         hyprctl keyword misc:disable_autoreload 1 -q
#     fi

#     "${SCR_DIR}/restore_fnt.sh"
#     "${SCR_DIR}/restore_cfg.sh"
#     "${SCR_DIR}/restore_thm.sh"
#     # print_log -g "[generate] " "cache ::" "Wallpapers..."
#     # if [ "${flg_DryRun}" -ne 1 ]; then
#     #     "$HOME/.local/lib/hyde/swwwallcache.sh" -t ""
#     #     "$HOME/.local/lib/hyde/theme.switch.sh" -q || true
#     #     echo "[install] reload :: Hyprland"
#     # fi

# fi

#---------------------#
# post-install script #
#---------------------#
if [ ${flg_Install} -eq 1 ] && [ ${flg_Restore} -eq 1 ]; then
    cat <<"EOF"

             _      _         _       _ _
 ___ ___ ___| |_   |_|___ ___| |_ ___| | |
| . | . |_ -|  _|  | |   |_ -|  _| .'| | |
|  _|___|___|_|    |_|_|_|___|_| |__,|_|_|
|_|

EOF

    "${SCR_DIR}/install_pst.sh"
fi

#------------------------#
# enable system services #
#------------------------#
# if [ ${flg_Service} -eq 1 ]; then
#     cat <<"EOF"

#                  _
#  ___ ___ ___ _ _|_|___ ___ ___
# |_ -| -_|  _| | | |  _| -_|_ -|
# |___|___|_|  \_/|_|___|___|___|

# EOF

#     while read -r serviceChk; do

#         if [[ $(systemctl list-units --all -t service --full --no-legend "${serviceChk}.service" | sed 's/^\s*//g' | cut -f1 -d' ') == "${serviceChk}.service" ]]; then
#             print_log -y "[skip] " -b "active " "Service ${serviceChk}"
#         else
#             print_log -y "start" "Service ${serviceChk}"
#             if [ $flg_DryRun -ne 1 ]; then
#                 sudo systemctl enable "${serviceChk}.service"
#                 sudo systemctl start "${serviceChk}.service"
#             fi
#         fi

#     done <"${SCR_DIR}/system_ctl.lst"
# fi

# if [ $flg_Install -eq 1 ]; then
#     print_log -stat "\nInstallation" "completed"
# fi
# print_log -stat "Log" "View logs at ${cacheDir}/logs/${AXDE_LOG}"
# if [ $flg_Install -eq 1 ] ||
#     [ $flg_Restore -eq 1 ] ||
#     [ $flg_Service -eq 1 ]; then
#     print_log -stat "HyDE" "It is not recommended to use newly installed or upgraded HyDE without rebooting the system. Do you want to reboot the system? (y/N)"
#     read -r answer

#     if [[ "$answer" == [Yy] ]]; then
#         echo "Rebooting system"
#         systemctl reboot
#     else
#         echo "The system will not reboot"
#     fi
# fi
