#!/bin/bash

set -e
set -u

etc_dir=/home/luke/unisync/server

unisync_conf=$etc_dir/unisync-server.conf
source $unisync_conf

client_dir=$UNISYNC_DIR/clients
sync_req_dir=$UNISYNC_DIR/sync_request

# Cleanup for signal traps
function cleanup() {
    if [ -f $lockfile ]
    then
        if [[ `head -n 1 $lockfile` -eq $$ ]]
        then
            rm -f $lockfile
        fi
    fi

    trap - EXIT
    exit 1
}

# Output error messages
function err_msg() {
    #echo "`basename $0` (`date`): $1" 1>&2
    echo "`basename $0` (`date`): $1" >> $UNISYNC_LOG
    
}

# Output log messages
function log_msg() {
    #echo "`basename $0` (`date`): $1" 1>&2
    echo "`basename $0` (`date`): $1" >> $UNISYNC_LOG
}

# Exit if the server is not running
if ! ( unisync-server-status &> /dev/null )
then
    err_msg "Server is not running!"
    exit 3
fi

trap cleanup INT TERM EXIT

# Lock the clients directory
lockfile=$client_dir/client_lock
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

# Clean up any clients that are no longer connected
if ( ls $client_dir &> /dev/null )
then
    for port in `ls $client_dir | egrep '[^-][0-9]+$'`
    do
        if ! (nc -zv -w1 localhost $port &> /dev/null)
        then
            log_msg "Removing unconnected client on port $port"
            rm -f $client_dir/$port
            rm -f $client_dir/$port-*
            rm -f $sync_req_dir/$port-*
        fi
    done
fi

# Find an open port
found_port=0
for port in $(eval echo {$SERVER_MIN_PORT..$SERVER_MAX_PORT})
do
    if ! (nc -zv -w1 localhost $port &> /dev/null)
    then
        touch $client_dir/$port
        found_port=1
        break
    fi 
done
#touch $client_dir/$port
rm -f $lockfile

if [ $found_port -ne 1 ]
then
    err_msg "ERROR: No ports available"
    exit 1
else
    log_msg "Assigned port $port to client"
    echo $port
fi

trap - EXIT
exit 0


