# -* bash -*

#
# Unisync client monitor
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

unisync_conf=$etc_dir/unisync-server.conf
source $unisync_conf

port=$1

client_dir=$UNISYNC_DIR/clients
sync_req_dir=$UNISYNC_DIR/sync_request
monitor_dir=$UNISYNC_DIR/monitors
monitor_file=$monitor_dir/$port

sync_client_cmd="@unisync-sync-client@"
sync_lock_file=$UNISYNC_DIR/sync_lock

function usage {
    cat << EOF
Usage:
% unisync-client-mon [OPTION] PORT

NOTE: This script is intended for use by unisync-client

Opens up an ssh connection back to the client on PORT for monitoring.

Options: 
    --help      Print this message
    --version   Print version information

Submit bug reports at github.com/Duncanla/unisync-server
EOF
}

function version {
    cat <<EOF
unisync-client-mon @VERSION@
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
  esac
fi


function cleanup() {
    # Kill the ssh process
    ps --pid $(jobs -p) &> /dev/null && kill $(jobs -p)

    # Kill syncs for this client
    kill_syncs

    # Remove client and clean up any sync requests
    rm -f $client_dir/$port
    rm -f $client_dir/$port-*
    rm -f $sync_req_dir/$port-*
    rm -f $monitor_file

    err_msg "killed!"
    trap - EXIT
    exit 1
}

# Output error messages
function err_msg() {
    echo "`basename $0` (`date`): $1" >> $UNISYNC_LOG
    echo "`basename $0` (`date`): $1" 1>&2
}

# Output log messages
function log_msg() {
    echo "`basename $0` (`date`): $1" >> $UNISYNC_LOG
    echo "`basename $0` (`date`): $1"
}

# Kill any syncs that are running on this port
function kill_syncs () {
    pid=`ps -C $sync_client_cmd -o pid | tail -n 1`
    if ( ps --pid $pid -o cmd | tail -n 1 | egrep "$sync_client_cmd\s+$port-[0-9]+" &> /dev/null )
    then
        log_msg "Killing sync on localhost:$port (pid: $pid)"
        kill $pid
    fi    
}

trap cleanup INT TERM EXIT

echo $$ > $monitor_file

# SSH back to the client on the reverse tunnel port
# to catch when the tunnel is closed
ssh -N -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -o "ServerAliveInterval 60" -o "ServerAliveCountMax 3" -p $port localhost &
ssh_pid=$!

# Wait for tunnel to close -- we expect nonzero exit codes here
log_msg "Monitoring port $port"
set +e
wait $ssh_pid
ssh_exit=$?
set -e

log_msg "Connection to port $port closed"

# Remove client and clean up any sync requests
log_msg "Killing files for port $port"
rm -f $client_dir/$port
rm -f $client_dir/$port-*
rm -f $sync_req_dir/$port-*
rm -f $monitor_file

trap - EXIT
exit 0