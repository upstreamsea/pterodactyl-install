#!/bin/bash

output(){
    echo -e '\e[36m'$1'\e[0m';
}

copyright(){
    output "Pterodactyl Installation & Upgrade script."
    output "By Upstream Sea --- Discord: Upstream Sea#3920"
    output ""
    output "By using this script, you agree that you are not being offered a warranty of any kind, unless required by local law."
    output "This script can be used for commercial purpouses."
    output "Wanna help? Check my GitHub."
}

get_distribution(){
    output "Automatic Operating System Detection initialized."
	if [ -r /etc/os-release ]; then
		lsb_dist="$(. /etc/os-release && echo "$ID")"
		dist_version="$(. /etc/os-release && echo "$VERSION_ID")"
	fi
	output "OS: $lsb_dist $dist_version detected."
    output ""

    if [ "$lsb_dist" =  "ubuntu" ]; then
        if [ "$dist_version" != "18.10" ] && [ "$dist_version" != "18.04" ] && [ "$dist_version" != "16.04" ] && [ "$dist_version" != "14.04" ]; then
            output "Unsupported Ubuntu version. Only Ubuntu 18.04, 16.04, and 14.04 are supported."
            exit 0
        fi
	elif [ "$lsb_dist" = "debian" ]; then
        if [ "$dist_version" != "9" ] && [ "$dist_version" != "8" ]; then
            output "Unsupported Debian version. Only Debian 9 and 8 are supported.."
            exit 0
		fi
    elif [ "$lsb_dist" = "fedora" ]; then
        if [ "$dist_version" != "28" ]; then
            output "Unsupported Fedora version. Only Fedora 28 is supported."
            exit 0
        fi
    elif [ "$lsb_dist" = "centos" ]; then
        if [ "$dist_version" != "7" ]; then
            output "Unsupported CentOS version. Only CentOS 7 is supported."
            exit 0
        fi
    elif [ "$lsb_dist" = "rhel" ]; then
        if [ "$dist_version" != "7" ]&&[ "$dist_version" != "7.1" ]&&[ "$dist_version" != "7.2" ]&&[ "$dist_version" != "7.3" ]&&[ "$dist_version" != "7.4" ]&&[ "$dist_version" != "7.5" ]&&[ "$dist_version" != "7.6" ]; then
            output "Unsupported RHEL version. Only RHEL 7 is supported."
            exit 0
        fi
    elif [ "$lsb_dist" != "ubuntu" ] && [ "$lsb_dist" != "debian" ] && [ "$lsb_dist" != "centos" ] && [ "$lsb_dist" != "rhel" ]; then
        output "Unsupported Operating System."
        output ""
        output "Supported OS:"
        output "Ubuntu: 18.10, 18.04, 16.04 14.04"
        output "Debian: 9, 8"
        output "Fedora: 28"
        output "CentOS: 7"
        output "RHEL: 7"
        exit 0
    fi
}

get_architecture(){
    output "Automatic Architecture Detection initialized."
    MACHINE_TYPE=`uname -m`
    if [ ${MACHINE_TYPE} == 'x86_64' ]; then
        output "64-bit server detected! Good to go."
        output ""
    else
        output "Unsupported architecture detected! Please switch to 64-bit (x86_64)."
        exit 0
    fi
}

get_virtualization(){
    output "Automatic Virtualization Detection initialized."
    if [ "$lsb_dist" =  "ubuntu" ]; then
        apt-get update --fix-missing
        apt-get -y install software-properties-common
        add-apt-repository -y universe
        apt-get -y install virt-what
    elif [ "$lsb_dist" =  "debian" ]; then
        apt update --fix-missing
        apt-get -y install software-properties-common
        apt-get -y install virt-what
    elif [ "$lsb_dist" =  "fedora" ] || [ "$lsb_dist" =  "centos" ] || [ "$lsb_dist" =  "rhel" ]; then
        yum -y install virt-what
    fi
    virt_serv=$(virt-what)
    if [ "$virt_serv" = "" ]; then
        output "Virtualization: Bare Metal detected."
    else
        output "Virtualization: $virt_serv detected."
    fi
    output ""
    if [ "$virt_serv" != "" ] && [ "$virt_serv" != "kvm" ] && [ "$virt_serv" != "vmware" ] && [ "$virt_serv" != "hyperv" ]; then
        output "Unsupported Virtualization method. Please consult with your provider whether your server can run Docker or not. Proceed at your own risk."
        output "Proceed?\n[1] Yes.\n[2] No."
        read choice
        case $choice in 
            1)  output "Proceeding..."
                ;;
            2)  output "Cancelling installation..."
                exit 0
                ;;
        esac
        output ""
    fi
}

