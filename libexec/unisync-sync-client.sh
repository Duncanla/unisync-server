# -* bash -*

#
# Unisync client synchronization
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

unison_dir=$UNISYNC_DIR/unison
unison_profile="unisync"

client_dir=$UNISYNC_DIR/clients
sync_req_dir=$UNISYNC_DIR/sync_request

sync_req=$1

sync_req_file=$sync_req_dir/$sync_req

sync_file=$UNISYNC_DIR/syncs

lockfile=$UNISYNC_DIR/sync_lock

# Cleanup for signal traps
unison_pid=
function cleanup() {
    rm -f $sync_req_file
    rm -f $lockfile

    log_msg "Killing unison (pid: $unison_pid)"
    kill $unison_pid

    err_msg "Died!"

    trap - EXIT
    exit 1
}

# Output error messages
function err_msg() {
#    echo "`basename $0` (`date`): $1" 1>&2
    echo "`basename $0` (`date`): $1" >> $UNISYNC_LOG
    
}

# Output log messages
function log_msg() {
#    echo "`basename $0` (`date`): $1" 1>&2
    echo "`basename $0` (`date`): $1" >> $UNISYNC_LOG
}

trap cleanup INT TERM EXIT

log_msg "Servicing sync request $sync_req"

# Exit if the sync request no longer exists
if [ ! -f $sync_req_dir/$sync_req ]
then
    log_msg "Sync request $sync_req no longer exists"
    trap - EXIT
    exit 0
fi

port=$(echo $sync_req | sed -r 's/^([0-9]+)-[0-9]+/\1/')
sync_req_options=$(cat $sync_req_dir/$sync_req)

log_msg "Sync request options: $sync_req_options"

# Lock the all other syncs out
lock_tries=0
while ! ( set -o noclobber; echo "$$" > "$lockfile" ) &> /dev/null 
do
    if [[ lock_tries -eq 0 ]]
    then
        log_msg "Waiting on existing lock: $lockfile"
    fi

    lock_tries=$lock_tries+1
    sleep 1
done

log_msg "Lock acquired."

# Sync with unison
# Unison returns an exit code of 1 if there is nothing to propagate,
# so don't exit on that error
set +e
bash -c "UNISON=$unison_dir @UNISON@ $unison_profile -ui text -batch $sync_req_options" &>> $UNISYNC_LOG &
unison_pid=$!
wait $unison_pid
unison_exit_code=$?
log_msg "Unison sync exited with code $unison_exit_code"
set -e

# If a fatal error occured in unison, it might be that one of the
# archives was messed up. Try again, ignoring the archives
#if [ $unison_exit_code -eq 3 ]
#then
#    err_msg "Unison fatal error detected. Trying again with -ignorearchives."
#    set +e
#    bash -c "UNISON=$unison_dir @UNISON@ $unison_profile -ui text -batch -ignorearchives $sync_req_options"
#    unison_exit_code=$?
#    log_msg "Unison sync exited with code $unison_exit_code"
#    set -e
#fi

rm -f $sync_req_file
rm -f $lockfile
trap - EXIT

exit 0
