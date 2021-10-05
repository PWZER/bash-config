#!/bin/bash

set -o errexit

CUR_DIR=$(dirname $(realpath $0))
TMP_FILE=${CUR_DIR}/.config_auto.sh
OUTPUT_FILE=${CUR_DIR}/config_auto.sh

function export_auto_path() {
    # auto append /usr/local/opt bins
    if [ "$(uname)" = "Darwin" ]; then
        bin_path_list=()
        names=$(/bin/ls -d /usr/local/opt/*)
        for name in ${names[@]}
        do
            bin_path=$(/bin/ls -d ${name}/bin 2> /dev/null | sort -r | head -n1)
            if [ ! -z "${bin_path}" ]; then
                bin_path_list="${bin_path_list} ${bin_path},$(realpath ${bin_path})"
            fi
        done

        # 根据 realpath 去重
        bin_path_list=($(echo ${bin_path_list[@]} | awk -F, -v RS=' ' '!x[$2]++{print $1}'))
        bin_path_list=$(IFS=":"; printf '%s' "${bin_path_list[*]}")

        if [ ! -z "${bin_path_list}" ]; then
            echo "export AUTO_PATH=${bin_path_list}" >> ${TMP_FILE}
        fi
    fi
}

function export_current_host_ipv4_addr() {
    devices=()
    ips=()
    if [ "$(uname)" = "Darwin" ]; then
        if [ -z "$(which ifconfig)" ]; then
            return
        fi
        for device in $(ifconfig -l)
        do
            ip=$(ifconfig ${device} | \
                grep -oE "inet [0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}" | \
                awk '{print $2}')
            if [[ ! -z "${ip}" && "${ip}" != "127.0.0.1" ]]; then
                devices+=(${device})
                ips+=(${ip})
            fi
        done
    else
        if [ -z "$(which ip)" ]; then
            return
        fi
        while read line; do
            device=$(echo ${line} | awk '{print $2}')
            ip=$(echo ${line} | \
                grep -oE "inet [0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}" | \
                awk '{print $2}')
            if [[ ! -z "${device}" && ! -z "${ip}" && "${ip}" != "127.0.0.1" ]]; then
                devices+=(${device})
                ips+=(${ip})
            fi
        done <<< $(ip -o -4 addr)
    fi

    num=${#devices[@]}

    if [[ ${num} == 1 ]]; then
        current_host_ipv4_addr=${ips[0]}
    elif [[ ${num} > 1 ]]; then
        while [ -z "${current_host_ipv4_addr}" ]
        do
            cur_device=""
            echo "------------------------------------------"
            for ((i=0; i<${num}; i++))
            do
                echo "${devices[i]}: ${ips[i]}"
                if [ "${ips[i]}" == "${CURRENT_HOST_IPV4_ADDR}" ]; then
                    cur_device=${devices[i]}
                fi
            done
            echo "------------------------------------------"

            if [ -z "${cur_device}" ]; then
                echo -n "select network interface: "
            else
                echo -n "select network interface [default: ${cur_device}]: "
            fi

            read device
            if [[ ! -z "${cur_device}" && -z "${device}" ]]; then
                device=${cur_device}
            fi

            for ((i=0; i<${num}; i++))
            do
                if [ "${devices[i]}" = "${device}" ]; then
                    current_host_ipv4_addr=${ips[i]}
                    break
                fi
            done
        done
    fi

    if [ -z "${current_host_ipv4_addr}" ]; then
        current_host_ipv4_addr="localhost"
    fi

    echo "export CURRENT_HOST_IPV4_ADDR=${current_host_ipv4_addr}" >> ${TMP_FILE}
}

function export_current_host_ipv4_addr_v2() {
    current_host_ipv4_addr=$(echo ${SSH_CONNECTION} | awk "{print \$3}")
    if [ -z $current_host_ipv4_addr ] && [ ! -z ${DEFAULT_NETWORK_DEVICE} ]; then
        if [ $(uname) = "Darwin" ]; then
            current_host_ipv4_addr=$( \
                ifconfig ${DEFAULT_NETWORK_DEVICE} | \
                grep -oE "inet [0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}" | \
                awk "{print \$2}")
        elif [ $(uname) = "Linux" ]; then
            current_host_ipv4_addr=$(\
                ip -o -4 addr show ${DEFAULT_NETWORK_DEVICE} | \
                egrep -vE "127.0.0.1| docker" | \
                grep -oE "inet [0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}" | \
                head -n1 | \
                awk "{print \$2}")
        fi
    fi

    if [ -z "${current_host_ipv4_addr}" ]; then
        current_host_ipv4_addr="localhost"
    fi

    echo "export CURRENT_HOST_IPV4_ADDR=${current_host_ipv4_addr}" >> ${TMP_FILE}
}

function set_git_default_user_name_and_email() {
    if [ -z "$(which git)" ]; then
        return
    fi

    user_name="$(git config --global --default "" --get user.name)"
    while [ -z "${git_default_user_name}" ]
    do
        if [ -z "${user_name}" ]; then
            echo -n "set git global default user.name: "
        else
            echo -n "set git global default user.name [default: ${user_name}]: "
        fi
        read git_default_user_name
        if [[ ! -z "${user_name}" && -z "${git_default_user_name}" ]]; then
            git_default_user_name=${user_name}
        fi
    done
    git config --global user.name "${git_default_user_name}"

    user_email=$(git config --global --default "" --get user.email)
    while [ -z "${git_default_user_email}" ]
    do
        if [ -z "${user_email}" ]; then
            echo -n "set git global default user.email: "
        else
            echo -n "set git global default user.email [default: ${user_email}]: "
        fi
        read git_default_user_email
        if [[ ! -z "${user_email}" && -z "${git_default_user_email}" ]]; then
            git_default_user_email=${user_email}
        fi
    done
    git config --global user.email "${git_default_user_email}"

    git config --global core.editor vim
    git config --global http.sslVerify false
    git config --global color.diff auto
    git config --global color.status auto
    git config --global diff.tool vimdiff
}

if [ -e "${TMP_FILE}" ]; then
    rm -rf ${TMP_FILE}
fi

export_current_host_ipv4_addr

export_auto_path

set_git_default_user_name_and_email

mv ${TMP_FILE} ${OUTPUT_FILE}
