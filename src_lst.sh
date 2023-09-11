#!/bin/bash

this_dir_path="$(dirname "$(realpath "$0")")"
confif_dir=etc/apt
source_lists_dir="/$confif_dir"/sources.list.d
keyrings_dirs="/$confif_dir"/keyrings

sudo mkdir -p $source_lists_dir $keyrings_dirs

for s in $(command ls "$this_dir_path$source_lists_dir"); do
	sudo cp "$this_dir_path$source_lists_dir/$s" "$source_lists_dir/$s"
done

for k in $(command ls "$this_dir_path$keyrings_dirs"); do
	sudo cp "$this_dir_path$keyrings_dirs/$k" "$keyrings_dirs/$k"
done
# sudo chown root:root -R $keyrings_dirs $source_lists_dir