server_options() {
    output "Please select what you would like to install:\n[1] Install panel (v0.7.15).\n[2] Install daemon (v0.6.12).\n[3] Install the panel and daemon.\n[4] Upgrade 0.7.x panel to 0.7.15.\n[5] Upgrade 0.6.x daemon to 0.6.12.\n[6] Install the standalone SFTP server (Only use this after you have installed and configured the daemon. Ubuntu 14.04 is NOT supported.)\n[7] Emergency MariaDB root password reset."
    read choice
    case $choice in
        1 ) installoption=1
            output "You have selected panel installation only."
            ;;
        2 ) installoption=2
            output "You have selected daemon installation only."
            ;;
        3 ) installoption=3
            output "You have selected panel and daemon installation."
            ;;
        4 ) installoption=4
            output "You have selected to upgrade the panel."
            ;;
        5 ) installoption=5
            output "You have selected to upgrade the daemon."
            ;;
        6 ) installoption=6
            output "You have selected to install the standalone SFTP server."
            ;;
        7 ) installoption=7
            output "You have selected MariaDB root password reset."
            ;;
        * ) output "You did not enter a a valid selection."
            server_options
    esac
}   

webserver_options() {
    output "Please select which web server you would like to use:\n[1] Nginx (Recommended).\n[2] Apache2/Httpd."
    read choice
    case $choice in
        1 ) webserver=1
            output "You have selected Nginx."
            ;;
        2 ) webserver=2
            output "You have selected Apache2 / Httpd."
            ;;
        * ) output "You did not enter a valid selection."
            webserver_options
    esac
}

theme_options() {
    output "Would you like to install Fonix's themes? :\n[1] No.\n[2] Graphite theme.\n[3] Midnight theme."
    output "You can find out about Fonix's themes here: https://github.com/TheFonix/Pterodactyl-Themes"
    read choice
    case $choice in
        1 ) themeoption=1
            output "You have selected to install vanilla Pterodactyl theme."
            ;;
        2 ) themeoption=2
            output "You have selected to install Fonix's Graphite theme."
            ;;
        3 ) themeoption=3
            output "You have selected panel and Fonix's Midnight theme."
            ;;
        * ) output "You did not enter a a valid selection"
            theme_options
    esac
}   

required_infos() {
    output "Please enter your FQDN (panel.yourdomain.com):"
    read FQDN

    output "Please enter the desired user email address:"
    read email
}

theme() {
    output "Theme installation initialized."
    cd /var/www/pterodactyl
    if [ "$themeoption" = "1" ]; then
        output "Keeping Pterodactyl's vanilla theme."
    elif [ "$themeoption" = "2" ]; then
        curl https://raw.githubusercontent.com/TheFonix/Pterodactyl-Themes/master/Pterodactyl-7/Graphite/build.sh | sh    
    elif [ "$themeoption" = "3" ]; then
        curl https://raw.githubusercontent.com/TheFonix/Pterodactyl-Themes/master/Pterodactyl-7/Midnight/build.sh | sh
    fi
}

