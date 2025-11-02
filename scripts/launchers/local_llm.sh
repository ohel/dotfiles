#!/usr/bin/sh
# Run Ollama installed with custom prefix and Open WebUI installed to venv with pip.
# $1 = stop|ollama. If "stop", stop serving and kill Open WebUI. If "ollama", Open WebUI is not started.
# $2 = context size for Ollama, e.g. 8192 for Aider. Optional.

ollama_path=/opt/ai_tools/ollama
openwebui_path=/opt/ai_tools/open-webui-venv
logsdir=~/.cache/local_llm_logs
scriptsdir=$(dirname "$(readlink -f "$0")")

mkdir -p $logsdir

if [ "$1" = "stop" ]
then
    pid=$(ps -ef | grep "$ollama_path/bin/ollama serve$" | tr -s ' ' | cut -f 2 -d ' ')
    [ "$pid" ] && kill $pid
    pid=$(ps -ef | grep "$openwebui_path/bin/open-webui serve$" | tr -s ' ' | cut -f 2 -d ' ')
    [ "$pid" ] && kill $pid
    exit 0
fi

ctx=""
[ "$2" ] && ctx="OLLAMA_CONTEXT_LENGTH=$2"

if ! ps -ef | grep -q "$ollama_path/bin/ollama serve$"
then
    env $ctx LD_LIBRARY_PATH=$ollama_path/lib $ollama_path/bin/ollama serve > $logsdir/ollama.log 2>&1 &
    if which nc >/dev/null 2>&1
    then
        while ! nc -z localhost 11434; do sleep 0.5; done
    else
        sleep 3
    fi
else
    echo "Ollama already running."
fi

[ "$1" = "ollama" ] && exit 0

if ! ps -ef | grep "$openwebui_path/bin/open-webui serve$"
then
    . $openwebui_path/bin/activate
    # cd so that .webui_secret_key is read from ~
    cd ~
    $openwebui_path/bin/open-webui serve > $logsdir/openwebui.log 2>&1 &
    sleep 5
fi

$scriptsdir/chromium.sh app "http://localhost:8080" &
