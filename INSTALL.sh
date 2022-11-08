#!/bin/bash


this=$(realpath "$0")
printf "Script path: $this\n"

context=$(dirname $this)
printf "Script fodler: $context\n\n"



function create_symlink() {
	target_file="$to_folder/$name"
	echo "Linking: $name >> $target_file"
	
	if [[ -s $target_file ]]
	then
		echo "  Exists"
		sudo rm $target_file
		echo "  Removed"
	fi

	cd "$to_folder" && ln -s "$context/$name" "$name"
}


to_folder=~/Code && name="api.sh" && create_symlink

to_folder=~/Code && name="creds.sh" && create_symlink

to_folder=~ && name="DirectoryTemplates" && create_symlink

to_folder=~/.config && name="nvim" && create_symlink


printf "\nSuccess!!!"
cd $context
