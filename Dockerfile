FROM php:7.4-fpm

ENV DEBIAN_FRONTEND noninteractive
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE 1

# Install general packages
RUN apt-get update && apt-get install -qq -y \
    autoconf \
    build-essential \
    curl \
    default-mysql-client \
    g++ \
    gcc \
    git \
    git-core \
    gnupg \
    htop \
    libc-dev \
    libcurl4-gnutls-dev \
    libfreetype6-dev \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libonig-dev \
    libpng-dev \
    libpq-dev \
    librabbitmq-dev \
    libssh-dev \
    libssl-dev \
    libvpx-dev \
    libxml2-dev \
    libxpm-dev \
    libzip-dev \
    make \
    nano \
    net-tools \
    openssh-client \
    openssl \
    pkg-config \
    postgresql-client \
    procps \
    software-properties-common \
    unzip \
    wget \
    zlib1g-dev

# Install APCU
ADD https://pecl.php.net/get/apcu-5.1.17.tgz /tmp/apcu.tar.gz
RUN mkdir -p /usr/src/php/ext/apcu && \
    tar xf /tmp/apcu.tar.gz -C /usr/src/php/ext/apcu --strip-components=1 && \
    docker-php-ext-configure apcu && \
    docker-php-ext-install apcu && \
    rm -rd /usr/src/php/ext/apcu && \
    rm /tmp/apcu.tar.gz

ADD https://pecl.php.net/get/apcu_bc-1.0.3.tgz /tmp/apcu_bc.tar.gz
RUN mkdir -p /usr/src/php/ext/apcu-bc && \
    tar xf /tmp/apcu_bc.tar.gz -C /usr/src/php/ext/apcu-bc --strip-components=1 && \
    docker-php-ext-configure apcu-bc && \
    docker-php-ext-install apcu-bc && \
    rm -rd /usr/src/php/ext/apcu-bc && \
    rm /tmp/apcu_bc.tar.gz && \
    rm /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini && \
    echo 'extension=apcu.so' > /usr/local/etc/php/conf.d/20-php-ext-apcu.ini

# Install APC
RUN rm /usr/local/etc/php/conf.d/docker-php-ext-apc.ini && \
    echo 'extension=apc.so' > /usr/local/etc/php/conf.d/21-php-ext-apc.ini

# Install Graphics Draw (GD)
RUN docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ && \
    docker-php-ext-install gd

# Install PostgreSQL
RUN docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql && \
    docker-php-ext-install pdo_pgsql && \
    docker-php-ext-install pgsql

# Install other extensions
RUN docker-php-ext-install bcmath && \
    docker-php-ext-install intl && \
    docker-php-ext-install pdo_mysql && \
    docker-php-ext-install mysqli && \
    docker-php-ext-install curl && \
    docker-php-ext-install opcache && \
    docker-php-ext-install zip && \
    docker-php-ext-install xml && \
    docker-php-ext-install json && \
    docker-php-ext-install mbstring && \
    docker-php-ext-install sockets && \
    docker-php-ext-install exif && \
    docker-php-ext-install fileinfo

# Generate locales
RUN apt-get install -y locales && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen && \
    echo "cs_CZ.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install node and yarn
RUN curl -sL https://deb.nodesource.com/setup_12.x  | bash - && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get remove -y cmdtest && \
    apt-get install -qq -y nodejs yarn

# Install igbinary
RUN cd /usr/src/php/ext && \
    curl -fsSL https://github.com/igbinary/igbinary/archive/3.1.2.tar.gz -o igbinary.tar.gz && \
    mkdir -p igbinary && \
    tar -xf igbinary.tar.gz -C igbinary --strip-components=1 && \
    rm igbinary.tar.gz && \
    docker-php-ext-install igbinary

# Install Redis
RUN mkdir -p /usr/src/php/ext/redis && \
    curl -L https://github.com/phpredis/phpredis/archive/5.1.1.tar.gz | tar xvz -C /usr/src/php/ext/redis --strip 1 && \
    echo 'redis' >> /usr/src/php-available-exts && \
    docker-php-ext-configure redis --enable-redis-igbinary && \
    docker-php-ext-install redis

# Install Swoole
# based on https://www.swoole.co.uk/docs/get-started/try-docker
RUN cd /tmp && git clone https://github.com/swoole/swoole-src.git && \
    cd swoole-src && \
    git checkout v4.4.16 && \
    phpize && \
    ./configure --enable-openssl && \
    make && \
    make install && \
    cd /tmp && \
    rm -rf swoole-src && \
    echo 'extension=swoole.so' > /usr/local/etc/php/conf.d/swoole.ini

# Install Swoole Async
# https://github.com/swoole/ext-async
COPY swoole_async.so /usr/local/lib/php/extensions/swoole_async.so
RUN echo 'extension=/usr/local/lib/php/extensions/swoole_async.so' > /usr/local/etc/php/conf.d/swoole_async.ini

# Custom php.ini
COPY php.ini /usr/local/etc/php/php.ini