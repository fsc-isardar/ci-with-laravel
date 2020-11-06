#!/bin/bash

cd /var/www/html/laravel-project
php artisan migrate:fresh --seed

apachectl -D FOREGROUND