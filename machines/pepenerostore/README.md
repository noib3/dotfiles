# Bootstrapping instructions

**NOTE:** it's assumed that `git` is installed and that the current user is
named `pepe`. If the user has a different name, change the values of
`home.username` and `home.homeDirectory` in `home.nix` after cloning this
repository.

## Installing nix and home-manager on a non-NixOS Linux server

First install nix, add the `nixos`, `nixos-unstable` and `home-manager`
channels and install home-manager:

```sh
curl -L https://nixos.org/nix/install | sh
. /home/pepe/.nix-profile/etc/profile.d/nix.sh
nix-channel --add https://nixos.org/channels/nixos-20.09 nixos
nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
```

Next clone this repository, symlink it into place and log out:

```sh
cd ~
git clone https://github.com/noib3/dotfiles.git
mkdir -p ~/.config/nixpkgs
ln -sf ~/dotfiles/* ~/.config/nixpkgs/
ln -sf ~/.config/nixpkgs/machines/pepenerostore/home.nix ~/.config/nixpkgs/home.nix
exit
```

After logging back in a simple `home-manager switch` should be all that's left
to do to have a development environment configured the way I like.

## Setting fish as the default shell

Add `/home/pepe/.nix-profile/bin/fish` to `/etc/shells`, then `chsh -s
/home/pepe/.nix-profile/bin/fish`.

## Installing WordPress with all its dependencies

