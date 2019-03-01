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
- 'q' to quit leaving the original $FILE unencrypted >>"
SECRETS_HOME="$HOME/.secrets"

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
    nosecrets="There are no gpg encrypted tar.gz in $SECRETS_HOME"
    if [[ ! $(find $SECRETS_HOME -type f -name '*.gpg') ]]; then
        echo "$nosecrets"
        exit 10
    fi

    counter=0
    for i in $(find $SECRETS_HOME -type f -name '*.gpg'); do
        counter=$((counter + 1))
        echo "$counter -) $(basename $i)"
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
            # FILE=$2
            # SFILE=$FILE.tar.gz.gpg
            # Test if encrypted tar.gz.pgp archive exists
            # if [[ -f $SFILE ]]; then
            #     gpg --output $FILE --decrypt $SFILE
            #     echo 'File decrypted'
            #     exit 0
            # else
            #     echo -e "\tERROR: $FILE does not exists, check path is ok"
            #     echo -e "\tThe secret should have been created by using"
            #     echo -e "\t secrets -e FILE"
            #     exit 2
            # fi
            ;;
            *)
            echo "$USAGE"
            exit 1
        esac
done
echo 'ERROR:Missing option and targe file'
echo "$USAGE"
exit 1
