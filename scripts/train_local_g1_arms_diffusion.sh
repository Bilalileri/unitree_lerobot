#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$HOME/Humanoid}"
LERO_ENV="${LERO_ENV:-$ROOT_DIR/.lerobot-smoke}"
DATASET_REPO="${DATASET_REPO:-bilileri/g1_arms_dummy_wood_cube_1cam_v1}"
WANDB_PROJECT="${WANDB_PROJECT:-g1_arms_dummy_wood_cube}"
JOB_NAME="${JOB_NAME:-g1_arms_dummy_diffusion_20k_cuda_wandb}"
OUTPUT_DIR="${OUTPUT_DIR:-unitree_lerobot/unitree_lerobot/lerobot/outputs/train/${JOB_NAME}}"

STEPS="${STEPS:-20000}"
BATCH_SIZE="${BATCH_SIZE:-4}"
NUM_WORKERS="${NUM_WORKERS:-4}"
SAVE_FREQ="${SAVE_FREQ:-5000}"
LOG_FREQ="${LOG_FREQ:-200}"

cd "${ROOT_DIR}"

~/.local/bin/micromamba run -p "${LERO_ENV}" python unitree_lerobot/unitree_lerobot/lerobot/src/lerobot/scripts/lerobot_train.py \
  --dataset.repo_id="${DATASET_REPO}" \
  --dataset.video_backend=pyav \
  --policy.type=diffusion \
  --policy.input_features='{"observation.images.cam_left_high":{"type":"VISUAL","shape":[3,480,640]},"observation.state":{"type":"STATE","shape":[14]}}' \
  --policy.output_features='{"action":{"type":"ACTION","shape":[14]}}' \
  --policy.horizon=16 \
  --policy.n_action_steps=8 \
  --policy.n_obs_steps=2 \
  --policy.crop_shape='[240,320]' \
  --policy.crop_is_random=false \
  --policy.device=cuda \
  --policy.push_to_hub=false \
  --batch_size="${BATCH_SIZE}" \
  --steps="${STEPS}" \
  --log_freq="${LOG_FREQ}" \
  --save_freq="${SAVE_FREQ}" \
  --eval_freq=0 \
  --num_workers="${NUM_WORKERS}" \
  --wandb.enable=true \
  --wandb.project="${WANDB_PROJECT}" \
  --wandb.mode=online \
  --wandb.disable_artifact=true \
  --output_dir="${OUTPUT_DIR}" \
  --job_name="${JOB_NAME}"
