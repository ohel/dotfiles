#!/usr/bin/sh
# Open KVM with GPU passthrough enabled. Also start Deskflow server for software keyboard-mouse switch/extension.

! ps -e | grep -q "deskflow$" && /usr/bin/flatpak run --command=/app/bin/deskflow-core org.deskflow.deskflow server &

cd /opt/virtualmachines
sudo ./startvm.sh 1
