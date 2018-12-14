FROM etates/centos7-systemd:latest
LABEL maintainer="Eliécer Tatés eliecer.tates@gmail.com"
#Install repo epel, repo remi for php 5.6 and other tools
RUN mkdir -p /var/lib/asterisk ; \
	adduser asterisk -m -c "Asterisk User" -d /var/lib/asterisk; \
	chown -R asterisk. /var/lib/asterisk ; \
	yum -y install --nogpgcheck epel-release yum-utils wget net-tools bind-utils ; \
	yum -y install --nogpgcheck http://rpms.remirepo.net/enterprise/remi-release-7.rpm ; \
\
#Install tucny repo for asterisk 13 and enable repos
	yum-config-manager --add-repo https://ast.tucny.com/repo/tucny-asterisk.repo ; \
	yum-config-manager --enable asterisk-common asterisk-13 remi-php56 ; \
	rpm --import https://ast.tucny.com/repo/RPM-GPG-KEY-dtucny ; \
\
#Install dependencies
	yum -y install --nogpgcheck tftp-server unixODBC mysql-connector-odbc mariadb-server mariadb \
	httpd sendmail sendmail-cf sox newt libxml2 libtiff \
	audiofile  subversion  git crontabs cronie \
	cronie-anacron wget nano uuid sqlite net-tools gnutls python \
	texinfo libuuid iptables-services fail2ban-server mpg123 lame-mp3x; \
\
#Install asterisk 13
	VERSION="13.23.1" ; \
	yum -y install --nogpgcheck asterisk-$VERSION asterisk-sip-$VERSION asterisk-iax2-$VERSION \
	asterisk-festival-$VERSION asterisk-voicemail-$VERSION asterisk-odbc-$VERSION \
	asterisk-mysql-$VERSION asterisk-moh-opsound-$VERSION asterisk-pjsip-$VERSION \
	asterisk-voicemail-plain-$VERSION asterisk-snmp-$VERSION asterisk-mp3-$VERSION \
	asterisk-sounds-core-es asterisk-sounds-core-en asterisk-moh-opsound ; \
\
#Install php 5.6 from remi	
	yum -y install --nogpgcheck php php-pdo php-mysql php-mbstring php-pear php-process \
	php-xml php-opcache php-ldap php-intl php-soap ; \
\
#Install node	
	curl -sL https://rpm.nodesource.com/setup_8.x | bash - && yum -y install --nogpgcheck nodejs
\
#Install Legacy Pear requirements for FreePBX
#RUN pear install Console_Getopt
\
#Create asterisk user and working directories
RUN	mkdir -p /var/lib/asterisk/{astconfig,modplus} ;  \
#link directory for external modules for asterisk
	ln -s /var/lib/asterisk/modplus /usr/lib64/asterisk/modules/modplus ; \
