#!/bin/bash


this=$(realpath "$0")
printf "\nScript path: $this\n"

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



function install_deps() {
   printf "\nInstalling dependecies...\n\n"

   sudo apt-get install imwheel

   printf "\nDeps have been installed!\n\n\n"
}

install_deps



function after_party() {
   printf "\n\n"
   printf "Now you need to:\n"
   printf "  * Add command \`imwheel\` to startup. Use \`imwheel -k -q\` to reset scroll speed.\n"
   printf "  * Install DTL from https://github.com/fritylo/dtl\n"
   printf "  * Install Nvim https://askubuntu.com/questions/430008/how-to-install-neovim-on-ubuntu\n"
}



to_folder=~/Code && name="api.sh" && create_symlink

to_folder=~/Code && name="creds.sh" && create_symlink

to_folder=~ && name="DirectoryTemplates" && create_symlink

to_folder=~/.config && name="nvim" && create_symlink

to_folder=~ && name=".imwheelrc" && create_symlink



printf "\nSuccess!!!"

after_party
cd $context
