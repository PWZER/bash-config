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

function _list_host_network_devices() {
    network_devices=()

    pattern="inet [0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}"
    if [ "$(uname)" = "Darwin" ]; then
        if [ -z "$(which ifconfig)" ]; then
            return
        fi
        for device in $(ifconfig -l)
        do
            ip=$(ifconfig ${device} | grep -oE "${pattern}" | awk '{print $2}')
            if [ ! -z "${ip}" ] && [ ! "${ip}" = "127.0.0.1" ]; then
                network_devices+=("${device}: ${ip}")
            fi
        done
    else
        if [ -z "$(which ip)" ]; then
            return
        fi
        while read line; do
            device=$(echo ${line} | awk '{print $2}')
            ip=$(echo ${line} | grep -oE "${pattern}" | awk '{print $2}')
            if [ ! -z "${device}" ] && [  ! -z "${ip}" ] && [ ! "${ip}" = "127.0.0.1" ]; then
                network_devices+=("${device}: ${ip}")
            fi
        done <<< $(ip -o -4 addr)
    fi
}

function export_current_host_ipv4_addr() {
    if [ -z "${current_host_ipv4_addr}" ]; then
        _list_host_network_devices

        if [ ${#network_devices[@]} -eq 1 ]; then
            current_host_ipv4_addr=$(echo ${network_devices[0]} | awk '{print $2}')
        elif [ ${#network_devices[@]} -gt 1 ]; then
            PS3="select network interface: "
            select cur_device in "${network_devices[@]}"; do
                current_host_ipv4_addr=$(echo ${cur_device} | awk '{print $2}')
                break
            done
        fi

        if [ -z "${current_host_ipv4_addr}" ]; then
            current_host_ipv4_addr="localhost"
        fi
    fi

    echo "export CURRENT_HOST_IPV4_ADDR=${current_host_ipv4_addr}" >> ${TMP_FILE}
}

if [ -e "${TMP_FILE}" ]; then
    rm -rf ${TMP_FILE}
fi

export_current_host_ipv4_addr

export_auto_path

mv ${TMP_FILE} ${OUTPUT_FILE}
