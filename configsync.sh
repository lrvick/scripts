#! /bin/bash
#configsync.sh v.000000something

#This is a script I wrote to ease the process of keeping configuration files in sync between several of my servers.
#It drops to a "sync" account and uses that and matching sudopcapable accounts on other servers to push and pull 
#things around so no direct root-root trust ever exists.

# syntax: ./sync_configs your_username

username=$1
sync_username='sync'
domain='example.com'
sync_servers='server1 server2 server3 server4'
dns_servers='server1 server3'
irc_servers='server4 server2'

global_sync_dir='/home/sync'
global_sync_conf_dir='/configs'
global_backup_conf_dir='/backups'

local_bind_conf='/chroot/dns/etc/bind'
sync_bind_conf='/bind'
target_bind_conf='/etc/bind'

local_apache_conf='/etc/apache2'
sync_apache_conf='/apache'
target_apache_conf='/etc/apache2'

local_unrealirc_conf='/etc/unrealircd/configs'
sync_unrealirc_conf='/unrealirc'
target_unrealirc_conf='/etc/unrealircd/configs'

local_anope_conf='/opt/anope'
sync_anope_conf='/anope'
target_anope_conf='/opt/anope'

#output=`if [ -z "$2" ] && [ "$2" != "debug" ]; then echo "> /dev/null 2>&1"; elif echo " " fi`


read -s -p "Please enter the sudo/ssh password for $username :" password  
echo " "
printf "%-70s" " * Copying all bind configs to local sync account ..."
rsync -rptDL ${local_bind_conf}/ ${global_sync_dir}${global_sync_conf_dir}${sync_bind_conf}/ ${output}
if [ $? -ne 0 ]; then printf "%10s\n" "[ !! ]"; else printf "%10s\n" "[ ok ]"; fi
printf "%-70s" " * Copying all apache configs to local sync account ..."
rsync -rptDL ${local_apache_conf}/ ${global_sync_dir}${global_sync_conf_dir}${sync_apache_conf}/ ${output}
if [ $? -ne 0 ]; then printf "%10s\n" "[ !! ]"; else printf "%10s\n" "[ ok ]"; fi
printf "%-70s" " * Copying all apache configs to local sync account ..."
rsync -rptDL ${local_unrealirc_conf}/ ${global_sync_dir}${global_sync_conf_dir}${sync_unrealirc_conf}/ ${output}
if [ $? -ne 0 ]; then printf "%10s\n" "[ !! ]"; else printf "%10s\n" "[ ok ]"; fi
printf "%-70s" " * Resetting permissions on all files in local sync account ..."
chmod 750 ${global_sync_dir} ${output}
chmod -R 700 ${global_sync_dir}/.ssh ${output}
chown -R ${sync_username}:${sync_username} ${global_sync_dir}
if [ $? -ne 0 ]; then printf "%10s\n" "[ !! ]"; else printf "%10s\n" "[ ok ]"; fi
for server in $sync_servers; do 
  printf "%-70s" " * Logging in to '$server' and sending your sudo password..."
  sudo -u ${username} ssh -C ${username}@${server}.${domain} 'echo '\"$password\"' | sudo -S true '$output'
  if [ $? -ne 0 ]; then printf "%10s\n" "[ !! ]"; exit ; else printf "%10s\n" "[ ok ]"; fi
  printf "%-70s" " * Resetting all permissions in sync account on '$server' ..."
  sudo chmod 750 '$global_sync_dir' '$output'
  sudo chmod -R 700 '$global_sync_dir'/.ssh
  sudo chown -R '$sync_username':'$sync_username' '$global_sync_dir' '$output'
  if [ $? -ne 0 ]; then printf "%10s\n" "[ !! ]"; else printf "%10s\n" "[ ok ]"; fi'
  printf "%-70s" " * Copying all configs to sync account on $server ..."
  sudo -u ${sync_username} rsync -rptDL ${global_sync_dir}${global_sync_conf_dir}/ ${sync_username}@${server}.${domain}:${global_sync_dir}${global_sync_conf_dir}/ ${output} 
  if [ $? -ne 0 ]; then printf "%10s\n" "[ !! ]"; else printf "%10s\n" "[ ok ]"; fi
