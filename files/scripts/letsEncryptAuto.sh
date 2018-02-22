#!/bin/bash

SSLHome="/root/SSLCerts/"
SSLCert="privkey.pem"

letsEncryptSSLDirName="/etc/letsencrypt/live/PRIMARY_DOMAIN/"
letsEncryptCertFile="privkey.pem"

nginxDir="/etc/nginx/conf.d/"
nginxScriptsDir="/root/nginxScripts/"

nginxConf="default.conf"
nginxConfOld="default.old"

#Check for certificate present and run renew or replace accordingly
if [ -d ${letsEncryptSSLDirName} ]
then
  if [ -f ${letsEncryptSSLDirName}${letsEncryptCertFile} ]
  then
    echo "WARNING: Certificate file ${SSLHome}${SSLCert} already exists"
    echo "Running renew instead"
    echo " "
    ~/scripts/letsEncryptRenew.sh
  fi
else
  #Revert to default Nginx Config
  if [ ! -f ${nginxScriptsDir}${nginxConf} ]
  then
    echo "Reverting Nginx Configuration"

    #Move Nginx Config Files into backup dir
    mv ${nginxDir}*.conf ${nginxScriptsDir}

    #Restore Backup file
    mv ${nginxDir}${nginxConfOld} ${nginxDir}${nginxConf}

    echo "Re-loading Nginx Configuration"
    #Reload Nginfx with new settings
    nginx -s reload
  else
    echo  "Information: Nginx configuration was not reverted"
  fi


  #Download new Certificate
  certbot --nginx -n --agree-tos -d ALL_DOMAINS --email EMAIL
fi



#Check to see if certs were created and exit if not
if [ ! -d ${letsEncryptSSLDirName} ]
then
    echo  "ERROR: Certificate directory ${letsEncryptSSLDirName} was not successfully created"
    exit
else
  if [ ! -f ${letsEncryptSSLDirName}${letsEncryptCertFile} ]
  then
    echo  "ERROR: Certificate ${letsEncryptSSLDirName}${letsEncryptCertFile} was not successfully created"
    exit
  fi
fi

#Copy New Nginx Configuration
if [ -f ${nginxScriptsDir}${nginxConf} ]
then
  echo "Copying Nginx Configuration"

  #Backup conf file
  mv ${nginxDir}${nginxConf} ${nginxDir}${nginxConfOld}

  #Move New Config Files into place
  mv ${nginxScriptsDir}*.conf ${nginxDir}

  echo "Re-loading Nginx Configuration"
  #Reload Nginfx with new settings
  nginx -s reload
  exit
else
    echo  "Information: Nginx configuration was not copied"
    exit
fi

