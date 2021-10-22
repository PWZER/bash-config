#!/bin/bash

set -o errexit

CUR_DIR=$(dirname $(realpath $0))

function update_file() {
    url=$1
    path=$2

    tmp_path="${path}.tmp"

    curl -sSL -o ${tmp_path} --url "${url}"
    mv ${tmp_path} ${path}
    echo "update ${path} success!"
}

# dircolors.256dark
update_file https://raw.githubusercontent.com/seebi/dircolors-solarized/master/dircolors.256dark \
    ${CUR_DIR}/dircolors.256dark

# ./plugins/git-completion.bash
update_file https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash \
    ${CUR_DIR}/plugins/git-completion.bash

# ./plugins/git-prompt.sh
update_file https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh \
    ${CUR_DIR}/plugins/git-prompt.sh

# vim/vim_plug.vim
update_file https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
    ${CUR_DIR}/vim/plug.vim

# vim/solarized.vim
update_file https://raw.githubusercontent.com/altercation/solarized/master/vim-colors-solarized/colors/solarized.vim \
    ${CUR_DIR}/vim/solarized.vim
