FROM centos:centos7

LABEL maintainer="Unicon, Inc."

RUN yum -y install epel-release \
    && yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm \
    && yum -y update \
    && yum-config-manager --enable remi-php72 \
    && yum -y install httpd mod_ssl php php-ldap php-mbstring php-memcache php-mcrypt php-pdo php-pear php-xml wget \
    && yum -y clean all

RUN ssp_version=1.17.2; \
    ssp_hash=0e2fd641e8cba2966437fb64591e28a73fb90bae3bc97949c60a47a5b8c1e80e; \
    wget https://github.com/simplesamlphp/simplesamlphp/releases/download/v$ssp_version/simplesamlphp-$ssp_version.tar.gz \
    && echo "$ssp_hash  simplesamlphp-$ssp_version.tar.gz" | sha256sum -c - \
	&& cd /var \
	&& tar xzf /simplesamlphp-$ssp_version.tar.gz \
    && mv simplesamlphp-$ssp_version simplesamlphp \
    && rm /simplesamlphp-$ssp_version.tar.gz

RUN echo $'\nSetEnv SIMPLESAMLPHP_CONFIG_DIR /var/simplesamlphp/config\nAlias /simplesaml /var/simplesamlphp/www\n \
<Directory /var/simplesamlphp/www>\n \
    Require all granted\n \
</Directory>\n' \
       >> /etc/httpd/conf/httpd.conf

COPY httpd-foreground /usr/local/bin/

EXPOSE 80 443

CMD ["httpd-foreground"]
