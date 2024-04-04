#!/usr/bin/env bash

set -e

project_name=$1
if [[ -z $project_name ]]; then
  echo "Need to pass project name"
  exit 1
fi

project_folder_name="${project_name//_/-}"

work_dir=$(mktemp -d -p .)

git clone https://github.com/searayeah/ds-template.git "$work_dir"
mv "$work_dir/.editorconfig" ".editorconfig"

cat ".gitignore" >>"$work_dir/.gitignore"
rm ".gitignore"
mv "$work_dir/.gitignore" ".gitignore"

mv "$work_dir/.markdownlint.yaml" ".markdownlint.yaml"
mv "$work_dir/.pre-commit-config.yaml" ".pre-commit-config.yaml"
mv "$work_dir/.python-version" ".python-version"
mv "$work_dir/.yamllint.yaml" ".yamllint.yaml"
mv "$work_dir/poetry.lock" "poetry.lock"
mv "$work_dir/pyproject.toml" "pyproject.toml"

sed -i -e "/name.*=/s/= .*/= \"$project_folder_name\"/1" \
  "pyproject.toml"

rm -rf "$work_dir"

echo "Init $project_name"
