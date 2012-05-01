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

root2=$1
shift
paths="$@"

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

log_msg "Files updated on server -- syncing clients..."

# Run unison for each client
for client in `ls $client_dir | egrep ^[0-9]+-[0-9]+$`
do  
    client_options=$(cat $client_dir/$client)
    log_msg "Client options: $client_options"

    # If this client is syncing the specified path, sync with unison
    if ( echo "$client_options" | egrep "\-root[[:space:]]+$root2" &> /dev/null )
    then
        port=`echo client | sed -r 's/^([0-9]+)-[0-9]+$/\1/'`
        log_msg "Syncing client $client with options:"
        log_msg "$client_options $paths"
        set +e
        bash -c "UNISON=$unison_dir @UNISON@ -ui text -batch $unison_profile $client_options $paths"
        unison_exit_code=$?
        set -e
        
        # If there was a fatal error in unsion, one of the archives
        # may have been screwed up. Try again, ignoring the archives
        if [ $unison_exit_code -eq 3 ]
        then
            err_msg "Unisync encountered fatal error. Retrying with -ignorearchives"
            set +e
            bash -c "UNISON=$unison_dir @UNISON@ -ui text -batch $unison_profile -ignorearchives $client_options $paths"
            unison_exit_code=$?
            set -e
        fi
    else
        err_msg "Skipping client $client: Not syncing to root $root2"
        err_msg "Client options were $client_options"
    fi
done

log_msg "Finished syncing updates with clients."
