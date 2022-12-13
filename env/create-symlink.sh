function create_symlink() {
	POSITIONAL_ARGS=()

	# Paring command args: https://stackoverflow.com/a/14203146/12537042
	while [[ $# -gt 0 ]]; do
		case $1 in
			-f|--file-name)
				file_name="$2"
				shift # past argument
				shift # past value
			;;
			-t|--target-folder)
				target_folder="$2"
				shift # past argument
				shift # past value
			;;
			-*|--*)
				echo "Unknown option $1"
				exit 1
			;;
			*)
			POSITIONAL_ARGS+=("$1") # save positional arg
				shift # past argument
			;;
		esac
	done

	set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

	if [[ -n $1 ]]; then
		echo "Last line of file specified as non-opt/last argument:"
		tail -1 "$1"
	fi


	target_file="$target_folder/$file_name"
	echo "Linking: $file_name >> $target_file"
	
	# If target_file exists, simply remove it
	if [[ -e $target_file ]]
	then
		echo "  Exists"
		sudo rm $target_file
		echo "  Recreate"
	fi

	# Creating symlink in target_folder
	cd "$target_folder" && ln -s "$context/$file_name" "$file_name"
	
	# Appending rm command to uninstall script
	uninstall_sh="${uninstall_sh}rm $target_folder/$file_name\n"
}
