#!/usr/bin/env python3
import argparse
import os
import signal
import subprocess
import time


PROCESS_PATTERNS = [
    "unitree_lerobot/eval_robot/eval_g1.py",
    "teleop_hand_and_arm.py",
    "run_xr_teleop_official_image.sh",
    "run_xr_teleop_pass_through.sh",
    "interactive_arm_real.py",
]


def pkill_controllers():
    for pattern in PROCESS_PATTERNS:
        subprocess.run(["pkill", "-INT", "-f", pattern], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(0.08)
    for pattern in PROCESS_PATTERNS:
        subprocess.run(["pkill", "-TERM", "-f", pattern], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(0.08)
    for pattern in PROCESS_PATTERNS:
        subprocess.run(["pkill", "-KILL", "-f", pattern], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def release_arm_sdk(network_interface: str, bursts: int):
    from unitree_sdk2py.core.channel import ChannelFactoryInitialize, ChannelPublisher
    from unitree_sdk2py.idl.default import unitree_hg_msg_dds__LowCmd_
    from unitree_sdk2py.idl.unitree_hg.msg.dds_ import LowCmd_
    from unitree_sdk2py.utils.crc import CRC

    ChannelFactoryInitialize(0, network_interface)
    pub = ChannelPublisher("rt/arm_sdk", LowCmd_)
    pub.Init()
    crc = CRC()
    cmd = unitree_hg_msg_dds__LowCmd_()

    for _ in range(bursts):
        cmd.motor_cmd[29].q = 0.0
        cmd.crc = crc.Crc(cmd)
        pub.Write(cmd)
        time.sleep(0.01)


def damp_robot(network_interface: str, attempts: int):
    from unitree_sdk2py.core.channel import ChannelFactoryInitialize
    from unitree_sdk2py.g1.loco.g1_loco_client import LocoClient

    ChannelFactoryInitialize(0, network_interface)
    client = LocoClient()
    client.SetTimeout(0.6)
    client.Init()
    for _ in range(attempts):
        try:
            client.Damp()
        except Exception:
            pass
        time.sleep(0.03)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--network-interface", default=os.environ.get("UNITREE_NETWORK_INTERFACE", "enp0s31f6"))
    parser.add_argument("--arm-release-bursts", type=int, default=30)
    parser.add_argument("--damp-attempts", type=int, default=5)
    args = parser.parse_args()

    print("KILL_NOW: stopping local controllers", flush=True)
    pkill_controllers()

    print("KILL_NOW: releasing arm_sdk weight", flush=True)
    try:
        release_arm_sdk(args.network_interface, args.arm_release_bursts)
    except Exception as exc:
        print(f"KILL_NOW: arm_sdk release failed: {exc}", flush=True)

    print("KILL_NOW: sending damping command", flush=True)
    try:
        damp_robot(args.network_interface, args.damp_attempts)
    except Exception as exc:
        print(f"KILL_NOW: damping command failed: {exc}", flush=True)

    print("KILL_NOW: done. Use physical remote emergency damping if needed.", flush=True)


if __name__ == "__main__":
    signal.signal(signal.SIGINT, signal.SIG_IGN)
    main()
