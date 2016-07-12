FROM ubuntu:16.04
MAINTAINER Robin Andrew <randrew@christian-aid.org>
ENV DEBIAN_FRONTEND noninteractive

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 4F4EA0AAE5267A6C

RUN apt-get update
RUN apt-get -y install software-properties-common

# Repositories for git and Apache2 with HTTP/2
# HTTP/2 N/A in LTS build of Apache https://bugs.launchpad.net/ubuntu-release-notes/+bug/1531864
RUN add-apt-repository ppa:ondrej/apache2 && \
    add-apt-repository ppa:git-core/ppa

RUN apt-get update && \
    apt-get -y upgrade

# I/O, Network Other useful troubleshooting tools, see: http://www.linuxjournal.com/magazine/hack-and-linux-troubleshooting-part-i-high-load
RUN apt-get -y install wget nano vim sysstat iotop htop ethtool nmap dnsutils traceroute

# Install MariaDb
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
RUN add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://lon1.mirrors.digitalocean.com/mariadb/repo/10.1/ubuntu xenial main'
RUN apt-get -y --quiet update
RUN apt-get -y --quiet install mariadb-server mariadb-client

RUN apt-get update && \
    apt-get -y upgrade
# Server software and PHP 7.0
RUN apt-get -y install curl apache2 supervisor openssh-client make libpcre3-dev git
RUN apt-get -y install php php-fpm php-gd php-mysql php-curl php-cli php-common libapache2-mod-php php-dev php-mbstring

RUN apt-get -y install bash-completion zip

# Install cURL with HTTP/2 support
RUN apt-get -y install g++ make binutils autoconf automake \
    autotools-dev libtool pkg-config zlib1g-dev libcunit1-dev libssl-dev libxml2-dev libev-dev libevent-dev \
    libjansson-dev libjemalloc-dev cython python3-dev python-setuptools
RUN wget https://github.com/tatsuhiro-t/nghttp2/releases/download/v1.9.1/nghttp2-1.9.1.tar.gz && \
    tar -xvf nghttp2-1.9.1.tar.gz && \
    cd nghttp2-1.9.1/ && \
    autoreconf -i && \
    automake && \
    autoconf && \
    ./configure && \
    make && \
    make install && \
    cd .. && rm -Rf nghttp2-1.9.1 nghttp2-1.9.1.tar.gz

# Install cURL with HTTP/2 support
RUN wget http://curl.haxx.se/download/curl-7.48.0.tar.gz && \
    tar -xvf curl-7.48.0.tar.gz && \
    cd curl-7.48.0 && \
    ./configure --with-nghttp2=/usr/local --with-ssl && \
    make && \
    make install && \
    cd .. && rm -Rf curl-7.48.0 curl-7.48.0.tar.gz

# Add ubuntu user.
RUN useradd -ms /bin/bash ubuntu

# Configure Apache
COPY default.conf /etc/apache2/sites-available/default.conf
COPY default-ssl.conf /etc/apache2/sites-available/default-ssl.conf
RUN a2enmod rewrite ssl && \
    a2dissite 000-default && \
    a2ensite default default-ssl

RUN mkdir /var/www/html/_www
COPY index.php /var/www/html/_www/index.php

# Disable all Apache modules (need to disable specific ones first to avoid error codes)
RUN printf "*" | a2dismod -f
# Only enable essential Apache modules.
RUN a2enmod access_compat actions alias authz_host filter deflate dir expires headers mime setenvif rewrite socache_shmcb ssl mpm_event proxy_fcgi http2

RUN sed -i "s/listen =.*/listen = 127.0.0.1:9000/" /etc/php/7.0/fpm/pool.d/www.conf

# Allow for Overrides in path /var/www/
RUN sed -i '166s/None/All/' /etc/apache2/apache2.conf && \
    echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
    echo "ServerSignature Off" >> /etc/apache2/apache2.conf && \
    echo "ServerTokens Prod" >> /etc/apache2/apache2.conf

# Install Google Page Speed for Apache
RUN wget https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_amd64.deb && \
    dpkg -i mod-pagespeed-stable_current_amd64.deb && \
    rm mod-pagespeed-stable_current_amd64.deb

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

#Set Composer Paths
RUN export PATH="/home/ubuntu/.composer/vendor/bin:$PATH"
RUN echo "export PATH=\"/home/ubuntu/.composer/vendor/bin:$PATH\"" >> ~/.bashrc

# Install Drush 8.
RUN su -c "composer global require drush/drush:8.*" -s /bin/sh ubuntu
RUN su -c "composer global update" -s /bin/sh ubuntu
RUN ln -sf /home/ubuntu/.composer/vendor/bin/drush /usr/bin/drush

#Install Drupal Console
RUN curl https://drupalconsole.com/installer -L -o drupal.phar
RUN mv drupal.phar /usr/local/bin/drupal
RUN chmod +x /usr/local/bin/drupal