repositories_setup(){
    output "Configuring your repositories."
    if [ "$lsb_dist" =  "ubuntu" ] || [ "$lsb_dist" =  "debian" ]; then
        apt-get -y install sudo
        echo 'Acquire::ForceIPv4 "true";' | sudo tee /etc/apt/apt.conf.d/99force-ipv4
        apt-get -y update 
        if [ "$lsb_dist" =  "ubuntu" ]; then
            LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
            add-apt-repository -y ppa:chris-lea/redis-server
            add-apt-repository -y ppa:certbot/certbot
            if [ "$dist_version" = "18.10" ]; then
                apt-get install software-properties-common
                apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
                add-apt-repository 'deb [arch=amd64] http://nyc2.mirrors.digitalocean.com/mariadb/repo/10.3/ubuntu cosmic main'
            elif [ "$dist_version" = "18.04" ]; then
                add-apt-repository -y ppa:nginx/stable
                apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
                add-apt-repository -y 'deb [arch=amd64,arm64,ppc64el] http://nyc2.mirrors.digitalocean.com/mariadb/repo/10.3/ubuntu bionic main'
            elif [ "$dist_version" = "16.04" ]; then
                add-apt-repository -y ppa:nginx/stable
                apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
                add-apt-repository 'deb [arch=amd64,arm64,i386,ppc64el] http://nyc2.mirrors.digitalocean.com/mariadb/repo/10.3/ubuntu xenial main'
            elif [ "$dist_version" = "14.04" ]; then
                add-apt-repository -y ppa:ondrej/nginx
                apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
                add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://sfo1.mirrors.digitalocean.com/mariadb/repo/10.3/ubuntu trusty main'            
            fi
        elif [ "$lsb_dist" =  "debian" ]; then
            apt-get -y install ca-certificates apt-transport-https
            if [ "$dist_version" = "9" ]; then
                apt-get -y install software-properties-common dirmngr
                wget -q https://packages.sury.org/php/apt.gpg -O- | sudo apt-key add -
                sudo echo "deb https://packages.sury.org/php/ stretch main" | sudo tee /etc/apt/sources.list.d/php.list
                sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xF1656F24C74CD1D8
                sudo add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://nyc2.mirrors.digitalocean.com/mariadb/repo/10.3/debian stretch main'
            elif [ "$dist_version" = "8" ]; then
                apt-get -y install software-properties-common
                wget -q https://packages.sury.org/php/apt.gpg -O- | sudo apt-key add -
                echo "deb https://packages.sury.org/php/ jessie main" | sudo tee /etc/apt/sources.list.d/php.list
                apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db
                add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://nyc2.mirrors.digitalocean.com/mariadb/repo/10.3/debian jessie main'
            fi
        fi
        apt-get -y update 
        apt-get -y upgrade
        apt-get -y autoremove
        apt-get -y autoclean   
    elif  [ "$lsb_dist" =  "fedora" ] || [ "$lsb_dist" =  "centos" ] || [ "$lsb_dist" =  "rhel" ]; then
        if  [ "$lsb_dist" =  "fedora" ] && [ "$dist_version" = "28" ]; then

            bash -c 'cat > /etc/yum.repos.d/mariadb.repo' <<-'EOF'
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.3/fedora28-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

bash -c 'cat > /etc/yum.repos.d/nginx.repo' <<-'EOF'
[heffer-nginx-mainline]
name=Copr repo for nginx-mainline owned by heffer
baseurl=https://copr-be.cloud.fedoraproject.org/results/heffer/nginx-mainline/fedora-$releasever-$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://copr-be.cloud.fedoraproject.org/results/heffer/nginx-mainline/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1
EOF

        elif  [ "$lsb_dist" =  "centos" ] && [ "$dist_version" = "7" ]; then

            bash -c 'cat > /etc/yum.repos.d/mariadb.repo' <<-'EOF'
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.3/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

            bash -c 'cat > /etc/yum.repos.d/nginx.repo' <<-'EOF'
[heffer-nginx-mainline]
name=Copr repo for nginx-mainline owned by heffer
baseurl=https://copr-be.cloud.fedoraproject.org/results/heffer/nginx-mainline/epel-7-$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://copr-be.cloud.fedoraproject.org/results/heffer/nginx-mainline/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1
EOF

            yum -y install epel-release
            yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
        elif  [ "$lsb_dist" =  "rhel" ]; then
            
            bash -c 'cat > /etc/yum.repos.d/mariadb.repo' <<-'EOF'        
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.3/rhel7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

            bash -c 'cat > /etc/yum.repos.d/nginx.repo' <<-'EOF'
[heffer-nginx-mainline]
name=Copr repo for nginx-mainline owned by heffer
baseurl=https://copr-be.cloud.fedoraproject.org/results/heffer/nginx-mainline/epel-7-$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://copr-be.cloud.fedoraproject.org/results/heffer/nginx-mainline/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1
EOF
            yum -y install epel-release
            yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
        fi
        yum -y install yum-utils
        yum-config-manager --enable remi-php72
        yum -y upgrade
        yum -y autoremove
        yum -y clean packages
    fi
}

install_dependencies(){
    output "Installing dependencies."
    if  [ "$lsb_dist" =  "ubuntu" ] ||  [ "$lsb_dist" =  "debian" ]; then
        if [ "$webserver" = "1" ]; then
            apt-get -y install php7.2 php7.2-cli php7.2-gd php7.2-mysql php7.2-pdo php7.2-mbstring php7.2-tokenizer php7.2-bcmath php7.2-xml php7.2-fpm php7.2-curl php7.2-zip curl tar unzip git redis-server nginx git wget
        elif [ "$webserver" = "2" ]; then
            apt-get -y install php7.2 php7.2-cli php7.2-gd php7.2-mysql php7.2-pdo php7.2-mbstring php7.2-tokenizer php7.2-bcmath php7.2-xml php7.2-fpm php7.2-curl php7.2-zip curl tar unzip git redis-server apache2 libapache2-mod-php7.2 redis-server git wget
        fi
        sh -c "DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server"
    elif [ "$lsb_dist" =  "fedora" ] ||  [ "$lsb_dist" =  "centos" ] ||  [ "$lsb_dist" =  "rhel" ]; then
        if [ "$webserver" = "1" ]; then
            yum -y install php php-common php-fpm php-cli php-json php-mysqlnd php-mcrypt php-gd php-mbstring php-pdo php-zip php-bcmath php-dom php-opcache mariadb-server redis cronie nginx git policycoreutils-python-utils libsemanage-devel unzip wget
        elif [ "$webserver" = "2" ]; then
            yum -y install php php-common php-fpm php-cli php-json php-mysqlnd php-mcrypt php-gd php-mbstring php-pdo php-zip php-bcmath php-dom php-opcache mariadb-server redis cronie httpd git policycoreutils-python-utils libsemanage-devel mod_ssl unzip wget
        fi
    fi

    output "Enabling Services."
    systemctl enable php-fpm
    systemctl enable php7.2-fpm
    if [ "$webserver" = "1" ]; then
        systemctl enable nginx
    elif [ "$webserver" = "2" ]; then
        systemctl enable apache2
        systemctl enable httpd
    fi

    if [ "$lsb_dist" =  "ubuntu" ] || [ "$lsb_dist" =  "debian" ]; then
    systemctl enable redis-server
    else 
    systemctl enable redis
    fi
    
    systemctl enable cron
    systemctl enable mariadb
    service php-fpm start
    service php7.2-fpm start
    if [ "$webserver" = "1" ]; then
        service nginx start
    elif [ "$webserver" = "2" ]; then
        service apache2 start
        service httpd start
    fi
    service redis start
    service cron start
    service mariadb start
}

