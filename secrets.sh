#!/usr/bin/env bash
# Script to encriypt decrypt files or directories

function encrypt_checks {

	if [ $# -ne 1 ]; then
		echo -e "\tmissing parameter <directory>"
		exit 9
	fi

	directory=$1
	tarfile=$1.tar.gz
	hidden=".$tarfile"
	encrypted=$hidden.gpg

	if [ ! -d "$directory" ]; then
		echo -e  "\t[-]ERROR: $directory is not a directory on the filesystem"
		exit 10
	fi
	
	if [ -f "$tarfile" ]; then
		echo -e "\t[-]ERROR: $tarfile tar file exists for that directory already"
		echo -e "\tconsider to fix that issue manually"
		exit 11

	elif [ -f "$hidden" ]; then
		echo -e "\t[-]ERROR: $hidden hidden tar file exists already"
		echo -e "\tconsider to fix that issue manually"
		exit 12

	elif [ -f "$encrypted" ]; then
		echo -e "\t[!]WARNING: There is an existing encrypted file for $directory called $encrypted"
		echo -e "\t At this point you can:"
		echo -e "\t * ENCRYPT the current content of $directory and generate a new $encrypted( backup old $encrypted)"
		echo -e "\t * Exit to review it manually"

		while true; do
			read -p "Type 'e' to encrypt $directory in $(dirname ${directory}) or 'q' to quit: >> " choices			
			case $choice in
			'e')
				mv $encrypted ${encrypted}_$(date -I).backup
				if [ $? -ne 0 ]; then
					echo -e "\t[-]ERROR:Could not  backup $encrypted before encrypting"
					exit 13
				fi
				encrypt $directory; exit;; 
			'q') 
				echo "\t[+]INFO: Good bye! :-) "; exit;;
			*)
				echo "Please type in 'e' to encrypt $directory or 'q' to quit : ";;
			esac
		done
	fi
	encrypt $directory
}


function decrypt_checks {

	if [ $# -ne 1 ]; then
		echo -e "\t[-]ERROR:missing parameter <directory>"
		exit 9
	fi

	directory=$1
	tarfile=$1.tar.gz
	hidden=".$tarfile"
	encrypted=$hidden.gpg

	if [ ! -f "$encrypted" ]; then
		echo -e "\t[-]ERROR: There is no $encrypted file for $directory"
		echo -e "\t Please review file exists or path is correct"
		exit 20
	fi
	
	if [ -f "$tarfile" ]; then
		echo -e "\t[-]ERROR: $tarfile tar file exists for that directory already"
		echo -e "\tconsider to fix that issue manually"
		exit 11

	elif [ -f "$hidden" ]; then
		echo -e "\t[-]ERROR: $hidden hidden tar file exists already"
		echo -e "\tconsider to fix that issue manually"
		exit 12

	elif [ -d "$directory" ]; then
		echo -e "\t[!]WARNING: $directory  file/directory decrypted version already exists"
		echo -e "\t At this point you can:"
		echo -e "\t * Overwrite $directory content with the latest $encrypted version (previously backup) "
		echo -e "\t * QUIT to exit"

		while true; do
			read -p "Type 'd' to decrypt $encrypted in $(dirname ${directory}) and overwrite the existing \
			$directory or 'q' to quit: >> " choice
			
			case $choice in
			'd')
				mv $directory ${directory}_$(date -I).backup
				if [ $? -ne 0 ]; then
					echo "\t[-]ERROR: Could not  backup $directory before decrypting $encrypted"
					exit 21
				fi
				decrypt $directory; exit;; 
			'quit') 
				echo "\t[+]INFO: Good bye! :-) "; exit;;
			*)
				echo "Please type 'd' to decrypt $encrypted and overwrite $directory or 'q' to quit : ";;
			esac
		done
	
	fi
	decrypt $directory
}

