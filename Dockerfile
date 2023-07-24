ARG PHP_VERSION="8.2.8"
ARG DISTRO="bookworm"

FROM php:${PHP_VERSION}-apache-${DISTRO}

ENV PGDATABASE="davical"
ENV PGPORT="5432"
ENV PGUSER="davical_app"
ENV DBA_PGUSER="davical_dba"

ENV HOST_NAME="localhost"
ENV ADMIN_EMAIL="admin@davical.example.com"
ENV TZ="UTC"

ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"
ENV LC_ALL="en_US.UTF-8"

# Install & configure Davical dependencies
RUN buildDeps="\
        libc-client-dev \
        libkrb5-dev \
        libpq-dev \
    " \
    && set -eux \
    && apt-get update \
    && apt-get install --no-install-recommends --yes \
        libdbd-pg-perl \
        libdbi-perl \
        libpq5 \
        libyaml-perl \
        locales \
        postgresql-client \
        ${buildDeps} \
    # configure locales
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen \
    # configure PHP extensions
    && docker-php-ext-configure imap --with-imap --with-imap-ssl --with-kerberos \
    && docker-php-ext-install \
        gettext \
        pdo \
        pgsql \
        pdo_pgsql \
        imap \
        calendar \
    # configure apache
    && a2enmod rewrite \
    && rm /etc/apache2/sites-enabled/000-default.conf \
    # cleanup
    && apt-get purge --auto-remove -y ${buildDeps} \
    && rm -rf  \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/doc/* \
        /usr/share/man/*

ARG DAVICAL_VERSION="r1.1.12"
ARG DAVICAL_SHA512="ace73d8962ac71b1cfac68cce2271d19147527d9b74d6a349a18bf9b799bf0b46a6db1612ef43c3f3f9f064be03b6232b959da691061e37505a30b2590dd3a30"
ARG DAVICAL_URL=https://gitlab.com/davical-project/davical/-/archive/${DAVICAL_VERSION}/davical.tar.gz

ARG AWL_VERSION="r0.64"
ARG AWL_SHA512="9d563e312f938b9d03811736453f5890df73adb0e3879ca1b828ba0957609829b93b7fce5f79e273e78f22af1293a0606e3578dc41143ca9c68df6f089e381c3"
ARG AWL_URL=https://gitlab.com/davical-project/awl/-/archive/${AWL_VERSION}/awl.tar.gz

LABEL com.fts.davical-version=$DAVICAL_VERSION \
      com.fts.awl-version=$AWL_VERSION

# Install AWL
ARG AWL_DEST=/usr/share/awl
RUN curl -o awl.tar.gz $AWL_URL \
    && \
        if [ -n "$AWL_SHA512" ]; then \
            echo "$AWL_SHA512  awl.tar.gz" | sha512sum --check --strict -; \
        fi \
    && tar -xf awl.tar.gz \
    && mv awl-* $AWL_DEST \
    && rm -rf awl.tar.gz $AWL_DEST/tests $AWL_DEST/docs \
    && chown -R root:www-data $AWL_DEST \
    && cd $AWL_DEST \
    && find ./ -type d -exec chmod u=rwx,g=rx,o=rx '{}' \; \
    && find ./ -type f -exec chmod u=rw,g=r,o=r '{}' \;

# Install DAViCal
ARG DAVICAL_DEST=/usr/share/davical
RUN curl -o davical.tar.gz $DAVICAL_URL \
    && \
        if [ -n "$DAVICAL_SHA512" ]; then \
            echo "$DAVICAL_SHA512  davical.tar.gz"  | sha512sum --check --strict -; \
        fi \
    && tar -xf davical.tar.gz \
    && mv davical-* $DAVICAL_DEST \
    && rm -rf davical.tar.gz $DAVICAL_DEST/testing $DAVICAL_DEST/docs \
    && chown -R root:www-data $DAVICAL_DEST \
    && cd $DAVICAL_DEST \
    && find ./ -type d -exec chmod u=rwx,g=rx,o=rx '{}' \; \
    && find ./ -type f -exec chmod u=rw,g=r,o=r '{}' \; \
    && chmod +x dba/update-davical-database

# Copy config and scripts last so as not to bust cache
COPY ./bin/* /usr/local/bin/
COPY config/apache.conf /etc/apache2/sites-enabled/
COPY config/config.php /etc/davical/config.php

EXPOSE 80
ENTRYPOINT ["davical-entrypoint.sh"]
CMD ["apache2-foreground"]
