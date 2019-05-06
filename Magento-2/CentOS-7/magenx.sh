#!/bin/bash
#=================================================================================#
#        Automated Server Configuration for Magento 2                             #
#        Copyright (C) 2019 admin@magenx.com                                      #
#        All rights reserved.                                                     #
#=================================================================================#
SELF=$(basename $0)
MAGENX_VER="21.0.7"
MAGENX_BASE="https://magenx.sh"

###################################################################################
###                            DEFINE LINKS AND PACKAGES                        ###
###################################################################################

# Magento
MAGE_VERSION="2"
MAGE_VERSION_FULL=$(curl -s https://api.github.com/repos/magento/magento2/tags 2>&1 | head -3 | grep -oP '(?<=")\d.*(?=")')
REPO_MAGE="composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition"

# Webmin Control Panel plugins:
WEBMIN_NGINX="https://github.com/magenx/webmin-nginx/archive/nginx-0.08.wbm__0.tar.gz"
WEBMIN_FAIL2BAN="http://download.webmin.com/download/modules/fail2ban.wbm.gz"

# Repositories
REPO_PERCONA="https://repo.percona.com/yum/percona-release-latest.noarch.rpm"
REPO_MYSQL="https://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm"
REPO_REMI="http://rpms.famillecollet.com/enterprise/remi-release-7.rpm"
REPO_FAN="http://www.city-fan.org/ftp/contrib/yum-repo/city-fan.org-release-2-1.rhel7.noarch.rpm"

# WebStack Packages
EXTRA_PACKAGES="autoconf automake dejavu-fonts-common dejavu-sans-fonts libtidy libpcap pygpgme gettext-devel cppunit recode boost boost-build boost-jam double-conversion fastlz fribidi gflags glog oniguruma tbb ed lz4 libyaml libdwarf bind-utils e2fsprogs svn screen gcc iptraf inotify-tools smartmontools net-tools mcrypt mlocate unzip vim wget curl sudo bc mailx clamav-filesystem clamav-server clamav-update clamav-milter-systemd clamav-data clamav-server-systemd clamav-scanner-systemd clamav clamav-milter clamav-lib clamav-scanner proftpd logrotate git patch ipset strace rsyslog gifsicle ncurses-devel GeoIP GeoIP-devel GeoIP-update openssl-devel ImageMagick libjpeg-turbo-utils pngcrush jpegoptim moreutils lsof net-snmp net-snmp-utils xinetd python-pip python-devel ncftp postfix yum-cron yum-plugin-versionlock sysstat libuuid-devel uuid-devel attr iotop expect postgresql-libs unixODBC gcc-c++"
PHP_PACKAGES=(cli common fpm opcache gd curl mbstring bcmath soap mcrypt mysqlnd pdo xml xmlrpc intl gmp php-gettext phpseclib recode symfony-class-loader symfony-common tcpdf tcpdf-dejavu-sans-fonts tidy udan11-sql-parser snappy lz4) 
PHP_PECL_PACKAGES=(pecl-redis pecl-lzf pecl-geoip pecl-zip pecl-memcache pecl-oauth)
PERL_MODULES=(LWP-Protocol-https libwww-perl CPAN Template-Toolkit Time-HiRes ExtUtils-CBuilder ExtUtils-Embed ExtUtils-MakeMaker TermReadKey DBI DBD-MySQL Digest-HMAC Digest-SHA1 Test-Simple Moose Net-SSLeay devel)
SPHINX="http://sphinxsearch.com/files/sphinx-2.2.11-1.rhel7.x86_64.rpm"

# Nginx extra configuration
REPO_MAGENX_TMP="https://raw.githubusercontent.com/magenx/Magento-Automated-Server-Configuration-from-MagenX/master/tmp/"
NGINX_VERSION=$(curl -s http://nginx.org/en/download.html | grep -oP '(?<=gz">nginx-).*?(?=</a>)' | head -1)
NGINX_BASE="https://raw.githubusercontent.com/magenx/Magento-nginx-config/master/"
NGINX_EXTRA_CONF="assets.conf error_page.conf extra_protect.conf export.conf pagespeed.conf status.conf setup.conf php_backend.conf maps.conf phpmyadmin.conf maintenance.conf"

# Debug Tools
MYSQL_TUNER="https://raw.githubusercontent.com/major/MySQLTuner-perl/master/mysqltuner.pl"
MYSQL_TOP="https://launchpad.net/ubuntu/+archive/primary/+files/mytop_1.9.1.orig.tar.gz"

###################################################################################
###                                    COLORS                                   ###
###################################################################################

RED="\e[31;40m"
GREEN="\e[32;40m"
YELLOW="\e[33;40m"
WHITE="\e[37;40m"
BLUE="\e[0;34m"
### Background
DGREYBG="\t\t\e[100m"
BLUEBG="\e[44m"
REDBG="\t\t\e[41m"
### Styles
BOLD="\e[1m"
### Reset
RESET="\e[0m"

###################################################################################
###                            ECHO MESSAGES DESIGN                             ###
###################################################################################

function WHITETXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${WHITE}${MESSAGE}${RESET}"
}
function BLUETXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${BLUE}${MESSAGE}${RESET}"
}
function REDTXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${RED}${MESSAGE}${RESET}"
}
function GREENTXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${GREEN}${MESSAGE}${RESET}"
}
function YELLOWTXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${YELLOW}${MESSAGE}${RESET}"
}
function BLUEBG() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "${BLUEBG}${MESSAGE}${RESET}"
}

###################################################################################
###                            PROGRESS BAR AND PAUSE                           ###
###################################################################################

function pause() {
   read -p "$*"
}
function start_progress {
  while true
  do
    echo -ne "#"
    sleep 1
  done
}
function quick_progress {
  while true
  do
    echo -ne "#"
    sleep 0.05
  done
}
function long_progress {
  while true
  do
    echo -ne "#"
    sleep 3
  done
}
function stop_progress {
kill $1
wait $1 2>/dev/null
echo -en "\n"
}

###################################################################################
###                            ARROW KEYS UP/DOWN MENU                          ###
###################################################################################

updown_menu () {
i=1;for items in $(echo $1); do item[$i]="${items}"; let i=$i+1; done
i=1
echo
echo -e "\n---> Use up/down arrow keys then press Enter to select $2"
while [ 0 ]; do
  if [ "$i" -eq 0 ]; then i=1; fi
  if [ ! "${item[$i]}" ]; then let i=i-1; fi
  echo -en "\r                                 " 
  echo -en "\r${item[$i]}"
  read -sn 1 selector
  case "${selector}" in
    "B") let i=i+1;;
    "A") let i=i-1;;
    "") echo; read -sn 1 -p "To confirm [ ${item[$i]} ] press y or n for new selection" confirm
      if [[ "${confirm}" =~ ^[Yy]$  ]]; then
        printf -v "$2" '%s' "${item[$i]}"
        break
      else
        echo
        echo -e "\n---> Use up/down arrow keys then press Enter to select $2"
      fi
      ;;
  esac
done }

clear
###################################################################################
###                                  START CHECKING                             ###
###################################################################################

echo
echo
# root?
if [[ ${EUID} -ne 0 ]]; then
  echo
  REDTXT "ERROR: THIS SCRIPT MUST BE RUN AS ROOT!"
  YELLOWTXT "------> USE SUPER-USER PRIVILEGES."
  exit 1
  else
  GREENTXT "PASS: ROOT!"
fi

# check if webstack is clean
if ! grep -q "webstack_is_clean" /root/magenx/.webstack >/dev/null 2>&1 ; then
installed_packages="$(rpm -qa --qf '%{name} ' 'mysqld?|Percona*|maria*|php-?|nginx*|*ftp*|varnish*|certbot*|redis*|webmin')"
  if [ ! -z "$installed_packages" ]; then
  REDTXT  "ERROR: WEBSTACK PACKAGES ALREADY INSTALLED"
  YELLOWTXT "------> YOU NEED TO REMOVE THEM OR RE-INSTALL MINIMAL OS VERSION"
  echo
  echo -e "\t\t yum remove ${installed_packages}"
  echo
  echo
  exit 1
    else
  mkdir -p /root/magenx
  echo "webstack_is_clean" > /root/magenx/.webstack
  fi
fi

# network is up?
host1=209.85.202.91
host2=151.101.193.69
RESULT=$(((ping -w3 -c2 ${host1} || ping -w3 -c2 ${host2}) > /dev/null 2>&1) && echo "up" || (echo "down" && exit 1))
if [[ ${RESULT} == up ]]; then
  GREENTXT "PASS: NETWORK IS UP. GREAT, LETS START!"
  else
  echo
  REDTXT "ERROR: NETWORK IS DOWN?"
  YELLOWTXT "------> PLEASE CHECK YOUR NETWORK SETTINGS."
  echo
  echo
  exit 1
fi
        MD5_NEW=$(curl -sL ${MAGENX_BASE} > MAGENX_NEW && md5sum MAGENX_NEW | awk '{print $1}')
        MD5_OLD=$(md5sum ${SELF} | awk '{print $1}')
            if [[ "${MD5_NEW}" == "${MD5_OLD}" ]]; then
            GREENTXT "PASS: INTEGRITY CHECK FOR '${SELF}' OK"
            rm MAGENX_NEW
            elif [[ "${MD5_NEW}" != "${MD5_OLD}" ]]; then
            echo
            YELLOWTXT "INTEGRITY CHECK FOR '${SELF}'"
            YELLOWTXT "DETECTED DIFFERENT MD5 CHECKSUM"
            YELLOWTXT "REMOTE REPOSITORY FILE HAS SOME CHANGES"
            REDTXT "IF YOU HAVE LOCAL CHANGES - SKIP UPDATES"
            echo
                echo -n "---> Would you like to update the file now?  [y/n][y]:"
		read update_agree
		if [ "${update_agree}" == "y" ];then
		mv MAGENX_NEW ${SELF}
		echo
                GREENTXT "THE FILE WAS UPGRADED, PLEASE RUN IT AGAIN"
		echo
                exit 1
            else
        echo
        YELLOWTXT "NEW FILE SAVED TO MAGENX_NEW"
        echo
  fi
fi

# do we have CentOS 7?
if grep "CentOS.* 7\." /etc/centos-release  > /dev/null 2>&1; then
  GREENTXT "PASS: CENTOS RELEASE 7"
  else
  echo
  REDTXT "ERROR: UNABLE TO DETERMINE DISTRIBUTION TYPE."
  YELLOWTXT "------> THIS CONFIGURATION FOR CENTOS 7"
  echo
  exit 1
fi

# check if x64. if not, beat it...
ARCH=$(uname -m)
if [ "${ARCH}" = "x86_64" ]; then
  GREENTXT "PASS: 64-BIT"
  else
  echo
  REDTXT "ERROR: 32-BIT SYSTEM?"
  YELLOWTXT "------> CONFIGURATION FOR 64-BIT ONLY."
  echo
  exit 1
fi

