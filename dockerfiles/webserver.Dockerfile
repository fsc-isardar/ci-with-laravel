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

@todo FIX !
~~~~> PROBLEM: both Jenkins and this DockerFile are COPYing the project to the server in different places !!!

# set up virtual host in docker container
COPY ./server/vhost.conf /etc/apache2/sites-available/vhost.conf
#COPY ./server/apache2.conf /etc/apache2/apache2.conf .........probably will always stick to defaults for this one..............
RUN rm -rfv /etc/apache2/sites-enabled/*.conf
RUN ln -s /etc/apache2/sites-available/vhost.conf /etc/apache2/sites-enabled/vhost.conf

# copy laravel project
COPY . /var/www/html/laravel-project
#COPY ./server/.env /var/www/html/laravel-project

# get composer
RUN /var/www/html/laravel-project/server/getcomposer.sh

# navigate to and compile project
RUN cd /var/www/html/laravel-project
RUN composer update
RUN composer install
RUN npm install

# TODO: set up Laravel folder permissions correctly
# see: https://stackoverflow.com/q/30639174
RUN sudo chown -R root:www-data /var/www/html/laravel-project
RUN sudo find /var/www/html/laravel-project -type f -exec chmod 664 {} \;    
RUN sudo find /var/www/html/laravel-project -type d -exec chmod 775 {} \;
RUN sudo chgrp -R www-data storage bootstrap/cache
RUN sudo chmod -R ug+rwx storage bootstrap/cache

# compile ui, gen key, and migrate
RUN npm run dev
RUN php artisan key:generate
RUN php artisan migrate:fresh --seed

# run container
CMD ["apachectl","-D","FOREGROUND"]
RUN a2enmod rewrite
EXPOSE 80
EXPOSE 443