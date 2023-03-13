FROM rockylinux/rockylinux:9 as download_ssp

ARG SIMPLE_SAML_PHP_VERSION=2.0.2
ARG SIMPLE_SAML_PHP_HASH=ce974d387eba6e37dc502bd7fa7a5c7803f9572c59ac9c05cbc03b5fc0220838

RUN dnf install -y wget \
    && ssp_version=$SIMPLE_SAML_PHP_VERSION; \
           ssp_hash=$SIMPLE_SAML_PHP_HASH; \
           wget https://github.com/simplesamlphp/simplesamlphp/releases/download/v$ssp_version/simplesamlphp-$ssp_version.tar.gz \
    && echo "$ssp_hash  simplesamlphp-$ssp_version.tar.gz" | sha256sum -c - \
    && cd /var \
    && tar xzf /simplesamlphp-$ssp_version.tar.gz \
    && mv simplesamlphp-$ssp_version simplesamlphp

FROM rockylinux/rockylinux:9

LABEL maintainer="Unicon, Inc."

ARG PHP_VERSION=8.1.8
ARG HTTPD_VERSION=2.4.53

COPY --from=download_ssp /var/simplesamlphp /var/simplesamlphp

RUN dnf module enable -y php:8.1 \
    && dnf install -y httpd-$HTTPD_VERSION php-$PHP_VERSION \
    && dnf clean all \
    && rm -rf /var/cache/yum

RUN echo $'\nSetEnv SIMPLESAMLPHP_CONFIG_DIR /var/simplesamlphp/config\nAlias /simplesaml /var/simplesamlphp/public\n \
<Directory /var/simplesamlphp/public>\n \
    Require all granted\n \
</Directory>\n' \
       >> /etc/httpd/conf/httpd.conf

COPY httpd-foreground /usr/local/bin/

EXPOSE 80 443

CMD ["httpd-foreground"]
