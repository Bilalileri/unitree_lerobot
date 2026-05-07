# LeRobot H.264 Video Conversion Patch

The local LeRobot submodule was patched during data upload/conversion because AV1 encoding was too slow at the end of dataset conversion.

The important behavior:

- Default video codec changed from `libsvtav1` to `h264`.
- H.264 encoding uses `preset=ultrafast`.
- Default video chunk size was reduced from `500 MB` to `25 MB`.

This is intentionally documented here because the LeRobot code lives in a nested upstream submodule. If a fresh clone does not include these local edits, run:

```bash
cd ~/Humanoid/unitree_lerobot
scripts/patch_lerobot_h264_video.sh
```

Then rerun dataset conversion.
