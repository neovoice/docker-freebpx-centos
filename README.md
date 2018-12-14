# Freebpx
FreePBX 14 with asterisk 13 running on Centos 7 with systemd

This image links /etc/asterisk, /etc/freepbx.conf, /etc/amportal.conf to /var and works with an external volume to save persistent information.

The version of asterisk is 13 and is installed from tucny repositories (thank you tucny!): https://www.tucny.com/telephony/asterisk-rpms

Inside /var/lib/asterisk/modplus you can put g729 and g729 binary codecs from: http://asterisk.hosting.lv/

Systemd works good and enable services: iptables, fail2ban, asterisk, mariadbd and httpd.

How to run this image:

**docker push etates/freepbx

**docker run -d --name FreePBX --cap-add=NET_ADMIN --cap-add=NET_RAW -v /sys/fs/cgroup:/sys/fs/cgroup:ro --tmpfs /run -v freepbxvol:/var -v /etc/localtime:/etc/localtime:ro  etates/freepbx

