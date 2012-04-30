# -* bash -*

#
# Unisync server status
# 
# Copyright (c) 2012, Luke Duncan <Duncan72187@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public license version 2 as
# published by the Free Software Foundation. See COPYING for more details.
#

set -e
set -u

etc_dir=@pkgsysconfdir@
source $etc_dir/unisync-server.conf

server_pid_file=$UNISYNC_DIR/unisync-server.pid
server_cmd="@unisync-server@"

function usage {
    cat << EOF
Usage:
% unisync-server-status [OPTION]

Print the status of the server

Options: 
    --help      Print this message
    --version   Print version information

Submit bug reports at github.com/Duncanla/unisync-server
EOF
}

function version {
    cat <<EOF
unisync-server-status @VERSION@
Unisync server for real-time file synchronization

This is free software, and you are welcome to redistribute it and modify it 
under certain conditions. There is ABSOLUTELY NO WARRANTY for this software.
For legal details see the GNU General Public License.

EOF
}

# Parse options
if test $# -ne 0
then
  case $1 in
  --help)
    usage
    exit
    ;;
  --version)
    version
    exit
    ;;
  *)
    usage
    exit
    ;;
  esac
fi

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
