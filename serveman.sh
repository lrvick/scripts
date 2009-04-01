#! /bin/sh
#
# -- ServeMan --
#
# Generic Server Mangement Script by lrvick
#
# I no longer use this on any of my servers but I decided to provide it for reference.
# Also I am fully aware this is some straight up ghetto code in parts, I wrote it years ago before I had near the bash knowledge I do today. Be nice.

ARG1=$1
ARG2=$2
ARG3=$3
ARG4=$4


SERVER1="two.example.com"
SERVER2="one.example.com"
SERVER1_IP="1.2.3.4"
SERVER2_IP="5.6.7.8"
NAMED1="ns1.example.com"
NAMED2="ns2.example.com"
ROOTMYSQLPASS="password"


usage() {
cat << "USAGE_END"

ServeMan Server Administration Script.
-----------------------------------------

To create a new user use:

 #serveman.sh --newuser somewebsite.com some@externalemail.com SomePassword 

To suspend a user use:
 
 #serveman.sh --suspend someuser

To just jail a user use:
 
 #serveman.sh --jail someuser

or to re-jail all users:
 
 #serveman.sh --jail all

To give an existing system user specific resources use:

 #serveman.sh --giveperl someuser
 
 #serveman.sh --givephp  someuser

 #serveman.sh --giveroot someuser

To re-set secure permissions for all users:

 #serveman.sh --doperms
   
To re-mount all needed dirs for all users:
(Used On boot-up)

 #serveman.sh --domounts 

To repair a users passwd use

 #serveman.sh --dopasswds someuser

or to repair passwds for all users:
 
 #serveman.sh --dopasswds all

To check for necissary security updates:

 #serveman.sh --secup

--help : This help Message.


USAGE_END
        exit 1
}


checkargs() {
   if [ -z "$USERNAME" ] && [ -n ${ARG2} ]; then
       USERNAME=${ARG2}
   fi
  # if [ "$USERNAME" == "all" ]; then
  #     USERNAME=`ls -dF1 /home/*/ | sed 's#//##g' | sed 's#/home/_backups##g' | sed 's#/home/_jails##g' | sed 's/lost+foun$
  # fi
   if [ "$USERNAME" == "all" ]; then
       USERNAME=`ls -d -1 /home/*/public_html | sed 's#/home/##g' | sed 's#/public_html##g'`
   fi
}


dopasswds() {
   checkargs
   for USERNAME in ${USERNAME}
     do
        PASSWDLINE="`grep $USERNAME: /etc/passwd`"
        grep -s -q $USERNAME /home/_jails/$USERNAME/etc/passwd
        if [ ! $? -eq 0 ]; then
            echo "${PASSWDLINE}" >> /home/_jails/$USERNAME/etc/passwd
            sort -u /home/_jails/$USERNAME/etc/passwd > temp
          if [ $? -eq 0 ]; then
             mv temp /home/_jails/$USERNAME/etc/passwd
          else
            echo "Error creating temp file"
            exit -1
          fi;
            sed -i '/^$/d' /home/_jails/$USERNAME/etc/passwd
        fi
      chown $USERNAME: /home/_jails/$USERNAME/etc/passwd
      chmod 755 /home/_jails/$USERNAME/etc/passwd
     done
   exit 1
}


