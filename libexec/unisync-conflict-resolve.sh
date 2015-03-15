# -* bash -*

#
# Unisync conflict resolution
# 
# Copyright (c) 2012, Luke Duncan <Duncan72187@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public license version 2 as
# published by the Free Software Foundation. See COPYING for more details.
#

# This script is intended to deal with unison merges.
# Usage: conflict_resolve CURRENT1 CURRENT2 NEW

date=`date "+%Y-%m-%d-%H%M%S"`
outname=`echo $3 | sed -e 's/[.]unison.mergenew[12]-//'`
cp "$2" "$outname-conflict-$date"
cp "$1" "$3"
