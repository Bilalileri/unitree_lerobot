#!/usr/bin/env bash
set +e

cd "$HOME/Humanoid" || exit 0

export CYCLONEDDS_HOME="$HOME/cyclonedds/install"
export LD_LIBRARY_PATH="$HOME/cyclonedds/install/lib:${LD_LIBRARY_PATH:-}"
export UNITREE_NETWORK_INTERFACE="${UNITREE_NETWORK_INTERFACE:-enp0s31f6}"
export PYTHONPATH="$HOME/Humanoid/unitree_sdk2_python:${PYTHONPATH:-}"

"$HOME/Humanoid/.venv/bin/python" -u "$HOME/Humanoid/unitree_lerobot/scripts/g1_instant_kill.py" \
  --network-interface "$UNITREE_NETWORK_INTERFACE"