jail() {
   #mv /etc/security/chroot.conf /etc/security/chroot.conf.last
   #touch /etc/security/chroot.conf
   
   checkargs  
   for USERNAME in ${USERNAME}
     do
        mkdir -p /home/_jails/$USERNAME/home/$USERNAME
        jk_init /home/_jails/$USERNAME/ udderweb
        mount --bind /home/$USERNAME /home/_jails/${USERNAME}/home/$USERNAME
        echo "$USERNAME /home/_jails/$USERNAME/" >> /etc/security/chroot.conf
        mkdir -p /home/_jails/$USERNAME/etc/mysql/
        rm /home/_jails/$USERNAME/etc/mysql/my.cnf
        echo -e '[mysql]\nhost = 127.0.0.1' >> /home/_jails/$USERNAME/etc/mysql/my.cnf
        #mount --bind /tmp /home/_jails/$USERNAME/tmp
        mkdir -p /home/_jails/$USERNAME/tmp
        mount --bind /tmp /home/_jails/$USERNAME/tmp
        mkdir -p /home/_jails/$USERNAME/home/$USERNAME/_cron/cron.{hourly,daily,weekly,monthly}
        chown -R $USERNAME /home/_jails/$USERNAME/home/$USERNAME/_cron  
        grep -s -q $USERNAME /etc/crontab
        if [ ! $? -eq 0 ]; then
           if [ -z "$MIN" ] || [ "$MIN" == "61" ]; then MIN="1"; fi
           if [ -z "$HOUR" ] || [ "$HOUR" == "25" ]; then HOUR="1"; fi
           if [ -z "$DAYOFWEEK" ] || [ "$DAYOFWEEK" == "8" ]; then DAYOFWEEK="1"; fi
           if [ -z "$DAYOFMONTH" ] || [ "$DAYOFMONTH" == "32" ]; then DAYOFMONTH="1"; fi   
           echo "$MIN  *    *    *   *     $USERNAME sh /home/_jails/$USERNAME/etc/cron.hourly/*" >> /etc/crontab
           echo "$MIN  $HOUR   *    *   *     $USERNAME sh /home/_jails/$USERNAME/etc/cron.daily/*" >> /etc/crontab
           echo "$MIN  $HOUR   *    *   $DAYOFWEEK     $USERNAME sh /home/_jails/$USERNAME/etc/cron.weekly/*" >> /etc/crontab
           echo "$MIN  $HOUR   $DAYOFMONTH    *   *     $USERNAME sh /home/_jails/$USERNAME/etc/cron.monthly/*" >> /etc/crontab
           MIN=`expr $MIN + 1`
           HOUR=`expr $HOUR + 1`
           DAYOFWEEK=`expr $DAYOFWEEK + 1`
           DAYOFMONTH=`expr $DAYOFMONTH + 1`
        fi
     done
}

domounts () {  
   checkargs
   for USERNAME in ${USERNAME}
      do
        mkdir -p /chroot/apache/var/www/$USERNAME
        mkdir -p /var/www/$USERNAME
        mkdir -p /home/_jails/$USERNAME/home/$USERNAME
        mkdir -p /home/_jails/$USERNAME/proc
        mkdir -p /home/_jails/$USERNAME/dev/pts
        mkdir -p /home/_jails/$USERNAME/tmp
        mount --bind /home/$USERNAME/public_html /var/www/$USERNAME
        mount --bind /home/$USERNAME/public_html /chroot/apache/var/www/$USERNAME 
        mount --bind /home/$USERNAME /home/_jails/$USERNAME/home/$USERNAME
        mount --bind /proc /home/_jails/$USERNAME/proc
        mount --bind /tmp /home/_jails/$USERNAME/tmp
        mount -t devpts devpts /home/_jails/$USERNAME/dev/pts
        mount --bind /home/adullam/_bots/UnaBiblia/adullamlogs/ /var/www/adullam/logs/
        mount --bind /home/adullam/_bots/UnaBiblia/idlerpglogs/ /var/www/adullam/logs/idlerpg/
	mount --bind /usr/share/sword /home/_jails/adullam/usr/share/sword
     done
   mount --bind /tmp /chroot/apache/tmp
}

doperms () {
   checkargs
   for USERNAME in ${USERNAME}
     do
        chown -R $USERNAME:apache /home/$USERNAME/public_html
        find /home/$USERNAME/public_html -type f -print0 | xargs -0 chmod 644
        find /home/$USERNAME/public_html -type d -print0 | xargs -0 chmod 751
     done
}