function encrypt {

	if [ $# -ne 1 ]; then
		echo -e "\t[-]ERROR: missing parameter <directory>"
		exit 9
	fi

	directory=$1
	tar_file="$1.tar.gz"

    echo " The file is: $directory"
	echo " The tar file will be $tar_file"

	if [ ! -d "$directory" ]; then
		echo -e  "\t[-]ERROR: $directory is not a directory on the filesystem"
		exit 10
	fi
     
	if [ -f $tar_file ]; then
		echo -e "\t[!]WARNING: Tar file already exist"
		while true; do
			read -p "Type 'c' to continue and re-crate $tar_file or 'q' to quit and fix it manually: >> " choices			
			case $choice in
			'c')
				rm -f $tar_file
				echo -e "\t[+]INFO: Creating tar archive"
				tar czvf $tar_file $directory
				if [ $? -ne 0 ]; then
					echo -e "\t[-]ERROR:Could not creat tar.gz archive"
					exit 20
				fi
				echo -e "\t[+]INFO: $tar_file created"; exit;;
			'q') 
				echo "\t[+]INFO: Good bye! :-) "; exit;;
			*)
				echo "Please 'c' to continue and re-crate $tar_file or 'q' to quit and fix it manually: ";;
			esac
		done
	fi 
	
	
	echo -e "\t[+]INFO: Creating tar archive"
	tar czvf $tar_file $directory
	if [ $? -ne 0 ]; then
			echo -e "\t[-]ERROR:Could not creat tar.gz archive"
			exit 20
	fi

	echo -e "\t[+]INFO: Hiding the tar archive"
	mv $tar_file ".$tar_file"
	if [ $? -ne 0 ]; then
		echo -e "\t[-]ERROR: Error hiding the $tar_file"
		exit 21
	fi

	echo -e "\t[+]INFO: Encrypting the hidden tar archive"
	gpg -c ".$tar_file"
	if [ $? -ne 0 ]; then
		echo -e "\t[-]ERROR: Error encrypting the .$tar_file"
		exit 22
	fi
	
	echo -e "\t[+]INFO: Removing the non encrypted tar archive: .$tar_file"
	rm ".$tar_file"
	if [ $? -ne 0 ]; then
		echo -e "[-]ERROR: Could not delete the .$tar_file"
		exit 23
	fi

	echo -e "\t[+]INFO: DELETING ghe original $directory, remember the PATH where it is \
	as it will be needed to decrypt with secrets 'd' "
	rm -rf $directory
	if [ $? -ne 0 ]; then
		echo -e "\t[-]ERROR: Can not delte the $directory"
		exit 24
	fi			

	return 0
}

function decrypt {

	if [ $# -ne 1 ]; then
		echo -e "\t[-]ERROR:missing parameter <directory>"
		exit 9
	fi

	directory=$1
	tarfile=$1.tar.gz
	hidden=".$tarfile"
	encrypted=$hidden.gpg

	if [ ! -f "$encrypted" ]; then
		echo -e "\t[-]ERROR: $encrypted file does not exist"
		echo -e "\tSeems like there is no encrypted file for this $directory yet"
		echo -e "\tPlease ensure the name of the file or directory is ok and try it again"
		exit 30
	fi

	echo -e "\t[+]INFO: Decripting $encrypted"
	gpg --output $tarfile --decrypt $encrypted

	if [ $? -ne 0 ]; then
		echo -e "\t[-]ERROR: Can not decrypt $encrypted"
		exit 31
	else 
		echo -e "\t[+]INFO: Untar $tarfile"
		tar xzvf $tarfile
		if [ $? -ne 0 ]; then
			echo -e "\t[-]ERROR: Can not untar $tarfile"
			exit 32
		fi
		echo -e "\t[+]INFO: Removing $tarfile"
		rm $tarfile
	fi

	return 0	
}

# Main 

echo "Enter full path of the directory: "
echo "If decrypting, make sure to put the same PATH where the secret file was created"
read directory
cd $(dirname "${directory}")
secret_dir=$(basename "${directory}")

while true; do
	read -p "Do you want to Encrypt [type 'e'] or decryt $directory [type 'd']?: >> " choice
	case $choice in
		e|E)
			echo "IMPORTANT: READ carefully"
			echo 'This script will do the next:'
			echo -e '\t1- Create a tar.gz archive of your secret file/dir in the same PATH where it lives'
			echo -e '\t2- Encrypt with gpg the tar.gz archive in the same PATH using a symetric key'
			echo -e '\t3- Hides the gpg tar.gz archive in the same PATH'
			echo -e '\t4- DELETES the original file or directory leaving only the hidden gpg tar.gz archive !!!'
			echo -e "\t5- To retrieve the original file/dir use ./secrets and select the 'd' to decrypt"
			encrypt_checks $secret_dir; break;;
		d|D) 
			echo "IMPORTANT: READ carefully"
			echo 'This script will do the next:'
			echo -e "\t1- Decrypt the hidden gpg tar.gz archive created previously by 'secrets with 'e'"
			echo -e '\t2- Extract the hidden tart.gz file/dir'
			echo -e '\t3- Removes the hidden tar.gz if the extraction of the original file is correct'
			decrypt_checks $secret_dir; break;;
		*)
			echo "Please answer 'e' or 'd'";;
	esac
done
