FROM ubuntu:18.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y
RUN apt-get upgrade -y

# server
RUN apt-get install -y apache2

# php 7.4
RUN apt -y install software-properties-common
RUN add-apt-repository ppa:ondrej/php
RUN apt-get update
RUN apt -y install php7.4
RUN apt-get -y install php7.4-dev
RUN apt-get -y install php7.4-mysql
RUN apt-get -y install php7.4-curl
RUN apt-get -y install php7.4-json
RUN apt-get -y install php7.4-common
RUN apt-get -y install php7.4-mbstring

# make apache understand php
RUN apt-get install -y libapache2-mod-php

# composer
RUN apt-get install -y composer
RUN composer --version

# npm, node
ENV NODE_VERSION=14.15.0
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.36.0/install.sh | bash
ENV NVM_DIR=/root/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"
RUN node --version
RUN npm --version

# misc
RUN apt-get update
RUN apt-get install -y wget
RUN apt-get install -y zip
RUN apt-get install -y unzip

# TODO: install PHP 7.3, NOT PHP 7.2. Anything lower than 7.3 is unacceptable
#RUN apt-get install -y php 
#RUN apt-get install -y php-dev 
#RUN apt-get install -y php-mysql 
#RUN apt-get install -y libapache2-mod-php 
#RUN apt-get install -y php-curl 
#RUN apt-get install -y php-json 
#RUN apt-get install -y php-common 
#RUN apt-get install -y php-mbstring 
#RUN apt-get install -y composer
#RUN curl -s "https://packagecloud.io/install/repositories/phalcon/stable/script.deb.sh" | /bin/bash
#RUN apt-get install -y software-properties-common
#RUN apt install -y php7.4
#RUN apt-get install -y php 7.2-phalcon
#COPY ../server/php.ini /etc/php/7.2/apache2/php.ini .........safe to ignore for now - only need it if we need to pre-set a php setting................

# set up virtual host in docker container
COPY ./server/vhost.conf /etc/apache2/sites-available/vhost.conf
#COPY ./server/apache2.conf /etc/apache2/apache2.conf .........probably will always stick to defaults for this one..............
RUN rm -rfv /etc/apache2/sites-enabled/*.conf
RUN ln -s /etc/apache2/sites-available/vhost.conf /etc/apache2/sites-enabled/vhost.conf

# copy laravel project
RUN mkdir /var/www/html/laravel-project
COPY . /var/www/html/laravel-project/
COPY ./server/.env /var/www/html/laravel-project/

# get composer
RUN chmod +x /var/www/html/laravel-project/server/getcomposer.sh
RUN /var/www/html/laravel-project/server/getcomposer.sh

# navigate to and compile project
WORKDIR /var/www/html/laravel-project
RUN composer update
RUN composer install
RUN npm install

# TODO: set up Laravel folder permissions correctly
# see: https://stackoverflow.com/q/30639174
RUN chown -R root:www-data /var/www/html/laravel-project
RUN find /var/www/html/laravel-project -type f -exec chmod 664 {} \;    
RUN find /var/www/html/laravel-project -type d -exec chmod 775 {} \;
RUN chgrp -R www-data storage bootstrap/cache
RUN chmod -R ug+rwx storage bootstrap/cache

# compile ui, gen key, and migrate
RUN npm rebuild
RUN npm run dev
RUN php artisan key:generate
#RUN php artisan migrate:fresh --seed   <--- requires the docker containers to be up and running

# allow execute on shell script
RUN chmod +x /var/www/html/laravel-project/server/init.sh

# run container
ENTRYPOINT ["/var/www/html/laravel-project/server/init.sh"]
RUN a2dissite 000-default.conf
RUN a2ensite vhost.conf
RUN a2enmod rewrite
RUN service apache2 restart
EXPOSE 80
EXPOSE 443