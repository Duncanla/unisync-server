# -* bash -*

#
# Unisync client updater
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

lockfile=$UNISYNC_DIR/sync_lock

sync_req_cmd=@bindir@/@unisync-sync-req@

root2=$1
shift
paths="$@"

# Cleanup for signal traps
function cleanup() {
    rm -f $lockfile

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

log_msg "Files updated on server -- syncing clients..."

# Escape things for the shell
target_paths=\'$paths\'

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


# Run unison for each client
for client in `ls $client_dir | egrep ^[0-9]+-[0-9]+$`
do  
    client_options=$(cat $client_dir/$client)
    log_msg "Client options: $client_options"

    # If this client is syncing the specified path, sync with unison
    if ( echo "$client_options" | egrep "\-root[[:space:]]+$root2" &> /dev/null )
    then
        port=`echo $client | sed -r 's/^([0-9]+)-[0-9]+$/\1/'`
        log_msg "Request sync for client $client with options:"
        log_msg "$client_options $paths"
        $sync_req_cmd $port $client_options $paths
    else
        err_msg "Skipping client $client: Not syncing to root $root2"
        err_msg "Client options were $client_options"
    fi
done

rm -f $lockfile

trap - EXIT