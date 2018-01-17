#!/bin/bash

usage() { echo "Usage: $0 github-username" 1>&2; exit 1; }

if [ $# -lt "1" ]; then
    usage;
fi


#Assumptions
#Default user deploy whose SSH authorized_keys is to modify
#SSH authorized_keys is in the format ssh-rsa key 
home=${home:-deploy}
username=$1
name=`curl --silent https://api.github.com/users/kajisaap | grep "name" | awk -F: '{ print $2}' | cut -d "," -f1`

prompt() {
echo "You are adding $username - $name"
read -p "To avoid unintended pubkey additions, press ENTER/RETURN to continue: "
}

prompt;

#get public key from a github
KEY="https://github.com/$username.keys"
curl --silent $KEY -o /tmp/$username.pub

ssh_auth_file=`eval echo ~${home}/.ssh/authorized_keys`

##Append found keys to authorized_keys file
while read line
do
echo $line >> ${ssh_auth_file}
done <"/tmp/${username}.pub"

#Simulate idempotence/de-duplication
cat $ssh_auth_file | sort -u -k1,2 > ${ssh_auth_file}.uniq
mv ${ssh_auth_file}.uniq ${ssh_auth_file}



if [ $? -eq "0" ]; then
echo "SUCCESS : $name - $username added"; exit 0;
fi

echo "FAILED: $name - $username not added"; exit 1;
