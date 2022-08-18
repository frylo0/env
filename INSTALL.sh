#!/bin/bash


this=$(realpath "$0")
printf "Script path: $this\n"

context=$(dirname $this)
printf "Script fodler: $context\n\n"



function create_symlink() {
	target_file="$path/$name"
	echo "Linking: $name >> $target_file"
	
	if [[ -s $target_file ]]
	then
		echo "  Exists"
		sudo rm $target_file
		echo "  Removed"
	fi

	cd "$path" && ln -s "$context/$name" "$name"
}


path=~/Code && name="api.sh" && create_symlink
path=~ && name="DirectoryTemplates" && create_symlink
path=~/.config && name="nvim" && create_symlink


printf "\nSuccess!!!"
cd $context
