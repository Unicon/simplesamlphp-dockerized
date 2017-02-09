[![](https://badge.imagelayers.io/unicon/simplesamlphp:latest.svg)](https://imagelayers.io/?images=unicon/simplesamlphp:latest 'image layer analysis')

## Overview
This Docker image contains a deployed SimpleSAMLphp IdP/SP based on PHP 5.5 running on Appache HTTP Server 2.4 on the latest CentOS 7 base. This image is a base image and should be used to set the content and configuration with local changes. It is suitable for use as a standalone IdP application or as a base to deploy another PHP application that will be protected by the service provider module.

```
[rootdir]
|-- etc/
|   |-- httpd/
|   |   |-- conf/       - The Apache HTTP Server configuration
|-- var/
|   |-- log/
|   |   |-- httpd/      - The log files for Apache HTTP Server 
|   |-- simplesamlphp/  - The base SimpleSAMLphp directory
|   |   |-- conf/       - The SimpleSAMLphp configuration directory
|   |-- www/
|   |   |-- html/       - The base Apache HTTP Server document root directory
```

SimpleSAMLphp is verified using cryptographic hashes obtained from the vendor and stored in the Dockerfile directly.

A working example of how this image can be used can be found at https://github.com/UniconLabs/dockerized-idp-testbed.

## Tags
It is recommended that only the highest version tag is used as each previous tag/version is generally associated to fixes of the SimpleSAMLphp application.

## Creating a SimpleSAMLphp Configuration
Image adopters should follow the SimpleSAMLphp documentation (https://simplesamlphp.org/docs/stable/) to configure the IdP/SP and/or other features. Include other directories that one would often customized, such as the images, css, and application files themselves. 

## Using the Image
You should use this image as a base image for one's own IdP/SP deployment. The directory structure could look like:

```
[rootdir]
|-- .dockerignore
|-- Dockerfile
|-- etc-httpd/
|   |-- conf.d/
|   |   |-- httpd.conf
|-- var-simplesamlphp/
|   |-- config/
|   |   |-- config.php
|-- var-www/
|   |-- html/
|   |   |-- index.php
```

Next, assuming you create a Dockerfile similar to this example:

```
FROM unicon/shibboleth-idp

MAINTAINER <your_contact_email>

COPY etc-httpd/ /etc/httdp/
COPY var-simplesamlphp/ /var/simplesamlphp/
COPY var-www/ /var/www/
```

The dependant image can be built by running:

```
docker pull centos:centos7
docker build --tag="<org_id>/simplesamlphp-idp:<version>" .
```

or 

```
docker pull centos:centos7
docker build --tag="<org_id>/ourapplication:<version>" .
```

> This will download the base image from the Docker Hub repository. Next, your files are overlaid replacing the base image's counter-parts.

Now, execute the new/customized image:

```
$ docker run -d --name="ssp-local-test" <org_id>/simplesamlphp-idp
```

or 

```
$ docker run -d --name="ourapplication-local-test" <org_id>/ourapplication
```

> This is the base command-line used to start the container. The container will likely fail to initialize if this limited command-line is used. You'll likely need to specify additional parameters to start-up the container.

## Run-time Parameters
Start the IdP will take several parameters. The following parameters can be specified when `run`ning a new container:

### Port Mappings
The image exposes two ports. `80` is the for standard browser-based HTTP communication. `443` is the standard browser-based HTTPS/TLS communication port. These ports will need to be mapped to the Docker host so that communication can occur.

* `-P`: Used to indicate that the Docker Service should map all exposed container ports to ephemeral host ports. Use `docker ps` to see the mappings.
* `-p <host>:<container>`: Explicitly maps the host ports to the container's exposed ports. This parameters can be used multiple times to map multiple sets of ports. `-p 443:443` would make the service accessible on `https://<docker_host_ip>/simplesaml/`. 

### Environmental variables
No explicit envinonmental variables are used by this container. Any that SimpleSAMLphp might use can be used per the application documentation.

### Volume Mount
The container does not explicitally need any volumes mapped for operation, but the option does exist using the following format:

* `-v hostDir:containerDir`

It maybe desirable to map things like  `/var/log/httpd/` or `/var/simplesamlphp/cert/` to host-side storage.

## Notables
There are a few things that implementors should be aware of.

### Browser-based TLS Certificate and Key
Adapters should generate their own private key and get the CSR signed by a trusted certificate authority. The resulting files should be included in the image (directly or mounted to the container at start-up). The standard Apache HTTPD TLS config can be changed by adding/modifying the files in `/etc/httpd/conf.d/`.

### Logging 
This image does not use the standard Docker logging mechanism, but the native OS-based logging.

If you like, you can add the following commands in the file "httpd-foreground" in order to build an image that logs SimpleSAMLphp info to syslog and that you can check with `docker logs -f <image-name>`:

```
SAML_FOLDER=/var/simplesamlphp
SAML_LOG_FILE=${SAML_FOLDER}/log/simplesamlphp.log

touch ${SAML_LOG_FILE}
chown apache:apache ${SAML_LOG_FILE}
chmod a+rw /dev/console
ln -sf /dev/console ${SAML_LOG_FILE}
```

## Building from source:
 
```
$ docker build --tag="<org_id>/simplesamlphp" github.com/unicon/simplesamlphp-dockerized
```


## Authors/Contributors

  * John Gasper (<jgasper@unicon.net>)

## LICENSE

Copyright 2016 Unicon, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