Taken from
[this](https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-on-ubuntu-20-04-with-a-lamp-stack),
[this](https://www.digitalocean.com/community/tutorials/how-to-secure-apache-with-let-s-encrypt-on-ubuntu-20-04)
and
[this](https://www.digitalocean.com/community/tutorials/how-to-install-the-apache-web-server-on-ubuntu-20-04)
DigitalOcean articles.

### Installing and configuring Apache

Install Apache

``` sh
$ sudo apt update
$ sudo apt install apache2
```

Next let's set up a firewall allowing ssh and web access. We can list all the
applications registered with `ufw` with

``` sh
$ sudo ufw app list
```

which will show something like
```
Available applications:
  Apache
  Apache Full
  Apache Secure
  OpenSSH
```

There are three profiles available for Apache: `Apache` which only opens port
80 for normal, unencrypted web traffic, `Apache Secure` which only opens port
443 for TLS/SSL encrypted traffic, and `Apache Full` which opens both. We'll go
with `Apache Full`:

``` sh
$ sudo ufw allow OpenSSH
$ sudo ufw allow 'Apache Full'
$ sudo ufw enable
```

`sudo ufw status` should now list both `OpenSSH` and `Apache Full`.

#### Setting up virtual hosts

We'll create the root directory from which all the files will be served in
`/var/www/pepenerostore.it`:

```
$ sudo mkdir -p /var/www/pepenerostore.it
$ sudo chown -R $USER:$USER /var/www/pepenerostore.it
$ sudo chmod -R 755 /var/www/pepenerostore.it
```
now let's create a virtual host file for Apache with all the correct
directives. Instead of modifying the default config file at
`/etc/apache2/sites-available/000-default.conf` let's create a new one at
`/etc/apache2/sites-available/pepenerostore.conf` with the following contents

```
<VirtualHost *:80>
  ServerAdmin info@pepenerostore.it
  ServerName pepenerostore.it
  ServerAlias www.pepenerostore.it
  DocumentRoot /var/www/pepenerostore.it
  ErrorLog ${APACHE_LOG_DIR}/error.log
  CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>

ServerName localhost
```
let's enable the file with `a2ensite` disabling the default config with
`a2dissite`:
```
$ sudo a2ensite pepenerostore.conf
$ sudo a2dissite 000-default.conf
```
next let's test for configuration errors
```
$ sudo apache2ctl configtest
```
which should output
```
Syntax OK
```

To apply our changes we need to reload Apache:
```
$ sudo systemctl reload apache2
```

#### Securing Apache with Let's Encrypt

We first install the Certbot software:

```sh
$ sudo apt install certbot python3-certbot-apache
```

next we need to install the Apache plugin for Certbot which will take care of
reconfiguring Apache while also reloading the configuration when necessary.
Execute the following and follow the steps:

```sh
$ sudo certbot --apache
```

### Installing MySQL and PHP

```sh
$ sudo apt install mysql-server
$ sudo apt install php libapache2-mod-php php-mysql
```

launch mysql as root
```sh
$ sudo mysql -u root
```

set a new password for the MySQL root account with

```
mysql> ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '<your_password_here>';
```

now you can `exit` and log back into the database with `mysql -u root -p`.
Within MySQL we create a new database for WordPress to control named
`wordpress`:

```mysql
mysql> CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
```

next we create a new MySQL user called `wordpressuser` that we will use
exclusively to operate our new database. We are going to create the account,
set a password and grant access to the `wordpress` database:

```mysql
mysql> CREATE USER 'wordpressuser'@'%' IDENTIFIED WITH mysql_native_password BY '<your_password_here>';
mysql> GRANT ALL ON wordpress.* TO 'wordpressuser'@'%';
mysql> FLUSH PRIVILEGES;
mysql> EXIT;
```

We now install some of the most popular PHP extensions for WordPress to use
with:

```sh
$ sudo apt install php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip
```

### Enabling `.htaccess` overrides and the `mod_rewrite` module

Currently the use of `.htaccess` files is disabled. WordPress and many
WordPress plugins use these files extensively for in-directory tweaks to the
web server’s behavior. To allow them we need to edit our
`/etc/apache2/sites-available/pepenerostore.conf` by setting the following
block of text **inside** our `VirtualHost` block:

```apache
<Directory /var/www/pepenerostore.it/>
    AllowOverride All
</Directory>
```

next we enable the `mod_rewrite` module so that we can utilize the WordPress
permalink feature:

```sh
$ sudo a2enmod rewrite
```

before enabling the changes we check that we haven't made any syntax errors

```sh
$ sudo apache2ctl configtest
```

### Downloading WordPress

```sh
$ cd /tmp
$ curl -O https://wordpress.org/latest.tar.gz
$ tar xzvf latest.tar.gz
```
we now add a dummy `.htaccess` file so that it will be available for WordPress
to use later.

```sh
$ touch /tmp/wordpress/.htaccess
```

we’ll also copy over the sample configuration file to the filename that
WordPress reads:

```sh
$ cp /tmp/wordpress/wp-config-sample.php /tmp/wordpress/wp-config.php
```

we can also create the upgrade directory, so that WordPress won’t run into
permissions issues when trying to do this on its own following an update to its
software, then we copy the contents of the `wordpress` directory to the root
directory of our Apache VirtualHost:

``` sh
$ mkdir /tmp/wordpress/wp-content/upgrade
$ sudo cp -a /tmp/wordpress/. /var/www/pepenerostore.it
```

# Configuring the WordPress directory

## Adjusting the ownership and permissions

We’ll start by giving ownership of all the files to the www-data user and
group. This is the user that the Apache web server runs as, and Apache will
need to be able to read and write WordPress files in order to serve the website
and perform automatic updates.

Update the ownership with the chown command which allows you to modify file
ownership. Be sure to point to your server’s relevant directory.

```sh
$ sudo chown -R www-data:www-data /var/www/pepenerostore.it
```

Next we’ll run two find commands to set the correct permissions on the
WordPress directories and files:

```sh
$ sudo find /var/www/pepenerostore.it/ -type d -exec chmod 750 {} \;
$ sudo find /var/www/pepenerostore.it/ -type f -exec chmod 640 {} \;
```

These permissions should get you working effectively with WordPress, but note
that some plugins and procedures may require additional tweaks.

## Setting Up the WordPress Configuration File

Now, we need to make some changes to the main WordPress configuration file.

When we open the file, our first task will be to adjust some secret keys to
provide a level of security for our installation. WordPress provides a secure
generator for these values so that you do not have to try to come up with good
values on your own. These are only used internally, so it won’t hurt usability
to have complex, secure values here.

To grab secure values from the WordPress secret key generator, type:

```sh
$ curl -s https://api.wordpress.org/secret-key/1.1/salt/
```

Next, open the WordPress configuration file. Find the section that contains the
example values for those settings.

```php
. . .
define('AUTH_KEY',         'put your unique phrase here');
define('SECURE_AUTH_KEY',  'put your unique phrase here');
define('LOGGED_IN_KEY',    'put your unique phrase here');
define('NONCE_KEY',        'put your unique phrase here');
define('AUTH_SALT',        'put your unique phrase here');
define('SECURE_AUTH_SALT', 'put your unique phrase here');
define('LOGGED_IN_SALT',   'put your unique phrase here');
define('NONCE_SALT',       'put your unique phrase here');
. . .
```
delete those lines and paste in the values you copied from the command line.

Next, we are going to modify some of the database connection settings at the
beginning of the file. You need to adjust the database name, the database user,
and the associated password that you configured within MySQL.

The other change we need to make is to set the method that WordPress should use
to write to the filesystem. Since we’ve given the web server permission to
write where it needs to, we can explicitly set the filesystem method to
“direct”. Failure to set this with our current settings would result in
WordPress prompting for FTP credentials when we perform some actions.

This setting can be added below the database connection settings, or anywhere
else in the file:

```php
. . .

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'wordpress' );

/** MySQL database username */
define( 'DB_USER', 'wordpressuser' );

/** MySQL database password */
define( 'DB_PASSWORD', '<your_password_here>' );

/** MySQL hostname */
define( 'DB_HOST', 'localhost' );

/** Database Charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8' );

/** The Database Collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );


. . .

define('FS_METHOD', 'direct');
```

finally go to the site in a web browser and finish the set up process there (
they say it should only take 5 minutes!).
