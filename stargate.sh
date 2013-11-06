#!/usr/bin/env bash
# author: admin@kbni.net

_ssh_check() {
    # don't believe ssh, try to connect to be sure
    ssh -O check "$ssh_host" &> /dev/null && \
    ssh -o 'BatchMode yes' -o 'ConnectTimeout 3' -f "$ssh_host" exit &>/dev/null
    [[ $? -gt 0 ]] && return 1
    return 0
}

_help() {
    cat <<EOF
$bn [mix of options, list setting flags and host strings]
ssh ControlSocket connection manager

options:
-Q --quiet     quieten script (no stdout)
-S --silent    silent script (no stdout or stdin)
-C --ssh-conf  add non-wildcard hosts from ssh_config to list

changing the list:
-a --add       add next string(s) as host(s) to add
-d --delete    add next string(s) as host(s) to delete
-c --check     add next string(s) as host(s) to check

examples:
$bn -d host1 -c -C
  delete host1's connection
  check all hosts from ssh_config
$bn -C
  check all hosts from ssh_config
$bn -a host1 -d host2 -c -C
  add host1 connection
  delete host2 connection
  check all hosts from ssh_config

note:
 operations are performed in order add, delete then check
 flags cannot be combined (Don't use -cC, use -c -C)
EOF
    exit 1
}

bn=$(basename "$0")

stdout="/dev/stdout"
stderr="/dev/stderr"
mode="check"

targets_add=()
targets_del=()
targets_check=()
ssh_hosts=()
ssh_read=0

# figure out what we are going to do (:
while [ $# -gt 0 ]; do
    case $1 in
        -Q|--quiet)    stdout="/dev/null" ;;
        -S|--silent)   stdout="/dev/null"
                       stderr="/dev/null" ;;
        -c|--check)    mode="check"       ;;
        -a|--add)      mode="add"         ;;
        -d|--delete)   mode="del"         ;;
        -h|--help)     _help ; exit 0     ;;
        -C|--ssh-conf)
            if [ $ssh_read -eq 0 ]; then
                while read ssh_host; do
                    ssh_hosts+=($ssh_host)
                done < <(grep "^Host [a-z]\+$" "${HOME}/.ssh/config" 2> /dev/null | sed -e 's/^Host //g; s/ *#.*//g')
                ssh_read=1
            fi
            [[ "$mode" = "add" ]] && targets_add+=( "${ssh_hosts[@]}" )
            [[ "$mode" = "del" ]] && targets_del+=( "${ssh_hosts[@]}" )
            [[ "$mode" = "check" ]] && targets_check+=( "${ssh_hosts[@]}" )
            ;;
        -*)
            echo -e "Unknown argument: $1\n" > /dev/stderr
            _help > /dev/stderr
            exit 1
            ;;
        *)
            [[ "$mode" = "add" ]] && targets_add+=( "$1" )
            [[ "$mode" = "del" ]] && targets_del+=( "$1" )
            [[ "$mode" = "check" ]] && targets_check+=( "$1" )
            ;;
    esac
    shift
done

# add any hosts in $targets_add array
for ssh_host in "${targets_add[@]}"; do
    if _ssh_check "$ssh_host"; then
        echo "$ssh_host already up" > $stdout
    else
        # check it's up, maybe the socket is stale
        ssh -M -N -f "$ssh_host" &> "${TMPDIR}/${ssh_host}.ssh"
        if grep -q "already exists" "${TMPDIR}/${ssh_host}.ssh"; then
            ssh_socket=$(cat "${TMPDIR}/${ssh_host}.ssh" | awk '{ print $2 }')
            rm -v "$ssh_socket" && echo "removed stale socket.. running 'ssh $ssh_host' again" > $stderr
            if ssh -M -N -f "$ssh_host"; then
                echo "master up for $ssh_host!" > $stdout
            else
                echo "unable to setup master for $ssh_host!" > $stderr
            fi
        fi
    fi
done

# delete any hosts in $targets_del array
for ssh_host in "${targets_del[@]}"; do
    ssh -O exit "$ssh_host" &> /dev/null
    _ssh_check "$ssh_host" || echo "removed any connection to $ssh_host" > $stdout
done

# check any hosts in $targets_check array
for ssh_host in "${targets_check[@]}"; do
    echo -n "$ssh_host.." > $stdout
    if _ssh_check "$ssh_host"; then
        echo ". is up." > $stdout
    else
        echo ". is down." > $stdout
    fi
done

