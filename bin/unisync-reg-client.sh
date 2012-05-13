B1;2802;0c# -* bash -*

#
# Unisync client registration
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

client_dir=$UNISYNC_DIR/clients
sync_req_dir=$UNISYNC_DIR/sync_request
sync_file=$UNISYNC_DIR/syncs

sync_req_cmd=@bindir@/@unisync-sync-req@

status_cmd=@bindir@/@unisync-server-status@

lockfile=$UNISYNC_DIR/client_lock

sync_wait_max=60

port=$1
shift
options="$@"

function usage {
    cat << EOF
Usage:
% unisync-client-reg [OPTION] PORT

NOTE: This script is intended for use by unisync-client

Register the client on the server with port PORT

Options:
    --help      Print this message
    --version   Print version information

Submit bug reports at github.com/Duncanla/unisync-server
EOF
}

function version {
    cat <<EOF
unisync-reg-client @VERSION@
Unisync server for real-time file synchronization

This is free software, and you are welcome to redistribute it and modify it 
under certain conditions. There is ABSOLUTELY NO WARRANTY for this software.
For legal details see the GNU General Public License.

EOF
}


# Cleanup for signal traps
function cleanup() {
    if [ -f $lockfile ]
    then
        if [[ `head -n 1 $lockfile` -eq $$ ]]
        then
            rm -f $lockfile
        fi
    fi
    
    rm -f $client_file

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

# Check that the server is running
if ! ($status_cmd &> /dev/null)
then
    err_msg "Server is not running! Refusting to register client."
    exit 3
fi

# Make sure syncs are open on the server
if [ ! -f $sync_file ]
then
    err_msg "No sync file $sync_file."
    exit 2
fi

# Check that the client is asking for a valid sync root
touch $sync_file
client_valid=0
sync_wait=0
target_id=$(echo $options | sed -r 's|.*\-targetid\s+(\S+).*|\1|')
while [ $client_valid -ne 1 ]
do
    for sync_id in `cat $sync_file | egrep "^$target_id\s+"`
    do
        if ( egrep "^$target_id\s" $sync_file )
        then
            client_valid=1
            break;
        fi
    done
    if [ $sync_wait -eq 0 ]
    then
        log_msg "Sync not registered yet... Waiting for up to $sync_wait_max seconds..."
    fi
    if [ $sync_wait -ge $sync_wait_max ]
    then
        err_msg "Client is requesting an invalid sync! Refusing to register client."
        err_msg "Client request was: $options"
        err_msg "Valid syncs are:"
        err_msg "`cat $sync_file`"
        exit 2
    fi
    sync_wait=$(expr $sync_wait + 1)
    sleep 1
done

trap cleanup INT TERM EXIT

# Lock the clients directory
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
log_msg "Client dir: $client_dir"
log_msg "Port: $port"
#Make sure we aren't duplicating a left-over client file
client_file=$(echo $client_dir/$port-`ls $client_dir | egrep -c ^$port-[0-9]+`)

root=$(cat $sync_file | sed -r "s|$target_id\s+(.*)|\1|" | head -n 1)
target_options=$(echo $options | sed -r "s|\-targetid\s+\S+|\-root ${root}|")


if [ `ls $client_dir | egrep -c $port-[0-9]+` -ne 0 ]
then
    for cfile in $client_dir/$port-*
    do
        if [ "`cat $cfile`" = "$target_options" ]
        then
            log_msg "Client file $cfile already created"
            client_file=$cfile
            break;
        fi
    done
fi

log_msg "Client file: $client_file" 

echo $target_options > $client_file

rm -f $lockfile

$sync_req_cmd $port $target_options

log_msg "Client registered on port $port"

trap - EXIT
exit 0