FROM ubuntu:13.10

MAINTAINER Iliyan Trifonov <iliyan.trifonov@gmail.com>

RUN cat /proc/mounts > /etc/mtab

RUN echo "deb mirror://mirrors.ubuntu.com/mirrors.txt saucy main restricted universe multiverse" > /etc/apt/sources.list;\
	echo "deb mirror://mirrors.ubuntu.com/mirrors.txt saucy-updates main restricted universe multiverse" >> /etc/apt/sources.list;\
	echo "deb mirror://mirrors.ubuntu.com/mirrors.txt saucy-backports main restricted universe multiverse" >> /etc/apt/sources.list;\
	echo "deb mirror://mirrors.ubuntu.com/mirrors.txt saucy-security main restricted universe multiverse" >> /etc/apt/sources.list

RUN apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A;\
	echo "deb http://repo.percona.com/apt saucy main" >> /etc/apt/sources.list;\
	echo "deb-src http://repo.percona.com/apt saucy main" >> /etc/apt/sources.list

RUN export DEBIAN_FRONTEND=noninteractive;\
	apt-get update;\
	apt-get -qq install percona-server-server-5.5 percona-server-client-5.5 \
	php5-fpm php5-mysqlnd php5-mcrypt php5-cli \
	nginx-full \
	curl openssh-server

RUN mkdir /var/run/sshd;\
	echo "root:root"|chpasswd;\
	sed -i 's|session.*required.*pam_loginuid.so|session optional pam_loginuid.so|' /etc/pam.d/sshd;\
	echo LANG="en_US.UTF-8" > /etc/default/locale

RUN curl -L https://raw.github.com/wp-cli/builds/gh-pages/phar/wp-cli.phar > wp-cli.phar;\
	chmod +x wp-cli.phar;\
	mv wp-cli.phar /usr/bin/wp

RUN sed -i 's|listen.*=.*|listen=127.0.0.1:9000|' /etc/php5/fpm/pool.d/www.conf;\
	sed -i 's|;cgi.fix_pathinfo.*=.*|cgi.fix_pathinfo=0|' /etc/php5/fpm/php.ini;\
	sed -i 's|;date.timezone.*=.*|date.timezone=Europe/Sofia|' /etc/php5/fpm/php.ini

RUN mkdir -p /var/www/wordpress;\
	chown -R www-data:www-data /var/www;\
	chmod 0755 /var/www

RUN NGINXCONFFILE=/etc/nginx/nginx.conf;\
	echo "daemon off;" | cat - $NGINXCONFFILE > $NGINXCONFFILE.tmp;\
	mv $NGINXCONFFILE.tmp $NGINXCONFFILE

ADD nginx/default /etc/nginx/sites-available/default

RUN /etc/init.d/mysql start;\
	sleep 3;\
	echo 'CREATE DATABASE wordpress; GRANT ALL PRIVILEGES ON wordpress.* TO "wordpress"@"127.0.0.1" IDENTIFIED BY "wordpress"; FLUSH PRIVILEGES;' | mysql -h127.0.0.1 -uroot;\
	su - www-data -c '\
		cd wordpress;\
		wp core download;\
		wp core config --dbhost="127.0.0.1" --dbname="wordpress" --dbuser="wordpress" --dbpass="wordpress";\
		wp core install --url="127.0.0.1" --title="My Docker Wordpress Blog!" --admin_user="admin" --admin_password="admin" --admin_email="me@127.0.0.1"';\
	/etc/init.d/mysql stop

ADD shell/run_all_servers.sh /

EXPOSE 80 22

CMD ["sh", "/run_all_servers.sh"]
