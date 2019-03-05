#!/usr/bin/env bash
# A command to encrypt and decrypt files and directories

# Global vars
TAG_VERSION='v0.1'
PROJECT_GIT='https://github.com/theraulpareja/secrets.git'
USAGE="
Secrets $TAG_VERSION ( $PROJECT_GIT )
Usage: secrets [Options] {target file}

Where Options are:
    -e to encrypt 
    -d to decrypt

And target file must be relative to your current path or provide the full path 
"
CONFIRM="
Please confirm, by typing wether:
- 'd' to delete the original $FILE (recomended)
- 'q' to quit leaving the original $FILE unencrypted
>> "
SECRETS_HOME="$HOME/.secrets"
NOSECRETS="There are no gpg encrypted tar.gz in $SECRETS_HOME"
SELECT_MESSAGE="
Select a number from the list above

>> "
ENSURE="
Please confirm you want to decrypt the tar.gz, by typing wether:
- 'y' to retrieve the encrypted tar.gz archive
- 'q' to quit

 >> "

# Functions
confirmation () {
    while true; do
		read -p "$CONFIRM" choice
			case $choice in
			'd')
				rm -rf $FILE
				echo "$FILE.tar.gz.gpg saved in $SECRETS_HOME, and original deleted" 
                exit 0
                ;; 
			'q') 
				echo "$FILE.tar.gz.gpg saved in $SECRETS_HOME, but original left where it  \
                was"
                exit 0
                ;;
			*)
                echo "$CONFIRM"
                ;;
			esac
	done
}

showsecrets () {
    if [[ ! $(find $SECRETS_HOME -type f -name '*.gpg') ]]; then
        echo "$NOSECRETS"
        exit 10
    fi
    counter=0
    options=()
    echo -e "\nAvailable secrets\n"
    for i in $(find $SECRETS_HOME -type f -name '*.gpg'); do
        echo "$counter -) $(basename $i)" 
        options+=($(basename $i))
        counter=$((counter + 1))
    done
    # echo "options value are ${options[*]}"
    while true; do
        read -p "$SELECT_MESSAGE" choice
            if [[ $choice -ge 0 && $choice -le $counter ]]; then
                secret_file=${options[$choice]}
                # echo "You selected ${options[$choice]}"
                echo -e "\nqYou selected $secret_file"
                while true; do
                    read -p "$ENSURE" confirmation_choice
                    case $confirmation_choice in
                    'y')
                        echo "Decrypting"
                        gpg --output $SECRETS_HOME/"${secret_file%.*}" \
                        --decrypt $SECRETS_HOME/$secret_file
                        echo "File decrypted"
                        echo "Extracting tar.gz archive"
                        echo "have to fix the uncompressing path"
                        tar xzvf $SECRETS_HOME/"${secret_file%.*}"
                        exit 0
                        ;;
                    'q')
                        echo -e "\nCancelling operations, bye"
                        exit 0
                        ;;
                    *)
                        echo "$ENSURE"
                        ;;
                    esac
                done
            else
                echo "Invalid choice please: "$SELECT_MESSAGE""
            fi
    done
exit 0
}

# Main
if [[ ! -d "$SECRETS_HOME" ]]; then
    echo "Creating $SECRETS_HOME"
    mkdir -p $SECRETS_HOME
fi

while [[ $# -gt 0 ]]; do
    option=$1 
        case $option in
            -e)
            FILE=$2
            if [[ -z $FILE ]]; then
                echo -e "ERROR: Missing target file argument"
                echo "$USAGE"
                exit 1
            fi
            # Test if file or directory exists
            if [ -f $FILE ] || [ -d $FILE ]; then
                tar czvf $FILE.tar.gz $FILE
                echo 'tar.gz archive created'
                gpg -c $FILE.tar.gz
                echo 'tar.gz archive encrypted'
                rm $FILE.tar.gz
                echo 'Deleted unencrypted tar.gz archive'
                mv $FILE.tar.gz.gpg $SECRETS_HOME/
                echo "Encrypted tar.gz archive moved to $SECRETS_HOME"
                confirmation
           
            else
                echo "ERROR: $FILE is not a regular nor directory file,"
                echo "Does $FILE actually exists? please check path is ok"
                echo "$USAGE"
                exit 1
            fi
            ;;
            -d)
                showsecrets
                ;;
            *)
                echo "$USAGE"
                exit 1
        esac
done
echo 'ERROR:Missing option and targe file'
echo "$USAGE"
exit 1
