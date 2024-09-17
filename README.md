A single script that can install CA-certificates on multiple platforms.
Works with Alpine, Debian-like, and RHEL-like distributions.

## Usage

```sh
sudo ./install.sh CA_CERTS_DIR
```

### Install Certificates in a Docker Image

```dockerfile
ARG BASE
FROM ${BASE}

USER root

RUN mkdir /tmp/install-ca-certs
# TODO: COPY or ADD your certificates to /tmp/install-ca-certs/certs
ADD --chmod=700 https://raw.githubusercontent.com/bachorp/install-ca-certs/main/install.sh /tmp/install/ca-certs/install.sh # TODO: Pin the version
RUN /tmp/install-ca-certs/install.sh /tmp/install-ca-certs/certs && rm -rf /tmp/install-ca-certs

USER ${USER} # ok if empty string
```

```sh
docker build --build-arg BASE=<YOUR_BASE_IMAGE> --build-arg USER="$(docker inspect --format-string '{{.Config.User}}' <YOUR_BASE_IMAGE>)"
```
