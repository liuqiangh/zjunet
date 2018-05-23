#!/bin/bash
#
# zjuvpn.sh: Script for connecting to VPN in ZJU
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

TIMEOUT_DEFAULT=30
XL2TPD_CONTROL_FILE='/var/run/xl2tpd/l2tp-control'
XL2TPD_LAC_CONF_DEFAULT='zjuvpn'

name=$(basename "$0")
disconnect=0
timeout=${TIMEOUT_DEFAULT}
xl2tpd_lac_conf="${XL2TPD_LAC_CONF_DEFAULT}"
gateway=

usage() {
    cat <<EOF
Usage: ${name} [OPTIONS]

Options:

  -d, --disconnect          Disconnect from ZJU VPN
  -h, --help                Display this help and exit
  -l, --lac-conf=NAME       Use LAC configuration NAME; the default
                            configuration name is ${XL2TPD_LAC_CONF_DEFAULT}
  -t, --timeout=SECONDS     Time out after SECONDS; the default timeout is
                            ${TIMEOUT_DEFAULT}
EOF
}

parse_args() {

    local args
    args=$(getopt -o dhlt: -l disconnect,help,lac-conf:,timeout: -n "${name}" -- "$@")
    if [[ $? != 0 ]]; then
        exit 1
    fi

    eval set -- "${args}"
    while :; do
        case "$1" in
            -d|--disconnect)
                shift
                disconnect=1
                ;;
            -h|--help)
                shift
                usage
                exit
                ;;
            -h|--lac-conf)
                shift
                xl2tpd_lac_conf="$1"
                shift
                ;;
            -t|--timeout)
                shift
                timeout="$1"
                shift
                ;;
            --)
                shift
                break
                ;;
        esac
    done

    if [[ $# -gt 0 ]]; then
        echo "Unknown argument: $@" >&2
        echo >&2
        usage >&2
        exit 1
    fi
}

prepare_sudo() {
    sudo -v
}

save_gateway() {
    gateway=$(ip route show 0/0 | awk '{ print $3; exit }')
}

restore_gateway() {
    gateway=$(ip route show 10.0.0.0/8 | awk '{ print $3; exit }')
}

xl2tpd_ready() {
    if [[ -e "${XL2TPD_CONTROL_FILE}" ]]; then
        return 0
    else
        return 1
    fi
}

xl2tpd_start() {
    echo -n 'Starting xl2tpd...'
    #sudo systemctl start xl2tpd
    sudo systemctl restart xl2tpd
    for i in $(seq 0 "${timeout}"); do
        if xl2tpd_ready; then
            echo
            return 0
        fi
        sleep 1
        echo -n '.'
    done
    echo
    echo 'Failed to start xl2tpd' >&2
    xl2tpd_stop
    exit 1
}

xl2tpd_stop() {
    echo 'Stoping xl2tpd...'
    sudo systemctl stop xl2tpd
}

ppp_ready() {
    if ip addr show | grep 'inet.*ppp0' >/dev/null; then
        return 0
    else
        return 1
    fi
}

ppp_connect() {
    echo -n 'Connecting...'
    sudo xl2tpd-control disconnect "${xl2tpd_lac_conf}" >/dev/null
    sudo xl2tpd-control connect "${xl2tpd_lac_conf}" >/dev/null
    for i in $(seq 0 "${timeout}"); do
        if ppp_ready; then
            echo
            return 0
        fi
        sleep 1
        echo -n '.'
    done
    echo
    echo 'Connection failed' >&2
    ppp_disconnect
    xl2tpd_stop
    exit 1
}

ppp_disconnect() {
    echo 'Disconnecting...'
    sudo xl2tpd-control disconnect "${xl2tpd_lac_conf}" >/dev/null
}

route_connect_pre() {
    # Override mysteriously added "10.5.1.7 dev ppp0"
    sudo ip route add 10.5.1.7 via "${gateway}"
    sudo ip route add 10.0.0.0/8 via "${gateway}"
    sudo ip route del default
}

route_connect_post() {
    sudo ip route add default dev ppp0
}

route_disconnect() {
    sudo ip route del 10.5.1.7
    sudo ip route del 10.0.0.0/8
    sudo ip route add default via "${gateway}"
}

connect() {
    # `ip route show` after connected causes system to hang up, reason unknown.
    save_gateway
    xl2tpd_start
    route_connect_pre
    ppp_connect
    route_connect_post
    echo 'Connected'
}

disconnect() {
    restore_gateway
    ppp_disconnect
    xl2tpd_stop
    route_disconnect
    echo 'Disconnected'
}

main() {
    parse_args "$@"
    prepare_sudo
    if [[ disconnect -eq 0 ]]; then
        connect
    else
        disconnect
    fi
}

main "$@"
