#!/bin/bash

set -e
set -u

etc_dir=@pkgsysconfdir@
source $etc_dir/unisync-server.conf

server_pid_file=$UNISYNC_DIR/unisync-server.pid
server_cmd="@unisync-server@"

trap "echo 'Failed to determine server stats'; exit $?" INT TERM EXIT

if [ ! -f $server_pid_file ]
then
    echo "Server not running. PID file $server_pid_file doesn't exist"
    trap - EXIT
    exit 1
fi

# Check server status
server_pid=$(cat $server_pid_file)
if [ -f $server_pid_file ] && ( ps --pid $server_pid -o cmd | tail -n 1 | egrep "$server_cmd$" &> /dev/null)
then
    echo "Server running. PID: $server_pid"
    trap - EXIT
    exit 0
else
    echo "Server not running. Process $server_pid not has exited"
    trap - EXIT
    exit 1
fi
