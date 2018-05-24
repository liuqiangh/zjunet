#!/bin/bash
#
# setup.sh: Script for automatic setup dependecies of ZJU VPN


name=($basename "$0")
username=
password=


usage() {
    cat << EOF
Usage: ${name} [OPTIONS] [USERNAME] [PASSWORD]

Options:
    -h,	--help		Display this help and exit

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
prepare_sudo() {
    sudo -v
}

setup_dependencies() {
    sudo apt-get install -y xl2tpd
}

add_user_to_chap_secrets() {
    # check chap-secrets file exists
    CHAP_SECRETS_FILE='/etc/ppp/chap-secrets'
    CHAP_SECRETS_LINE_TO_ADD="${username}	*	${password}	*"

    if [ ! -f $FILE ]; then
        echo "File ${CHAP_SECRETS_FILE} is missing. Please check whether xl2tpd is installed correctly." >&2
        echo >&2
        exit 1
    fi
    # check whether user is added
    if sudo grep -Fxq "${CHAP_SECRETS_LINE_TO_ADD}" ${CHAP_SECRETS_FILE}
    then
        echo "Username ${username} with given password is found in ${CHAP_SECRETS_FILE}" >&2
	echo >&2
    else
        sudo sed -i "\$a ${CHAP_SECRETS_LINE_TO_ADD}" ${CHAP_SECRETS_FILE}
    fi
}

copy_zjuvpn_xl2tpd_config_files() {
    # ZJUVPN_L2TPD_FILE=/etc/ppp/peers/zjuvpn.l2tpd
    # L2TPD_CONFIG_FILE=/etc/xl2tpd/xl2tpd.conf
    # check whether files exist
    cp -f "xl2tpd.conf" ".xl2tpd.conf.copy"
    sed -i "s/name =/name = ${username}/" .xl2tpd.conf.copy
    sudo mv -f .xl2tpd.conf.copy /etc/xl2tpd/xl2tpd.conf
    sudo cp -f zjuvpn.l2tpd /etc/ppp/peers/zjuvpn.l2tpd
    rm -f .xl2tpd.conf.copy
}

copy_zjuvpn_script() {
    sudo cp -f zjuvpn.sh /usr/local/bin/zjuvpn
    sudo chmod +x /usr/local/bin/zjuvpn
}

setup_configurations() {
    add_user_to_chap_secrets
    copy_zjuvpn_xl2tpd_config_files
    copy_zjuvpn_script
}


main() {
    prepare_sudo
    parse_args "$@"
    setup_dependencies
    setup_configurations
    echo "ZJPVPN installed. Please use command 'zjuvpn' to login."
}

main "$@"
