#!/bin/bash
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

get_label() {
  label=$(docker inspect \
    --format "{{ index .Config.Labels \"$1\" }}" \
    $IMAGE_NAME)
  if [[ $label == r* ]]; then
    echo "${label:1}"
  else
    echo $label
  fi
}

davical_version=$(get_label "com.fts.davical-version")
awl_version=$(get_label "com.fts.awl-version")

echo "\
$davical_version-awl$awl_version-php$PHP_VERSION-$DISTRO-$COMMITHASH \
$davical_version-awl$awl_version-php$PHP_VERSION-$DISTRO \
$davical_version-php$PHP_VERSION-$DISTRO \
$davical_version-$DISTRO \
$davical_version \
$DISTRO"
