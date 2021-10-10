#!/bin/bash

set -o errexit

user_name=""
user_email=""
network_device=""
disabled_vim_plugin=0


TEMP=`getopt -o h  --long help,no-vim-plug,name:,hostname:,email:,device: -- "$@"`
eval set -- "$TEMP"
USAGE="Usage: ./install.sh [--name=<name>] [--email=<email>] [--device=<device> | --hostname=<hostname>] [--no-vim-plug]"

while true ; do
    case "$1" in
        --name)
            user_name=$2; shift 2;;
        --email)
            user_email=$2; shift 2;;
        --device)
            network_device=$2; shift 2;;
        --hostname)
            current_host_ipv4_addr=$2; shift 2;;
        --no-vim-plug)
            IFS=","; disabled_vim_plugin=1; unset IFS; shift 1;;
        -h|--help)
            echo ${USAGE}; exit 0; shift 1;;
        --) shift; break;;
        *) echo "Invalid Argments: $1"; exit 1;;
    esac
done

CUR_DIR=$(dirname $(realpath $0))

function link_file() {
    src=$1
    dst=$2

    if [ ! -e "$(dirname ${dst})" ]; then
        mkdir -p $(dirname ${dst})
    fi

    if [[ ! -e "${dst}" || "$(realpath ${dst})" != "${src}" ]]; then
        ln -sf ${src} ${dst}
    fi
}

function find_python_executable_path_and_link_file() {
    if [ ! -d ${HOME}/.local/bin ]; then
        mkdir -p ${HOME}/.local/bin
    fi

    python3_path=$(which python3)
    if [[ ! -z "${python3_path}" && -x "${python3_path}" ]]; then
        link_file ${python3_path} ${HOME}/.local/bin/python
        echo "using ${python3_path}"
        return
    fi

    python_path=${which python}
    if [[ ! -z "${python_path}" && -x "${python_path}" ]]; then
        link_file ${python_path} ${HOME}/.local/bin/python
        echo "using ${python_path}"
        return
    fi
}

function _set_get_global_config() {
    key=$1
    value=$2
    if [ -z "${value}" ]; then
        cur_value=$(git config --global --get ${key} || echo -n "")
        while [ -z "${value}" ]; do
            if [ -z "${cur_value}" ]; then
                echo -n "set git global default ${key}: "
            else
                echo -n "set git global default ${key} [default: ${cur_value}]: "
            fi
            read value
            if [ ! -z "${cur_value}" ] && [ -z "${value}" ]; then
                value=${cur_value}
            fi
        done
    fi
    git config --global ${key} "${value}"
}

function set_git_global_configs() {
    if [ -z "$(which git)" ]; then
        return
    fi

    _set_get_global_config user.name "${user_name}"
    _set_get_global_config user.email "${user_email}"

    git config --global core.editor vim
    git config --global http.sslVerify false
    git config --global color.diff auto
    git config --global color.status auto
    git config --global diff.tool vimdiff
}

function install_vim_plugins() {
    #use fastgit
    #git config --global url."https://hub.fastgit.org/".insteadOf "https://github.com/"
    #git config protocol.https.allow always

    # vim plugs
    vim +PlugInstall +qall
    # vim +PlugUpdate +qall

    # compile YouCompleteMe
    ycm_dir=${HOME}/.vim/plugged/YouCompleteMe
    ycm_core_so=$(find ${ycm_dir}/third_party/ycmd -name "ycm_core.*.so")
    if [ ! -f "${ycm_core_so}" ]; then
        cd ${HOME}/.vim/plugged/YouCompleteMe
        git submodule update --init --recursive
        ./install.sh --clang-completer
        cd ${CUR_DIR}
    fi
    link_file ${ycm_dir}/third_party/ycmd/.ycm_extra_conf.py ${HOME}/.ycm_extra_conf.py
}

source ${CUR_DIR}/auto.sh

set_git_global_configs

# bash config
link_file ${CUR_DIR}/bashrc.sh ${HOME}/.bashrc
link_file ${CUR_DIR}/profile.sh ${HOME}/.profile
link_file ${CUR_DIR}/inputrc ${HOME}/.inputrc
if [[ -e ${HOME}/.bash_profile || -L ${HOME}/.bash_profile ]]; then
    rm -rf ${HOME}/.bash_profile
fi

if [[ ! -e ${HOME}/.config || "$(realpath ${HOME}/.config)" != ${CUR_DIR}/config ]]; then
    rm -rf ${HOME}/.config
    ln -sf ${CUR_DIR}/config ${HOME}/.config
fi

find_python_executable_path_and_link_file

# tmux config
link_file ${CUR_DIR}/tmux.conf ${HOME}/.tmux.conf

# ssh config
link_file ${CUR_DIR}/ssh/config ${HOME}/.ssh/config

# vim configs
link_file ${CUR_DIR}/vim/vimrc ${HOME}/.vimrc
link_file ${CUR_DIR}/vim/solarized.vim ${HOME}/.vim/colors/solarized.vim
link_file ${CUR_DIR}/vim/plug.vim ${HOME}/.vim/autoload/plug.vim

if [ ${disabled_vim_plugin} -eq 0 ]; then
    install_vim_plugins
fi

echo "Success"
