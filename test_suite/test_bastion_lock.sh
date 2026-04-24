#!/usr/bin/env bash

LOCKFILE="$HOME/bastion_lock"
TIMEOUT=100
WAIT=5
ELAPSED=0

while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
    if [ -e "$LOCKFILE" ]; then
        echo "bastion_lock file exists, waiting..."
    else
        # Try to create the lock atomically
        if ( set -o noclobber; > "$LOCKFILE" ) 2> /dev/null; then
            echo "Lock acquired."
            exit 0
        else
            echo "Race condition, retrying..."
        fi
    fi

    sleep "$WAIT"
    ELAPSED=$((ELAPSED + WAIT))
done

echo "Failed to acquire lock after ${TIMEOUT} seconds."
exit 1