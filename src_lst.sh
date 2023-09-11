#!/bin/bash

this_dir_path="$(dirname "$(realpath "$0")")"
confif_dirs=etc/apt
source_lists_dirs="$confif_dirs"/sources.list.d
keyrings_dirs="$confif_dirs"/keyrings

# sudo mkdir -p $source_lists_dirs $keyrings_dirs

sudo ln -svnf "$this_dir_path/$source_lists_dirs" "/$source_lists_dirs"

sudo cp -r "$this_dir_path/$keyrings_dirs" "/$keyrings_dirs"

# sudo chown root:root -R $keyrings_dirs $source_lists_dir
