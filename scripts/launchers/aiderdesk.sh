#!/usr/bin/sh
# Run aider-desk (assuming it's been built already) and watch for main main renderer window closing.
# Stop the Electron process when main window is no longer detected.

set -u

app_dir="/opt/ai_tools/aider-desk"

scriptsdir=$(dirname "$(readlink -f "$0")")
ollama_running=$($scriptsdir/local_llm.sh ollama 32768 | grep "Ollama already running.")
[ ! "$ollama_running" ] && echo "Started Ollama."

cd $app_dir
npx electron-vite preview --skipBuild &

echo "Watching for AiderDesk window renderer..."
check_interval=2

while true
do
    sleep "$check_interval"

    main_pid=$(pgrep -f "^${app_dir}/node_modules/electron/dist/electron \.$" | head -n1 || true)
    [ -z "$main_pid" ] && continue

    renderers=$(pgrep -P "$main_pid" -f -- "--type=renderer" || true)
    [ -n "$renderers" ] && continue

    echo "AiderDesk Electron renderer seems to have been closed."

    # Check one more time.
    sleep "$check_interval"
    ! kill -0 "$main_pid" 2>/dev/null && continue

    renderers=$(pgrep -P "$main_pid" -f -- "--type=renderer" || true)
    [ -n "$renderers" ] && continue

    kill -term "$main_pid" 2>/dev/null || true

    # Give Electron some time to shut down.
    max_wait=0
    while [ $max_wait -lt 5 ]
    do
        kill -0 "$main_pid" 2>/dev/null || break
        sleep 1
        max_wait=$(expr $max_wait + 1)
    done

    if kill -0 "$main_pid" 2>/dev/null
    then
        echo "$(date): Electron did not exit. Sending SIGKILL."
        kill -KILL "$main_pid" 2>/dev/null || true
    fi

    echo "AiderDesk stopped."
    [ ! "$ollama_running" ] && echo "Stopping Ollama..." && $scriptsdir/local_llm.sh stop
    exit 0
done
