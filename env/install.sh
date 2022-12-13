#!/bin/bash

this="${BASH_SOURCE%/*}"
context=$(readlink -f $this | xargs dirname)

printf "\nScript folder: $context\n\n"

# This string gonna be changed by create_symlink command
uninstall_sh='#!/bin/bash\n'


source "$this/deps.sh"
source "$this/after-party.sh"
source "$this/create-symlink.sh"


install_deps

create_symlink \
	--file-name 'api.sh' \
	--target-folder ~/Code

create_symlink \
	--file-name 'creds.sh' \
	--target-folder ~/Code

create_symlink \
	--file-name 'DirectoryTemplates' \
	--target-folder ~

create_symlink \
	--file-name 'nvim' \
	--target-folder ~/.config

create_symlink \
	--file-name '.imwheelrc' \
	--target-folder ~

printf "\nSuccess!!!"


# Creating uninstall script
printf "$uninstall_sh" > "$context/env/uninstall.sh"
chmod +x "$context/env/uninstall.sh"


after_party
cd $context
