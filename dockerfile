from nginx:1.13.5
	#Set user context
	USER root
	
	#Add environment variables
	ARG primary_domain
	ARG secondary_domains
	ARG email

	#Run PreRequisites
	RUN apt-get update
	RUN apt-get install -y software-properties-common
	RUN apt-get install -y nano

	#Add Cert bot PPA and install
	RUN add-apt-repository ppa:certbot/certbot
	RUN apt-get update
	RUN apt-get install --allow-unauthenticated -y python-certbot-nginx 
	
	#Copy Lets Encrypt config and update with e-mail parameter
	COPY ./files/letsEncryptConfig/cli.ini /etc/letsencrypt/
	RUN sed -i "s/foo@example.com/$email/g" /etc/letsencrypt/cli.ini
	
	#Copy and Update Nginx Config with provided domain parameters
	COPY ./files/nginxConfig/*.conf /etc/nginx/conf.d/	

	#Temporary location for Nginx scripts
	RUN mkdir -p "/root/nginxScripts"
	COPY ./files/nginxScripts/*.conf /root/nginxScripts/
	
	#This is an intermediary file needed for Cert Renewal
	RUN sed -i "s/localhost;/${primary_domain} ${secondary_domains};/g" /etc/nginx/conf.d/default.conf

	#This is final nginx files. Secondary domains are broken out into other files
	RUN sed -i "s/localhost;/${primary_domain};/g" /root/nginxScripts/default.conf
	
	#Copy Scripts
	RUN mkdir -p /root/scripts
        COPY ./files/scripts/*.sh /root/scripts/

	#Create Domain Name Parameter for Certbot
	RUN echo ${primary_domain},${secondary_domains}>/root/tmpDomains
        RUN sed -i "s/ /,/g" /root/tmpDomains

	#Add All names. Cerbot needs them to be tab separated
        RUN cat /root/tmpDomains | xargs -i sed -i "s/ALL_DOMAINS/{}/g" /root/scripts/letsEncryptCertOnly.sh
        RUN cat /root/tmpDomains | xargs -i sed -i "s/ALL_DOMAINS/{}/g" /root/scripts/letsEncryptAuto.sh
	
	#Add primary domain name
        RUN sed -i "s/PRIMARY_DOMAIN/${primary_domain}/g" /root/scripts/letsEncryptCertOnly.sh
        RUN sed -i "s/PRIMARY_DOMAIN/${primary_domain}/g" /root/scripts/letsEncryptAuto.sh

	#Add e-mail Address
	RUN sed -i "s/EMAIL/${email}/g" /root/scripts/letsEncryptCertOnly.sh
        RUN sed -i "s/EMAIL/${email}/g" /root/scripts/letsEncryptAuto.sh

	#Create link to Cron job for updating scripts
	RUN ln -s /root/scripts/letsEncryptRenew.sh  /etc/cron.weekly/letsEncryptRenew.sh
	
	RUN chmod +x /root/scripts/*.sh

	#Run Nginx and Download Cert
        #ENTRYPOINT ["nginx", "-g", "daemon off;"]
	CMD /root/scripts/init.sh