giveroot() {
    checkargs 
    if [ "$USERNAME" == "all" ]; then
    echo "Are you INSANE?! BAD BAD!" ; exit  
    fi
    jk_init -v /home/_jails/${USERNAME}/ ssh-keygen
    cp /usr/bin/uwsu /home/_jails/${USERNAME}/usr/bin/su
    if [ ! -e /home/${USERNAME}/.ssh/id_rsa ]; then
      sudo -u ${USERNAME} ssh-keygen -N "" -P "" -f /home/${ARG2}/.ssh/id_rsa
    fi
    if [ ! -e /home/${USERNAME}/.bash_profile ]; then
      echo "clear" >> /home/${USERNAME}/.bash_profile
    fi
    cat /home/${USERNAME}/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
}

givephp () {
    checkargs
    if [ "$USERNAME" == "all" ]; then
    echo "Hello, hard drive space... conserve..." ; exit 1
    fi
    jk_init -v /home/_jails/${USERNAME}/ php
}

giveperl () {
    checkargs
    if [ "$USERNAME" == "all" ]; then
    echo "Hello, hard drive space... conserve..." ; exit 1
    fi
    jk_init -v /home/_jails/${ARG2}/ perl
}

sync_bind() { 
   for USERNAME in ${USERNAME}
     do   
       HOSTSFILES=`grep -Rl ";owner $USERNAME" /etc/bind/hosts`
       if [[ -n ${HOSTSFILES} ]]; then
        for HOSTSFILE in ${HOSTSFILES}
          do   
            OLDSERIAL=`sed -n '4p' $HOSTSFILE`
            NEWSERIAL=`date +%Y%m%d%H%M%S`
            sed -i "s/${OLDSERIAL}/                        ${NEWSERIAL}/g" $HOSTSFILE                
            rsync -avt --rsh="ssh -p 28" $HOSTSFILE root@eve.udderweb.com:$HOSTSFILE
            NEWSERIAL=`sed -n '4p' $HOSTSFILE`
            echo $HOSTSFILE has been synced with new serial ${NEWSERIAL}
          done
       else
          echo User ${USERNAME} does not have any bind domains to sync.
       fi
     done
   rsync -avt --rsh="ssh -p 28" /etc/bind/named.conf root@eve.udderweb.com:/etc/bind/named.conf
   /etc/init.d/named reload
   ssh -p 28 eve.udderweb.com /etc/init.d/named reload
}

sync_apache() {
   for USERNAME in ${USERNAME}
     do
       HOSTSFILE="/etc/apache2/vhosts.d/$USERNAME.conf"
       echo ${HOSTSFILE}
       if [[ -n ${HOSTSFILE} ]]; then
             rsync -avt --rsh="ssh -p 28" ${HOSTSFILE} root@eve.udderweb.com:${HOSTSFILE}
        else
             echo User ${USERNAME} does not have an apache2 conf file to sync.
       fi
     done 
    rsync -avt --rsh="ssh -p 28" /etc/apache2/httpd.conf root@eve.udderweb.com:/etc/apache2/httpd.conf
}
    
sync_homedir() {
   for USERNAME in ${USERNAME}
     do
       HOMEDIR=/home/$USERNAME
       if [[ -e ${HOMEDIR} ]]; then
             ssh -p 28 eve.udderweb.com mkdir -p ${HOMEDIR}
             rsync -avt --rsh="ssh -p 28" ${HOMEDIR} root@eve.udderweb.com:${HOMEDIR}
        else
             echo User ${USERNAME} does not have a home directory to sync.
       fi
     done
}

sync_jail() {
   for USERNAME in ${USERNAME}
     do
       JAIL=`/home/_jails/$USERNAME`
       if [[ -n ${JAIL} ]]; then
             ssh -p 28 eve.udderweb.com mkdir -p ${JAILDIR}
             rsync -avt --rsh="ssh -p 28" ${JAILDIR} root@eve.udderweb.com:${JAILDIR}
        else
             echo User ${USERNAME} does not have a chroot jail to sync.                  
       fi
     done
}

