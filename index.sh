#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
else
    echo "ERROR: .env file not found in $SCRIPT_DIR/.env!"
    exit 1
fi

THREADS=${THREADS:-1}
CONCURRENCY=${CONCURRENCY:-50} # Number of simultaneous connections, default 50
DURATION=${DURATION:-15s} # Test duration, default 15s
REPORT_FILE=${REPORT_FILE:-results.txt} # File to save wrk report
REQUEST_METHOD=${REQUEST_METHOD:-results.txt} # Request method to make the request

if [ -z "$ENDPOINT" ]; then
    echo "ERROR: ENDPOINT variable not defined in .env!"
    exit 1
fi

if [ "$REQUEST_METHOD" != "GET" ] && [ "$REQUEST_METHOD" != "POST" ]; then
    echo "ERROR: REQUEST_METHOD must be either GET or POST (got '$REQUEST_METHOD')"
    exit 1
fi

USERS_JSON="$SCRIPT_DIR/users.json"
if [ ! -f "$USERS_JSON" ]; then
    echo "ERROR: users.json file not found in $USERS_JSON!"
    exit 1
fi

USER_COUNT=$(jq 'length' "$USERS_JSON")

LUA_SCRIPT="$SCRIPT_DIR/request-script.lua"

echo "Starting test with wrk..."
echo "Endpoint URL: $ENDPOINT"
echo "Threads: $CONCURRENCY"
echo "Concurrency: $CONCURRENCY"
echo "Duration: $DURATION"
echo "Users loaded for testing: $USER_COUNT"

wrk -t "$THREADS" -c "$CONCURRENCY" -d "$DURATION" -s "$LUA_SCRIPT" "$ENDPOINT" > "$SCRIPT_DIR/$REPORT_FILE" 2>&1

echo "Test completed. Results saved to $SCRIPT_DIR/$REPORT_FILE"