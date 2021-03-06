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
    libicu-dev \
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

# Install APCu
ADD https://pecl.php.net/get/apcu-5.1.19.tgz /tmp/apcu.tar.gz
RUN mkdir -p /usr/src/php/ext/apcu && \
    tar xf /tmp/apcu.tar.gz -C /usr/src/php/ext/apcu --strip-components=1 && \
    docker-php-ext-configure apcu && \
    docker-php-ext-install apcu && \
    rm -rd /usr/src/php/ext/apcu && \
    rm /tmp/apcu.tar.gz

ADD https://pecl.php.net/get/apcu_bc-1.0.5.tgz /tmp/apcu_bc.tar.gz
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

# Install inotify
RUN pecl install inotify && \
    docker-php-ext-enable inotify

# Install other extensions
RUN docker-php-ext-install bcmath
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
RUN docker-php-ext-install fileinfo

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
    curl -fsSL https://github.com/igbinary/igbinary/archive/3.1.6.tar.gz -o igbinary.tar.gz && \
    mkdir -p igbinary && \
    tar -xf igbinary.tar.gz -C igbinary --strip-components=1 && \
    rm igbinary.tar.gz && \
    docker-php-ext-install igbinary

# Install Redis
RUN mkdir -p /usr/src/php/ext/redis && \
    curl -L https://github.com/phpredis/phpredis/archive/5.3.2.tar.gz | tar xvz -C /usr/src/php/ext/redis --strip 1 && \
    echo 'redis' >> /usr/src/php-available-exts && \
    docker-php-ext-configure redis --enable-redis-igbinary && \
    docker-php-ext-install redis

# Install Swoole
# based on https://www.swoole.co.uk/docs/get-started/try-docker
RUN cd /tmp && git clone https://github.com/swoole/swoole-src.git && \
    cd swoole-src && \
    git checkout v4.5.7 && \
    phpize && \
    ./configure --enable-openssl && \
    make -j $(nproc) && \
    make install && \
    cd /tmp && \
    echo 'extension=swoole.so' > /usr/local/etc/php/conf.d/swoole.ini

# Install Swoole PostgreSQL
# based on https://www.swoole.co.uk/docs/modules/swoole-coroutine-postgres
RUN cd /tmp && git clone https://github.com/swoole/ext-postgresql.git && \
    cd ext-postgresql && \
    git checkout ab616dbc19354c8cd1616ccc3a3e261d4ecd4d35 && \
    phpize && \
    ./configure && \
    make -j $(nproc) && \
    make install && \
    cd /tmp && \
    rm -rf ext-postgresql && \
    echo 'extension=swoole_postgresql.so' > /usr/local/etc/php/conf.d/swoole_postgresql.ini

# Install Swoole Async
# https://github.com/swoole/ext-async
RUN cd /tmp && git clone https://github.com/swoole/ext-async.git && \
    cd ext-async && \
    git checkout 87aba176d02c7a0f2078dee3334f863226089daf && \
    phpize && \
    ./configure && \
    make -j $(nproc) && \
    make install && \
    cd /tmp && \
    rm -rf ext-async && \
    echo 'extension=swoole_async.so' > /usr/local/etc/php/conf.d/swoole_async.ini

# Custom php.ini
COPY php.ini /usr/local/etc/php/php.ini

# Custom www.conf
COPY www.conf /usr/local/etc/php-fpm.d/www.conf