if [ -r /etc/bashrc ]; then
    . /etc/bashrc
fi

# 被后面所依赖，必须放在最前面
if [ "$(uname)" = "Darwin" ]; then
    if [ -d /usr/local/opt ]; then
        HOMEBREW_DIR=/usr/local/opt
    elif [ -d /opt/homebrew/opt ]; then
        HOMEBREW_DIR=/opt/homebrew/opt
    fi

    if [ -d ${HOMEBREW_DIR}/gnu-getopt/bin ]; then
        export PATH=/opt/homebrew/opt/gnu-getopt/bin:${PATH}
    fi
    if [ -d ${HOMEBREW_DIR}/coreutils/libexec/gnubin ]; then
        export PATH=/opt/homebrew/opt/coreutils/libexec/gnubin:${PATH}
    fi
fi

alias ssh="ssh -A"
alias rsync="rsync -rzvaP"

if [ -x "$(which dircolors)" ]; then
    alias grep="grep --color"
    alias egrep="egrep --color"
    alias fgrep="fgrep --color"

    alias ls="ls -F --show-control-chars --color=auto"
else
    alias ls="ls -F --show-control-chars"
fi

alias l='ls -CF'
alias ll="ls -lF"
alias la='ls -A'

# base config
export EDITOR=vim
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export TERM=xterm-256color
export TIME_STYLE="+%Y-%m-%d %H:%M:%S"

# git config
export GIT_PS1_SHOWCOLORHINTS=1
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_STATESEPARATOR=""
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWUPSTREAM="auto"
export GIT_PS1_DESCRIBE_STYLE="branch"

HISTSIZE=10000
HISTFILESIZE=20000
# ignoredups：忽略重复命令（默认），即连续重复多次执行这条命令，只在历史命令中记录一条
# ignorespace：忽略以空白开头的命令，如果想要执行的命令不被历史所记录，可以开启这个变量，同时执行命令的时候加空格开头，就不会被记录
# ignoreboth：以上两者都生效
# erasedups: 消除整个命令历史中的重复命令
#export HISTCONTROL=erasedups
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

export BASH_SILENCE_DEPRECATION_WARNING=1

# Go 环境
export GOPATH=${HOME}/.govm/go
export GO111MODULE=on
export GOPROXY=https://goproxy.cn
export PATH=${GOPATH}/bin:${PATH}

if [ "$(uname)" = "Darwin" ]; then
    export HOMEBREW_NO_AUTO_UPDATE=1
    export HOMEBREW_INSTALL_FROM_API=1

    export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
    export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"

    export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
    export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
fi

# PS1 颜色符号必须包含在 \[\] 内，否则提示符长度计算有偏差，有显示错位等问题
# http://mywiki.wooledge.org/BashFAQ/053
PS1_PREFIX='\[\e[1;31m\]${CURRENT_HOST_IPV4_ADDR} \[\e[1;35m\]$(date +"%m/%d %H:%M:%S")\[\e[1;32m\] \[\e[1;33m\]\w\[\e[0m\]'
export PROMPT_COMMAND='__git_ps1 "${PS1_PREFIX}" " $? \\\$ " "(%s)"'

# tmux 多 windows 实时同步历史命令
export PROMPT_COMMAND="${PROMPT_COMMAND:-:}; history -a ${CUSTOM_HISTORY_FILE}; history -c; history -r ${CUSTOM_HISTORY_FILE};"

#===================================================================================================

CUR_DIR=$(dirname $(realpath ${HOME}/.bashrc))

if [ -x "$(which dircolors)" ]; then
    eval `$(which dircolors) -b ${CUR_DIR}/dircolors.256dark`
fi

# bash 自动补全
if [ -r /etc/profile.d/bash_completion.sh ]; then
    . /etc/profile.d/bash_completion.sh
elif [ -r /usr/local/etc/profile.d/bash_completion.sh ]; then
    . /usr/local/etc/profile.d/bash_completion.sh
elif [ -r /opt/homebrew/etc/profile.d/bash_completion.sh ]; then
    . /opt/homebrew/etc/profile.d/bash_completion.sh
fi

for plugin_file in $(find ${CUR_DIR}/plugins -name "*.sh" -or -name "*.bash" 2>/dev/null); do
    if [ -f ${plugin_file} ]; then
        . ${plugin_file}
    fi
done

# ssh config
if [ -S ${SSH_AUTH_SOCK}  ] && ! [ -h ${SSH_AUTH_SOCK}  ]; then
    ln -sf ${SSH_AUTH_SOCK} ${HOME}/.ssh/ssh_auth_sock
    export SSH_AUTH_SOCK=${HOME}/.ssh/ssh_auth_sock
fi

# 自动生成配置
if [ -r ${CUR_DIR}/config_auto.sh ]; then
    . ${CUR_DIR}/config_auto.sh
fi

# 常规手动配置
if [ -r ${CUR_DIR}/config.sh ]; then
    . ${CUR_DIR}/config.sh
fi

history -c && history -r ${CUSTOM_HISTORY_FILE}

if [ ! -z "${AUTO_PATH}" ]; then
    export PATH=${PATH}:${AUTO_PATH}
fi

export PATH=${HOME}/.local/bin:/usr/local/bin:${PATH}

# PATH 去重, 放到最后
paths=($(echo ${PATH} | awk -v RS=':' '!x[$1]++{print}'))
export PATH=$(IFS=":"; printf '%s' "${paths[*]}")
