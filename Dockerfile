ARG PHP_VERSION="8.1.3"
ARG DISTRO="bullseye"

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

ARG DAVICAL_VERSION="r1.1.10"
ARG DAVICAL_SHA512="20a4a473b12d467131a3b93aed1828ae978cf3b34feedecda384a974814b285c1b842d1ec0d2638b14388a94643ed6f5566a5993884b6e71bdaf6789ce43bd63"
ARG DAVICAL_URL=https://gitlab.com/davical-project/davical/-/archive/${DAVICAL_VERSION}/davical.tar.gz

ARG AWL_VERSION="r0.62"
ARG AWL_SHA512="c4de99e627ba3bd0a0ace1feef89a341d1bb29c79e4f1f0dc786da890b7540577444a19f10d0ae118d53ae723bd61538e82fee15aa689d1a4b7fc13a39c4a559"
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
