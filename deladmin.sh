#!/bin/bash
#usage ./deladmin.sh existingadmin admintodelete

sync_servers="server1 server2 server3 server4"

read -s -p "Please enter the sudo/ssh password for $username :" password

for server in $sync_servers; do 
  sudo -S -u $1 ssh $1@$server.example.com '
  echo "Are you SURE you want to delete the user '$2' and the entire /home/'$2' folder? [y/n]"
  read answer
  if [ "$answer" == "y" ]; then 
  echo '$password' | sudo userdel -rf '$2'
  fi'
done
userdel -rf $2
