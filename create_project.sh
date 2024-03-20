#!/usr/bin/env bash

set -e

project_name=$1
if [[ -z $project_name ]]; then
	echo "Need to pass project name"
	exit 1
fi

project_folder_name="${project_name//_/-}"
project_python_name="${project_name//-/_}"

git clone https://github.com/searayeah/ds-template.git
mv ds-template "$project_folder_name"
mv "$project_folder_name/ds_template" "$project_folder_name/$project_python_name"
sed -i -e "/name.*=/s/= .*/= \"$project_folder_name\"/1" "$project_folder_name/pyproject.toml"

cd "$project_folder_name" && rm -rf .git && git init --initial-branch="main" && git add -A && git commit -m "Initialized using ds-template"

echo "Created $project_name"
