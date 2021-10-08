#!/bin/bash

set -o errexit

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

bash ${CUR_DIR}/auto.sh

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
link_file ${CUR_DIR}/vim/vim_plug.vim ${HOME}/.vim/autoload/plug.vim

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

echo "Success"
