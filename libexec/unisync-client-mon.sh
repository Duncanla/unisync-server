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

# This script is intended to deal with unison merges.
# Usage: conflict_resolve CURRENT1 CURRENT2 NEW

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


function cleanup() {
    # Kill the ssh process
    ps --pid $(jobs -p) &> /dev/null && kill $(jobs -p)

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


trap cleanup INT TERM EXIT

echo $$ > $monitor_file

# SSH back to the client on the reverse tunnel port
# to catch when the tunnel is closed
ssh -N -o "ServerAliveInterval 60" -o "ServerAliveCountMax 3" -p $port localhost &
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