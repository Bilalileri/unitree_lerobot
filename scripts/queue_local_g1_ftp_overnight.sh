#!/usr/bin/env bash
set -u

ROOT="${ROOT:-$HOME/Humanoid}"
REPO="${REPO:-$ROOT/unitree_lerobot}"
OUT_ROOT="${OUT_ROOT:-$REPO/unitree_lerobot/lerobot/outputs/train}"
LOG="${LOG:-$OUT_ROOT/g1_overnight_training_queue.log}"

CURRENT_ACT_JOB="${CURRENT_ACT_JOB:-g1_ftp_wood_cube_act_20k_cuda_wandb}"
CURRENT_ACT_PID="${CURRENT_ACT_PID:-8579}"
CURRENT_ACT_PARENT_PID="${CURRENT_ACT_PARENT_PID:-8577}"
CURRENT_ACT_STOP_CHECKPOINT="${CURRENT_ACT_STOP_CHECKPOINT:-010000}"

mkdir -p "$(dirname "$LOG")"

log() {
  echo "$(date -Is) $*" | tee -a "$LOG"
}

run_job() {
  local name="$1"
  shift
  log "START ${name}"
  (cd "$REPO" && "$@") >> "$LOG" 2>&1
  local code=$?
  log "END ${name} exit=${code}"
  return "$code"
}

checkpoint_dir="$OUT_ROOT/$CURRENT_ACT_JOB/checkpoints/$CURRENT_ACT_STOP_CHECKPOINT/pretrained_model"

log "Corrected queue started."
log "Waiting for ${CURRENT_ACT_JOB} checkpoint ${CURRENT_ACT_STOP_CHECKPOINT}, then queued ACT variants begin."

while [ ! -d "$checkpoint_dir" ] && [ -d "/proc/${CURRENT_ACT_PID}" ]; do
  log "waiting for ${CURRENT_ACT_JOB} checkpoint ${CURRENT_ACT_STOP_CHECKPOINT}; current pid ${CURRENT_ACT_PID} still running"
  sleep 60
done

if [ -d "$checkpoint_dir" ]; then
  log "Found ${CURRENT_ACT_STOP_CHECKPOINT} checkpoint. Stopping current ACT-100 run so variants can start."
  kill -TERM "$CURRENT_ACT_PARENT_PID" "$CURRENT_ACT_PID" 2>/dev/null || true
  sleep 20
  kill -KILL "$CURRENT_ACT_PARENT_PID" "$CURRENT_ACT_PID" 2>/dev/null || true
else
  log "Current ACT-100 process ended before checkpoint ${CURRENT_ACT_STOP_CHECKPOINT} was seen. Continuing queue."
fi

run_job "ACT chunk50 action50" env \
  STEPS=20000 BATCH_SIZE=8 NUM_WORKERS=4 \
  CHUNK_SIZE=50 ACTION_STEPS=50 \
  JOB_NAME=g1_ftp_wood_cube_act_chunk50_action50_20k_cuda_wandb \
  OUTPUT_DIR=unitree_lerobot/unitree_lerobot/lerobot/outputs/train/g1_ftp_wood_cube_act_chunk50_action50_20k_cuda_wandb \
  scripts/train_local_g1_ftp_act.sh

run_job "ACT chunk25 action25" env \
  STEPS=20000 BATCH_SIZE=8 NUM_WORKERS=4 \
  CHUNK_SIZE=25 ACTION_STEPS=25 \
  JOB_NAME=g1_ftp_wood_cube_act_chunk25_action25_20k_cuda_wandb \
  OUTPUT_DIR=unitree_lerobot/unitree_lerobot/lerobot/outputs/train/g1_ftp_wood_cube_act_chunk25_action25_20k_cuda_wandb \
  scripts/train_local_g1_ftp_act.sh

run_job "ACT chunk50 action25" env \
  STEPS=20000 BATCH_SIZE=8 NUM_WORKERS=4 \
  CHUNK_SIZE=50 ACTION_STEPS=25 \
  JOB_NAME=g1_ftp_wood_cube_act_chunk50_action25_20k_cuda_wandb \
  OUTPUT_DIR=unitree_lerobot/unitree_lerobot/lerobot/outputs/train/g1_ftp_wood_cube_act_chunk50_action25_20k_cuda_wandb \
  scripts/train_local_g1_ftp_act.sh

run_job "Diffusion horizon16 action8" env \
  STEPS=20000 BATCH_SIZE=4 NUM_WORKERS=4 \
  JOB_NAME=g1_ftp_wood_cube_diffusion_20k_cuda_wandb \
  OUTPUT_DIR=unitree_lerobot/unitree_lerobot/lerobot/outputs/train/g1_ftp_wood_cube_diffusion_20k_cuda_wandb \
  scripts/train_local_g1_ftp_diffusion.sh

log "Queue complete."
