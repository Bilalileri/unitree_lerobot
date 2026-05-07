# G1 Teleoperation Notes

This folder captures the working Unitree G1 teleoperation setup used for LeRobot data collection and training.

Current hardware state:

- Robot: Unitree G1 EDU 29DOF U2.
- Hands: dummy/passive hands, no controllable hand joints.
- Camera: single RealSense head camera.
- Robot dataset type: `Unitree_G1_29_Arms_1Cam`.
- State/action size: `14`.
- State/action order: left arm 7 joints, then right arm 7 joints.
- Camera key: `observation.images.cam_left_high`.

Do not use the old Inspire FTP 26D robot config for new dummy-hand demos. That old config expected 14D arms plus 12D hand actions.

## Main Files

- `g1_arms_dummy_runbook.md`: start services, record demos, convert to LeRobot, train ACT/diffusion.
- `lerobot_h264_video_patch.md`: explains the local LeRobot video encoder patch used to avoid slow AV1 conversion.
- `scripts/run_xr_record_arms_dummy.sh`: recording launcher from the workspace root.
- `scripts/train_local_g1_arms_act.sh`: local ACT training entrypoint.
- `scripts/train_local_g1_arms_diffusion.sh`: local diffusion policy training entrypoint.
- `scripts/g1_instant_kill.py` and `scripts/g1_kill_now.sh`: local emergency stop helpers.

## Safety

Keep the Unitree remote in hand. The local instant-kill helper is a software backup, not a replacement for the physical remote emergency damping command.