#/var files
	mv -f /usr/share/asterisk/* /var/lib/asterisk/ ; \
	rm -rf /usr/share/asterisk ; \
	ln -s /var/lib/asterisk /usr/share/asterisk ; \
#/etc files
	mv -f /etc/asterisk/* /var/lib/asterisk/astconfig/ ; \
	rm -rf /etc/asterisk ; \
	ln -s /var/lib/asterisk/astconfig /etc/asterisk ; \
	sed -i 's/\/usr\/share/\/var\/lib/' /etc/asterisk/asterisk.conf ; \
	sed -i 's/^;run/run/' /etc/asterisk/asterisk.conf ; \
#link to safe_asterisk and load confbridge
	ln -s /usr/sbin/asterisk /usr/sbin/safe_asterisk ; \
	chmod +x /usr/sbin/safe_asterisk ; \
\
#Fail2ban and iptables
	mkdir /var/fw-ips ; \
	mv /etc/sysconfig/iptables /var/fw-ips/iptables-rules ; \
	ln -s /var/fw-ips/iptables-rules /etc/sysconfig/iptables ; \
	mv /etc/fail2ban /var/fw-ips/ ; \
	ln -s /var/fw-ips/fail2ban /etc/fail2ban ; \
	systemctl enable iptables.service ; \
	systemctl enable fail2ban.service ; \
	printf "#!/bin/bash\niptables -F\niptables -A INPUT -i lo -j ACCEPT\niptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT\niptables -A INPUT -i eth0 -p icmp --icmp-type echo-request -j ACCEPT\niptables -A INPUT -i eth0 -p udp --dport 5060 -j ACCEPT\niptables -A INPUT -i eth0 -p udp --dport 4569 -j ACCEPT\niptables -A INPUT -i eth0 -p tcp --dport 5060 -j ACCEPT\niptables -A INPUT -i eth0 -p tcp --dport 5061 -j ACCEPT\niptables -A INPUT -i eth0 -p tcp --dport 80 -j ACCEPT\niptables -A INPUT -i eth0 -p udp --dport 10000:20000 -j ACCEPT\niptables -P INPUT DROP\niptables -P FORWARD DROP\niptables -P OUTPUT ACCEPT\niptables-save > /var/fw-ips/iptables-rules" > /var/fw-ips/iptables-run.sh ; \
	chmod +x /var/fw-ips/iptables-run.sh ; \
	echo "/var/fw-ips/iptables-run.sh" >> /etc/rc.d/rc.local ; \
	chmod +x /etc/rc.d/rc.local ; \
	cat /dev/null > /etc/fail2ban/jail.conf ; \
	printf "[INCLUDES]\n[Definition]\nfailregex = ^.* Authentication failure for .* from <HOST>\$\nignoreregex =" > /etc/fail2ban/filter.d/freepbx.conf ; \
	printf "[asterisk]\nbackend  = auto\nenabled  = true\nfilter   = asterisk\nbanaction = iptables-allports\nchain	  = INPUT\naction   = iptables-allports[name=asterisk, protocol=all]\nlogpath  = /var/log/asterisk/security\nmaxretry = 3\nbantime = 14400\nfindtime = 3600\nignoreip = 127.0.0.1/8\n\n[freepbx]\nbackend  = auto\nenabled  = true\nfilter   = freepbx\nbanaction = iptables-allports\nchain	  = INPUT\naction   = iptables-allports[name=freepbx, protocol=all]\nlogpath  = /var/log/asterisk/freepbx_security.log\nmaxretry = 3\nbantime = 14400\nfindtime = 3600\nignoreip = 127.0.0.1/8" > /etc/fail2ban/jail.d/pbx.conf ; \
\
#create log files for fail2ban
	touch /var/log/asterisk/security && touch /var/log/asterisk/freepbx_security.log ; \
	chown asterisk. /var/log/asterisk/* ; \
\
# #Set permissions
	# chown -R asterisk. /etc/asterisk ; \
	# chown -R asterisk. /var/{lib,log,spool,run}/asterisk ; \
	# chown -R asterisk. /usr/{lib64,share}/asterisk ; \
	# chown -R asterisk. /var/www/ ; \
\	
#tricks for apache
	sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php.ini && \
	sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/httpd/conf/httpd.conf && \
	sed -i 's/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf	; \
\	
#Enable services mariadb, asterisk and http
	systemctl enable mariadb.service && mysql_install_db ; \
	chown -R mysql. /var/lib/mysql ; \
	systemctl enable httpd.service && systemctl enable asterisk.service ; \
\	
#Install FreePBX
	rm -f /etc/freepbx.conf ; \
	rm -f /etc/amportal.conf ; \
	mysqld_safe --defaults-file=/etc/my.cnf --port=3306& \
	httpd -DBACKGROUND && \
	cd /usr/src && \
	wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-14.0-latest.tgz && \
	tar xfz freepbx-14.0-latest.tgz && \
	cd freepbx && \
	./start_asterisk start && \
	./install -n ; \
\	
#Set permissions
	mv /etc/freepbx.conf /var/lib/asterisk/ && ln -s /var/lib/asterisk/freepbx.conf /etc/freepbx.conf ; \
	mv /etc/amportal.conf /var/lib/asterisk/ && ln -s /var/lib/asterisk/amportal.conf /etc/amportal.conf ; \
	chown asterisk. /etc/{freepbx.conf,amportal.conf} ; \
	chmod +x /usr/sbin/safe_asterisk ; \
	chown -R asterisk. /etc/asterisk ; \
	chown -R asterisk. /var/{lib,log,spool,run}/asterisk ; \
	chown -R asterisk. /usr/{lib64,share}/asterisk ; \
	chown -R asterisk. /var/www/ ; \
	echo "load = app_confbridge.so" >> /etc/asterisk/modules.conf
\	
#Set /var as external volume
VOLUME [ "/var" ]
CMD ["/usr/sbin/init"]
