#!/usr/bin/sh
# Ollama installed with custom prefix. Open WebUI installed to venv with pip.

prefix=/opt/programs/ollama
openwebui=/opt/programs/open-webui-venv

if [ "$1" = "stop" ]
then
    pid=$(ps -ef | grep "$prefix/bin/ollama serve$" | tr -s ' ' | cut -f 2 -d ' ')
    [ "$pid" ] && kill $pid
    pid=$(ps -ef | grep "$openwebui/bin/open-webui serve$" | tr -s ' ' | cut -f 2 -d ' ')
    [ "$pid" ] && kill $pid
    exit 0
fi

if [ ! "$(ps -ef | grep "$prefix/bin/ollama serve$")" ]
then
    env LD_LIBRARY_PATH=$prefix/lib $prefix/bin/ollama serve &
fi

if [ ! "$(ps -ef | grep "$openwebui/bin/open-webui serve$")" ]
then
    . $openwebui/bin/activate
    # cd so that .webui_secret_key is read from ~
    cd ~
    open-webui serve &
    sleep 5
fi

scriptsdir=$(dirname "$(readlink -f "$0")")
$scriptsdir/chromium.sh app "http://localhost:8080"
