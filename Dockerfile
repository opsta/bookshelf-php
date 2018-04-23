# Use Docker Hub PHP with Apache
FROM php:7.2.4-apache

# Update and install required packages for composer
RUN apt-get update \
  && apt-get -y dist-upgrade \
  && apt-get install -y zip unzip \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Enable Apache Rewrite Module
RUN a2enmod rewrite

# Install required PHP extension
RUN docker-php-ext-install -j$(nproc) pdo_mysql

# Install composer
RUN curl -sS https://raw.githubusercontent.com/composer/getcomposer.org/master/web/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copy composer.* and install required libraries
COPY composer.* /var/www/html/
RUN composer install --no-dev

# Copy PHP source code
COPY . /var/www/html/
