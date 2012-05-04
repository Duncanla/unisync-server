# -* bash -*

#
# Unisync server
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

status_cmd=@bindir@/@unisync-server-status@

lockfile=$UNISYNC_DIR/sync_req_lock

port=$1
shift
options="$@"

function usage {
    cat << EOF
Usage:
% unisync-sync-req [OPTION] PORT CLIENT_OPTIONS

Note: This script is intended for use by unisync-client

Submit a sync request to the server for the client connected to PORT
with the CLIENT_OPTIONS being passed to unison.

Options: 
    --help      Print this message
    --version   Print version information

Submit bug reports at github.com/Duncanla/unisync-server
EOF
}

function version {
    cat <<EOF
unisync-sync-req @VERSION@
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

# Cleanup for signal traps
function cleanup() {
    if [ -f $lockfile ]
    then
        if [[ `head -n 1 $lockfile` -eq $$ ]]
        then
            rm -f $lockfile
        fi
    fi
    
    if [ ! -z $sync_req_file ]
    then
        rm -f $sync_req_file
    fi

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

# Determine the maximum of the input parameters
function max() {
    max=$1
    shift
    while [ $# -gt 0 ]
    do
        [ $1 -gt $max ] && max=$1
        shift
    done
    echo $max
}

trap cleanup INT TERM EXIT

# Check that the server is running
if ! ($status_cmd &> /dev/null)
then
    err_msg "Server is not running!"
    exit 3
fi


# Lock the sync_request directory
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
set +e
pending_sync=`ls $sync_req_dir | egrep "^$port-[0-9]+" &> /dev/null`
set -e
if ( echo $pending_sync | egrep -c . &> /dev/null )
then
    sync_num=$(max `echo $pending_sync | sed -r "s,^$port-([0-9]+),\1,"`)
    sync_num=$(expr $sync_num + 1)
else
    sync_num=0
fi

sync_req_file=$sync_req_dir/$port-$sync_num

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
root=$(cat $sync_file | sed -r "s|$target_id\s+(.*)|\1|" | head -n 1)
target_options=`echo $options | sed -r "s|\-targetid\s+\S+|\-root $root|"`

log_msg "Registering sync request number $sync_num for client on port $port"
log_msg "With options: $options"

echo $target_options > $sync_req_file

rm -f $lockfile

trap - EXIT
exit 0