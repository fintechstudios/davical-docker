#!/bin/sh
set -e
###
# Get the set of tags to release the given image
#
# Usage:
# ./get-release-sha.sh <IMAGE_NAME> <PHP_VERSION> <DISTRO> <COMMITHASH>
#
# Example:
# ./get-release-sha.sh fintechstudios/davical 8.1.3 bullseye b62fa33a
###

IMAGE_NAME=$1
PHP_VERSION=$2
DISTRO=$3
COMMITHASH=$4

beginswith() { case $2 in "$1"*) true;; *) false;; esac; }

get_label() {
  label=$(docker inspect \
    --format "{{ index .Config.Labels \"$1\" }}" \
    $IMAGE_NAME)
  if beginswith r "$label"; then
    echo "$label" | cut -c 2-
  else
    echo $label
  fi
}

davical_version=$(get_label "com.fts.davical-version")
awl_version=$(get_label "com.fts.awl-version")
short_hash=$(echo "$COMMITHASH" | cut -c 1-8)

echo "\
$davical_version-awl$awl_version-php$PHP_VERSION-$DISTRO-$short_hash \
$davical_version-awl$awl_version-php$PHP_VERSION-$DISTRO \
$davical_version-php$PHP_VERSION-$DISTRO \
$davical_version-$DISTRO \
$davical_version \
$DISTRO"
