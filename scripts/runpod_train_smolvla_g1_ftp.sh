#!/usr/bin/env bash
set -euo pipefail

# Run this on a fresh RunPod PyTorch/CUDA pod.
#
# Required env vars:
#   HF_TOKEN          Hugging Face token with dataset/model write access
#   WANDB_API_KEY     Weights & Biases API key
#
# Useful overrides:
#   STEPS=10 BATCH_SIZE=2 PUSH_TO_HUB=false ./scripts/runpod_train_smolvla_g1_ftp.sh
#   STEPS=20000 BATCH_SIZE=8 ./scripts/runpod_train_smolvla_g1_ftp.sh

DATASET_REPO="${DATASET_REPO:-bilileri/g1_ftp_wood_cube_63eps_video_v1}"
POLICY_BASE="${POLICY_BASE:-lerobot/smolvla_base}"
POLICY_REPO_ID="${POLICY_REPO_ID:-bilileri/g1_ftp_wood_cube_smolvla_20k}"
WANDB_PROJECT="${WANDB_PROJECT:-g1_ftp_wood_cube}"
JOB_NAME="${JOB_NAME:-g1_ftp_wood_cube_smolvla_runpod}"
OUTPUT_DIR="${OUTPUT_DIR:-/workspace/outputs/train/${JOB_NAME}}"

STEPS="${STEPS:-20000}"
BATCH_SIZE="${BATCH_SIZE:-8}"
NUM_WORKERS="${NUM_WORKERS:-8}"
SAVE_FREQ="${SAVE_FREQ:-5000}"
LOG_FREQ="${LOG_FREQ:-200}"
PUSH_TO_HUB="${PUSH_TO_HUB:-true}"
VIDEO_BACKEND="${VIDEO_BACKEND:-pyav}"
WANDB_ENABLE="${WANDB_ENABLE:-true}"

if [[ "${PUSH_TO_HUB}" == "true" && -z "${HF_TOKEN:-}" ]]; then
  echo "HF_TOKEN is not set. Export it first, or run with PUSH_TO_HUB=false."
  exit 1
fi

if [[ "${WANDB_ENABLE}" == "true" && -z "${WANDB_API_KEY:-}" ]]; then
  echo "WANDB_API_KEY is not set. Export it first, or run with WANDB_ENABLE=false."
  exit 1
fi

export HF_HUB_ENABLE_HF_TRANSFER=1
export WANDB_MODE=online

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNITREE_LEROBOT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LEROBOT_PATCH="${UNITREE_LEROBOT_ROOT}/patches/lerobot_h264_video_defaults.patch"

cd /workspace

if [[ ! -d lerobot ]]; then
  git clone https://github.com/huggingface/lerobot.git
fi

cd /workspace/lerobot

# Keep close to the LeRobot version used by the local Unitree submodule.
git fetch origin
git checkout a5b29d430105f5235eb05bbf2db5a0d747a869d6

if [[ -f "${LEROBOT_PATCH}" ]]; then
  if git apply --check "${LEROBOT_PATCH}"; then
    git apply "${LEROBOT_PATCH}"
  elif git apply --reverse --check "${LEROBOT_PATCH}"; then
    echo "LeRobot H.264 patch already applied."
  else
    echo "Could not apply LeRobot H.264 patch cleanly."
    exit 1
  fi
fi

python3 -m venv /workspace/.venv-lerobot-smolvla
source /workspace/.venv-lerobot-smolvla/bin/activate

python -m pip install -U pip
python -m pip install -e ".[smolvla]"

# LeRobot 0.4.1 pins wandb<0.22, but newer wandb_v1 keys need the newer client.
python -m pip install -U "wandb>=0.26.1" hf_transfer

if [[ -n "${HF_TOKEN:-}" ]]; then
  hf auth login --token "${HF_TOKEN}"
fi

if [[ "${WANDB_ENABLE}" == "true" ]]; then
  wandb login --relogin "${WANDB_API_KEY}"
fi

echo "Checking GPU..."
nvidia-smi
python - <<'PY'
import torch
print("torch", torch.__version__)
print("cuda", torch.cuda.is_available())
print("gpu", torch.cuda.get_device_name(0) if torch.cuda.is_available() else "none")
PY

echo "Starting SmolVLA training"
echo "Dataset: ${DATASET_REPO}"
echo "Base policy: ${POLICY_BASE}"
echo "Output: ${OUTPUT_DIR}"
echo "Steps: ${STEPS}, batch size: ${BATCH_SIZE}"

lerobot-train \
  --policy.path="${POLICY_BASE}" \
  --policy.input_features='{"observation.images.cam_left_high":{"type":"VISUAL","shape":[3,480,640]},"observation.state":{"type":"STATE","shape":[26]}}' \
  --policy.output_features='{"action":{"type":"ACTION","shape":[26]}}' \
  --dataset.repo_id="${DATASET_REPO}" \
  --dataset.video_backend="${VIDEO_BACKEND}" \
  --policy.device=cuda \
  --batch_size="${BATCH_SIZE}" \
  --steps="${STEPS}" \
  --log_freq="${LOG_FREQ}" \
  --save_freq="${SAVE_FREQ}" \
  --eval_freq=0 \
  --num_workers="${NUM_WORKERS}" \
  --output_dir="${OUTPUT_DIR}" \
  --job_name="${JOB_NAME}" \
  --wandb.enable="${WANDB_ENABLE}" \
  --wandb.project="${WANDB_PROJECT}" \
  --wandb.mode=online \
  --wandb.disable_artifact=true \
  --policy.push_to_hub="${PUSH_TO_HUB}" \
  --policy.repo_id="${POLICY_REPO_ID}"

echo "Done."
echo "Local output: ${OUTPUT_DIR}"
if [[ "${PUSH_TO_HUB}" == "true" ]]; then
  echo "Policy repo: https://huggingface.co/${POLICY_REPO_ID}"
fi