sync_mysql() {
   for USERNAME in ${USERNAME}
     do
          echo Make sellout finish sync_mysql. - username=$USERNAME
     done
}

sync_postfix() {
   for USERNAME in ${USERNAME}
     do
          echo Make sellout finish sync_postfix. - username=$USERNAME
     done
}

sync_bnc() {
       rsync -avt --rsh="ssh -p 28" /etc/psybnc/psybnc.conf root@eve.udderweb.com:/etc/psybnc/psybnc.conf
       rsync -avt --rsh="ssh -p 28" /etc/conf.d/psybnc root@eve.udderweb.com:/etc/conf.d/
       # /etc/init.d/psybnc restart
       ssh -p 28 eve.udderweb.com /etc/init.d/psybnc restart                  
}

sync() {
   checkargs
   if [[ ${ARG3} == "everything" ]];then sync_bind; sync_apache; sync_homedir; sync_jail; sync_mysql; fi
   if [[ ${ARG2} == "bnc" ]];then sync_bnc; fi
   if [[ ${ARG3} == "bind" ]];then sync_bind; fi
   if [[ ${ARG3} == "apache" ]];then sync_apache; fi
   if [[ ${ARG3} == "homedir" ]];then sync_homedir; fi
   if [[ ${ARG3} == "jail" ]];then sync_jail; fi
   if [[ ${ARG3} == "mysql" ]];then sync_mysql; fi
   if [[ ${ARG3} == "postfix" ]];then sync_postfix; fi
 }


