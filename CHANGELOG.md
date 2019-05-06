# Change Log


### RELEASE-21.0.7
  * fixed mwscan magenx.sh#L1332
  * minor code cleanup

### RELEASE-21.0.6
  
  * magento redis cache/session fix
  * minor code cleanup

### RELEASE-21.0.5
  
  * fixed wazuh/ossec configuration
  * php 7.2
  * minor code cleanup

### RELEASE-21.0.3
  
  * mysqlrouter - remote mysql connection routing

### RELEASE-21.0.2
  
  * replaced certbot/letsencrypt packages, using certbot-auto configuration script.
  * at [history commit diff](https://github.com/magenx/Magento-Automated-Server-Configuration-from-MagenX/commit/775397467b193242ca9846d8d8f337119703ded9#diff-3338fed2bb010f9dfb389aae8c5d556c)

### RELEASE-21.0.1
  
  * fixed request format in /usr/local/bin/zend_opcache.sh
  * at [#L1468](https://github.com/magenx/Magento-Automated-Server-Configuration-from-MagenX/blob/master/Magento-2/CentOS-7/MASC-M-7-v2.sh#L1468)

### RELEASE-21.0.0
  
  * magento 2 only
  * hhvm removed
  * percona database version 5.7
  * php version 7.1.x
  * varnish version 5.2
  * wazuh (ossec) + ELK stack upgraded
  * minor code cleanup

### RELEASE-20.8.1
  
  * mysql systemd double config removed
  * mysqld.service config cleanup
  * minor code cleanup
  
### RELEASE-20.8.0

  * magento 1.9.3.7
  * maldet monitoring disabled
  * mwscan hourly cronjob
  * opcache invalidation fixed
  * images optimization fixed
  * minor code cleanup

### RELEASE-20.7.0

  * install Percona 56 or 57
  * minor code cleanup
  
### RELEASE-20.6.0

  * stronger passwords
  * varnish repo updated
  * minor code cleanup

### RELEASE-20.5.7

  * magento 1.9.3.6
  * wazuh(ossec) 2.1
  * minor code cleanup

### RELEASE-20.5.6

  * magento 1.9.3.4
  * minor code cleanup

### RELEASE-20.5.5

  * magento 1.9.3.3
  * separate domain and linux user name
  * nginx stronger TLS ciphers. TLSv1 removed
  * minor code cleanup

### RELEASE-20.5

  * wazuh(ossec) 2.0 + ELK 5.3 upgrade
  * ELK Packetbeat monitoring

### RELEASE-20.4.2

  * realtime images optimization
  * realtime opcache invalidation
  * minor code cleaning
  
### RELEASE-20.4.1

  * varnish jail 
  * php-fpm hhvm config cleanup
  * magento home permissions fix
  * minor code cleaning

### RELEASE-20.4.0

  * magento 1.9.3.2
  * minor code cleaning

### RELEASE-20.3.9

  * magento 1.9.3.1
  * minor code cleaning

### RELEASE-20.3.8

  * better certbot/letsencrypt integration

### RELEASE-20.3.7

  * magento 1.9.3.0 now has php 7 support
  * redis lzf compression (you can set snappy, php module available)

### RELEASE-20.3.6

  * magento 1.9.3.0
  * minor code cleaning

### RELEASE-20.3.5

  * php-fpm master port now, (hhvm only for testing)
  * redis cache optimization
  * minor code cleaning

### RELEASE-20.3.4

  * add email alerting to maldet
  * csf firewall optimization
  * minor code cleaning
  
### RELEASE-20.3.3

  * phpmyadmin nginx basic auth
  * csf firewall optimization
  * minor code cleaning

### RELEASE-20.3.2

  * fixed redis config permissions
  * minor code cleaning

### RELEASE-20.3.1

  * Initial Magento 1+2 release
