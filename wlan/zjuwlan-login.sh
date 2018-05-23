#!/bin/bash
#
# zjuwlan-login.sh: Script for ZJUWLAN login
#
# Copyright (c) 2014 Zhang Hai <Dreaming.in.Code.ZH@Gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
#

name=$(basename "$0")
username=
password=

usage() {
    cat <<EOF
Usage: ${name} [OPTIONS] [USERNAME] [PASSWORD]

Options:
  -h, --help        Display this help and exit

With no USERNAME or PASSWORD, read standard input.
EOF
}

parse_args() {

    local args
    args=$(getopt -o h -l help -n "${name}" -- "$@")
    if [[ $? != 0 ]]; then
        exit 1
    fi

    eval set -- "${args}"
    while :; do
        case "$1" in
            -h|--help)
                shift
                usage
                exit
                ;;
            --)
                shift
                break
                ;;
        esac
    done

    if [[ $# -gt 0 ]]; then
        username="$1"
        shift
    else
        read -p 'username: ' username
    fi

    if [[ $# -gt 0 ]]; then
        password="$1"
        shift
    else
        read -p 'password: ' -s password && echo
    fi

    if [[ $# -gt 0 ]]; then
        echo "Unknown argument: $@" >&2
        echo >&2
        usage >&2
        exit 1
    fi
}

log_in() {
    echo 'Logging in...'
    local response
    # You may pass `-H "Expect:"` to disable curl from adding it.
    response=$(curl 'https://net.zju.edu.cn/include/auth_action.php' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Referer: https://net.zju.edu.cn/srun_portal_phone.php?url=http://www.zju.edu.cn/&ac_id=3' -d "action=login&username=${USERNAME}&password=${PASSWORD}&ac_id=3&save_me=0&ajax=1" -s)
    if [[ "${response}" = *'login_ok'* ]]; then
        echo 'Login successful.'
    else
        echo "${response}" >&2
        exit 1
    fi
}

main() {
    parse_args "$@"
    log_in
}

main "$@"
