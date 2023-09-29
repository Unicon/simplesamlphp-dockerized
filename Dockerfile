FROM rockylinux/rockylinux:8.8 as download_ssp

ARG SIMPLE_SAML_PHP_VERSION=1.18.8
ARG SIMPLE_SAML_PHP_HASH=363e32b431c62d174e3c3478b294e9aac96257092de726cbae520a4feee201f1

RUN dnf install -y wget \
    && ssp_version=$SIMPLE_SAML_PHP_VERSION; \
           ssp_hash=$SIMPLE_SAML_PHP_HASH; \
           wget https://github.com/simplesamlphp/simplesamlphp/releases/download/v$ssp_version/simplesamlphp-$ssp_version.tar.gz \
    && echo "$ssp_hash  simplesamlphp-$ssp_version.tar.gz" | sha256sum -c - \
    && cd /var \
    && tar xzf /simplesamlphp-$ssp_version.tar.gz \
    && mv simplesamlphp-$ssp_version simplesamlphp \
    && wget https://github.com/FriendsOfPHP/pickle/releases/latest/download/pickle.phar \
    && chmod +x pickle.phar \
    && mv pickle.phar pickle

FROM rockylinux/rockylinux:8.8

LABEL maintainer="3slab"

ARG PHP_VERSION=7.4.33
ARG HTTPD_VERSION=2.4.37

COPY --from=download_ssp /var/simplesamlphp /var/simplesamlphp
COPY --from=download_ssp /var/pickle /usr/local/bin/pickle
COPY httpd.conf /etc/httpd/conf/httpd.conf
COPY vhost.conf /etc/httpd/conf.d/idp.conf

RUN dnf module enable -y php:7.4 \
    && dnf install -y httpd-$HTTPD_VERSION php-$PHP_VERSION php-ldap php-devel make \
    && pickle install -n redis \
    && dnf clean all \
    && rm -rf /var/cache/yum


#RUN echo $'\nSetEnv SIMPLESAMLPHP_CONFIG_DIR /var/simplesamlphp/config\nAlias /simplesaml /var/simplesamlphp/www\n \
#<Directory /var/simplesamlphp/www>\n \
#    Require all granted\n \
#</Directory>\n' \
#       >> /etc/httpd/conf/httpd.conf

RUN sed -i 's/php_admin_value\[error_log\]/;php_admin_value\[error_log\]/g' /etc/php-fpm.d/www.conf
RUN sed -i '/^php_/s/php_/;php_/g' /etc/php-fpm.d/www.conf
RUN set -eux; \
    	{ \
    		echo '[global]'; \
    		echo 'error_log = /proc/self/fd/2'; \
    		echo; echo '; https://github.com/docker-library/php/pull/725#issuecomment-443540114'; echo 'log_limit = 8192'; \
    		echo; \
    		echo '[www]'; \
    		echo '; php-fpm closes STDOUT on startup, so sending logs to /proc/self/fd/1 does not work.'; \
    		echo '; https://bugs.php.net/bug.php?id=73886'; \
    		echo 'access.log = /proc/self/fd/2'; \
    		echo; \
    		echo 'clear_env = no'; \
    		echo; \
    		echo '; Ensure worker stdout and stderr are sent to the main error log.'; \
    		echo 'catch_workers_output = yes'; \
    		echo 'decorate_workers_output = no'; \
            echo '[global]'; \
            echo 'daemonize = no'; \
    	} | tee -a /etc/php-fpm.conf; \
    	{ \
    		echo '; https://github.com/docker-library/php/issues/878#issuecomment-938595965'; \
    		echo 'fastcgi.logging = Off'; \
    	} > "/etc/php.d/docker-fpm.ini"; \
    	{ \
    		echo 'extension=redis.so'; \
    	} > "/etc/php.d/redis.ini"

COPY httpd-foreground /usr/local/bin/

EXPOSE 80 443

CMD ["httpd-foreground"]
