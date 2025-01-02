#!/usr/bin/env sh
set -eu

usage() {
    echo "Usage: $0 CA_CERTS_DIR"
    exit 1
}

if [ "$#" -ne 1 ]; then
    usage
fi

CA_CERTS_DIR="${1}"

# Distro logic taken from https://github.com/devcontainers/features/blob/main/src/common-utils/main.sh

if [ "$(id -u)" -ne 0 ]; then
    echo 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

. /etc/os-release

if [ "${ID}" = "alpine" ]; then
    ADJUSTED_ID="alpine"
elif [ "${ID}" = "debian" ] || [ "${ID_LIKE}" = "debian" ]; then
    ADJUSTED_ID="debian"
elif [ "${ID}" = "rhel" ] || [ "${ID}" = "fedora" ] || [ "${ID}" = "mariner" ]; then
    ADJUSTED_ID="rhel"
else
    case "${ID_LIKE}" in
        *"rhel"* | *"fedora"* | *"mariner"*)
            ADJUSTED_ID="rhel"
            ;;
        *"suse"*)
            ADJUSTED_ID="suse"
            ;;
        *) ;;
    esac
fi

if [ -z "${ADJUSTED_ID+''}" ]; then
    echo "Linux distro ${ID} not supported."
    exit 1
fi

case "${ADJUSTED_ID}" in
    "debian")
        install_packages() {
            apt-get update --option Dir::Cache::pkgcache= --option Dir::Cache::srcpkgcache=
            apt-get install --option Dir::Cache::archives= --yes ca-certificates
        }
        custom_certs_dir=/usr/local/share/ca-certificates/
        update_ca_certs() {
            update-ca-certificates
        }
        ;;
    "rhel")
        install_packages() {
            true
        }
        custom_certs_dir=/etc/pki/ca-trust/source/anchors/
        update_ca_certs() {
            update-ca-trust
        }
        ;;
    "alpine")
        install_packages() {
            apk add --update-cache --no-cache ca-certificates
        }
        custom_certs_dir=/usr/local/share/ca-certificates/
        update_ca_certs() {
            update-ca-certificates
        }
        ;;
    "suse")
        install_packages() {
            true
        }
        custom_certs_dir=/etc/pki/trust/anchors/
        update_ca_certs() {
            update-ca-certificates
        }
        ;;
esac

install_packages || (cert_bundle="$(mktemp)" && cat "${CA_CERTS_DIR}"/* >> "${cert_bundle}" && SSL_CERT_FILE="${cert_bundle}" install_packages && rm "${cert_bundle}")
cp "${CA_CERTS_DIR}"/* "${custom_certs_dir}"
update_ca_certs
