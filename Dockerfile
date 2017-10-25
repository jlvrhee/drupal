# from https://www.drupal.org/requirements/php#drupalversions
FROM php:5-apache
MAINTAINER Jeroen van Rhee <jeroen_van_rhee@hotmail.com>

RUN a2enmod rewrite

# install the PHP extensions we need
RUN set -ex \
	&& buildDeps='libjpeg62-turbo-dev libpng12-dev libpq-dev libxml2-dev' \
	&& apt-get update && apt-get install -y --no-install-recommends $buildDeps && rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd --with-jpeg-dir=/usr --with-png-dir=/usr \
	&& docker-php-ext-install -j "$(nproc)" gd mbstring mysql mysqli pdo pdo_mysql pdo_pgsql xml zip \
# PHP Warning:  PHP Startup: Unable to load dynamic library '/usr/local/lib/php/extensions/no-debug-non-zts-20151012/gd.so' - libjpeg.so.62: cannot open shared object file: No such file or directory in Unknown on line 0
# PHP Warning:  PHP Startup: Unable to load dynamic library '/usr/local/lib/php/extensions/no-debug-non-zts-20151012/pdo_pgsql.so' - libpq.so.5: cannot open shared object file: No such file or directory in Unknown on line 0
	&& apt-mark manual \
		libjpeg62-turbo \
		libpq5 \
	&& apt-get purge -y --auto-remove $buildDeps

WORKDIR /var/www/html

# Install openssh-client package
RUN apt-get update && apt-get install -y openssh-client

# Give shell to www-data user (which runs apache processes)
RUN usermod -s /bin/bash www-data && \
           mkdir -p /var/www/.ssh && \
           chmod 700 /var/www/.ssh && \
           chown www-data:www-data /var/www/.ssh

ADD ssh /var/www/.ssh

RUN chmod 600 /var/www/.ssh/id_rsa && \
           chmod 644 /var/www/.ssh/id_rsa.pub && \
           chmod 600 /var/www/.ssh/config && \
           chown www-data:www-data /var/www/.ssh/*

# https://www.drupal.org/node/3060/release
ENV DRUPAL_VERSION 7.56
ENV DRUPAL_MD5 5d198f40f0f1cbf9cdf1bf3de842e534

RUN curl -fSL "https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz" -o drupal.tar.gz \
	&& echo "${DRUPAL_MD5} *drupal.tar.gz" | md5sum -c - \
	&& tar -xz --strip-components=1 -f drupal.tar.gz \
	&& rm drupal.tar.gz \
	&& chown -R www-data:www-data sites

