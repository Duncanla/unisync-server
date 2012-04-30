#!/bin/bash

set -e
set -u

etc_dir=/home/luke/unisync/server

unisync_conf=$etc_dir/unisync-server.conf
source $unisync_conf

unison_dir=$UNISYNC_DIR/unison
unison_profile="unisync"

client_dir=$UNISYNC_DIR/clients
sync_req_dir=$UNISYNC_DIR/sync_request

sync_req=$1

sync_req_file=$sync_req_dir/$sync_req

sync_file=$UNISYNC_DIR/syncs

# Cleanup for signal traps
function cleanup() {
    rm -f $sync_req_file

    err_msg "Died!"

    trap - EXIT
    exit 1
}

# Output error messages
function err_msg() {
    echo "`basename $0` (`date`): $1" 1>&2
    echo "`basename $0` (`date`): $1" >> $UNISYNC_LOG
    
}

# Output log messages
function log_msg() {
    echo "`basename $0` (`date`): $1" 1>&2
    echo "`basename $0` (`date`): $1" >> $UNISYNC_LOG
}

trap cleanup INT TERM EXIT

log_msg "Servicing sync request $sync_req"

port=$(echo $sync_req | sed -r 's/^([0-9]+)-[0-9]+/\1/')
sync_req_options=$(cat $sync_req_dir/$sync_req)

log_msg "Sync request options: $sync_req_options"

# Sync with unison
# Unison returns an exit code of 1 if there is nothing to propagate,
# so don't exit on that error
set +e
bash -c "UNISON=$unison_dir unison -ui text -batch $unison_profile $sync_req_options"
log_msg "Unison sync exited with code $?"
set -e

rm -f $sync_req_file

trap - EXIT

exit 0
