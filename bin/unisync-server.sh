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

source $etc_dir/unisync-server.conf

client_dir=$UNISYNC_DIR/clients
sync_req_dir=$UNISYNC_DIR/sync_request
sync_file=$UNISYNC_DIR/syncs

monitor_dir=$UNISYNC_DIR/monitors
monitor_cmd="@unisync-client-mon@"

pid_file=$UNISYNC_DIR/unisync-server.pid

client_lock_file=$UNISYNC_DIR/client_lock

user_conf_file=$UNISYNC_DIR/unisync-server.lua
blank_user_conf=$etc_dir/unisync-server-user.lua

unison_conf=$etc_dir/unisync.prf
unison_dir=$UNISYNC_DIR/unison
unison_conf_user=$unison_dir/unisync.prf

function usage {
    cat << EOF
Usage:
% unisync-server [OPTION]

Options: 
    --help      Print this message
    --version   Print version information

Submit bug reports at github.com/Duncanla/unisync-server
EOF
}

function version {
    cat <<EOF
unisync-server @VERSION@
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


# Cleanup for trapped signals
function cleanup {
    
    kill_open_monitors

    # Clean up directories
    rm -f $client_dir/*
    rm -f $sync_req_dir/*
    rm -f $sync_file
    rm -f $pid_file

    err_msg "Server died!"

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

function kill_open_monitors () {
    # Kill any open connections 
    for mon_file in `ls $monitor_dir`
    do
        port=$(echo $mon_file | sed -r 's/^([0-9]+)$/\1/')
        pid=$(cat $monitor_dir/$mon_file)
        
        log_msg "Killing (possibly old) monitor on localhost:$port"
        
        if ( ps --pid $pid -o cmd | tail -n 1 | egrep "$monitor_cmd\s+$port" &> /dev/null )
        then
            kill $pid
        fi

        rm -f $monitor_dir/$mon_file
    done
}

touch $pid_file
old_pid=`cat $pid_file`
if [ ! -z $old_pid ]
then
    echo "Old PID found... $old_pid"
    if ( ps --pid $old_pid -o cmd | tail -n 1 | egrep "$0$" )
    then
        err_msg "Unisync server is already running! (PID: $old_pid)"
        exit 2
    fi
fi

trap cleanup INT TERM EXIT

echo $$ > $pid_file

# Quit if there is no user configuration
if [ ! -f $user_conf_file ]
then
    err_msg "No user config found. Please add the configuration to $user_conf_file"
    cp $blank_user_conf $user_conf_file
    exit 1
fi

# Create all required directories
mkdir -p $monitor_dir
mkdir -p $client_dir
mkdir -p $sync_req_dir
mkdir -p $unison_dir

# Link to unison profile
if [ ! -e $unison_conf_user ]
then
    rm -f $unison_conf_user
    ln -s $unison_conf $unison_conf_user
fi

# Kill any old monitors
kill_open_monitors

# Clean up directories
rm -f $client_dir/*
rm -f $sync_req_dir/*
rm -f $sync_file
rm -f $client_lock_file

# Start lsyncd
log_msg "Starting lsync..."
lsyncd -log all $etc_dir/unisync-server.lua
err_msg "lsyncd died"

kill_open_monitors

# Clean up directoreis
rm -f $client_dir/*
rm -f $sync_req_dir/*
rm -f $sync_file
rm -f $pid_file
rm -f $client_lock_file