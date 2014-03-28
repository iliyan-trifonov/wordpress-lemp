Wordpress on a LEMP stack + sshd and wp-cli
===

This repo builds automatically the Trusted Build image
[on the Docker's index here.](https://index.docker.io/u/iliyan/docker-wordpress-lemp/ "Wordpress on a LEMP stack + sshd and wp-cli")

See it in action
---

I am using it for [my blog here](http://blog.iliyan-trifonov.com "Iliyan Trifonov's Tech Blog")
It's running behind the main nginx server on the host.

Some mysql variables are changed with a little increase in values like: innodb_log_file_size = 32M, tmp_table_size = 32M, max_heap_table_size = 32M, query_cache_limit = 2M

Percona Mysql Server
---

I chose the Percona DB server instead of the standard default mysql install.

The percona repos are used and it's the latest version of the time you bild it.

The server is installed quietly so you have to tighten its security if you're going to use this image for spawining
containers in production.


NGINX, PHP5 FPM
---

These servers are installed with their defaults and only the default site config of nginx is changed with the one
comming from the package's `./nginx/default` file

WP-Cli
---
I decided to use this great tool from the console to download the latest wordpress package, install and configure it.
Later updates, settings, posts of the blog can be managed by `wp-cli`.
The `.phar` is installed in `/usr/bin/wp` so you can call it easily from everywhere.

Openssh-server
---

the only changes for sshd are the ones suggested by the docker team for Ubuntu 13.10 containers:

`session optional pam_loginuid.so` -> `/etc/pam.d/sshd`

`LANG="en_US.UTF-8"` -> `/etc/default/locale`

Backup/Update the Docker image/container
---
If you've made some changes through ssh or other way inside the container(you definitely made many changes in the DB by using the blog and adding posts/comments), you better keep the changes (it's better to stop the running services inside the container(one by one or with `docker stop wordpress`) before commit but it will still work if you don't do it, depends on the server load):

`docker commit --run='{"Cmd":["sh","/run_all_servers.sh"]}' yourname/wordpress`

Rerun the container from the latest image (don't wait and let all commands execute asap):
`docker stop wordpress && docker rm wordpress && docker run -d --name wordpress -p 80:80 yourname/wordpres`

You may want to change `-p 80:80` to `-p 172.17.42.1:yourport:80` if you want to put it behind a proxy like I did.


Other
---

`mirrors.ubuntu.com` is used so you can rest asured the build and following updates will be fast
using the closest to yourself server

Ssh to the container
---

From inside the environment where the docker is running:

`docker inspect wordpress` or the better one: `docker inspect --format='{{.NetworkSettings.IPAddress}}' wordpress`

get the ip from the information shown, for example let it be `172.17.0.2`

connect: `ssh root@172.17.0.2`

say `yes` for the host to be added to the `known_hosts` and later remove it by executing `ssh-agent -R 172.17.0.2`

Things to change when using it on a different hosting environment:
---

If you want to use it on `blog.example.com`:

The params for `wp core install` will be:

`wp core install --url="blog.example.com" --title="My Example Blog!" --admin_user="admin" --admin_password="strongpass" --admin_email="me@example.com"`

Login on the blog with: `admin/admin` and change the admin password to a stronger one.

Ssh to the container and change the root password by executing: `passwd`, the default pass is: `root`

Again inside the container, change the mysql user `wordpress`'s password to a stronger one using the `mysql` command:

`echo "SET PASSWORD FOR 'wordpress'@'127.0.0.1' = PASSWORD('strong cleartext password');" | mysql`

Also the `root mysql user` has no password set yet, there are a couple of root users/hosts combinations that you have to find:
`echo "SELECT user,host FROM mysql.user;" | mysql` and then set the passwords for them

After changing the `wordpress` user password, go into `/var/www/wordpress/wp-config.php`
and set the new password there too: `define('DB_PASSWORD', 'strong cleartext password');`

You can set a different `timezone` in `php.ini`, which currently is:

`date.timezone=Europe/Sofia` -> `/etc/php5/fpm/php.ini`

Interesting stuff
---

I've created a better structured Dockerfile using multiline RUN commands to group similar commands into blocks.

Wordpress was not my first choise but after seeing it has a cli command line tool I quickly started building a new
Dockerfile with this cms.

I am thinking about trying LocomotiveCMS and finally building a blog from scratch to get some
new skills through the process. Stay tuned!