done
for server in $dns_servers; do
  sudo -u $username ssh ${username}@${server}.${domain} ' 
    printf "%-70s" " * Checking for differances between sync account and root on '$server'"    
    sudo mkdir -p '$global_sync_dir''$global_sync_conf_dir''$sync_bind_conf'/
    sudo mkdir -p '$target_bind_conf'/
    diff=`sudo diff -r -y --suppress-common-lines '$global_sync_dir''$global_sync_conf_dir''$sync_bind_conf'/ '$target_bind_conf'/`
    diff=`echo $diff | sed "s#diff -r -y --suppress-common-lines##g"`
    if [ $? -ne 0 ]; then printf "%10s\n" "[ !! ]"; else printf "%10s\n" "[ ok ]"; fi
    if [ ! -z "${diff}" ]; then
      echo ""
      echo "Showing diff between sync account on '$server' and root on '$server' :"
      echo ""
      echo $diff | less
      echo ""
      echo -ne "Is everything sane to rsync over? [y/n] "    
      read answer
      if [ "$answer" != "y" ] && [ "$answer" != "n" ]; then   
        echo "TYPE YES OR NO ONLY!" 
      elif [ "$answer" == "y" ]; then 
        printf "%-70s" " * Copying bind configs to '$server' as '$username' ..." 
        sudo rsync -aL '$global_sync_dir''$global_sync_conf_dir''$sync_bind_conf'/ '$target_bind_conf'/ '$output' 
        if [ $? -ne 0 ]; then printf "%10s\n" "[ !! ]"; else printf "%10s\n" "[ ok ]"; fi 
        printf "%-70s" " * Restarting bind on '$server' as '$username' ..."
        sudo /etc/init.d/named stop zap '$output' 
        sudo killall named '$output'
        sudo /etc/init.d/named start '$output'     
        if [ $? -ne 0 ]; then printf "%10s\n" "[ !! ]"; else printf "%10s\n" "[ ok ]"; fi
      else  
        echo "Ok, then. Go fix things by hand and come back later :-)"
        exit
      fi
   fi'
done
for server in $irc_servers; do
  sudo -u $username ssh ${username}@${server}.${domain} '
    printf "%-70s" " * Checking for differances between sync account and root on '$server'"
    sudo mkdir -p '$global_sync_dir''$global_sync_conf_dir''$sync_unrealirc_conf'/
    sudo mkdir -p '$target_unrealirc_conf'/
    diff=`sudo diff -r -y --suppress-common-lines '$global_sync_dir''$global_sync_conf_dir''$sync_unrealirc_conf'/ '$target_unrealirc_conf'/`
    diff=`echo $diff | sed "s#diff -r -y --suppress-common-lines##g"`
    if [ $? -ne 0 ]; then printf "%10s\n" "[ !! ]"; else printf "%10s\n" "[ ok ]"; fi
    if [ ! -z "${diff}" ]; then
      echo ""
      echo "Showing diff between sync account on '$server' and root on '$server' :"
      echo ""
      echo $diff | less
      echo ""
      echo -ne "Is everything sane to rsync over? [y/n] "
      read answer
      if [ "$answer" != "y" ] && [ "$answer" != "n" ]; then
        echo "TYPE YES OR NO ONLY!"
      elif [ "$answer" == "y" ]; then
        printf "%-70s" " * Copying unrealircd configs to '$server' as '$username' ..."
	sudo rsync -aL '$global_sync_dir''$global_sync_conf_dir''$sync_unrealirc_conf'/ '$target_unrealirc_conf'/ '$output'
	if [ $? -ne 0 ]; then printf "%10s\n" "[ !! ]"; else printf "%10s\n" "[ ok ]"; fi
        printf "%-70s" " * Reloading unrealircd on '$server' as '$username' ..."
        sudo /etc/init.d/unrealircd reload '$output'
        if [ $? -ne 0 ]; then printf "%10s\n" "[ !! ]"; else printf "%10s\n" "[ ok ]"; fi
      else
        echo "Ok, then. Go fix things by hand and come back later :-)"
        exit
      fi
   fi'
done



