#! /bin/bash

# This script is intended to deal with unison merges.
# Usage: conflict_resolve CURRENT1 CURRENT2 NEW1 NEW2

date=`date "+%Y-%m-%d-%H%M%S"`
outname=`echo $3 | sed -e 's/[.]unison.mergenew[12]-//'`
cp $2 $outname-conflict-$date
cp $1 $3