pterodactyl_queue(){
    if [ "$lsb_dist" =  "ubuntu" ] && [ "$dist_version" = "14.04" ]; then
        apt -y install supervisor
        service supervisor start
        sudo bash -c 'cat > /etc/supervisor/conf.d/pterodactyl-worker.conf' <<-'EOF'
[program:pterodactyl-worker]
process_name=%(program_name)s_%(process_num)02d
command=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
autostart=true
autorestart=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/www/pterodactyl/storage/logs/queue-worker.log
EOF
        output "Updating Supervisor"
        supervisorctl reread
        supervisorctl update
        supervisorctl start pterodactyl-worker:*
        sed -i -e '$i \service supervisor start\n' /etc/rc.local    
    elif  [ "$lsb_dist" =  "ubuntu" ] ||  [ "$lsb_dist" =  "debian" ]; then
        cat > /etc/systemd/system/pteroq.service <<- 'EOF'
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3

[Install]
WantedBy=multi-user.target
EOF
    elif  [ "$lsb_dist" =  "fedora" ] ||  [ "$lsb_dist" =  "centos" ] ||  [ "$lsb_dist" =  "rhel" ]; then
        if [ "$webserver" = "1" ]; then
            cat > /etc/systemd/system/pteroq.service <<- 'EOF'
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=nginx
Group=nginx
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3

[Install]
WantedBy=multi-user.target
EOF
        elif [ "$webserver" = "2" ]; then
            cat > /etc/systemd/system/pteroq.service <<- 'EOF'
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=apache
Group=apache
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3

[Install]
WantedBy=multi-user.target
EOF
        fi
    fi
    sudo systemctl daemon-reload
    systemctl enable pteroq.service
    systemctl start pteroq
}

