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

log_msg "Adding sync for $target_id"
if ! (egrep "^$target_id " $sync_file)
then
    echo "$sync_id $target_id" >> $sync_file
fi