FROM centos:centos7

LABEL maintainer="Unicon, Inc."

RUN yum -y install epel-release \
    && yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm \
    && yum -y update \
    && yum-config-manager --enable remi-php74 \
    && yum -y install httpd mod_ssl php php-ldap php-mbstring php-memcache php-mcrypt php-pdo php-pear php-xml wget \
    && yum -y clean all

# Get a release of simplesamlphp
ARG APP_VERSION=1.18.8
ARG SHA256_CHECKSUM=363e32b431c62d174e3c3478b294e9aac96257092de726cbae520a4feee201f1

RUN set -eux; \
    	\
    cd /tmp; \
	curl -fsSL -o simplesamlphp.tar.gz "https://github.com/simplesamlphp/simplesamlphp/releases/download/v$APP_VERSION/simplesamlphp-$APP_VERSION.tar.gz"; \
	if [ -n "$SHA256_CHECKSUM" ]; then \
    	echo "$SHA256_CHECKSUM simplesamlphp.tar.gz" | sha256sum -c -; \
    fi; \
	cd /var \
    tar -zxf /tmp/simplesamlphp.tar.gz -C simplesamlphp --strip-components=1; \
    rm /tmp/simplesamlphp.tar.gz;

RUN echo $'\nSetEnv SIMPLESAMLPHP_CONFIG_DIR /var/simplesamlphp/config\nAlias /simplesaml /var/simplesamlphp/www\n \
<Directory /var/simplesamlphp/www>\n \
    Require all granted\n \
</Directory>\n' \
       >> /etc/httpd/conf/httpd.conf

COPY httpd-foreground /usr/local/bin/

EXPOSE 80 443

CMD ["httpd-foreground"]