# Install Twig C extension.
#RUN wget https://github.com/twigphp/Twig/archive/v1.23.1.tar.gz && \
#    tar zxvf v1.23.1.tar.gz && \
#    rm v1.23.1.tar.gz && \
#    cd Twig-1.23.1/ext/twig/ && \
#    phpize && \
#    ./configure && \
#    make && \
#    make install
#COPY twig.ini /etc/php/7.0/fpm/conf.d/20-twig.ini

RUN wget -O /var/www/opcache.php https://raw.githubusercontent.com/rlerdorf/opcache-status/master/opcache.php

# Add tools installed via composer to PATH and Drupal logs to syslog
RUN echo "export PATH=/home/ubuntu/.composer/vendor/bin:$PATH" >> /etc/bash.bashrc && \
    echo "local0.* /var/log/drupal.log" >> /etc/rsyslog.conf

# Production PHP settings.
RUN sed -ri 's/^;opcache.enable=0/opcache.enable=1/g' /etc/php/7.0/fpm/php.ini && \
    sed -ri 's/^;error_log\s*=\s*syslog/error_log = syslog/g' /etc/php/7.0/fpm/php.ini && \
    sed -ri 's/^short_open_tag\s*=\s*On/short_open_tag = Off/g' /etc/php/7.0/fpm/php.ini && \
    sed -ri 's/^memory_limit\s*=\s*128M/memory_limit = 256M/g' /etc/php/7.0/fpm/php.ini && \
    sed -ri 's/^expose_php\s*=\s*On/expose_php = Off/g' /etc/php/7.0/fpm/php.ini && \
    sed -ri 's/^;date.timezone\s*=/date.timezone = "Europe\/London"/g' /etc/php/7.0/fpm/php.ini && \
    sed -ri 's/^;error_log\s*=\s*syslog/error_log = syslog/g' /etc/php/7.0/cli/php.ini

# Enable bash and git completion in interactive shells
RUN sed -ri '32,38 s/^#//' /etc/bash.bashrc && \
    /bin/bash -c "source /usr/share/bash-completion/completions/git"

# Configurations for bash.
RUN echo "export TERM=xterm" >> /etc/bash.bashrc

RUN mkdir -p /var/www/log && \
    ln -s /var/log/apache2/error.log /var/www/log/ && \
    ln -s /var/log/apache2/access.log /var/www/log/ && \
    ln -s /var/log/drupal.log /var/www/log/ && \
    ln -s /var/log/syslog /var/www/log/

# Install Redis
RUN apt-get -y install tcl8.6
RUN wget http://download.redis.io/releases/redis-stable.tar.gz && \
    tar xvzf redis-stable.tar.gz && \
    rm redis-stable.tar.gz && \
    cd redis-stable && \
    make && \
    make test && \
    make install && \
    cp redis.conf /etc/redis.conf && \
    rm -Rf ../redis-stable && \
    mkdir /var/log/redis

# igbinary doesn't pass tests yet: https://github.com/igbinary/igbinary7
#RUN wget https://github.com/igbinary/igbinary7/archive/master.tar.gz && \
#    tar zxvf master.tar.gz && \
#    rm -f master.tar.gz && \
#    cd igbinary7-master && \
#    phpize && \
#    ./configure CFLAGS="-O2 -g" --enable-igbinary && \
#     make && \
#     make test && \
#     make install && \
#     rm -Rf ../igbinary7-master

# Configure with igbinary when available for PHP 7.0: https://github.com/igbinary/igbinary
#   ./configure --enable-redis-igbinary
# Currently using php7 branch (no tags). Should change to stable tag when available.
RUN wget https://github.com/phpredis/phpredis/archive/php7.tar.gz && \
    tar zxvf php7.tar.gz && \
    rm -Rf php7.tar.gz && \
    cd phpredis-php7/ && \
    phpize && \
    ./configure && \
    make && \
    make install && \
    rm -Rf ../phpredis-php7

COPY redis.ini /etc/php/mods-available/redis.ini
RUN ln -s /etc/php/mods-available/redis.ini /etc/php/7.0/fpm/conf.d/20-redis.ini

# Activate globstar for bash and add alias to tail log files.
RUN echo "alias taillog='tail -f /var/www/log/syslog /var/log/redis/stderr.log /var/www/log/*.log'" >> /home/ubuntu/.bash_aliases && \
    echo "shopt -s globstar" >> /home/ubuntu/.bashrc

# Set user ownership
RUN ln -s /var/www /home/ubuntu/www && \
    chown -R ubuntu:ubuntu /home/ubuntu/ /home/ubuntu/.*

# Supervisor
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN service apache2 restart
RUN service php7.0-fpm start

COPY run.sh /usr/local/bin/run
RUN chmod +x /usr/local/bin/run

# Clean-up installation.
RUN apt-get -y autoclean && \
    apt-get -y autoremove

EXPOSE 80 443

ENTRYPOINT ["/usr/local/bin/run"]
