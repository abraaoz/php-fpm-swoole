FROM php:7.4-fpm

ENV DEBIAN_FRONTEND                      noninteractive
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE 1

# Install general packages
RUN apt-get update && apt-get install -qq -y \
    autoconf \
    gcc \
    libc-dev \
    libcurl4-gnutls-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    make \
    pkg-config \
    build-essential \
    curl \
    default-mysql-client \
    g++ \
    git \
    git-core \
    gnupg \
    htop \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libonig-dev \
    libpng-dev \
    librabbitmq-dev \
    libssh-dev \
    libssl-dev \
    libvpx-dev \
    libxml2-dev \
    libxpm-dev \
    libzip-dev \
    nano \
    net-tools \
    openssh-client \
    openssl \
    procps \
    software-properties-common \
    unzip \
    wget \
    zlib1g-dev

# Install APCU
ADD https://pecl.php.net/get/apcu-5.1.17.tgz /tmp/apcu.tar.gz
RUN mkdir -p /usr/src/php/ext/apcu && \
    tar xf /tmp/apcu.tar.gz -C /usr/src/php/ext/apcu --strip-components=1

RUN docker-php-ext-configure apcu && \
    docker-php-ext-install apcu

RUN rm -rd /usr/src/php/ext/apcu && rm /tmp/apcu.tar.gz

ADD https://pecl.php.net/get/apcu_bc-1.0.3.tgz /tmp/apcu_bc.tar.gz
RUN mkdir -p /usr/src/php/ext/apcu-bc && \
    tar xf /tmp/apcu_bc.tar.gz -C /usr/src/php/ext/apcu-bc --strip-components=1

RUN docker-php-ext-configure apcu-bc && \
    docker-php-ext-install apcu-bc

RUN rm -rd /usr/src/php/ext/apcu-bc && rm /tmp/apcu_bc.tar.gz

RUN rm /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini
RUN echo extension=apcu.so > /usr/local/etc/php/conf.d/20-php-ext-apcu.ini

# Install APC
RUN rm /usr/local/etc/php/conf.d/docker-php-ext-apc.ini
RUN echo extension=apc.so > /usr/local/etc/php/conf.d/21-php-ext-apc.ini

# Install other extensions
RUN docker-php-ext-install bcmath

RUN docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/

RUN docker-php-ext-install gd
RUN docker-php-ext-install intl
RUN docker-php-ext-install pdo_mysql
RUN docker-php-ext-install mysqli
RUN docker-php-ext-install curl
RUN docker-php-ext-install opcache
RUN docker-php-ext-install zip
RUN docker-php-ext-install xml
RUN docker-php-ext-install json
RUN docker-php-ext-install mbstring
RUN docker-php-ext-install sockets
RUN docker-php-ext-install exif

# Generate locales
RUN apt-get install -y locales
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
RUN echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen
RUN echo "cs_CZ.UTF-8 UTF-8" >> /etc/locale.gen
RUN locale-gen

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install node and yarn
RUN curl -sL https://deb.nodesource.com/setup_12.x  | bash - && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get install -qq -y nodejs yarn

# Install Redis
RUN mkdir -p /usr/src/php/ext/redis && \
    curl -L https://github.com/phpredis/phpredis/archive/5.1.1.tar.gz | tar xvz -C /usr/src/php/ext/redis --strip 1 && \
    echo 'redis' >> /usr/src/php-available-exts && \
    docker-php-ext-install redis

# Install Swoole
# based on https://www.swoole.co.uk/docs/get-started/try-docker
RUN cd /tmp && git clone https://github.com/swoole/swoole-src.git && \
    cd swoole-src && \
    git checkout v4.4.16 && \
    phpize && \
    ./configure  --enable-openssl && \
    make && \
    make install

RUN echo 'extension=swoole.so' > /usr/local/etc/php/conf.d/swoole.ini
