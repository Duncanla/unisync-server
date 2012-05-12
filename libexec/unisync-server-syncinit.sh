# -* bash -*

#
# Unisync server sync initialization
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

sync_id=$1
shift
target_id=$1

sync_file=$UNISYNC_DIR/syncs
touch $sync_file

sync_req_dir=$UNISYNC_DIR/sync_request
client_dir=$UNISYNC_DIR/clients

sync_req_cmd=@bindir@/@unisync-sync-req@

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

# Delete stale sync requests
for sync_req in `ls $sync_req_dir | egrep "[0-9]+-[0-9]+"`
do
    if ( egrep "\-root\s+$target_id\s+" $sync_req_dir/$sync_req )
    then
        log_msg "Deleting stale sync request $sync_req"
        port=$(echo $sync_req | sed -r 's,([0-9]+)-[0-9]+,\1,')
        rm -f $sync_req_dir/$sync_req
    fi
done

log_msg "Adding sync for $target_id"
if ! (egrep "^$sync_id " $sync_file)
then
    echo "$sync_id $target_id" >> $sync_file
fi

# Re-sync with all clients as needed
for cfile in `ls $client_dir | egrep "[0-9]+-[0-9]+"`
do
    if ( egrep "\-root\s+$target_id\s+" $client_dir/$cfile )
    then
        log_msg "Requesting re-sync with client: $cfile"
        port=$(echo $cfile | sed -r 's,([0-9]+)-[0-9]+,\1,')
        $sync_req_cmd $port `cat $client_dir/$cfile`
    fi
done