install_pterodactyl() {
    output "Creating the databases and setting root password"
    password=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    rootpassword=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    Q1="CREATE DATABASE IF NOT EXISTS panel;"
    Q2="GRANT ALL ON panel.* TO 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '$password';"
    Q3="SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$rootpassword');"
    Q4="SET PASSWORD FOR 'root'@'127.0.0.1' = PASSWORD('$rootpassword');"
    Q5="SET PASSWORD FOR 'root'@'::1' = PASSWORD('$rootpassword');"
    Q6="DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    Q7="DELETE FROM mysql.user WHERE User='';"
    Q8="DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';"
    Q9="FLUSH PRIVILEGES;"
    SQL="${Q1}${Q2}${Q3}${Q4}${Q5}${Q6}${Q7}${Q8}${Q9}"
    mysql -u root -e "$SQL"

    output "Downloading Pterodactyl."
    mkdir -p /var/www/pterodactyl
    cd /var/www/pterodactyl
    curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/download/v0.7.15/panel.tar.gz
    tar --strip-components=1 -xzvf panel.tar.gz
    chmod -R 755 storage/* bootstrap/cache/

    output "Installing Pterodactyl."
    curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
    cp .env.example .env
    if [ "$lsb_dist" =  "rhel" ]; then
        yum -y install composer
        composer update
    else
        composer install --no-dev --optimize-autoloader
    fi
    php artisan key:generate --force
    php artisan p:environment:setup --author=$email --url=https://$FQDN --timezone=America/New_York --cache=redis --session=database --queue=redis --disable-settings-ui --redis-host=127.0.0.1 --redis-pass= --redis-port=6379
    php artisan p:environment:database --host=127.0.0.1 --port=3306 --database=panel --username=pterodactyl --password=$password
    output "To use PHP's internal mail sending, select [mail]. To use a custom SMTP server, select [smtp]. TLS Encryption is recommended."
    php artisan p:environment:mail
    php artisan migrate --seed --force
    php artisan p:user:make --email=$email --admin=1
    chown -R www-data:www-data *
    chown -R nginx:nginx *
    chown -R apache:apache *
    chown -R apache:apache .*

    output "Creating panel queue listeners"
    (crontab -l ; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1")| crontab -
    service cron restart
}

upgrade_pterodactyl(){
    cd /var/www/pterodactyl
    php artisan down
    curl -L https://github.com/pterodactyl/panel/releases/download/v0.7.15/panel.tar.gz | tar --strip-components=1 -xzv
    unzip panel
    chmod -R 755 storage/* bootstrap/cache
    composer install --no-dev --optimize-autoloader
    php artisan view:clear
    php artisan migrate --force
    php artisan db:seed --force
    chown -R www-data:www-data *
    if [ "$lsb_dist" =  "fedora" ] || [ "$lsb_dist" =  "centos" ] || [ "$lsb_dist" =  "rhel" ]; then
    chown -R nginx:nginx $(pwd)
    semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/pterodactyl/storage(/.*)?"
    restorecon -R /var/www/pterodactyl
    fi
    output "Your panel has been updated to version 0.7.11."
    php artisan up
    php artisan queue:restart
}

webserver_config(){
    if  [ "$lsb_dist" =  "ubuntu" ] || [ "$lsb_dist" =  "debian" ]; then
        if [ "$webserver" = "1" ]; then
            nginx_config
        elif [ "$webserver" = "2" ]; then
            apache_config
        fi
    elif  [ "$lsb_dist" =  "fedora" ] ||  [ "$lsb_dist" =  "centos" ] ||  [ "$lsb_dist" =  "rhel" ]; then
        if [ "$webserver" = "1" ]; then
            php_config
            nginx_config_redhat
        elif [ "$webserver" = "2" ]; then
            apache_config_redhat
        fi
    fi
}

nginx_config() {
    output "Disabling default configuration"
    rm -rf /etc/nginx/sites-enabled/default
    output "Configuring Nginx Webserver"
    
echo '
server_tokens off;

server {
    listen 80;
    server_name '"$FQDN"';
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name '"$FQDN"';

    root /var/www/pterodactyl/public;
    index index.php;

    access_log /var/log/nginx/pterodactyl.app-access.log;
    error_log  /var/log/nginx/pterodactyl.app-error.log error;

    # allow larger file uploads and longer script runtimes
    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/'"$FQDN"'/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/'"$FQDN"'/privkey.pem;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2;
    ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256';
    ssl_prefer_server_ciphers on;

    # See https://hstspreload.org/ before uncommenting the line below.
    # add_header Strict-Transport-Security "max-age=15768000; preload;";
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header Content-Security-Policy "frame-ancestors 'self'";
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
        include /etc/nginx/fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
' | sudo -E tee /etc/nginx/sites-available/pterodactyl.conf >/dev/null 2>&1

    ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
    service nginx restart
}

apache_config() {
    output "Disabling default configuration"
    rm -rf /etc/nginx/sites-enabled/default
    output "Configuring Apache2"
echo '
<VirtualHost *:80> 
ServerName '"$FQDN"' 
RewriteEngine On
RewriteCond %{HTTPS} !=on
RewriteRule ^/?(.*) https://%{SERVER_NAME}/$1 [R,L]
</VirtualHost>

<VirtualHost *:443>
  DocumentRoot "/var/www/pterodactyl/public"
  AllowEncodedSlashes On
  php_value upload_max_filesize 100M
  php_value post_max_size 100M
  <Directory "/var/www/pterodactyl/public">
    AllowOverride all
  </Directory>

SSLEngine on
SSLCertificateFile /etc/letsencrypt/live/'"$FQDN"'/fullchain.pem
SSLCertificateKeyFile /etc/letsencrypt/live/'"$FQDN"'/privkey.pem
ServerName '"$FQDN"'
</VirtualHost>

' | sudo -E tee /etc/apache2/sites-available/pterodactyl.conf >/dev/null 2>&1
    
    ln -s /etc/apache2/sites-available/pterodactyl.conf /etc/apache2/sites-enabled/pterodactyl.conf
    a2enmod ssl
    a2enmod rewrite
    service apache2 restart
}

nginx_config_redhat(){
    output "Configuring Nginx Webserver"
    
echo '
server {
    listen 80;
    server_name '"$FQDN"';
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name '"$FQDN"';

    root /var/www/pterodactyl/public;
    index index.php;

    access_log /var/log/nginx/pterodactyl.app-access.log;
    error_log  /var/log/nginx/pterodactyl.app-error.log error;

    # allow larger file uploads and longer script runtimes
    client_max_body_size 100m;
    client_body_timeout 120s;
    
    sendfile off;

    # strengthen ssl security
    ssl_certificate /etc/letsencrypt/live/'"$FQDN"'/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/'"$FQDN"'/privkey.pem;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:ECDHE-RSA-AES128-GCM-SHA256:AES256+EECDH:DHE-RSA-AES128-GCM-SHA256:AES256+EDH:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4";
    
    # See the link below for more SSL information:
    #     https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html
    #
    # ssl_dhparam /etc/ssl/certs/dhparam.pem;

    # Add headers to serve security related headers
    add_header Strict-Transport-Security "max-age=15768000; preload;";
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header Content-Security-Policy "frame-ancestors 'self'";

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php-fpm/pterodactyl.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
        include /etc/nginx/fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
' | sudo -E tee /etc/nginx/conf.d/pterodactyl.conf >/dev/null 2>&1

    service nginx restart
    chown -R nginx:nginx $(pwd)
    semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/pterodactyl/storage(/.*)?"
    restorecon -R /var/www/pterodactyl
}

apache_config_redhat() {
    output "Configuring Apache2"
echo '
<VirtualHost *:80> 
ServerName '"$FQDN"' 
RewriteEngine On
RewriteCond %{HTTPS} !=on
RewriteRule ^/?(.*) https://%{SERVER_NAME}/$1 [R,L]
</VirtualHost>

<VirtualHost *:443>
  DocumentRoot "/var/www/pterodactyl/public"
  AllowEncodedSlashes On
  <Directory "/var/www/pterodactyl/public">
    AllowOverride all
  </Directory>

SSLEngine on
SSLCertificateFile /etc/letsencrypt/live/'"$FQDN"'/fullchain.pem
SSLCertificateKeyFile /etc/letsencrypt/live/'"$FQDN"'/privkey.pem
ServerName '"$FQDN"'
</VirtualHost>

' | sudo -E tee /etc/httpd/conf.d/pterodactyl.conf >/dev/null 2>&1
    service httpd restart
}

php_config(){
    output "Configuring PHP socket."
    bash -c 'cat > /etc/php-fpm.d/www-pterodactyl.conf' <<-'EOF'
[pterodactyl]

user = nginx
group = nginx

listen = /var/run/php-fpm/pterodactyl.sock
listen.owner = nginx
listen.group = nginx
listen.mode = 0750

pm = ondemand
pm.max_children = 9
pm.process_idle_timeout = 10s
pm.max_requests = 200
EOF
    systemctl restart php-fpm
}

install_daemon() {
    cd /root
    output "Installing Pterodactyl Daemon dependencies."
    if  [ "$lsb_dist" =  "ubuntu" ] ||  [ "$lsb_dist" =  "debian" ]; then
        apt-get -y install curl tar unzip
    elif  [ "$lsb_dist" =  "fedora" ] ||  [ "$lsb_dist" =  "centos" ] ||  [ "$lsb_dist" =  "rhel" ]; then
        yum -y install curl tar unzip
    fi
    output "Installing Docker"
    curl -sSL https://get.docker.com/ | CHANNEL=stable bash
    systemctl enable docker
    systemctl start docker
    output "Enabling Swap support for Docker & Installing NodeJS."
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& swapaccount=1/' /etc/default/grub
    if  [ "$lsb_dist" =  "ubuntu" ] ||  [ "$lsb_dist" =  "debian" ]; then
        sudo update-grub
        curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
        apt -y install nodejs make gcc g++ node-gyp
        apt-get -y update 
        apt-get -y upgrade
        apt-get -y autoremove
        apt-get -y autoclean
    elif  [ "$lsb_dist" =  "fedora" ] ||  [ "$lsb_dist" =  "centos" ] ||  [ "$lsb_dist" =  "rhel" ]; then
        grub2-mkconfig -o "$(readlink /etc/grub2.conf)"
        curl --silent --location https://rpm.nodesource.com/setup_10.x | sudo bash -
        yum -y install nodejs gcc-c++ make
        yum -y upgrade
        yum -y autoremove
        yum -y clean packages
    fi
    output "Installing the Pterodactyl Daemon."
    mkdir -p /srv/daemon /srv/daemon-data
    cd /srv/daemon
    curl -L https://github.com/pterodactyl/daemon/releases/download/v0.6.12/daemon.tar.gz | tar --strip-components=1 -xzv
    npm install --only=production
    if [ "$lsb_dist" =  "ubuntu" ] && [ "$dist_version" = "14.04" ]; then
        npm install -g forever
    else
        bash -c 'cat > /etc/systemd/system/wings.service' <<-'EOF'
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service

[Service]
User=root
#Group=some_group
WorkingDirectory=/srv/daemon
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/bin/node /srv/daemon/src/index.js
Restart=on-failure
StartLimitInterval=600

[Install]
WantedBy=multi-user.target
EOF

        systemctl daemon-reload
        systemctl enable wings
    fi
    if [ "$lsb_dist" =  "debian" ] && [ "$dist_version" = "8" ]; then
        kernel_modifications_d8
    fi
}

upgrade_daemon(){
    cd /srv/daemon
    if [ "$lsb_dist" =  "ubuntu" ] && [ "$dist_version" = "14.04" ]; then
        forever stop src/index.js
    else
    service wings stop
    fi
    curl -L https://github.com/pterodactyl/daemon/releases/download/v0.6.12/daemon.tar.gz | tar --strip-components=1 -xzv
    npm update --only=production
    if [ "$lsb_dist" =  "ubuntu" ] && [ "$dist_version" = "14.04" ]; then
        forever start src/index.js
    else
    service wings restart
    fi
    output "Your daemon has been updated to version 0.6.7."
}

install_standalone_sftp(){
    cd /srv/daemon
    output "Disabling default SFTP server."
    sed -i '/"port": 2022,/a        "enabled": false,' /srv/daemon/config/core.json
    service wings restart
    output "Installing standalone SFTP server."
    curl -Lo sftp-server https://github.com/pterodactyl/sftp-server/releases/download/v1.0.1/sftp-server
    chmod +x sftp-server
    bash -c 'cat > /etc/systemd/system/pterosftp.service' <<-'EOF'
[Unit]
Description=Pterodactyl Standalone SFTP Server
After=wings.service

[Service]
User=root
WorkingDirectory=/srv/daemon
LimitNOFILE=4096
PIDFile=/var/run/wings/sftp.pid
ExecStart=/srv/daemon/sftp-server
Restart=on-failure
StartLimitInterval=600

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable --now pterosftp
    service pterosftp restart
}

kernel_modifications_d8(){
    output "Modifying Grub."
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& cgroup_enable=memory/' /etc/default/grub  
    output "Adding backport repositories." 
    echo deb http://http.debian.net/debian jessie-backports main > /etc/apt/sources.list.d/jessie-backports.list
    echo deb http://http.debian.net/debian jessie-backports main contrib non-free > /etc/apt/sources.list.d/jessie-backports.list
    output "Updating Server Packages."
    apt-get -y update
    apt-get -y upgrade
    apt-get -y autoremove
    apt-get -y autoclean
    output"Installing new kernel"
    apt install -t jessie-backports linux-image-4.9.0-0.bpo.7-amd64
    output "Modifying Docker."
    sed -i 's,/usr/bin/dockerd,/usr/bin/dockerd --storage-driver=overlay2,g' /lib/systemd/system/docker.service
    systemctl daemon-reload
    service docker start
}

ssl_certs(){
    output "Installing LetsEncrypt and creating an SSL certificate."
    if  [ "$lsb_dist" =  "ubuntu" ] || [ "$lsb_dist" =  "debian" ]; then
        apt-get -y install certbot
    elif [ "$lsb_dist" =  "fedora" ] || [ "$lsb_dist" =  "centos" ] ||  [ "$lsb_dist" =  "rhel" ]; then
        yum -y install certbot
    fi
    if  [ "$lsb_dist" =  "ubuntu" ] || [ "$lsb_dist" =  "debian" ]; then
        ufw disable
    elif  [ "$lsb_dist" =  "fedora" ] || [ "$lsb_dist" =  "centos" ] ||  [ "$lsb_dist" =  "rhel" ]; then
        service firewalld stop
    fi
    service nginx stop
    service apache2 stop
    service httpd stop
    certbot certonly --standalone --email "$email" --agree-tos -d "$FQDN" --non-interactive
    ufw --force enable
    service firewalld restart
    service nginx restart
    service apache2 restart
    service httpd restart
}

firewall(){
    rm -rf /etc/rc.local
    printf '%s\n' '#!/bin/bash' 'exit 0' | sudo tee -a /etc/rc.local
    chmod +x /etc/rc.local

    iptables -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP
    iptables -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP
    iptables -t mangle -A PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP
    iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP 
    iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP 
    iptables -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j DROP 
    iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j DROP 
    iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j DROP 
    iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,URG URG -j DROP 
    iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,FIN FIN -j DROP 
    iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j DROP 
    iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL ALL -j DROP 
    iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP 
    iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP 
    iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP 
    iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
    iptables -t mangle -A PREROUTING -p icmp -j DROP
    iptables -A INPUT -p tcp -m connlimit --connlimit-above 80 --connlimit-mask 32 --connlimit-saddr -j REJECT --reject-with tcp-reset
    iptables -t mangle -A PREROUTING -f -j DROP
    /sbin/iptables -A INPUT -p tcp --dport ssh -m conntrack --ctstate NEW -m recent --set 
    /sbin/iptables -A INPUT -p tcp --dport ssh -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 10 -j DROP
    /sbin/iptables -N port-scanning 
    /sbin/iptables -A port-scanning -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN 
    /sbin/iptables -A port-scanning -j DROP  
    sh -c "iptables-save > /etc/iptables.conf"
    sed -i -e '$i \iptables-restore < /etc/iptables.conf\n' /etc/rc.local

    output "Configuring your firewall."
    if [ "$lsb_dist" =  "ubuntu" ] || [ "$lsb_dist" =  "debian" ]; then
        apt-get -y install ufw
        ufw allow 22
        if [ "$installoption" = "1" ]; then
            ufw allow 80
            ufw allow 443
        elif [ "$installoption" = "2" ]; then
            ufw allow 8080
            ufw allow 2022
        elif [ "$installoption" = "3" ]; then
            ufw allow 80
            ufw allow 443
            ufw allow 8080
            ufw allow 2022
        fi
        ufw --force enable
    elif [ "$lsb_dist" =  "centos" ] || [ "$lsb_dist" =  "fedora" ] ||  [ "$lsb_dist" =  "rhel" ]; then
        yum -y install firewalld
        systemctl enable firewalld
        systemctl start firewalld
        if [ "$installoption" = "1" ]; then
            firewall-cmd --add-service=http --permanent
            firewall-cmd --add-service=https --permanent 
        elif [ "$installoption" = "2" ]; then
            firewall-cmd --permanent --add-port=2022/tcp
            firewall-cmd --permanent --add-port=8080/tcp
        elif [ "$installoption" = "3" ]; then
            firewall-cmd --add-service=http --permanent
            firewall-cmd --add-service=https --permanent 
            firewall-cmd --permanent --add-port=2022/tcp
            firewall-cmd --permanent --add-port=8080/tcp
        fi
        firewall-cmd --reload
    fi
}

mariadb_root_reset(){
    service mariadb stop
    mysqld_safe --skip-grant-tables >res 2>&1 &
    sleep 5
    rootpassword=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    Q1="UPDATE user SET plugin='';"
    Q2="UPDATE user SET password=PASSWORD('$rootpassword') WHERE user='root';"
    Q3="FLUSH PRIVILEGES;"
    SQL="${Q1}${Q2}${Q3}"
    mysql mysql -e "$SQL"
    pkill mysqld
    service mariadb restart
    output "Your MariaDB root password is $rootpassword"
}

broadcast(){
    if [ "$installoption" = "1" ] || [ "$installoption" = "3" ]; then
        output "Your MariaDB root password is $rootpassword"
    fi
    output "All unnecessary ports are blocked by default."
    if [ "$lsb_dist" =  "ubuntu" ] || [ "$lsb_dist" =  "debian" ]; then
        output "Use 'ufw enable <port>' to enable your desired ports"
    elif [ "$lsb_dist" =  "fedora" ] || [ "$lsb_dist" =  "centos" ] ||  [ "$lsb_dist" =  "rhel" ]; then
        output "Use 'firewall-cmd --permanent --add-port=<port>/tcp' to enable your desired ports."
        semanage permissive -a httpd_t
    fi
}

broadcast_daemon(){
    output "Installation completed. Please configure the daemon. "
    output "The guide for daemon configuration can be founded here: https://pterodactyl.io/daemon/installing.html#configure-daemon"   
    if [ "$lsb_dist" =  "ubuntu" ] && [ "$dist_version" = "14.04" ]; then
        output "Please run 'forever start src/index.js' after the configuration process is finished."
    else
        output "Please run 'service wings restart' after the configuration."  
        if [ "$lsb_dist" =  "debian" ] && [ "$dist_version" = "8" ]; then
            output "Please restart the server after you have configured the daemon to apply the necessary kernel changes on Debian 8."
        fi
    fi
                          
}

#Execution
copyright
get_distribution
get_architecture
server_options
case $installoption in 
    1)  get_virtualization
        webserver_options
        theme_options
        required_infos
        repositories_setup
        firewall
        install_dependencies
        install_pterodactyl
        pterodactyl_queue
        ssl_certs
        webserver_config
        theme
        broadcast
        ;;
    2)  required_infos
        repositories_setup
        firewall
        ssl_certs
        install_daemon
        broadcast
        broadcast_daemon
        ;;
    3)  get_virtualization
        webserver_options
        theme_options
        required_infos
        repositories_setup
        firewall
        install_dependencies
        install_pterodactyl
        pterodactyl_queue
        ssl_certs
        webserver_config
        theme
        install_daemon
        broadcast
        broadcast_daemon
        ;;
    4)  theme_options
        upgrade_pterodactyl
        theme
        ;;
    5)  upgrade_daemon
        ;;
    6)  install_standalone_sftp
        ;;
    7 ) mariadb_root_reset
        ;;
esac
