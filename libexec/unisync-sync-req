#!/bin/bash

set -e
set -u

etc_dir=/home/luke/unisync/server

unisync_conf=$etc_dir/unisync-server.conf
source $unisync_conf

client_dir=$UNISYNC_DIR/clients
sync_req_dir=$UNISYNC_DIR/sync_request

sync_file=$UNISYNC_DIR/syncs

port=$1
shift
options="$@"

# Cleanup for signal traps
function cleanup() {
    if [ -f $lockfile ]
    then
        if [[ `head -n 1 $lockfile` -eq $$ ]]
        then
            rm -f $lockfile
        fi
    fi

    rm -f $sync_req_file

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

# Check that the server is running
if ! (unisync-server-status &> /dev/null)
then
    err_msg "Server is not running!"
    exit 3
fi


# Lock the sync_request directory
lockfile=$UNISYNC_DIR/sync_req_lock
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

#Make sure we aren't duplicating a left-over client file
sync_req_file=$(echo $sync_req_dir/$port-`ls $sync_req_dir | egrep -c ^$port-[0-9]+`)

if [ `ls $sync_req_dir | egrep -c ^$port-[0-9]+` -ne 0 ]
then
    for cfile in $sync_req_dir/$port-*
    do
        if [ "`cat $cfile`" = "$options" ]
        then
            log_msg "Sync request file $cfile already pending"
            sync_req_file=$cfile
            break;
        fi
    done
fi

target_id=$(echo $options | sed -r 's|.*\-targetid\s+(\S+).*|\1|')
root=$(cat $sync_file | sed -r "s|$target_id\s+(.*)|\1|")
target_options=`echo $options | sed -r "s|\-targetid\s+\S+|\-root $root|"`

echo $target_options > $sync_req_file

rm -f $lockfile

trap - EXIT
exit 0