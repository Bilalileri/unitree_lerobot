# G1 Arms-Only Dummy Hands Runbook

Setup after removing the Inspire FTP hands. Dummy hands have no controllable hand joints.

## Dataset Shape

- Robot type: `Unitree_G1_29_Arms_1Cam`
- Camera: `observation.images.cam_left_high`
- State/action size: `14`
- State/action order:
  - left arm 7 joints
  - right arm 7 joints
- Do not use old `Unitree_G1_Inspire_FTP_1Cam` for this setup. That old config is `26D`.

## Services

Start only the PC2 image server. Do not start the Inspire hand bridge.

On PC2:

```bash
cd ~/teleimager
/unitree/sbin/mscli stopservice video_hub_pc4
pkill -f 'teleimager.image_server' || true
rm -f ~/teleimager_server.log
nohup ~/miniconda3/envs/teleimager/bin/python -u -m teleimager.image_server > ~/teleimager_server.log 2>&1 &
sleep 5
tail -80 ~/teleimager_server.log
```

Expected:

```text
ZMQ: enabled, zmq port=55555
WebRTC: enabled, webrtc port=60001
head_camera is ready.
```

## Record New Demos

On laptop:

```bash
cd ~/Humanoid
unitree_lerobot/scripts/run_xr_record_arms_dummy.sh
```

Controls:

```text
r   start robot tracking
s   start/save recording episode
q   quit
F12 instant kill
```

Raw recordings go to:

```text
~/Humanoid/xr_teleoperate/teleop/utils/data/wood_cube_to_white_a4_area_arms_dummy_1cam_v1
```

## Convert To LeRobot

Use a new dataset repo, separate from the old Inspire FTP one:

```bash
cd ~/Humanoid
~/.local/bin/micromamba run -p ~/Humanoid/.lerobot-smoke python -m unitree_lerobot.utils.convert_unitree_json_to_lerobot \
  --raw-dir ~/Humanoid/xr_teleoperate/teleop/utils/data \
  --repo-id bilileri/g1_arms_dummy_wood_cube_1cam_v1 \
  --robot-type Unitree_G1_29_Arms_1Cam \
  --mode video \
  --dataset-config.use-videos \
  --dataset-config.video-backend pyav
```

## Train ACT

```bash
cd ~/Humanoid
DATASET_REPO=bilileri/g1_arms_dummy_wood_cube_1cam_v1 \
CHUNK_SIZE=50 ACTION_STEPS=50 \
unitree_lerobot/scripts/train_local_g1_arms_act.sh
```

## Train Diffusion

```bash
cd ~/Humanoid
DATASET_REPO=bilileri/g1_arms_dummy_wood_cube_1cam_v1 \
unitree_lerobot/scripts/train_local_g1_arms_diffusion.sh
```

## Real Eval

Use an arms-only 14D checkpoint and do not pass `--ee`.

Safety:

- Keep the remote in hand.
- F12 runs the instant kill script.
- Physical emergency damping is still the main emergency path.
