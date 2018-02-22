#Initialize Cron for weekly process
cron -f &

#Run Nginx
nginx -g "daemon off;" &
sleep 2

#Download SSL Cert
./root/scripts/letsEncryptCertOnly.sh

#Quit Nginx
nginx -s quit
sleep 2

#Restart Nginx
nginx -g "daemon off;"
