import os
import subprocess

PYPROJECT = "pyproject.toml"
LINTERS = "pyproject_linters.toml"

def check_and_init_pyproject():
    if os.path.isfile(PYPROJECT):
        print(f"{PYPROJECT} exists!")
    else:
        print(f"{PYPROJECT} is missing!")
        subprocess.run(["uv", "init", "--vcs", "git"], check=True)

def append_linters_config():
    if not os.path.isfile(LINTERS):
        print(f"{LINTERS} not found! Skipping append.")
        return

    with open(LINTERS, "r") as linter_file:
        linters_content = linter_file.read()

    with open(PYPROJECT, "a") as pyproject_file:
        pyproject_file.write("\n\n# Linters Configuration\n")
        pyproject_file.write(linters_content)
    print(f"Appended {LINTERS} to {PYPROJECT}")

def delete_self():
    os.remove(__file__)

if __name__ == "__main__":
    check_and_init_pyproject()
    append_linters_config()
    delete_self()
