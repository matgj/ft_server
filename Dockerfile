FROM debian:buster
MAINTAINER Mathis Grosjean <magrosje@student.42.fr>
#WORKDIR /ft_server
RUN apt-get update 
RUN apt-get upgrade -y 
RUN apt-get install wget -y 
RUN apt-get install nginx -y 
RUN apt-get install mariadb-server -y 
RUN apt-get install php php-fpm php-mysqli php-pear php-json php-mbstring -y
RUN apt-get install php-gettext php-common php-phpseclib php-mysql -y

#configurer nginx
COPY /srcs/defaultnginx /etc/nginx/sites-available/defaultnginx
#By default on Debian systems, 
#Nginx server blocks configuration files are stored in /etc/nginx/sites-available directory, 
#which are enabled through symbolic links to the /etc/nginx/sites-enabled/ directory.
#Enable the new server block file by creating a symbolic link from the file to 
#the sites-enabled directory:
RUN ln -s /etc/nginx/sites-available/defaultnginx /etc/nginx/sites-enabled/

#make a directory to store all files
RUN  mkdir /var/www/localhost \
	&& mv /var/www/html/index.nginx-debian.html /var/www/localhost/
#cd /var/www/ \
	#&& mkdir localhost \
#	cp /var/www/html/index.nginx-debian.html /var/www/localhost/

#lets install and dezip phpmyadmin
RUN wget https://files.phpmyadmin.net/phpMyAdmin/4.9.0.1/phpMyAdmin-4.9.0.1-all-languages.tar.gz \
	&& tar -zxvf phpMyAdmin-4.9.0.1-all-languages.tar.gz \
	&& mv phpMyAdmin-4.9.0.1-all-languages /var/www/localhost/phpmyadmin \
#change the ownership of the domain document root directory to the Nginx user
	&& chown -R www-data:www-data /var/www/ \
	&& chmod -R 777 /var/www/
#configurer phpmyadmin
COPY /srcs/config.inc.php /var/www/localhost/phpmyadmin/
#copy du backup wordpress
COPY /srcs/db1-backup-2020-01-30.sql /var/www/db1-backup-2020-01-30.sql
#creer une database pour wordpress
RUN service mysql start \
	&& mysql -u root -e "create database db_wp" \
	&& mysql -u root -e "create user 'admin'@'localhost' identified by 'admin'" \
	&& mysql -u root -e "grant all privileges on *.* to 'admin'@'localhost' identified by 'admin'" \
	&& mysql -u root -e "flush privileges" \
#dump la db	
	&& mysql db_wp < /var/www/db1-backup-2020-01-30.sql 

#dump la db	
 #/srcs/db1-backup-2020-01-30.sql /var/www/localhost/db1-backup-2020-01-30.sql
#RUN mysql db_wp < /var/www/localhost/db1-backup-2020-01-30.sql \
#	&& service mysql status 


#lets install and dezip wordpress
RUN wget https://wordpress.org/latest.tar.gz \
	&& tar -zxvf latest.tar.gz \
	&& ls -l \
	&& mv wordpress /var/www/localhost/wordpress 

#configurer wordpress
COPY srcs/wp-config.php /var/www/localhost/wordpress/wp-config.php

RUN cd /var/www/localhost/wordpress \
	&& ls -l

COPY /srcs/server.crt /etc/ssl/certs/nginx-selfsigned.crt
COPY /srcs/server.key /etc/ssl/private/nginx-selfsigned.key

CMD service nginx start \
	&& nginx -t \
	&& service mysql start \
	&& service php7.3-fpm start \
	&& service php7.3-fpm status && tail -f /dev/null

EXPOSE 443 80
