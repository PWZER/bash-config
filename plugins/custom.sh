function fixssh() {
    ssh_agent_file=$(find /tmp/ssh-*/agent.* -user ${USER} -printf '%T+ %p\n' 2>/dev/null | \
        sort -k1 -r | \
        head -n1 | \
        awk '{print $2}')
    if [ ! -z "${ssh_agent_file}" ] && [ -e "${ssh_agent_file}" ]; then
        if [ ! -e ${HOME}/.ssh/ssh_auth_sock ] || [ ! "$(realpath ${HOME}/.ssh/ssh_auth_sock)" = "${ssh_agent_file}" ]; then
            ln -sf ${ssh_agent_file} ${HOME}/.ssh/ssh_auth_sock
            echo ${ssh_agent_file}
        fi
    fi
}

function mem_cache_clean() {
    if [ "$(uname)" = "Linux" ]; then
        level=3
        if [ $# -gt 0 ] && [ $1 -ge 1 ] && [ $1 -le 3 ]; then
            level=$1
        fi
        sudo bash -c "sync; echo ${level} > /proc/sys/vm/drop_caches"
    fi
}
