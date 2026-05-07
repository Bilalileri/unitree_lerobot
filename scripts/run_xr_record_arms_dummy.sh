#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

MICROMAMBA="${MICROMAMBA:-$HOME/.local/bin/micromamba}"
export CYCLONEDDS_HOME="${CYCLONEDDS_HOME:-$HOME/cyclonedds/install}"
export LD_LIBRARY_PATH="$CYCLONEDDS_HOME/lib:${LD_LIBRARY_PATH:-}"

ROBOT_IFACE="${ROBOT_IFACE:-enp0s31f6}"
XR_HOST_IFACE="${XR_HOST_IFACE:-wlp0s20f3}"
XR_HOST_IP="${XR_HOST_IP:-$(ip -4 -o addr show "$XR_HOST_IFACE" | awk '{split($4, a, "/"); print a[1]; exit}')}"
IMG_SERVER_IP="${IMG_SERVER_IP:-192.168.123.164}"
TASK_DIR="${TASK_DIR:-./utils/data}"
TASK_NAME="${TASK_NAME:-wood_cube_to_white_a4_area_arms_dummy_1cam_v1}"
TASK_GOAL="${TASK_GOAL:-pick up the wood cube and place it on the white A4 paper area.}"
TASK_DESC="${TASK_DESC:-single RealSense head camera, G1 29DOF arms only, dummy hands/no hand joints}"
TASK_STEPS="${TASK_STEPS:-reach the wood cube; close dummy hand by arm motion/contact only; move above the white A4 paper; release/place}"

cat <<EOF
Arms-only XR recording is starting.

No end-effector controller will be started.
Dataset state/action should be 14D:
  left_arm.qpos(7) + right_arm.qpos(7)

Before this, teleimager must be running on PC2:
  $IMG_SERVER_IP:55555 for laptop ZMQ image
  $IMG_SERVER_IP:60001 for WebRTC head camera

Open this on the Pico browser:
  https://$XR_HOST_IP:8012/?ws=wss://$XR_HOST_IP:8012

Controls:
  r = start robot tracking
  s = start/save recording episode
  q = quit
  F12 = instant kill

Robot DDS interface:
  $ROBOT_IFACE

Task:
  $TASK_NAME
EOF

cd xr_teleoperate/teleop
"$MICROMAMBA" run -p "$PWD/../../.xr-teleop" python teleop_hand_and_arm.py \
  --arm G1_29 \
  --input-mode hand \
  --display-mode immersive \
  --img-server-ip "$IMG_SERVER_IP" \
  --network-interface "$ROBOT_IFACE" \
  --motion \
  --record \
  --task-dir "$TASK_DIR" \
  --task-name "$TASK_NAME" \
  --task-goal "$TASK_GOAL" \
  --task-desc "$TASK_DESC" \
  --task-steps "$TASK_STEPS"