backup() {
   PASSPHRASE="ub0jocowwak3quorpt)ottasco{arayuke6cyjugpun}kudtnow#rarifj\`gelfjpf!imfot"
   backup_conf() {
      locate *.conf *.hosts *.zones | zip /root/.backup/zip/conf.zip -@ > /dev/null
      find /etc/unrealircd -print | zip /root/.backup/zip/unreal.zip -@  > /dev/null
      find /opt/anope -print | zip /root/.backup/zip/anope.zip -@  > /dev/null
      export PASSPHRASE="ub0jocowwak3quorpt)ottasco{arayuke6cyjugpun}kudtnow#rarifj\`gelfjpf!imfot"
      duplicity --encrypt-key 667D6DC5 --sign-key 667D6DC5 --scp-command 'scp -i /root/.backup/id_rsa' \
      /root/.backup/zip scp://shar0213video@colbert.dreamhost.com/backupzip
      rm /root/.backup/zip/*.zip
      }
   backup_homes() {
     duplicity --exclude /home/fluxbox --exclude /home/bryan --exclude /home/_jails --exclude /home/_backups \
     --encrypt-key 667D6DC5 --sign-key 667D6DC5 --scp-command 'scp -i /root/.backup/id_rsa' \
     /home scp://shar0213video@colbert.dreamhost.com/backup
     }
  if [[ ${ARG2} == "everything" ]];then backup_conf; backup_homes; fi
  if [[ ${ARG2} == "conf" ]];then backup_conf;  fi
  if [[ ${ARG2} == "homes" ]];then backup_homes; fi
}


#-----TESTME just updates, fuzzy and tired

create_bind() {
  SERIAL=`date +%Y%m%d%H%M%S`
  cat > /etc/bind/hosts/${DOMAIN}.hosts << BIND_CONFIG_END
\$ttl 38400
$ttl 38400
;owner ${USERNAME}
@       IN      SOA     ns1.udderweb.com. root.ns1.udderweb.com. (
                        20070811203526
                        10800
                        3600
                        604800
                        38400 )
        IN      NS      ns1.udderweb.com.
        IN      NS      ns2.udderweb.com.
@                       IN      A       12.47.45.189
@                       IN      A       12.158.188.112
*                       IN      A       12.47.45.189
*                       IN      A       12.158.188.112

mail.${USERNAME}.udderweb.com.    IN      CNAME   ghs.google.com.

@   IN      MX      1 ASPMX.L.GOOGLE.COM.
@   IN      MX      5 ALT1.ASPMX.L.GOOGLE.COM.
@   IN      MX      5 ALT2.ASPMX.L.GOOGLE.COM.
@   IN      MX      10 ASPMX2.GOOGLEMAIL.COM.
@   IN      MX      10 ASPMX3.GOOGLEMAIL.COM.
@   IN      MX      10 ASPMX4.GOOGLEMAIL.COM.
@   IN      MX      10 ASPMX5.GOOGLEMAIL.COM.
BIND_CONFIG_END

#This has been breaking bind all along i have just been too lazy to write it
cat >> /etc/bind/named.conf << NAMED_CONFIG_END
zone "${USERNAME}.udderweb.com" {
        type master;
        file "/etc/bind/hosts/${USERNAME}.udderweb.com.hosts";
        };
NAMED_CONFIG_END


}

create_apache() {
  cat > /etc/apache2/vhosts.d/${USERNAME}.conf << APACHE_CONFIG_END
<VirtualHost *:8080>
  ServerName ${DOMAIN}
  ServerAlias www.${DOMAIN}
  DocumentRoot /var/www/${USERNAME}/
  <Directory /var/www/${USERNAME}/ >
    Options MultiViews IncludesNOEXEC FollowSymLinks
    allow from all
    AllowOverride All
  </Directory>
</VirtualHost>
APACHE_CONFIG_END
}

create_postfix() {
   cat >> /etc/postfix/virtual << POSTFIX_CONFIG_END
${USERNAME}@${DOMAIN}  ${USERNAME}@adam.udderweb.com
hostmaster@${DOMAIN}   ${USERNAME}@adam.udderweb.com
abuse@${DOMAIN}        ${USERNAME}@adam.udderweb.com
webmaster@${DOMAIN}    ${USERNAME}@adam.udderweb.com
postmaster@${DOMAIN}   ${USERNAME}@adam.udderweb.com
POSTFIX_CONFIG_END

}

create_mysql() {
	echo "type this into the password prompt below: ${ROOTMYSQLPASS}";
   echo "GRANT SELECT, INSERT, UPDATE, DELETE, INDEX, ALTER, CREATE, LOCK TABLES, \
   CREATE TEMPORARY TABLES, DROP, REFERENCES ON ${USERNAME}.* \
   TO ${USERNAME}@localhost IDENTIFIED BY '${PASSWORD}'; FLUSH PRIVILEGES;" \
   | mysql -u root -p ${USERNAME}
}

newuser() {
   DOMAIN=${ARG2}
   echo "DEBUG:::: $DOMAIN"
   USERNAME=$(echo ${DOMAIN} | sed -e 's/^\([-_a-zA-Z0-9]*\)\..*$/\1/')
   echo "DEBUG:::: $USERNAME"
   PASSWORD=${ARG3}
   echo "DEBUG:::: $PASSWORD"
   #good work Viaken, took me a couple trys to see it ^_^ 
   if [[ ${USERNAME} == "" ]] ; then echo "The domain name regexp stumbled." ; exit ; fi
   echo "Creating user ${USERNAME}. Is that right? (y,N)"
   read ANSWER
   if [[ ${ANSWER} == "y" || ${ANSWER} == "Y" ]] ; then
      useradd -m -d /home/${USERNAME} -c ${DOMAIN} -p ${PASSWORD} ${USERNAME}
      create_bind
      create_apache
      create_mysql
      jail
      domounts
      doperms
      sync_bind
      sync_apache
      sync_mysql
      sync_postfix
      sync_jail
      sync_homedir
    else
      echo "Cancelling." ; exit
   fi
}

suspend_user() {
echo "working on it"
}

lbon(){
/etc/init.d/squid stop
/etc/init.d/apache2 murder
sed -i 's/*:80>/*:8080>/g' /etc/apache2/vhosts.d/*
sed -i 's/80 #auto/8080 #auto/g' /etc/httpd.conf 
sed -i 's#;*                       IN      A       12.158.188.112#*                       IN      A       12.158.188.112#g' /etc/bind/hosts/*
sed -i 's#;@                       IN      A       12.158.188.112#@                       IN      A       12.158.188.112#g' /etc/bind/hosts/*
sync_bind
/etc/init.d/apache2 failsafe 
/etc/init.d/squid start
}

lboff(){
/etc/init.d/squid stop
/etc/init.d/apache2 murder
sed -i 's/*:8080>/*:80>/g' /etc/apache2/vhosts.d/*
sed -i 's/8080 #auto/80 #auto/g' /etc/httpd.conf
sed -i 's#*                       IN      A       12.158.188.112#;*                       IN      A       12.158.188.112#g' /etc/bind/hosts/*
sed -i 's#@                       IN      A       12.158.188.112#;@                       IN      A       12.158.188.112#g' /etc/bind/hosts/*
sync_bind
/etc/init.d/apache2 failsafe 
}


do_sync_bind() {
	USERNAME=${ARG2}
	sync_bind
}

secup(){
#Have glsa-check dump the details of the affected GLSAs, pull out the package and version, remove cruft, prettify
glsa-check -d affected | grep -E "Affected package|Unaffected" | sed -e 'N; s/Affected package:\s*\(.*\)Unaffected:\s*\(.*\)/\1 \2/; s/\n//' | sort | column -t | uniq ;
}

error1(){ echo "Please supply a Domain Name, and Password";}
error2(){ echo "Please supply a Username or specify 'all' for all users";} 
error3(){ echo "Please supply a Username";}
error4(){ echo "Please supply a Username and what you would like to sync.";}
error5(){ echo "Please specify what you would like to back-up";}
if [[ ${ARG1} == "--help"      ]]       || [[ -z ${ARG1} ]]; then usage; fi
if [[ ${ARG1} == "--newuser"   ]]; then if [[ -n ${ARG4} ]]; then newuser;   else error1; fi fi
if [[ ${ARG1} == "--jail"      ]]; then if [[ -n ${ARG2} ]]; then jail;      else error2; fi fi
if [[ ${ARG1} == "--giveroot"  ]]; then if [[ -n ${ARG2} ]]; then giveroot;  else error3; fi fi
if [[ ${ARG1} == "--giveperl"  ]]; then if [[ -n ${ARG2} ]]; then giveperl;  else error3; fi fi
if [[ ${ARG1} == "--givephp"   ]]; then if [[ -n ${ARG2} ]]; then givephp;   else error3; fi fi
if [[ ${ARG1} == "--domounts"  ]]; then if [[ -n ${ARG2} ]]; then domounts;  else error2; fi fi
if [[ ${ARG1} == "--doperms"   ]]; then if [[ -n ${ARG2} ]]; then doperms;   else error3; fi fi
if [[ ${ARG1} == "--dopasswds" ]]; then if [[ -n ${ARG2} ]]; then dopasswds; else error3; fi fi
if [[ ${ARG1} == "--sync"      ]]; then if [[ -n ${ARG2} ]]; then sync;      else error4; fi fi
if [[ ${ARG1} == "--backup"    ]]; then if [[ -n ${ARG2} ]]; then backup;    else error5; fi fi
if [[ ${ARG1} == "--lbon"      ]];                           then lbon;                      fi
if [[ ${ARG1} == "--lboff"     ]];                           then lboff;                     fi
if [[ ${ARG1} == "--secup"     ]];                           then secup;                     fi 

if [[ ${ARG1} == "==sync_bind" ]]; then if [[ -n ${ARG2} ]]; then do_sync_bind; else error3; fi fi
