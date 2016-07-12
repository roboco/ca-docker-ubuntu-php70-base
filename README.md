Dockerised Drupal container using PHP 7.0 and HTTP/2 on Ubuntu 16.04 and configured with PHP tools.

For example of how to use this container, see [docker-drupal-project-example](https://github.com/andrewholgate/docker-drupal-project-example)

# Installed

- PHP 7.0.x with production settings.
- [HTTP/2](https://en.wikipedia.org/wiki/HTTP/2)
- Apache 2.4 with [PHP-FPM](https://wiki.apache.org/httpd/PHP-FPM) and [event MPM](https://httpd.apache.org/docs/2.4/mod/event.html) configured for HTTP & HTTPS and with minimal modules installed.
- MySQL 5.7 client
- [Redis 3.x](http://redis.io/) and [phpredis](https://github.com/phpredis/phpredis) extension
- [Google Page Speed](https://developers.google.com/speed/pagespeed/module/) for Apache
- cURL with [HTTP/2 support](https://nghttp2.org/)
- [Linux troubleshooting tools](http://www.linuxjournal.com/magazine/hack-and-linux-troubleshooting-part-i-high-load)
- [git](http://git-scm.com/) (latest version)
- [Composer](https://getcomposer.org/) - PHP dependency management.
- Rsyslog and common log directory
- Guest user (`ubuntu`)

# Installation

## Create persistent database data-only container



```bash
# Clone Drupal docker repository
git clone https://github.com/andrewholgate/docker-drupal-php70.git
cd docker-drupal-php70

# Build docker image
sudo docker build --rm=true --no-cache --tag="drupal-php70" . | tee ./build.log
```

## Build Project using Docker Compose

```bash
# Customise docker-compose.yml configurations for environment.
cp docker-compose.yml.dist docker-compose.yml
vim docker-compose.yml

# Build docker containers using Docker Compose.
sudo docker-compose build --no-cache | tee ./build.log
sudo docker-compose up -d
```

## Host Access

From the host server, add the web container IP address to the hosts file.

```bash
# Add IP address to hosts file.
./host.sh
```

## Logging into Web Front-end

```bash
# Using the container name of the web frontend.
sudo docker exec -it dockerdrupalphp70_drupalphp70web_1 su - ubuntu
```

Dockerised Drupal 8 development environment using PHP 7.0 on Ubuntu 16.04 with HTTP/2. This image is the development companion to the [docker-drupal-php70](https://github.com/andrewholgate/docker-drupal-php70) project.

# Included Tools

## Debugging Tools

- [XDebug](http://www.xdebug.org/) - PHP debugging and profiling.
- [XHProf](http://pecl.php.net/package/xhprof) - function-level hierarchical profiler.

## Front-end Tools

- [Wraith](https://github.com/BBC-News/wraith) - for visual regression testing.
- [BrowserStackLocal](https://www.browserstack.com) - for automating browser tests locally (need a paid account).

## PHP Documentation Tools

- [DoxyGen](http://www.doxygen.org) - generate documentation from annotated PHP code. It is used to generate XML which is then interpreted by Sphinx.
- [Sphinx](http://sphinx-doc.org/) - generate beautiful [Read The Docs](http://docs.readthedocs.org/en/latest/) format using [Breathe](https://breathe.readthedocs.org/) as a bridge to DoxyGen XML output.

# Other
- [NodeJS LTS](https://nodejs.org/) and [NVM (Node Version Manager)](https://github.com/creationix/nvm)
- Java Runtime Environment (JRE) - project dev tools like [sitespeed.io](http://www.sitespeed.io/) need this.

# Installation

## Create Presistant Database data-only container

```bash
# Build database image based off MySQL 5.7
sudo docker run -d --name mysql-drupal-php70-dev mysql:5.7 --entrypoint /bin/echo MySQL data-only container for Drupal Dev MySQL
```

## Build Project using Docker Compose

```bash
# Customise docker-compose.yml configurations for environment.
cp docker-compose.yml.dist docker-compose.yml
vim docker-compose.yml

# Build docker containers using Docker Composer.
sudo docker-compose build --no-cache
sudo docker-compose up -d
```

## Host Access

From the host server, add the web container IP address to the hosts file.

```bash
# Add IP address to hosts file.
./host.sh
```

## Logging into Web Front-end

```bash
# Using the container name of the web frontend.
sudo docker exec -it dockerdrupalphp70dev_drupalphp70devweb_1 su - ubuntu
```

## Local customisations

```bash
# Customize scripts in local folders.
cp local/bashrc.dist local/bashrc
vim local/bashrc
```

## XDebug enable and disable

Note that XDebug CLI is disabled by default.

```bash
# Turn XDebug on / off in Apache.
xdebug on
xdebug off

# Turn XDebug on / off fopr both Apache and CLI.
xdebug on-all
xdebug off-all
```

## BrowserStack integration

Use [BrowserStack credentials](https://www.browserstack.com/accounts/settings) to get `{Access Key}`

```bash
# Run BrowserStackLocal binary in background
BrowserStackLocal {Access Key} </dev/null &>/dev/null &
```
