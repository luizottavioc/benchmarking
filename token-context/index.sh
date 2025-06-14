#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
else
    echo "ERROR: .env file not found in $SCRIPT_DIR/.env!"
    exit 1
fi

CONCURRENCY=${CONCURRENCY:-50} # Number of simultaneous connections, default 50
DURATION=${DURATION:-30s}      # Test duration, default 30s
REPORT_FILE=${REPORT_FILE:-wrk_token_results.txt} # File to save wrk report

if [ -z "$ENDPOINT" ]; then
    echo "ERROR: ENDPOINT variable not defined in .env!"
    exit 1
fi

USER_LIST=""
for i in $(seq 1 100); do # Support until 100 users (USER_ID_1 to USER_ID_100)
    USER_ID_VAR="USER_ID_${i}"
    USER_TOKEN_VAR="USER_TOKEN_${i}"

    if [ -n "${!USER_ID_VAR}" ] && [ -n "${!USER_TOKEN_VAR}" ]; then
        USER_LIST+="{ id = \"${!USER_ID_VAR}\", token = \"${!USER_TOKEN_VAR}\" },"
    else
        break
    fi
done

if [ -n "$USER_LIST" ]; then
    USER_LIST=${USER_LIST%,}
fi

GENERATED_LUA_SCRIPT="$SCRIPT_DIR/token-context.lua"
echo "Generating Lua script for benchmark in $GENERATED_LUA_SCRIPT..."
sed "s|-- USERS_PLACEHOLDER|${USER_LIST}|g" "$SCRIPT_DIR/token-context.lua.tmpl" > "$GENERATED_LUA_SCRIPT"

echo "Starting authentication isolation test with wrk..."
echo "Endpoint URL: $ENDPOINT"
echo "Concurrency: $CONCURRENCY"
echo "Duration: $DURATION"
echo "Users loaded for testing: $(echo "$USER_LIST" | grep -o "id=" | wc -l)"

wrk -t 1 -c "$CONCURRENCY" -d "$DURATION" -s "$GENERATED_LUA_SCRIPT" "$ENDPOINT" > "$SCRIPT_DIR/$REPORT_FILE" 2>&1

echo "Authentication isolation test completed. Results saved to $SCRIPT_DIR/$REPORT_FILE"
echo "Check the $SCRIPT_DIR/$REPORT_FILE file and the terminal output for token leak warnings."

rm "$GENERATED_LUA_SCRIPT"