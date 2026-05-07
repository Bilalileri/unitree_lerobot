#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LERO_DIR="$ROOT_DIR/unitree_lerobot/lerobot"

cd "$ROOT_DIR"

python - <<'PY'
from pathlib import Path

root = Path("unitree_lerobot/lerobot")
utils = root / "src/lerobot/datasets/utils.py"
video = root / "src/lerobot/datasets/video_utils.py"

text = utils.read_text()
text = text.replace("DEFAULT_VIDEO_FILE_SIZE_IN_MB = 500", "DEFAULT_VIDEO_FILE_SIZE_IN_MB = 25")
utils.write_text(text)

text = video.read_text()
text = text.replace('vcodec: str = "libsvtav1"', 'vcodec: str = "h264"')
needle = '    if crf is not None:\n        video_options["crf"] = str(crf)\n'
insert = needle + '\n    if vcodec == "h264":\n        video_options["preset"] = "ultrafast"\n'
if 'video_options["preset"] = "ultrafast"' not in text:
    text = text.replace(needle, insert)
video.write_text(text)
PY

git -C "$LERO_DIR" diff -- src/lerobot/datasets/utils.py src/lerobot/datasets/video_utils.py
