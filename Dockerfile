FROM php:8.0-fpm

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
    libevent-dev \
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

# Install Graphics Draw (GD)
RUN docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ && \
    docker-php-ext-install gd

# Install PostgreSQL
RUN docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql && \
    docker-php-ext-install pdo_pgsql && \
    docker-php-ext-install pgsql

# Install other extensions
RUN docker-php-ext-install bcmath
RUN docker-php-ext-install intl
RUN docker-php-ext-install pdo_mysql
RUN docker-php-ext-install mysqli
RUN docker-php-ext-install curl
RUN docker-php-ext-install opcache
RUN docker-php-ext-install zip
RUN docker-php-ext-install xml
RUN docker-php-ext-install mbstring
RUN docker-php-ext-install sockets
RUN docker-php-ext-install exif
RUN docker-php-ext-install fileinfo
RUN docker-php-ext-install pcntl

# Install Event
ADD https://pecl.php.net/get/event-3.0.2.tgz /tmp/event.tar.gz
RUN mkdir -p /usr/src/php/ext/event && \
    tar xf /tmp/event.tar.gz -C /usr/src/php/ext/event --strip-components=1 && \
    docker-php-ext-configure event --with-event-pthreads --with-event-openssl=no --enable-event-sockets=no && \
    docker-php-ext-install event && \
    rm -rd /usr/src/php/ext/event && \
    rm /tmp/event.tar.gz

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
    git checkout v4.5.9 && \
    phpize && \
    ./configure --enable-openssl && \
    make -j $(nproc) && \
    make install && \
    echo 'extension=swoole.so' > /usr/local/etc/php/conf.d/swoole.ini

# Install Swoole PostgreSQL
# based on https://www.swoole.co.uk/docs/modules/swoole-coroutine-postgres
RUN cd /tmp && git clone https://github.com/swoole/ext-postgresql.git && \
    cd ext-postgresql && \
    git checkout eb076d72cb35b1a458a886e259dbbc30feecb298 && \
    mkdir ext && \
    ln -s /tmp/swoole-src/ext-src ext/swoole && \
    phpize && \
    ./configure && \
    make -j $(nproc) && \
    make install && \
    cd /tmp && \
    rm -rf ext-postgresql && \
    echo 'extension=swoole_postgresql.so' > /usr/local/etc/php/conf.d/swoole_postgresql.ini

# Install Swoole Async
# https://github.com/swoole/ext-async
# RUN cd /tmp && git clone https://github.com/swoole/ext-async.git && \
#     cd ext-async && \
#     git checkout v4.5.5 && \
#     phpize && \
#     ./configure && \
#     make -j $(nproc) && \
#     make install && \
#     cd /tmp && \
#     rm -rf ext-async && \
#     echo 'extension=swoole_async.so' > /usr/local/etc/php/conf.d/swoole_async.ini

# Custom php.ini
COPY php.ini /usr/local/etc/php/php.ini

# Custom www.conf
COPY www.conf /usr/local/etc/php-fpm.d/www.conf