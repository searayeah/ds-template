import subprocess

def run_dvc_commands():
    commands = [
        ["dvc", "init"],
        ["dvc", "config", "core.autostage", "true"],
        ["dvc", "config", "core.analytics", "false"]
    ]

    for cmd in commands:
        print(f"Running: {' '.join(cmd)}")
        subprocess.run(cmd, check=True)

if __name__ == "__main__":
    run_dvc_commands()
