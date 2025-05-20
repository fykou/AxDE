#!/usr/bin/env bash

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck source=$HOME/.local/lib/hyde/globalcontrol.sh

source "${scrDir}/globalcontrol.sh"
HYDE_RUNTIME_DIR="${HYDE_RUNTIME_DIR:-$XDG_RUNTIME_DIR/hyde}"

source "${HYDE_RUNTIME_DIR}/environment"

"${LOCKSCREEN:-hyprlock}" "${@}"