# check if memory is enough
TOTALMEM=$(awk '/MemTotal/ { print $2 }' /proc/meminfo)
if [ "${TOTALMEM}" -gt "3000000" ]; then
  GREENTXT "PASS: YOU HAVE ${TOTALMEM} Kb OF RAM"
  else
  echo
  REDTXT "WARNING: YOU HAVE LESS THAN 3Gb OF RAM"
  REDTXT "TO PROPERLY RUN COMPLETE STACK YOU NEED 4Gb+"
  echo
fi

# some selinux, sir?
if [ -f "/etc/selinux/config" ]; then
SELINUX=$(awk -F "=" '/^SELINUX=/ {print $2}' /etc/selinux/config)
if [[ ! "${SELINUX}" =~ (disabled|permissive) ]]; then
  echo
  REDTXT "ERROR: SELINUX IS NOT DISABLED OR PERMISSIVE"
  YELLOWTXT "------> PLEASE CHECK YOUR SELINUX SETTINGS"
  echo
  exit 1
  else
  GREENTXT "PASS: SELINUX IS ${SELINUX^^}"
fi
fi
echo
if ! grep -q "yes" /root/magenx/.systest >/dev/null 2>&1 ; then
echo "-------------------------------------------------------------------------------------"
BLUEBG "| QUICK SYSTEM TEST |"
echo "-------------------------------------------------------------------------------------"
echo
    yum -y install epel-release > /dev/null 2>&1
    yum -y install time bzip2 tar > /dev/null 2>&1
    
    test_file=vpsbench__$$
    tar_file=tarfile
    now=$(date +"%m/%d/%Y")

    cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo )
    cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
    freq=$( awk -F: ' /cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo )
    tram=$( free -m | awk 'NR==2 {print $2}' )   
    echo  
    echo -n "     PROCESSING I/O PERFORMANCE "
    start_progress &
    pid="$!"
    io=$( ( dd if=/dev/zero of=$test_file bs=64k count=16k conv=fdatasync && rm -f $test_file ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
    stop_progress "$pid"

    echo -n "     PROCESSING CPU PERFORMANCE "
    dd if=/dev/urandom of=$tar_file bs=1024 count=25000 >>/dev/null 2>&1
    start_progress &
    pid="$!"
    tf=$( (/usr/bin/time -f "%es" tar cfj $tar_file.bz2 $tar_file) 2>&1 )
    stop_progress "$pid"
    rm -f tarfile*
    echo
    echo

    if [ ${io% *} -ge 250 ] ; then
        IO_COLOR="${GREEN}$io - excellent result"
    elif [ ${io% *} -ge 200 ] ; then
        IO_COLOR="${YELLOW}$io - average result"
    else
        IO_COLOR="${RED}$io - very bad result"
    fi

    if [ ${tf%.*} -ge 10 ] ; then
        CPU_COLOR="${RED}$tf - very bad result"
    elif [ ${tf%.*} -ge 5 ] ; then
        CPU_COLOR="${YELLOW}$tf - average result"
    else
        CPU_COLOR="${GREEN}$tf - excellent result"
    fi

  WHITETXT "${BOLD}SYSTEM DETAILS"
  WHITETXT "CPU model: $cname"
  WHITETXT "Number of cores: $cores"
  WHITETXT "CPU frequency: $freq MHz"
  WHITETXT "Total amount of RAM: $tram MB"
  echo
  WHITETXT "${BOLD}BENCHMARKS RESULTS"
  WHITETXT "I/O speed: ${IO_COLOR}"
  WHITETXT "CPU Time: ${CPU_COLOR}"

echo
mkdir -p /root/magenx/ && echo "yes" > /root/magenx/.systest
echo
pause "---> Press [Enter] key to proceed"
echo
fi
echo
# ssh test
if ! grep -q "yes" /root/magenx/.sshport >/dev/null 2>&1 ; then
if grep -q "Port 22" /etc/ssh/sshd_config >/dev/null 2>&1 ; then
REDTXT "DEFAULT SSH PORT :22 DETECTED"
echo
      sed -i "s/.*LoginGraceTime.*/LoginGraceTime 30/" /etc/ssh/sshd_config
      sed -i "s/.*MaxAuthTries.*/MaxAuthTries 6/" /etc/ssh/sshd_config
      sed -i "s/.*X11Forwarding.*/X11Forwarding no/" /etc/ssh/sshd_config
      sed -i "s/.*PrintLastLog.*/PrintLastLog yes/" /etc/ssh/sshd_config
      sed -i "s/.*TCPKeepAlive.*/TCPKeepAlive yes/" /etc/ssh/sshd_config
      sed -i "s/.*ClientAliveInterval.*/ClientAliveInterval 600/" /etc/ssh/sshd_config
      sed -i "s/.*ClientAliveCountMax.*/ClientAliveCountMax 3/" /etc/ssh/sshd_config
      sed -i "s/.*UseDNS.*/UseDNS no/" /etc/ssh/sshd_config
      
echo -n "---> Lets change the default ssh port now? [y/n][n]:"
read new_ssh_set
if [ "${new_ssh_set}" == "y" ];then
   echo
      cp /etc/ssh/sshd_config /etc/ssh/sshd_config.BACK
      SSHPORT=$(shuf -i 9537-9554 -n 1)
      read -e -p "---> Enter the new ssh port : " -i "${SSHPORT}" NEW_SSH_PORT
      sed -i "s/.*Port 22/Port ${NEW_SSH_PORT}/g" /etc/ssh/sshd_config
     echo
        GREENTXT "SSH PORT AND SETTINGS WERE UPDATED  -  OK"
        systemctl restart sshd.service
        ss -tlp | grep sshd
     echo
echo
REDTXT "!IMPORTANT: NOW OPEN A NEW SSH SESSION WITH A NEW PORT!"
REDTXT "!IMPORTANT: DO NOT CLOSE THE CURRENT SESSION!"
echo
echo -n "------> Have you logged in another session? [y/n][n]:"
read new_ssh_test
if [ "${new_ssh_test}" == "y" ];then
      echo
        GREENTXT "REMEMBER THE NEW SSH PORT NOW: ${NEW_SSH_PORT}"
        echo "yes" > /root/magenx/.sshport
        else
	echo
        mv /etc/ssh/sshd_config.BACK /etc/ssh/sshd_config
        REDTXT "RESTORING sshd_config FILE BACK TO DEFAULTS ${GREEN} [ok]"
        systemctl restart sshd.service
        echo
        GREENTXT "SSH PORT HAS BEEN RESTORED  -  OK"
        ss -tlp | grep sshd
fi
fi
fi
fi
echo
echo

###################################################################################
###                                  AGREEMENT                                  ###
###################################################################################

echo
if ! grep -q "yes" /root/magenx/.terms >/dev/null 2>&1 ; then
  YELLOWTXT "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo
  YELLOWTXT "BY INSTALLING THIS SOFTWARE AND BY USING ANY AND ALL SOFTWARE"
  YELLOWTXT "YOU ACKNOWLEDGE AND AGREE:"
  echo
  YELLOWTXT "THIS SOFTWARE AND ALL SOFTWARE PROVIDED IS PROVIDED AS IS"
  YELLOWTXT "UNSUPPORTED AND WE ARE NOT RESPONSIBLE FOR ANY DAMAGE"
  echo
  YELLOWTXT "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo
   echo
    echo -n "---> Do you agree to these terms?  [y/n][y]:"
    read terms_agree
  if [ "${terms_agree}" == "y" ];then
    echo "yes" > /root/magenx/.terms
          else
        REDTXT "Going out. EXIT"
        echo
    exit 1
  fi
fi

###################################################################################
###                                  MAIN MENU                                  ###
###################################################################################

showMenu () {
printf "\033c"
    echo
      echo
        echo -e "${DGREYBG}${BOLD}  MAGENTO SERVER CONFIGURATION v.${MAGENX_VER}  ${RESET}"
        BLUETXT ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
        echo
        WHITETXT "-> Install repository and LEMP packages :  ${YELLOW}\tlemp"
        WHITETXT "-> Download Magento latest packages     :  ${YELLOW}\t\tmagento"
        WHITETXT "-> Setup Magento database               :  ${YELLOW}\t\t\tdatabase"
        WHITETXT "-> Install Magento no sample data       :  ${YELLOW}\t\tinstall"
        WHITETXT "-> Post-Install configuration           :  ${YELLOW}\t\tconfig"
        echo
        BLUETXT ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
        echo
        WHITETXT "-> Install CSF Firewall or Fail2Ban     :  ${YELLOW}\t\tfirewall"
        WHITETXT "-> Install Webmin control panel         :  ${YELLOW}\t\twebmin"
        WHITETXT "-> Install Wazuh ELK stack              :  ${YELLOW}\t\t\twazuh"
        echo
        BLUETXT ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
        echo
        WHITETXT "-> To quit and exit                     :  ${RED}\t\t\t\texit"
        echo
    echo
}
while [ 1 ]
do
        showMenu
        read CHOICE
        case "${CHOICE}" in
                "lemp")
echo
echo

###################################################################################
###                                  SYSTEM UPGRADE                             ###
###################################################################################

if ! grep -q "yes" /root/magenx/.sysupdate >/dev/null 2>&1 ; then
## install all extra packages
GREENTXT "SYSTEM PACKAGES INSTALLATION. PLEASE WAIT"
yum -q -y upgrade >/dev/null 2>&1
yum -q -y install https://dl.iuscommunity.org/pub/ius/stable/CentOS/7/x86_64/yum-plugin-replace-0.2.7-1.ius.centos7.noarch.rpm >/dev/null 2>&1
yum -q -y install ${REPO_FAN} >/dev/null 2>&1
sed -i '0,/gpgkey/s//includepkgs=curl libmetalink libpsl libcurl libssh2\n&/' /etc/yum.repos.d/city-fan.org.repo
yum install -y yum-utils >/dev/null 2>&1
yum-config-manager --enable city-fan.org >/dev/null 2>&1
yum -q -y install ${EXTRA_PACKAGES} ${PERL_MODULES[@]/#/perl-} >/dev/null 2>&1
echo
echo "yes" > /root/magenx/.sysupdate
echo
fi
echo
echo
echo "-------------------------------------------------------------------------------------"
BLUEBG "| INSTALLATION OF REPOSITORIES AND PACKAGES |"
echo "-------------------------------------------------------------------------------------"
echo
WHITETXT "============================================================================="
echo
echo -n "---> Start Percona repository and Percona database installation? [y/n][n]:"
read repo_percona_install
if [ "${repo_percona_install}" == "y" ];then
            echo
            echo -n "     PROCESSING  "
            quick_progress &
            pid="$!"
            rpm --quiet -U ${REPO_PERCONA} >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q percona-release
      if [ "$?" = 0 ] # if repository installed then install package
        then
          echo
            GREENTXT "REPOSITORY INSTALLED  -  OK"
              echo
              echo
              GREENTXT "Installation of Percona 5.7 database:"
              echo
              echo -n "     PROCESSING  "
              long_progress &
              pid="$!"
              yum -y -q install Percona-Server-server-57 Percona-Server-client-57 >/dev/null 2>&1
              stop_progress "$pid"
              rpm  --quiet -q Percona-Server-server-57 Percona-Server-client-57
        if [ "$?" = 0 ] # if package installed then configure
          then
            echo
              GREENTXT "DATABASE INSTALLED  -  OK"
              echo
              ## plug in service status alert
              cp /usr/lib/systemd/system/mysqld.service /etc/systemd/system/mysqld.service
              sed -i "s/^Restart=always/Restart=on-failure/" /etc/systemd/system/mysqld.service
              sed -i "/^After=syslog.target.*/a OnFailure=service-status-mail@%n.service" /etc/systemd/system/mysqld.service
              sed -i "/Restart=on-failure/a RestartSec=10" /etc/systemd/system/mysqld.service
              systemctl daemon-reload
              systemctl enable mysqld >/dev/null 2>&1
              echo
              WHITETXT "Downloading my.cnf file from MagenX Github repository"
              wget -qO /etc/my.cnf https://raw.githubusercontent.com/magenx/magento-mysql/master/my.cnf/my.cnf
              echo
                echo
                 WHITETXT "We need to correct your innodb_buffer_pool_size"
                 rpm -qa | grep -qw bc || yum -q -y install bc >/dev/null 2>&1
                 IBPS=$(echo "0.5*$(awk '/MemTotal/ { print $2 / (1024*1024)}' /proc/meminfo | cut -d'.' -f1)" | bc | xargs printf "%1.0f")
                 sed -i "s/innodb_buffer_pool_size = 4G/innodb_buffer_pool_size = ${IBPS}G/" /etc/my.cnf
                 sed -i "s/innodb_buffer_pool_instances = 4/innodb_buffer_pool_instances = ${IBPS}/" /etc/my.cnf
                 echo
                 YELLOWTXT "innodb_buffer_pool_size = ${IBPS}G"
                 YELLOWTXT "innodb_buffer_pool_instances = ${IBPS}"
                echo
              echo
              ## get mysql tools
	      YELLOWTXT "INSTALL MYSQLTOP, PERCONA-TOOLKIT, MYSQLROUTER, MYSQLTUNER"
	      wget -qO /usr/local/bin/mysqltuner ${MYSQL_TUNER}
              cd /usr/local/src
              wget -qO - ${MYSQL_TOP} | tar -xzp && cd mytop*
              perl Makefile.PL && make && make install  >/dev/null 2>&1
              yum -y -q install percona-toolkit xtrabackup >/dev/null 2>&1
              echo
              yum -y -q install ${REPO_MYSQL} >/dev/null 2>&1
              yum-config-manager --disable mysql80-community >/dev/null 2>&1
              yum -y -q install mysql-router >/dev/null 2>&1
              else
              echo
              REDTXT "DATABASE INSTALLATION ERROR"
          exit # if package is not installed then exit
        fi
          else
            echo
              REDTXT "REPOSITORY INSTALLATION ERROR"
        exit # if repository is not installed then exit
      fi
        else
              echo
            YELLOWTXT "Percona repository installation was skipped by the user. Next step"
fi
echo
WHITETXT "============================================================================="
echo
echo -n "---> Start nginx ${NGINX_VERSION} installation? [y/n][n]:"
read repo_nginx_install
if [ "${repo_nginx_install}" == "y" ];then
          echo
            WHITETXT "Downloading Nginx GPG key"
            wget -qO /etc/pki/rpm-gpg/nginx_signing.key  http://nginx.org/packages/keys/nginx_signing.key
            echo
            echo
cat > /etc/yum.repos.d/nginx.repo <<END
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/mainline/centos/7/x86_64/
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/nginx_signing.key
gpgcheck=1
END
            echo
            GREENTXT "REPOSITORY INSTALLED  -  OK"
            echo
            GREENTXT "Installation of nginx package:"
            echo
            echo -n "     PROCESSING  "
            start_progress &
            pid="$!"
            yum -y -q install nginx nginx-module-geoip nginx-module-perl >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q nginx
      if [ "$?" = 0 ]
        then
          echo
            GREENTXT "NGINX INSTALLED  -  OK"
            echo
            ## plug in service status alert
            cp /usr/lib/systemd/system/nginx.service /etc/systemd/system/nginx.service
            sed -i "/^After.*/a OnFailure=service-status-mail@%n.service" /etc/systemd/system/nginx.service
            sed -i "/\[Install\]/i Restart=on-failure\nRestartSec=10\n" /etc/systemd/system/nginx.service
            sed -i "s,PIDFile=/run/nginx.pid,PIDFile=/var/run/nginx.pid," /etc/systemd/system/nginx.service
            sed -i "s/PrivateTmp=true/PrivateTmp=false/" /etc/systemd/system/nginx.service
            systemctl daemon-reload
            systemctl enable nginx >/dev/null 2>&1
              else
             echo
            REDTXT "NGINX INSTALLATION ERROR"
        exit
      fi
        else
          echo
            YELLOWTXT "Nginx repository installation was skipped by the user. Next step"
fi
echo
WHITETXT "============================================================================="
echo
echo -n "---> Start the Remi repository and PHP 7.2 installation? [y/n][n]:"
read repo_remi_install
if [ "${repo_remi_install}" == "y" ];then
          echo
            GREENTXT "Installation of Remi repository:"
            echo
            echo -n "     PROCESSING  "
            quick_progress &
            pid="$!"
            rpm --quiet -U ${REPO_REMI} >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q remi-release
      if [ "$?" = 0 ]
        then
          echo
            GREENTXT "REPOSITORY INSTALLED  -  OK"
            echo
            GREENTXT "Installation of PHP 7.2:"
            echo
            echo -n "     PROCESSING  "
            long_progress &
            pid="$!"
            yum --enablerepo=remi,remi-php72 -y -q install php ${PHP_PACKAGES[@]/#/php-} ${PHP_PECL_PACKAGES[@]/#/php-} >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q php
       if [ "$?" = 0 ]
         then
           echo
             GREENTXT "PHP INSTALLED  -  OK"
             ## plug in service status alert
             cp /usr/lib/systemd/system/php-fpm.service /etc/systemd/system/php-fpm.service
             sed -i "s/PrivateTmp=true/PrivateTmp=false/" /etc/systemd/system/php-fpm.service
             sed -i "/^After.*/a OnFailure=service-status-mail@%n.service" /etc/systemd/system/php-fpm.service
             sed -i "/\[Install\]/i Restart=on-failure\nRestartSec=10\n" /etc/systemd/system/php-fpm.service
             systemctl daemon-reload
             systemctl enable php-fpm >/dev/null 2>&1
             systemctl disable httpd >/dev/null 2>&1
             rpm -qa 'php*' | awk '{print "  Installed: ",$1}'
                else
               echo
             REDTXT "PHP INSTALLATION ERROR"
         exit
       fi
         echo
           echo
            GREENTXT "Installation of Redis, Memcached and Sphinx packages:"
            echo
            echo -n "     PROCESSING  "
            start_progress &
            pid="$!"
            yum --enablerepo=remi -y -q install redis memcached ${SPHINX} >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q redis
       if [ "$?" = 0 ]
         then
           echo
             GREENTXT "REDIS INSTALLED"
             systemctl disable redis >/dev/null 2>&1
             echo
cat > /etc/systemd/system/redis@.service <<END
[Unit]
Description=Redis %i
After=network.target
OnFailure=service-status-mail@%n.service
PartOf=redis.target

[Service]
Type=simple
User=redis
Group=redis
PrivateTmp=true
PIDFile=/var/run/redis-%i.pid
ExecStart=/usr/bin/redis-server /etc/redis-%i.conf

Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target redis.target
END

cat > /etc/systemd/system/redis.target <<END
[Unit]
Description=Redis start/stop all redis@.service instances
END

for REDISPORT in 6379 6380
do
mkdir -p /var/lib/redis-${REDISPORT}
chmod 755 /var/lib/redis-${REDISPORT}
chown redis /var/lib/redis-${REDISPORT}
cp -rf /etc/redis.conf /etc/redis-${REDISPORT}.conf
chmod 644 /etc/redis-${REDISPORT}.conf
sed -i "s/^bind 127.0.0.1.*/bind 127.0.0.1/"  /etc/redis-${REDISPORT}.conf
sed -i "s/^dir.*/dir \/var\/lib\/redis-${REDISPORT}\//"  /etc/redis-${REDISPORT}.conf
sed -i "s/^logfile.*/logfile \/var\/log\/redis\/redis-${REDISPORT}.log/"  /etc/redis-${REDISPORT}.conf
sed -i "s/^pidfile.*/pidfile \/var\/run\/redis-${REDISPORT}.pid/"  /etc/redis-${REDISPORT}.conf
sed -i "s/^port.*/port ${REDISPORT}/" /etc/redis-${REDISPORT}.conf
sed -i "s/dump.rdb/dump-${REDISPORT}.rdb/" /etc/redis-${REDISPORT}.conf
done
echo
cat > /etc/sysconfig/memcached <<END
PORT="11211"
USER="memcached"
MAXCONN="5024"
CACHESIZE="128"
OPTIONS="-l 127.0.0.1"
END
## plug in service status alert
cp /usr/lib/systemd/system/memcached.service /etc/systemd/system/memcached.service
cp /usr/lib/systemd/system/searchd.service /etc/systemd/system/searchd.service
sed -i "/^After.*/a OnFailure=service-status-mail@%n.service" /etc/systemd/system/memcached.service
sed -i "/\[Install\]/i Restart=on-failure\nRestartSec=10\n" /etc/systemd/system/memcached.service
sed -i "/^After.*/a OnFailure=service-status-mail@%n.service" /etc/systemd/system/searchd.service
sed -i "/\[Install\]/i Restart=on-failure\nRestartSec=10\n" /etc/systemd/system/searchd.service
systemctl daemon-reload
systemctl enable redis@6379 >/dev/null 2>&1
systemctl enable redis@6380 >/dev/null 2>&1
systemctl enable memcached  >/dev/null 2>&1
                else
               echo
             REDTXT "PACKAGES INSTALLATION ERROR"
         exit
       fi
         else
           echo
             REDTXT "REPOSITORY INSTALLATION ERROR"
        exit
      fi
        else
          echo
            YELLOWTXT "The Remi repository installation was skipped by the user. Next step"
fi
echo
WHITETXT "============================================================================="
echo
echo -n "---> Start Varnish Cache installation? [y/n][n]:"
read varnish_install
if [ "${varnish_install}" == "y" ];then
cat >> /etc/yum.repos.d/varnishcache_varnish52.repo <<END
[varnishcache_varnish52]
name=varnishcache_varnish52}
baseurl=https://packagecloud.io/varnishcache/varnish52/el/7/x86_64
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/varnishcache/varnish52/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300

[varnishcache_varnish52-source]
name=varnishcache_varnish52-source
baseurl=https://packagecloud.io/varnishcache/varnish52/el/7/SRPMS
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/varnishcache/varnish52/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
END
echo
            echo -n "     PROCESSING  "
            start_progress &
            pid="$!"
            yum -y -q install varnish >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q varnish
      if [ "$?" = 0 ]
        then
          echo
	    wget -qO /etc/systemd/system/varnish.service ${REPO_MAGENX_TMP}varnish.service
            wget -qO /etc/varnish/varnish.params ${REPO_MAGENX_TMP}varnish.params
            systemctl daemon-reload >/dev/null 2>&1
            GREENTXT "VARNISH 52 INSTALLED  -  OK"
               else
              echo
            REDTXT "VARNISH INSTALLATION ERROR"
      fi
        else
          echo
            YELLOWTXT "Varnish installation was skipped by the user. Next step"
fi
echo
echo
GREENTXT "NOW WE ARE GOING TO CONFIGURE EVERYTHING"
echo
pause "---> Press [Enter] key to proceed"
echo
echo "Load optimized configs of php, opcache, fpm, fastcgi, sysctl, varnish"
WHITETXT "YOU HAVE TO CHECK THEM AFTER ANYWAY"
cat > /etc/sysctl.conf <<END
fs.file-max = 1000000
fs.inotify.max_user_watches = 1000000
vm.swappiness = 10
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
kernel.msgmnb = 65535
kernel.msgmax = 65535
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 8388608 8388608 8388608
net.ipv4.tcp_rmem = 4096 87380 8388608
net.ipv4.tcp_wmem = 4096 65535 8388608
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_challenge_ack_limit = 1073741823
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 15
net.ipv4.tcp_max_orphans = 262144
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_max_tw_buckets = 400000
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_sack = 1
net.ipv4.route.flush = 1
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 8388608
net.core.wmem_default = 8388608
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 65535
END

sysctl -q -p
echo
WHITETXT "sysctl.conf loaded ${GREEN} [ok]"
cat > /etc/php.d/10-opcache.ini <<END
zend_extension=opcache.so
opcache.enable = 1
opcache.enable_cli = 1
opcache.memory_consumption = 256
opcache.interned_strings_buffer = 4
opcache.max_accelerated_files = 50000
opcache.max_wasted_percentage = 5
opcache.use_cwd = 1
opcache.validate_timestamps = 0
;opcache.revalidate_freq = 2
;opcache.validate_permission= 1
;opcache.validate_root= 1
opcache.file_update_protection = 2
opcache.revalidate_path = 0
opcache.save_comments = 1
opcache.load_comments = 1
opcache.fast_shutdown = 1
opcache.enable_file_override = 0
opcache.optimization_level = 0xffffffff
opcache.inherited_hack = 1
opcache.blacklist_filename=/etc/php.d/opcache-default.blacklist
opcache.max_file_size = 0
opcache.consistency_checks = 0
opcache.force_restart_timeout = 60
opcache.error_log = "/var/log/php-fpm/opcache.log"
opcache.log_verbosity_level = 1
opcache.preferred_memory_model = ""
opcache.protect_memory = 0
;opcache.mmap_base = ""
END

WHITETXT "opcache.ini loaded ${GREEN} [ok]"
#Tweak php.ini.
cp /etc/php.ini /etc/php.ini.BACK
sed -i 's/^\(max_execution_time = \)[0-9]*/\17200/' /etc/php.ini
sed -i 's/^\(max_input_time = \)[0-9]*/\17200/' /etc/php.ini
sed -i 's/^\(memory_limit = \)[0-9]*M/\11024M/' /etc/php.ini
sed -i 's/^\(post_max_size = \)[0-9]*M/\164M/' /etc/php.ini
sed -i 's/^\(upload_max_filesize = \)[0-9]*M/\164M/' /etc/php.ini
sed -i 's/expose_php = On/expose_php = Off/' /etc/php.ini
sed -i 's/;realpath_cache_size = 16k/realpath_cache_size = 512k/' /etc/php.ini
sed -i 's/;realpath_cache_ttl = 120/realpath_cache_ttl = 86400/' /etc/php.ini
sed -i 's/short_open_tag = Off/short_open_tag = On/' /etc/php.ini
sed -i 's/; max_input_vars = 1000/max_input_vars = 50000/' /etc/php.ini
sed -i 's/session.gc_maxlifetime = 1440/session.gc_maxlifetime = 28800/' /etc/php.ini
sed -i 's/mysql.allow_persistent = On/mysql.allow_persistent = Off/' /etc/php.ini
sed -i 's/mysqli.allow_persistent = On/mysqli.allow_persistent = Off/' /etc/php.ini
sed -i 's/pm = dynamic/pm = ondemand/' /etc/php-fpm.d/www.conf
sed -i 's/;pm.max_requests = 500/pm.max_requests = 10000/' /etc/php-fpm.d/www.conf
sed -i 's/pm.max_children = 50/pm.max_children = 1000/' /etc/php-fpm.d/www.conf

WHITETXT "php.ini loaded ${GREEN} [ok]"
echo
echo "*         soft    nofile          700000" >> /etc/security/limits.conf
echo "*         hard    nofile          1000000" >> /etc/security/limits.conf
echo
echo
echo "-------------------------------------------------------------------------------------"
BLUEBG "| INSTALLATION OF REPOSITORIES AND PACKAGES IS COMPLETED |"
echo "-------------------------------------------------------------------------------------"
echo
echo
pause '------> Press [Enter] key to show the menu'
printf "\033c"
;;

###################################################################################
###                                  MAGENTO DOWNLOAD                           ###
###################################################################################

"magento")
echo
echo "-------------------------------------------------------------------------------------"
BLUEBG "|   DOWNLOAD MAGENTO ${MAGE_VERSION} (${MAGE_VERSION_FULL})                                            |"
echo "-------------------------------------------------------------------------------------"
echo
echo
     read -e -p "---> ENTER YOUR DOMAIN OR IP ADDRESS: " -i "myshop.com" MAGE_DOMAIN
     read -e -p "---> ENTER MAGENTO FILES USER NAME: " -i "myshop" MAGE_WEB_USER
     MAGE_WEB_ROOT_PATH="/home/${MAGE_WEB_USER}/public_html"
     echo
	 echo "---> MAGENTO ${MAGE_VERSION} (${MAGE_VERSION_FULL})"
	 echo "---> WILL BE DOWNLOADED TO ${MAGE_WEB_ROOT_PATH}"
     echo
        mkdir -p ${MAGE_WEB_ROOT_PATH} && cd $_
        useradd -d ${MAGE_WEB_ROOT_PATH%/*} -s /sbin/nologin ${MAGE_WEB_USER}  >/dev/null 2>&1
        MAGE_WEB_USER_PASS=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&?=+_[]{}()<>-' | fold -w 15 | head -n 1)
        echo "${MAGE_WEB_USER}:${MAGE_WEB_USER_PASS}"  | chpasswd  >/dev/null 2>&1
        chmod 711 /home/${MAGE_WEB_USER}
        chown -R ${MAGE_WEB_USER}:${MAGE_WEB_USER} ${MAGE_WEB_ROOT_PATH%/*}
        chmod 2770 ${MAGE_WEB_ROOT_PATH}
        setfacl -Rdm u:${MAGE_WEB_USER}:rwx,g:${MAGE_WEB_USER}:rwx,g::rw-,o::- ${MAGE_WEB_ROOT_PATH}
        echo
                curl -sS https://getcomposer.org/installer | php >/dev/null 2>&1
		mv composer.phar /usr/local/bin/composer
		[ -f "/usr/local/bin/composer" ] || { echo "---> COMPOSER INSTALLATION ERROR" ; exit 1 ;}
		su ${MAGE_WEB_USER} -s /bin/bash -c "${REPO_MAGE} ."
        echo
     echo
WHITETXT "============================================================================="
GREENTXT "      == MAGENTO DOWNLOADED AND READY FOR INSTALLATION =="
WHITETXT "============================================================================="
mkdir -p /root/magenx/
if [ -f /root/magenx/.magenx_index ]; then
sed -i "s,webshop.*,webshop ${MAGE_DOMAIN}    ${MAGE_WEB_ROOT_PATH}    ${MAGE_WEB_USER}   ${MAGE_WEB_USER_PASS}  ${MAGE_VERSION}  ${MAGE_VERSION_FULL}," /root/magenx/.magenx_index
else
cat >> /root/magenx/.magenx_index <<END
webshop ${MAGE_DOMAIN}    ${MAGE_WEB_ROOT_PATH}    ${MAGE_WEB_USER}   ${MAGE_WEB_USER_PASS}  ${MAGE_VERSION}  ${MAGE_VERSION_FULL}
END
fi
echo
pause '------> Press [Enter] key to show menu'
printf "\033c"
;;

###################################################################################
###                                  DATABASE SETUP                             ###
###################################################################################

"database")
printf "\033c"
WHITETXT "============================================================================="
GREENTXT "CRAETE MAGENTO DATABASE AND DATABASE USER"
echo
if [ ! -f /root/.my.cnf ]; then
systemctl start mysqld.service
MYSQL_ROOT_PASS_GEN=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&?=+_[]{}()<>-' | fold -w 15 | head -n 1)
MYSQL_ROOT_PASS="${MYSQL_ROOT_PASS_GEN}${RANDOM}#"
MYSQL_ROOT_TMP_PASS=$(grep 'temporary password is generated for' /var/log/mysqld.log | awk '{print $NF}')
## reset temporary password
mysql --connect-expired-password -u root -p${MYSQL_ROOT_TMP_PASS}  <<EOMYSQL
ALTER USER 'root'@'localhost' IDENTIFIED BY "${MYSQL_ROOT_PASS}";
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
exit
EOMYSQL
cat > /root/.mytop <<END
user=root
pass=${MYSQL_ROOT_PASS}
db=mysql
END
cat > /root/.my.cnf <<END
[client]
user=root
password="${MYSQL_ROOT_PASS}"
END
fi
MAGE_VERSION=$(awk '/webshop/ { print $6 }' /root/magenx/.magenx_index)
MAGE_DB_PASS_GEN=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&?=+_{}()<>-' | fold -w 15 | head -n 1)
MAGE_DB_PASS="${MAGE_DB_PASS_GEN}${RANDOM}#"
echo
echo
read -e -p "---> Enter Magento database host : " -i "localhost" MAGE_DB_HOST
read -e -p "---> Enter Magento database name : " -i "m${MAGE_VERSION}d_$(openssl rand 6 -hex)" MAGE_DB_NAME
read -e -p "---> Enter Magento database user : " -i "m${MAGE_VERSION}u_$(openssl rand 6 -hex)" MAGE_DB_USER_NAME
echo
echo
pause '------> Press [Enter] key to create MySQL database and user'
mysql <<EOMYSQL
CREATE USER '${MAGE_DB_USER_NAME}'@'${MAGE_DB_HOST}' IDENTIFIED BY '${MAGE_DB_PASS}';
CREATE DATABASE ${MAGE_DB_NAME};
GRANT ALL PRIVILEGES ON ${MAGE_DB_NAME}.* TO '${MAGE_DB_USER_NAME}'@'${MAGE_DB_HOST}' WITH GRANT OPTION;
exit
EOMYSQL
echo
mkdir -p /root/magenx/
cat >> /root/magenx/.magenx_index <<END
database   ${MAGE_DB_HOST}   ${MAGE_DB_NAME}   ${MAGE_DB_USER_NAME}   ${MAGE_DB_PASS}  ${MYSQL_ROOT_PASS}
END
echo
echo
pause '------> Press [Enter] key to show menu'
printf "\033c"
;;

###################################################################################
###                               MAGENTO INSTALLATION                         ###
###################################################################################

"install")
printf "\033c"
MAGE_VERSION=$(awk '/webshop/ { print $6 }' /root/magenx/.magenx_index)
MAGE_VERSION_FULL=$(awk '/webshop/ { print $7 }' /root/magenx/.magenx_index)
echo "-------------------------------------------------------------------------------------"
BLUEBG   "|  MAGENTO ${MAGE_VERSION} (${MAGE_VERSION_FULL}) INSTALLATION  |"
echo "-------------------------------------------------------------------------------------"
echo
MAGE_WEB_ROOT_PATH=$(awk '/webshop/ { print $3 }' /root/magenx/.magenx_index)
MAGE_WEB_USER=$(awk '/webshop/ { print $4 }' /root/magenx/.magenx_index)
MAGE_DOMAIN=$(awk '/webshop/ { print $2 }' /root/magenx/.magenx_index)
DB_HOST=$(awk '/database/ { print $2 }' /root/magenx/.magenx_index)
DB_NAME=$(awk '/database/ { print $3 }' /root/magenx/.magenx_index)
DB_USER_NAME=$(awk '/database/ { print $4 }' /root/magenx/.magenx_index)
DB_PASS=$(awk '/database/ { print $5 }' /root/magenx/.magenx_index)

cd ${MAGE_WEB_ROOT_PATH}
chown -R ${MAGE_WEB_USER}:${MAGE_WEB_USER} ${MAGE_WEB_ROOT_PATH}
echo
echo "---> ENTER SETUP INFORMATION"
echo
WHITETXT "Database information"
read -e -p "---> Enter your database host: " -i "${DB_HOST}"  MAGE_DB_HOST
read -e -p "---> Enter your database name: " -i "${DB_NAME}"  MAGE_DB_NAME
read -e -p "---> Enter your database user: " -i "${DB_USER_NAME}"  MAGE_DB_USER_NAME
read -e -p "---> Enter your database password: " -i "${DB_PASS}"  MAGE_DB_PASS
echo
WHITETXT "Administrator and domain"
read -e -p "---> Enter your First Name: " -i "Name"  MAGE_ADMIN_FNAME
read -e -p "---> Enter your Last Name: " -i "Lastname"  MAGE_ADMIN_LNAME
read -e -p "---> Enter your email: " -i "admin@${MAGE_DOMAIN}"  MAGE_ADMIN_EMAIL
read -e -p "---> Enter your admins login name: " -i "admin"  MAGE_ADMIN_LOGIN
MAGE_ADMIN_PASSGEN=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&?=+_[]{}()<>-' | fold -w 10 | head -n 1)
read -e -p "---> Use generated admin password: " -i "${MAGE_ADMIN_PASSGEN}${RANDOM}"  MAGE_ADMIN_PASS
read -e -p "---> Enter your shop url: " -i "http://${MAGE_DOMAIN}/"  MAGE_SITE_URL
echo
WHITETXT "Language, Currency and Timezone settings"
echo
chmod u+x bin/magento
updown_menu "$(bin/magento info:language:list | sed "s/[|+-]//g" | awk 'NR > 3 {print $NF}' | sort )" MAGE_LOCALE
updown_menu "$(bin/magento info:currency:list | sed "s/[|+-]//g" | awk 'NR > 3 {print $NF}' | sort )" MAGE_CURRENCY
updown_menu "$(bin/magento info:timezone:list | sed "s/[|+-]//g" | awk 'NR > 3 {print $NF}' | sort )" MAGE_TIMEZONE
echo
echo
GREENTXT "SETUP MAGENTO ${MAGE_VERSION} (${MAGE_VERSION_FULL}) WITHOUT SAMPLE DATA"
echo
pause '---> Press [Enter] key to run setup'
echo
su ${MAGE_WEB_USER} -s /bin/bash -c "bin/magento setup:install --base-url=${MAGE_SITE_URL} \
--db-host=${MAGE_DB_HOST} \
--db-name=${MAGE_DB_NAME} \
--db-user=${MAGE_DB_USER_NAME} \
--db-password='${MAGE_DB_PASS}' \
--admin-firstname=${MAGE_ADMIN_FNAME} \
--admin-lastname=${MAGE_ADMIN_LNAME} \
--admin-email=${MAGE_ADMIN_EMAIL} \
--admin-user=${MAGE_ADMIN_LOGIN} \
--admin-password='${MAGE_ADMIN_PASS}' \
--language=${MAGE_LOCALE} \
--currency=${MAGE_CURRENCY} \
--timezone=${MAGE_TIMEZONE} \
--cleanup-database \
--session-save=files \
--use-rewrites=1"

mysqldump --single-transaction --routines --triggers --events ${MAGE_DB_NAME} | gzip > /root/${MAGE_DB_NAME}.sql.gz

echo
    WHITETXT "============================================================================="
    echo
    GREENTXT "INSTALLED MAGENTO ${MAGE_VERSION} (${MAGE_VERSION_FULL}) WITHOUT SAMPLE DATA"
    echo
    WHITETXT "============================================================================="
echo
cat >> /root/magenx/.magenx_index <<END
mageadmin  ${MAGE_ADMIN_LOGIN}  ${MAGE_ADMIN_PASS}  ${MAGE_ADMIN_EMAIL}  ${MAGE_TIMEZONE}  ${MAGE_LOCALE} ${MAGE_ADMIN_PATH_RANDOM}
END

pause '------> Press [Enter] key to show menu'
printf "\033c"
;;

###################################################################################
###                                FINAL CONFIGURATION                          ###
###################################################################################

"config")
printf "\033c"
MAGE_DOMAIN=$(awk '/webshop/ { print $2 }' /root/magenx/.magenx_index)
MAGE_WEB_ROOT_PATH=$(awk '/webshop/ { print $3 }' /root/magenx/.magenx_index)
MAGE_WEB_USER=$(awk '/webshop/ { print $4 }' /root/magenx/.magenx_index)
MAGE_WEB_USER_PASS=$(awk '/webshop/ { print $5 }' /root/magenx/.magenx_index)
MAGE_ADMIN_EMAIL=$(awk '/mageadmin/ { print $4 }' /root/magenx/.magenx_index)
MAGE_TIMEZONE=$(awk '/mageadmin/ { print $5 }' /root/magenx/.magenx_index)
MAGE_LOCALE=$(awk '/mageadmin/ { print $6 }' /root/magenx/.magenx_index)
MAGE_ADMIN_LOGIN=$(awk '/mageadmin/ { print $2 }' /root/magenx/.magenx_index)
MAGE_ADMIN_PASS=$(awk '/mageadmin/ { print $3 }' /root/magenx/.magenx_index)
MAGE_ADMIN_PATH_RANDOM=$(awk '/mageadmin/ { print $7 }' /root/magenx/.magenx_index)
MAGE_VERSION=$(awk '/webshop/ { print $6 }' /root/magenx/.magenx_index)
MAGE_VERSION_FULL=$(awk '/webshop/ { print $7 }' /root/magenx/.magenx_index)
MAGE_DB_HOST=$(awk '/database/ { print $2 }' /root/magenx/.magenx_index)
MAGE_DB_NAME=$(awk '/database/ { print $3 }' /root/magenx/.magenx_index)
MAGE_DB_USER_NAME=$(awk '/database/ { print $4 }' /root/magenx/.magenx_index)
MAGE_DB_PASS=$(awk '/database/ { print $5 }' /root/magenx/.magenx_index)
MYSQL_ROOT_PASS=$(awk '/database/ { print $6 }' /root/magenx/.magenx_index)
echo "-------------------------------------------------------------------------------------"
BLUEBG "| POST-INSTALLATION CONFIGURATION |"
echo "-------------------------------------------------------------------------------------"
echo
GREENTXT "SERVER HOSTNAME SETTINGS"
hostnamectl set-hostname server.${MAGE_DOMAIN} --static
echo
GREENTXT "SERVER TIMEZONE SETTINGS"
timedatectl set-timezone ${MAGE_TIMEZONE}
echo
GREENTXT "PHP-FPM SETTINGS"
sed -i "s/\[www\]/\[${MAGE_WEB_USER}\]/" /etc/php-fpm.d/www.conf
sed -i "s/user = apache/user = ${MAGE_WEB_USER}/" /etc/php-fpm.d/www.conf
sed -i "s/group = apache/group = ${MAGE_WEB_USER}/" /etc/php-fpm.d/www.conf
sed -i "s/;listen.owner = nobody/listen.group = ${MAGE_WEB_USER}/" /etc/php-fpm.d/www.conf
sed -i "s/;listen.group = nobody/listen.group = ${MAGE_WEB_USER}/" /etc/php-fpm.d/www.conf
sed -i "s/;listen.mode = 0660/listen.mode = 0660/" /etc/php-fpm.d/www.conf
sed -i '/PHPSESSID/d' /etc/php.ini
sed -i "s,.*date.timezone.*,date.timezone = ${MAGE_TIMEZONE}," /etc/php.ini
sed -i '/sendmail_path/,$d' /etc/php-fpm.d/www.conf

cat >> /etc/php-fpm.d/www.conf <<END
;;
;; Custom pool settings
php_flag[display_errors] = off
php_admin_flag[log_errors] = on
php_admin_value[error_log] = ${MAGE_WEB_ROOT_PATH}/var/log/php-fpm-error.log
php_admin_value[memory_limit] = 1024M
php_admin_value[date.timezone] = ${MAGE_TIMEZONE}
END

echo "${MAGE_WEB_ROOT_PATH}/app/etc/env.php" >> /etc/php.d/opcache-default.blacklist

systemctl daemon-reload
echo
GREENTXT "NGINX SETTINGS"
wget -qO /etc/nginx/fastcgi_params  ${NGINX_BASE}magento${MAGE_VERSION}/fastcgi_params
wget -qO /etc/nginx/nginx.conf  ${NGINX_BASE}magento${MAGE_VERSION}/nginx.conf
mkdir -p /etc/nginx/sites-enabled
mkdir -p /etc/nginx/sites-available && cd $_
wget -q ${NGINX_BASE}magento${MAGE_VERSION}/sites-available/default.conf
wget -q ${NGINX_BASE}magento${MAGE_VERSION}/sites-available/magento${MAGE_VERSION}.conf
ln -s /etc/nginx/sites-available/magento${MAGE_VERSION}.conf /etc/nginx/sites-enabled/magento${MAGE_VERSION}.conf
ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf
mkdir -p /etc/nginx/conf_m${MAGE_VERSION} && cd /etc/nginx/conf_m${MAGE_VERSION}/
for CONFIG in ${NGINX_EXTRA_CONF}
do
wget -q ${NGINX_BASE}magento${MAGE_VERSION}/conf_m${MAGE_VERSION}/${CONFIG}
done
sed -i "s/user  nginx;/user  ${MAGE_WEB_USER};/" /etc/nginx/nginx.conf
sed -i "s/example.com/${MAGE_DOMAIN}/g" /etc/nginx/sites-available/magento${MAGE_VERSION}.conf
sed -i "s/example.com/${MAGE_DOMAIN}/g" /etc/nginx/nginx.conf
sed -i "s,/var/www/html,${MAGE_WEB_ROOT_PATH},g" /etc/nginx/sites-available/magento${MAGE_VERSION}.conf

MAGE_ADMIN_PATH=$(grep -Po "(?<='frontName' => ')\w*(?=')" ${MAGE_WEB_ROOT_PATH}/app/etc/env.php)
sed -i "s/ADMIN_PLACEHOLDER/${MAGE_ADMIN_PATH}/" /etc/nginx/conf_m${MAGE_VERSION}/extra_protect.conf
echo
GREENTXT "PHPMYADMIN INSTALLATION AND CONFIGURATION"
     PMA_FOLDER=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1)
     PMA_PASSWD=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&?=+_[]{}()<>-' | fold -w 6 | head -n 1)
     BLOWFISHCODE=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9=+_[]{}()<>-' | fold -w 64 | head -n 1)
     yum -y -q --enablerepo=remi,remi-test,remi-php72 install phpMyAdmin
     USER_IP=${SSH_CLIENT%% *} 
     sed -i "s/.*blowfish_secret.*/\$cfg['blowfish_secret'] = '${BLOWFISHCODE}';/" /etc/phpMyAdmin/config.inc.php
     sed -i "s/PHPMYADMIN_PLACEHOLDER/mysql_${PMA_FOLDER}/g" /etc/nginx/conf_m${MAGE_VERSION}/phpmyadmin.conf
     sed -i "5i \\
           auth_basic  \"please login\"; \\
           auth_basic_user_file .mysql;"  /etc/nginx/conf_m${MAGE_VERSION}/phpmyadmin.conf
	 	   
     htpasswd -b -c /etc/nginx/.mysql mysql ${PMA_PASSWD}  >/dev/null 2>&1
     echo
     systemctl restart nginx.service
cat >> /root/magenx/.magenx_index <<END
pma   mysql_${PMA_FOLDER}   mysql   ${PMA_PASSWD}
END
echo
GREENTXT "PROFTPD CONFIGURATION"
     wget -qO /usr/local/bin/ftpasswd https://raw.githubusercontent.com/proftpd/proftpd/master/contrib/ftpasswd
     chmod +x /usr/local/bin/ftpasswd
     MAGE_SUPPORT_USER_PASS=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&?=+_[]{}()<>-' | fold -w 15 | head -n 1)
     MAGE_SUPPORT_USER_ID=$(id -u ${MAGE_WEB_USER})
     echo "${MAGE_SUPPORT_USER_PASS}" | ftpasswd --uid ${MAGE_SUPPORT_USER_ID} --gid ${MAGE_SUPPORT_USER_ID} --name ${MAGE_WEB_USER}_support --shell /bin/false --home ${MAGE_WEB_ROOT_PATH} --stdin --passwd --file=/etc/.ftpd.passwd  >/dev/null 2>&1
     chmod 640 /etc/.ftpd.passwd
     wget -qO /etc/proftpd.conf ${REPO_MAGENX_TMP}proftpd.conf
     ## change proftpd config
     SERVER_IP_ADDR=$(ip route get 1 | awk '{print $NF;exit}')
     USER_IP=${SSH_CLIENT%% *}
     USER_GEOIP=$(geoiplookup ${USER_IP} | awk 'NR==1{print substr($4,1,2)}')
     FTP_PORT=$(shuf -i 5121-5132 -n 1)
     sed -i "s/server_sftp_port/${FTP_PORT}/" /etc/proftpd.conf
     sed -i "s/server_ip_address/${SERVER_IP_ADDR}/" /etc/proftpd.conf
     sed -i "s/client_ip_address/${USER_IP}/" /etc/proftpd.conf
     sed -i "s/geoip_country_code/${USER_GEOIP}/" /etc/proftpd.conf
     sed -i "s/sftp_domain/${MAGE_DOMAIN}/" /etc/proftpd.conf
     sed -i "s/FTP_USER/${MAGE_WEB_USER}/" /etc/proftpd.conf
     echo
     ## plug in service status alert
     cp /usr/lib/systemd/system/proftpd.service /etc/systemd/system/proftpd.service
     sed -i "/^After.*/a OnFailure=service-status-mail@%n.service" /etc/systemd/system/proftpd.service
     sed -i "/\[Install\]/i Restart=on-failure\nRestartSec=10\n" /etc/systemd/system/proftpd.service
     systemctl daemon-reload
     systemctl enable proftpd.service >/dev/null 2>&1
     systemctl restart proftpd.service
     echo
cat >> /root/magenx/.magenx_index <<END
proftpd   ${USER_GEOIP}   ${FTP_PORT}   ${MAGE_WEB_USER_PASS}
END
echo
if [ -f /etc/mysqlrouter/mysqlrouter.conf ]; then
GREENTXT "MYSQLROUTER CONFIGURATION"
ROUTER_PORT=$(shuf -i 10501-10539 -n 1)
cat >> /etc/mysqlrouter/mysqlrouter.conf <<END

## REMOTE PORT ROUTING
[routing:${MAGE_WEB_USER}_mysql]
bind_address = ${SERVER_IP_ADDR}:${ROUTER_PORT}
destinations = 127.0.0.1:3306
mode = read-only
END
fi
echo
if [ -f /etc/systemd/system/varnish.service ]; then
GREENTXT "VARNISH CACHE CONFIGURATION"
    sed -i "s/MAGE_WEB_USER/${MAGE_WEB_USER}/g"  /etc/systemd/system/varnish.service
    systemctl enable varnish.service >/dev/null 2>&1
    chmod u+x ${MAGE_WEB_ROOT_PATH}/bin/magento
    php ${MAGE_WEB_ROOT_PATH}/bin/magento varnish:vcl:generate --export-version=5 --output-file=/etc/varnish/default.vcl
    systemctl restart varnish.service
    YELLOWTXT "VARNISH CACHE PORT :8081"
fi
echo
GREENTXT "DOWNLOADING n98-MAGERUN"
     mkdir -p /opt/magento_saved_scripts
     curl -s -o /usr/local/bin/n98-magerun2 https://files.magerun.net/n98-magerun2.phar
echo
GREENTXT "SYSTEM AUTO UPDATE WITH YUM-CRON"
yum-config-manager --enable remi-php72 >/dev/null 2>&1
yum-config-manager --enable remi >/dev/null 2>&1
sed -i 's/apply_updates = no/apply_updates = yes/' /etc/yum/yum-cron.conf
sed -i 's/emit_via = stdio/emit_via = email/' /etc/yum/yum-cron.conf
sed -i "s/email_from = root@localhost/email_from = yum-cron@${MAGE_DOMAIN}/" /etc/yum/yum-cron.conf
sed -i "s/email_to = root/email_to = ${MAGE_ADMIN_EMAIL}/" /etc/yum/yum-cron.conf
systemctl enable yum-cron >/dev/null 2>&1
systemctl restart yum-cron >/dev/null 2>&1
echo
GREENTXT "LETSENCRYPT SSL CERTIFICATE REQUEST"
wget -q https://dl.eff.org/certbot-auto -O /usr/local/bin/certbot-auto
chmod +x /usr/local/bin/certbot-auto
certbot-auto --install-only
certbot-auto certonly --agree-tos --no-eff-email --email ${MAGE_ADMIN_EMAIL} --webroot -w ${MAGE_WEB_ROOT_PATH}/pub/
systemctl reload nginx.service
echo '45 5 * * 1 root certbot-auto renew --quiet --deploy-hook "systemctl reload nginx" >> /var/log/letsencrypt-renew.log' >> /etc/crontab
echo
GREENTXT "GENERATE DHPARAM FOR NGINX SSL"
openssl dhparam -dsaparam -out /etc/ssl/certs/dhparams.pem 4096
echo
GREENTXT "GENERATE DEFAULT NGINX SSL SERVER KEY/CERT"
openssl req -x509 -newkey rsa:4096 -sha256 -nodes -keyout /etc/ssl/certs/default_server.key -out /etc/ssl/certs/default_server.crt \
-subj "/CN=default_server" -days 3650 -subj "/C=US/ST=Oregon/L=Portland/O=default_server/OU=Org/CN=default_server"
echo
GREENTXT "SIMPLE LOGROTATE SCRIPT FOR MAGENTO LOGS"
cat > /etc/logrotate.d/magento <<END
${MAGE_WEB_ROOT_PATH}/var/log/*.log
{
su root root
create 640 ${MAGE_WEB_USER} ${MAGE_WEB_USER}
weekly
rotate 2
notifempty
missingok
compress
}
END
echo
GREENTXT "SERVICE STATUS WITH E-MAIL ALERTING"
wget -qO /etc/systemd/system/service-status-mail@.service ${REPO_MAGENX_TMP}service-status-mail@.service
wget -qO /usr/local/bin/service-status-mail.sh ${REPO_MAGENX_TMP}service-status-mail.sh
sed -i "s/MAGEADMINEMAIL/${MAGE_ADMIN_EMAIL}/" /usr/local/bin/service-status-mail.sh
sed -i "s/DOMAINNAME/${MAGE_DOMAIN}/" /usr/local/bin/service-status-mail.sh
chmod u+x /usr/local/bin/service-status-mail.sh
systemctl daemon-reload
echo
GREENTXT "MAGENTO MALWARE SCANNER"
YELLOWTXT "Hourly cronjob created"
pip -q install --no-cache-dir --upgrade mwscan
cat > /etc/cron.hourly/mwscan <<END
## MAGENTO MALWARE SCANNER
MAILTO="${MAGE_ADMIN_EMAIL}"
RULESURL="https://raw.githubusercontent.com/gwillem/magento-malware-scanner/master/build/all-confirmed.yar"
RULEFILE="/tmp/rules.yar"

/usr/bin/curl -s \${RULESURL} -o \${RULEFILE} && /usr/bin/mwscan --quiet --newonly --rules \${RULEFILE} ${MAGE_WEB_ROOT_PATH}
END
echo
echo
GREENTXT "GOACCESS REALTIME ACCESS LOG DASHBOARD"
cd /usr/local/src
git clone https://github.com/allinurl/goaccess.git
cd goaccess
autoreconf -fi
./configure --enable-utf8 --enable-geoip=legacy --with-openssl  >/dev/null 2>&1
make > goaccess-make-log-file 2>&1
make install > goaccess-make-log-file 2>&1
sed -i '13s/#//' /usr/local/etc/goaccess.conf >/dev/null 2>&1
sed -i '36s/#//' /usr/local/etc/goaccess.conf >/dev/null 2>&1
sed -i '70s/#//' /usr/local/etc/goaccess.conf >/dev/null 2>&1
sed -i "s,#ssl-cert.*,ssl-cert /etc/letsencrypt/live/${MAGE_DOMAIN}/fullchain.pem," /usr/local/etc/goaccess.conf >/dev/null 2>&1
sed -i "s,#ssl-key.*,ssl-key /etc/letsencrypt/live/${MAGE_DOMAIN}/privkey.pem," /usr/local/etc/goaccess.conf >/dev/null 2>&1
echo
GREENTXT "MAGENTO CRONJOBS"
        echo "#* * * * * php -c /etc/php.ini ${MAGE_WEB_ROOT_PATH}/bin/magento cron:run" >> magecron
        echo "#* * * * * php -c /etc/php.ini ${MAGE_WEB_ROOT_PATH}/update/cron.php" >> magecron
        echo "#* * * * * php -c /etc/php.ini ${MAGE_WEB_ROOT_PATH}/bin/magento setup:cron:run" >> magecron
##
crontab -u ${MAGE_WEB_USER} magecron
GREENTXT "ROOT CRONJOBS"
echo "5 8 * * 7 perl /usr/local/bin/mysqltuner --nocolor 2>&1 | mailx -E -s \"MYSQLTUNER WEEKLY REPORT at ${HOSTNAME}\" ${MAGE_ADMIN_EMAIL}" >> rootcron
echo "30 23 * * * cd /var/log/nginx/; goaccess access.log -a -o access_log_report.html 2>&1 && echo | mailx -s \"Daily access log report at ${HOSTNAME}\" -a access_log_report.html ${MAGE_ADMIN_EMAIL}" >> rootcron
echo "0 1 * * 1 find ${MAGE_WEB_ROOT_PATH}/pub/ -name '*\.jpg' -type f -mtime -7 -exec jpegoptim -q -s -p --all-progressive -m 65 {} \; >/dev/null 2>&1" >> rootcron
crontab rootcron
rm magecron
rm rootcron
echo
GREENTXT "REDIS CACHE AND SESSION STORAGE"
echo
systemctl start redis.target
## cache backend
cd ${MAGE_WEB_ROOT_PATH}
su ${MAGE_WEB_USER} -s /bin/bash -c "bin/magento setup:config:set \
--cache-backend=redis \
--cache-backend-redis-server=127.0.0.1 \
--cache-backend-redis-port=6380 \
--cache-backend-redis-db=1 \
-n"
## page cache
su ${MAGE_WEB_USER} -s /bin/bash -c "bin/magento setup:config:set \
--page-cache=redis \
--page-cache-redis-server=127.0.0.1 \
--page-cache-redis-port=6380 \
--page-cache-redis-db=2 \
-n"
## session
su ${MAGE_WEB_USER} -s /bin/bash -c "bin/magento setup:config:set \
--session-save=redis \
--session-save-redis-host=127.0.0.1 \
--session-save-redis-port=6379 \
--session-save-redis-log-level=3 \
--session-save-redis-db=1 \
-n"
echo
systemctl daemon-reload
systemctl restart nginx.service
systemctl restart php-fpm.service

cd ${MAGE_WEB_ROOT_PATH}
chown -R ${MAGE_WEB_USER}:${MAGE_WEB_USER} ${MAGE_WEB_ROOT_PATH%/*}
echo
GREENTXT "DISABLE MAGENTO CACHE AND ENABLE DEVELOPER MODE"
rm -rf var/*
su ${MAGE_WEB_USER} -s /bin/bash -c "php bin/magento deploy:mode:set developer"
su ${MAGE_WEB_USER} -s /bin/bash -c "php bin/magento cache:flush"
su ${MAGE_WEB_USER} -s /bin/bash -c "php bin/magento cache:disable"

systemctl restart php-fpm.service
echo
GREENTXT "SAVING COMPOSER JSON AND LOCK"
cp composer.json ../composer.json.saved
cp composer.lock ../composer.lock.saved
echo
echo
GREENTXT "FIXING PERMISSIONS"
chown -R ${MAGE_WEB_USER}:${MAGE_WEB_USER} ${MAGE_WEB_ROOT_PATH}
find . -type f -exec chmod 660 {} \;
find . -type d -exec chmod 2770 {} \;
chmod +x /usr/local/bin/*
usermod -G apache ${MAGE_WEB_USER}
echo
echo
echo "===========================  INSTALLATION LOG  ======================================"
echo
echo
WHITETXT "[shop domain]: ${MAGE_DOMAIN}"
WHITETXT "[webroot path]: ${MAGE_WEB_ROOT_PATH}"
WHITETXT "[admin path]: ${MAGE_DOMAIN}/${MAGE_ADMIN_PATH}"
WHITETXT "[admin name]: ${MAGE_ADMIN_LOGIN}"
WHITETXT "[admin pass]: ${MAGE_ADMIN_PASS}"
echo
WHITETXT "[phpmyadmin url]: ${MAGE_DOMAIN}/mysql_${PMA_FOLDER}"
WHITETXT "[phpmyadmin http auth name]: mysql"
WHITETXT "[phpmyadmin http auth pass]: ${PMA_PASSWD}"
echo
WHITETXT "[mysql host]: ${MAGE_DB_HOST}"
WHITETXT "[mysql user]: ${MAGE_DB_USER_NAME}"
WHITETXT "[mysql pass]: ${MAGE_DB_PASS}"
WHITETXT "[mysql database]: ${MAGE_DB_NAME}"
WHITETXT "[mysql root pass]: ${MYSQL_ROOT_PASS}"
WHITETXT "[mysql-router port]:" ${ROUTER_PORT}
echo
WHITETXT "[ftp port]: ${FTP_PORT}"
WHITETXT "[ftp master user]: ${MAGE_WEB_USER}"
WHITETXT "[ftp master user password]: ${MAGE_WEB_USER_PASS}"
WHITETXT "[ftp support user]: ${MAGE_WEB_USER}_support"
WHITETXT "[ftp support user password]: ${MAGE_SUPPORT_USER_PASS}"
WHITETXT "[ftp allowed geoip]: ${USER_GEOIP}"
WHITETXT "[ftp allowed ip]: ${USER_IP}"
echo
WHITETXT "[percona toolkit]: https://www.percona.com/doc/percona-toolkit/LATEST/index.html"
WHITETXT "[database monitor]: /usr/local/bin/mytop"
WHITETXT "[mysql tuner]: /usr/local/bin/mysqltuner"
echo
WHITETXT "[n98-magerun2]: /usr/local/bin/n98-magerun2"
echo
WHITETXT "[service alert]: /usr/local/bin/service-status-mail.sh"
echo
WHITETXT "[redis on port 6379]: systemctl restart redis@6379"
WHITETXT "[redis on port 6380]: systemctl restart redis@6380"
echo
WHITETXT "[goaccess realtime]: goaccess /var/log/nginx/access.log -o ${MAGE_WEB_ROOT_PATH}/pub/access_report_${RANDOM}.html --real-time-html --daemonize"
echo
WHITETXT "[crontab]: in case of migration magento 2 cron disabled. enable it if no migration."
WHITETXT "[installed db dump]: /root/${MAGE_DB_NAME}.sql.gz"
echo
echo "===========================  INSTALLATION LOG  ======================================"
echo
## simple installation statistics for 30 days
curl --silent -X POST https://www.magenx.com/ping_back_domain_${MAGE_DOMAIN}_geo_${USER_GEOIP}_keep_30d >/dev/null 2>&1
echo
GREENTXT "SERVER IS READY. THANK YOU"
echo
echo
echo
pause '---> Press [Enter] key to show menu'
;;

###################################################################################
###                               FIREWALL INSTALLATION                         ###
###################################################################################

"firewall")
WHITETXT "============================================================================="
echo
MAGE_DOMAIN=$(awk '/webshop/ { print $2 }' /root/magenx/.magenx_index)
MAGE_ADMIN_EMAIL=$(awk '/mageadmin/ { print $4 }' /root/magenx/.magenx_index)
YELLOWTXT "If you are going to use services like CloudFlare - install Fail2Ban"
echo
echo -n "---> Would you like to install CSF firewall(csf) or Fail2Ban(f2b) or cancel (n):"
read frwlltst
if [ "${frwlltst}" == "csf" ];then
           echo
               GREENTXT "DOWNLOADING CSF FIREWALL"
               echo
               cd /usr/local/src/
               echo -n "     PROCESSING  "
               quick_progress &
               pid="$!"
               wget -qO - https://download.configserver.com/csf.tgz | tar -xz
               stop_progress "$pid"
               echo
               cd csf
               GREENTXT "NEXT, TEST IF YOU HAVE THE REQUIRED IPTABLES MODULES"
               echo
           if perl csftest.pl | grep "FATAL" ; then
               perl csftest.pl
               echo
               REDTXT "CSF FILERWALL HAS FATAL ERRORS INSTALL FAIL2BAN INSTEAD"
               echo -n "     PROCESSING  "
               quick_progress &
               pid="$!"
               yum -q -y install fail2ban >/dev/null 2>&1
               stop_progress "$pid"
               echo
               GREENTXT "FAIL2BAN HAS BEEN INSTALLED OK"
               echo
               pause '---> Press [Enter] key to show menu'
           else
               echo
               GREENTXT "CSF FIREWALL INSTALLATION"
               echo
               echo -n "     PROCESSING  "
               quick_progress &
               pid="$!"
               sh install.sh
               stop_progress "$pid"
               echo
               GREENTXT "CSF FIREWALL HAS BEEN INSTALLED OK"
                   echo
                   YELLOWTXT "Add ip addresses to whitelist/ignore (paypal,api,erp,backup,github,etc)"
                   echo
                   read -e -p "---> Enter ip address/cidr each after space: " -i "173.0.80.0/20 64.4.244.0/21 " IP_ADDR_IGNORE
                   for ip_addr_ignore in ${IP_ADDR_IGNORE}; do csf -a ${ip_addr_ignore}; done
                   ### csf firewall optimization
                   sed -i 's/^TESTING = "1"/TESTING = "0"/' /etc/csf/csf.conf
                   sed -i 's/^CT_LIMIT =.*/CT_LIMIT = "300"/' /etc/csf/csf.conf
                   sed -i 's/^CT_INTERVAL =.*/CT_INTERVAL = "30"/' /etc/csf/csf.conf
                   sed -i 's/^PS_INTERVAL =.*/PS_INTERVAL = "120"/' /etc/csf/csf.conf
                   sed -i 's/^PS_LIMIT =.*/PS_LIMIT = "10"/' /etc/csf/csf.conf
                   sed -i 's/^LF_WEBMIN =.*/LF_WEBMIN = "5"/' /etc/csf/csf.conf
                   sed -i 's/^LF_WEBMIN_EMAIL_ALERT =.*/LF_WEBMIN_EMAIL_ALERT = "1"/' /etc/csf/csf.conf
                   sed -i "s/^LF_ALERT_TO =.*/LF_ALERT_TO = \"${MAGE_ADMIN_EMAIL}\"/" /etc/csf/csf.conf
                   sed -i "s/^LF_ALERT_FROM =.*/LF_ALERT_FROM = \"firewall@${MAGE_DOMAIN}\"/" /etc/csf/csf.conf
                   sed -i 's/^DENY_IP_LIMIT =.*/DENY_IP_LIMIT = "50000"/' /etc/csf/csf.conf
                   sed -i 's/^DENY_TEMP_IP_LIMIT =.*/DENY_TEMP_IP_LIMIT = "200"/' /etc/csf/csf.conf
                   sed -i 's/^LF_IPSET =.*/LF_IPSET = "1"/' /etc/csf/csf.conf
                   ### this line will block every blacklisted ip address
                   sed -i "/|0|/s/^#//g" /etc/csf/csf.blocklists
        csf -r
    fi
    elif [ "${frwlltst}" == "f2b" ];then
    echo
    GREENTXT "FAIL2BAN INSTALLATION"
    echo
    echo -n "     PROCESSING  "
    quick_progress &
    pid="$!"
    yum -q -y install fail2ban >/dev/null 2>&1
    stop_progress "$pid"
    echo
    GREENTXT "FAIL2BAN HAS BEEN INSTALLED OK"
    echo
            else
          echo
            YELLOWTXT "Firewall installation was skipped by the user. Next step"
	    exit 1
fi
echo
echo
pause '---> Press [Enter] key to show menu'
;;

###################################################################################
###                                  WEBMIN INSTALLATION                        ###
###################################################################################

"webmin")
echo
echo -n "---> Start the Webmin Control Panel installation? [y/n][n]:"
read webmin_install
if [ "${webmin_install}" == "y" ];then
          echo
            GREENTXT "Installation of Webmin package:"
cat > /etc/yum.repos.d/webmin.repo <<END
[Webmin]
name=Webmin Distribution
#baseurl=http://download.webmin.com/download/yum
mirrorlist=http://download.webmin.com/download/yum/mirrorlist
enabled=1
END
rpm --import http://www.webmin.com/jcameron-key.asc
            echo
            echo -n "     PROCESSING  "
            start_progress &
            pid="$!"
            yum -y -q install webmin >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q webmin
      if [ "$?" = 0 ]
        then
          echo
            GREENTXT "WEBMIN HAS BEEN INSTALLED  -  OK"
            echo
            WEBMIN_PORT=$(shuf -i 17556-17728 -n 1)
            sed -i 's/theme=gray-theme/theme=authentic-theme/' /etc/webmin/config
            sed -i 's/preroot=gray-theme/preroot=authentic-theme/' /etc/webmin/miniserv.conf
            sed -i "s/port=10000/port=${WEBMIN_PORT}/" /etc/webmin/miniserv.conf
            sed -i "s/listen=10000/listen=${WEBMIN_PORT}/" /etc/webmin/miniserv.conf
            ## nginx module
            cd /usr/local/src/
            wget -q ${WEBMIN_NGINX} -O webmin_nginx
            perl /usr/libexec/webmin/install-module.pl $_ >/dev/null 2>&1
            if [ -f "/usr/local/csf/csfwebmin.tgz" ]
				then
				perl /usr/libexec/webmin/install-module.pl /usr/local/csf/csfwebmin.tgz >/dev/null 2>&1
				GREENTXT "INSTALLED CSF FIREWALL PLUGIN"
    		else
				cd /usr/local/src
				wget -q ${WEBMIN_FAIL2BAN} -O fail2ban.wbm.gz
				perl /usr/libexec/webmin/install-module.pl $_ >/dev/null 2>&1
				GREENTXT "INSTALLED FAIL2BAN PLUGIN"
            fi
            sed -i 's/root/webadmin/' /etc/webmin/miniserv.users
            sed -i 's/root:/webadmin:/' /etc/webmin/webmin.acl
            WEBADMIN_PASS=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&?=+_[]{}()<>-' | fold -w 15 | head -n 1)
            /usr/libexec/webmin/changepass.pl /etc/webmin/ webadmin "${WEBADMIN_PASS}" >/dev/null 2>&1
            chkconfig webmin on >/dev/null 2>&1
            service webmin restart  >/dev/null 2>&1
            YELLOWTXT "Access Webmin on port: ${WEBMIN_PORT}"
            YELLOWTXT "User: webadmin , Password: ${WEBADMIN_PASS}"
            REDTXT "PLEASE ENABLE TWO-FACTOR AUTHENTICATION!"
               else
              echo
            REDTXT "WEBMIN INSTALLATION ERROR"
      fi
        else
          echo
            YELLOWTXT "Webmin installation was skipped by the user. Next step"
fi
echo
echo
pause '---> Press [Enter] key to show menu'
;;

###################################################################################
###                         WAZUH + ELK STACK INSTALLATION                      ###
###################################################################################

"wazuh")
WHITETXT "============================================================================="
echo
GREENTXT "INSTALLATION OF WAZUH 3 + ELK 6 STACK:"
echo
GREENTXT "INSTALLATION OF WAZUH MANAGER"
cat > /etc/yum.repos.d/wazuh.repo <<EOF
[wazuh_repo]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=Wazuh repository
baseurl=https://packages.wazuh.com/3.x/yum/
protect=1
EOF
yum -y -q install wazuh-manager
echo
GREENTXT "INSTALLATION OF WAZUH API + NODEJS"
curl --silent --location https://rpm.nodesource.com/setup_8.x | bash >/dev/null 2>&1
yum -y -q install nodejs
yum -y -q install wazuh-api
echo
GREENTXT "INSTALLATION OF JAVA 8 JDK RPM:"
cd /usr/local/src
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "https://download.oracle.com/otn-pub/java/jdk/8u202-b08/1961070e4c9b4e26a04e7f5a083f551e/jre-8u202-linux-x64.rpm"
yum -y localinstall jre-8u202-linux-x64.rpm
echo
echo
GREENTXT "INSTALLATION OF ELASTCSEARCH:"
echo
cat > /etc/yum.repos.d/elastic.repo <<EOF
[elastic]
name=Elasticsearch repository for 6.x packages
baseurl=https://artifacts.elastic.co/packages/6.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF
echo
yum -y -q install elasticsearch >/dev/null 2>&1
echo
sed -i "s/.*cluster.name.*/cluster.name: wazuh/" /etc/elasticsearch/elasticsearch.yml
sed -i "s/.*node.name.*/node.name: wazuh-node1/" /etc/elasticsearch/elasticsearch.yml
sed -i "s/.*network.host.*/network.host: 127.0.0.1/" /etc/elasticsearch/elasticsearch.yml
sed -i "s/.*http.port.*/http.port: 9200/" /etc/elasticsearch/elasticsearch.yml
sed -i "s/-Xms.*/-Xms512m/" /etc/elasticsearch/jvm.options
sed -i "s/-Xmx.*/-Xmx512m/" /etc/elasticsearch/jvm.options
chown -R :elasticsearch /etc/elasticsearch/*
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl restart elasticsearch.service
YELLOWTXT "---> Waiting for elasticsearch to start:"
while ! curl --output /dev/null --silent --head --fail http://localhost:9200; do sleep 1 && echo -n .; done
echo "Importing templates"
curl https://raw.githubusercontent.com/wazuh/wazuh/3.7/extensions/elasticsearch/wazuh-elastic6-template-alerts.json | curl -X PUT "http://localhost:9200/_template/wazuh" -H 'Content-Type: application/json' -d @-
curl https://raw.githubusercontent.com/wazuh/wazuh/3.7/extensions/elasticsearch/wazuh-elastic6-template-monitoring.json | curl -XPUT 'http://localhost:9200/_template/wazuh-agent' -H 'Content-Type: application/json' -d @-
curl https://raw.githubusercontent.com/wazuh/wazuh/3.7/extensions/elasticsearch/alert_sample.json | curl -XPUT "http://localhost:9200/wazuh-alerts-3.x-"`date +%Y.%m.%d`"/wazuh/sample" -H 'Content-Type: application/json' -d @-
echo
echo
GREENTXT "INSTALLATION OF PACKETBEAT:"
yum -y -q install packetbeat
systemctl enable packetbeat
systemctl start packetbeat
echo
echo
GREENTXT "INSTALLATION OF LOGSTASH:"
yum -y -q install logstash
curl -so /etc/logstash/conf.d/01-wazuh.conf https://raw.githubusercontent.com/wazuh/wazuh/3.7/extensions/logstash/01-wazuh-local.conf
usermod -a -G ossec logstash
systemctl daemon-reload
systemctl enable logstash.service
systemctl start logstash.service
echo
echo
GREENTXT "INSTALLATION OF KIBANA:"
yum -y -q install kibana
/usr/share/kibana/bin/kibana-plugin install https://packages.wazuh.com/wazuhapp/wazuhapp-3.8.2_6.7.0.zip
echo
systemctl daemon-reload
systemctl enable kibana.service
systemctl restart kibana.service
echo
echo
yum-config-manager --disable elastic
yum-config-manager --disable wazuh
echo
GREENTXT "OSSEC WAZUH API SETTINGS"
sed -i 's/.*config.host.*/config.host = "127.0.0.1";/' /var/ossec/api/configuration/config.js
echo
MAGE_DOMAIN=$(awk '/webshop/ { print $2 }' /root/magenx/.magenx_index)
KIBANA_PORT=$(shuf -i 10322-10539 -n 1)
USER_IP=${SSH_CLIENT%% *}
KIBANA_PASSWD=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&?=+_[]{}()<>-' | fold -w 6 | head -n 1)
WAZUH_API_PASSWD=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&?=+_[]{}()<>-' | fold -w 6 | head -n 1)
htpasswd -b -c /etc/nginx/.wazuh wazuh-web "${KIBANA_PASSWD}"  >/dev/null 2>&1
cd /var/ossec/api/configuration/auth
htpasswd -b -c user wazuh-api "${WAZUH_API_PASSWD}"  >/dev/null 2>&1
systemctl restart wazuh-api
cat > /etc/nginx/sites-available/kibana.conf <<END
server {
  listen ${KIBANA_PORT} ssl http2;
  server_name           ${MAGE_DOMAIN};
  access_log            /var/log/nginx/access.log;
  
  ## SSL CONFIGURATION
	#ssl_certificate     /etc/letsencrypt/live/${MAGE_DOMAIN}/fullchain.pem; 
	#ssl_certificate_key /etc/letsencrypt/live/${MAGE_DOMAIN}/privkey.pem;
	
    auth_basic  "blackhole";
    auth_basic_user_file .wazuh;
       
       location / {
               proxy_pass http://127.0.0.1:5601;
       }
}
END
echo
cd /etc/nginx/sites-enabled/
ln -s /etc/nginx/sites-available/kibana.conf kibana.conf
service nginx reload
echo
YELLOWTXT "KIBANA WEB INTERFACE PORT: ${KIBANA_PORT}"
YELLOWTXT "KIBANA HTTP AUTH: wazuh-web ${KIBANA_PASSWD}"
echo
YELLOWTXT "WAZUH API AUTH: wazuh-api ${WAZUH_API_PASSWD}"
echo
pause '---> Press [Enter] key to show menu'
;;
"exit")
REDTXT "------> EXIT"
exit
;;

###################################################################################
###                             CATCH ALL MENU - THE END                        ###
###################################################################################

*)
printf "\033c"
;;
esac
done
