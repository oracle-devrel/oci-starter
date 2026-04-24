#!/usr/bin/env bash

LOCKFILE="$HOME/bastion_lock"
TIMEOUT=300
WAIT=5
ELAPSED=0
DATE_POSTFIX=`date '+%Y%m%d-%H%M%S'`
NAME=$DATE_POSTFIX - $1"
echo "$NAME" >> bastion_lock_waiting

while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
    if [ -e "$LOCKFILE" ]; then
        echo "bastion_lock file exists, waiting..."
    else
        # Try to create the lock atomically
        if ( set -o noclobber; > "$LOCKFILE" ) 2> /dev/null; then
            echo "Lock acquired."
            sed -i "s&$NAME&$NAME - $ELAPSED secs" bastion_lock_waiting     
            rm -Rf $HOME/app/*
            exit 0
        else
            echo "Race condition, retrying..."
        fi
    fi

    sleep "$WAIT"
    ELAPSED=$((ELAPSED + WAIT))
done

sed -i "s&$NAME&$NAME - ERROR TIMEOUT" bastion_lock_waiting     
echo "Failed to acquire lock after ${TIMEOUT} seconds."
exit 1