#!/bin/bash

# Prompt for project name (optional)
read -r -p "Enter the project name (leave blank - default to parent folder name): " project_folder_name

if [[ -z $project_folder_name ]]; then
  project_folder_name=$(basename "$PWD")
fi

project_folder_name="${project_folder_name//_/-}"
project_python_name="${project_folder_name//-/_}"

echo "Project folder name: $project_folder_name"
echo "Project python name: $project_python_name"

if [[ -d ".git" ]]; then
  vcs_choice="none"
else
  vcs_choice="git"
fi

echo "VCS choice: $vcs_choice"

# Default to creating a README file
if [[ -f "README.md" ]]; then
  readme_choice="no"
else
  readme_choice="yes"
fi

echo "Readme choice: $readme_choice"

# Prompt for Python version (optional)
read -r -p "Enter the Python version to use (leave blank if 3.9): " python_version

if [[ -z $python_version ]]; then
  python_version="3.9"
fi

python_version_without_dot="${python_version//./}"

echo "Python version: $python_version"
echo "Python version without dot: $python_version_without_dot"

# Construct the uv init command
cmd="uv init"

# Add project name to the command if provided
if [[ -n $project_folder_name ]]; then
  cmd="$cmd --name \"$project_folder_name\""
fi

# Add VCS option if provided
if [[ -n $vcs_choice ]]; then
  cmd="$cmd --vcs \"$vcs_choice\""
fi

# Add --no-readme if the user chooses no
if [[ $readme_choice == "no" ]]; then
  cmd="$cmd --no-readme"
fi

# Add Python version if provided
if [[ -n $python_version ]]; then
  cmd="$cmd --python \"$python_version\""
fi

cmd="$cmd --python-preference \"only-managed\""

# Execute the constructed command
echo "Executing: $cmd"
eval "$cmd"

if [[ ! -d $project_python_name ]]; then
  mkdir -p "$project_python_name"
  touch "$project_python_name/__init__.py"
fi

if [[ -f "hello.py" ]]; then
  echo "Removing hello.py"
  rm "hello.py"
fi

uv add pre-commit isort black flake8 flake8-bugbear flake8-simplify flake8-pyproject ruff mypy pylint deptry "nbqa[toolchain]" --dev --raw-sources

uv add typing-extensions pandas-stubs types-pillow types-beautifulsoup4 types-tqdm types-seaborn types-requests types-pyyaml types-regex types-openpyxl types-pygments types-colorama types-decorator types-jsonschema types-protobuf types-psutil types-setuptools types-six types-tabulate --dev --raw-sources

uv add numpy pandas matplotlib jupyterlab ipywidgets

git clone https://github.com/searayeah/ds-template.git

cp ds-template/.editorconfig .

if [[ $vcs_choice == "git" && -f ".gitignore" ]]; then
  echo "Removing default .gitignore"
  rm ".gitignore"
  cp ds-template/.gitignore .
fi

if [[ $vcs_choice == "no" && -f ".gitignore" ]]; then
  echo "Concatting current .gitignore and ds-template .gitignore"
  cat ds-template/.gitignore >>.gitignore
fi

read -r -p "Github actions (Y or n): " github_actions

if [[ $github_actions == "Y" || $github_actions == "y" ]]; then
  cp -r ds-template/.github .
fi

if [[ -d ".git" && ! -d ".dvc" ]]; then
  read -r -p "Initialize dvc (Y or n): " dvc_init
  if [[ $dvc_init == "Y" || $dvc_init == "y" ]]; then
    dvc init
    cat ds-template/.dvc/config >>.dvc/config
  fi
fi

if [[ ! -f "LICENSE" ]]; then
  cp ds-template/LICENSE .
fi

cp ds-template/.pre-commit-config.yaml .

# removing commented lines
sed -i '/^\s*#/d' .pre-commit-config.yaml

remove_hook() {
  local full_hook_name="$1"
  hook_name="${full_hook_name#*/}"
  echo "Removing $hook_name from .pre-commit-config.yaml..."

  # Remove the hook block from the YAML file
  sed -i "/^[[:space:]]*- repo:.*$hook_name/,/^$/d" .pre-commit-config.yaml
  echo "$hook_name removed."
}

mapfile -t hooks < <(grep -oP '(?<=- repo: https://github.com/)\S+' .pre-commit-config.yaml)

for hook in "${hooks[@]}"; do
  read -r -p "Do you want to keep $hook? (Y or n): " choice
  choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
  if [[ $choice == "n" || $choice == "no" ]]; then
    remove_hook "$hook"
  fi

  if [[ ($choice == "y" || $choice == "yes") && $hook == "adrienverge/yamllint.git" ]]; then
    echo "Copying .yamllint.yaml"
    cp ds-template/.yamllint.yaml .
  fi

  if [[ ($choice == "y" || $choice == "yes") && $hook == "igorshubovych/markdownlint-cli" ]]; then
    echo "Copying .markdownlint.yaml"
    cp ds-template/.markdownlint.yaml .
  fi

  if [[ ($choice == "y" || $choice == "yes") && $hook == "nbQA-dev/nbQA" ]]; then
    read -r -p "Do you want to keep nbqa/flake8? (Y or n): " nbqa_choice
    nbqa_choice=$(echo "$nbqa_choice" | tr '[:upper:]' '[:lower:]')
    if [[ $nbqa_choice == "n" || $nbqa_choice == "no" ]]; then
      echo "Removing flake8 from nbqa"
      sed -i '/^\s*- id: nbqa-flake8/,/^$/d' .pre-commit-config.yaml
    fi
  fi

done

echo "Replace python to $python_version in .pre-commit-config.yaml"
sed -i "s/python: python[0-9]\+\.[0-9]\+/python: python${python_version}/" .pre-commit-config.yaml
sed -i "s/--py[0-9]\+/--py${python_version_without_dot}/g" .pre-commit-config.yaml

uv run pre-commit install

echo "Copying linters and formatters configuration"
echo >>pyproject.toml
awk '/\[tool.black\]/ {found=1} found' ds-template/pyproject.toml >>pyproject.toml

echo "Setting up right python version in formatter and linters configuration"

sed -i "s/target-version *= *\[\"py[0-9]*\"\]/target-version = [\"py${python_version_without_dot}\"]/g" pyproject.toml
sed -i "s/py-version *= *\"[0-9]*\.[0-9]*\"/py-version = \"$python_version\"/g" pyproject.toml
sed -i "s/python_version *= *\"[0-9]*\.[0-9]*\"/python_version = \"$python_version\"/g" pyproject.toml
sed -i "s/target-version *= *\"py[0-9]*\"/target-version = \"py${python_version_without_dot}\"/g" pyproject.toml

rm -f -r ds-template
