# Source: Internal design notes (SCUDA + ComfyUI integration)
# Link: N/A (local integration script)
# Checked (UTC): 2025-11-24
# Version: 0.1.0

import json
import os
import sys
from pathlib import Path
import subprocess


def load_scuda_config(config_path: Path) -> dict:
    if not config_path.exists():
        print(f"[SCUDA] Config file not found at {config_path}, starting ComfyUI normally.")
        return {}

    try:
        with config_path.open("r", encoding="utf-8") as f:
            cfg = json.load(f)
        if not isinstance(cfg, dict):
            raise ValueError("Config root must be an object.")
        return cfg
    except Exception as e:
        print(f"[SCUDA] Failed to read config: {e}")
        return {}


def build_env_from_config(cfg: dict) -> dict:
    env = os.environ.copy()

    enabled = cfg.get("enabled", True)
    if not enabled:
        print("[SCUDA] 'enabled' is false, starting ComfyUI without SCUDA.")
        return env

    server = cfg.get("server")
    lib_path = cfg.get("lib_path")

    if not server or not lib_path:
        print("[SCUDA] 'server' or 'lib_path' missing in config, starting without SCUDA.")
        return env

    if not Path(lib_path).exists():
        print(f"[SCUDA] libscuda not found at {lib_path}, starting without SCUDA.")
        return env

    # Set SCUDA env
    env["SCUDA_SERVER"] = server

    # Inject LD_PRELOAD (prepend existing value if present)
    old_preload = env.get("LD_PRELOAD", "")
    if old_preload:
        env["LD_PRELOAD"] = f"{lib_path}:{old_preload}"
    else:
        env["LD_PRELOAD"] = lib_path

    # Optional extra env
    extra_env = cfg.get("extra_env") or {}
    for key, value in extra_env.items():
        if not isinstance(key, str):
            continue
        env[str(key)] = str(value)

    print("[SCUDA] Launching ComfyUI with SCUDA:")
    print(f"        SCUDA_SERVER={env['SCUDA_SERVER']}")
    print(f"        LD_PRELOAD={env['LD_PRELOAD']}")
    return env


def main():
    repo_root = Path(__file__).resolve().parent
    config_path = repo_root / "scuda_config.json"

    cfg = load_scuda_config(config_path)
    env = build_env_from_config(cfg)

    # Python executable
    python_exe = sys.executable or "python3"

    # ComfyUI main script
    comfy_main = repo_root / "main.py"
    if not comfy_main.exists():
        print(f"[SCUDA] Could not find main.py at {comfy_main}")
        sys.exit(1)

    # Forward all CLI args after launch_scuda.py to main.py
    args = [python_exe, str(comfy_main), *sys.argv[1:]]

    # Replace current process
    os.execve(python_exe, args, env)


if __name__ == "__main__":
    main()