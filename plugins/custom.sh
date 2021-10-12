function fixssh() {
    ssh_agent_file=$(find /tmp/ssh-*/agent.* -user ${USER} 2>/dev/null)
    if [ ! -z "${ssh_agent_file}" ] && [ -e "${ssh_agent_file}" ]; then
        if [ ! -e ${HOME}/.ssh/ssh_auth_sock ] || [ ! "$(realpath ${HOME}/.ssh/ssh_auth_sock)" = "${ssh_agent_file}" ]; then
            ln -sf ${ssh_agent_file} ${HOME}/.ssh/ssh_auth_sock
            echo ${ssh_agent_file}
        fi
    fi
}
