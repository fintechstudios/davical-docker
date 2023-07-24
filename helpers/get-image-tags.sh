#!/bin/sh
set -e
###
# Get the set of tags to release the given image
#
# Usage:
# ./get-release-sha.sh <IMAGE_NAME> <PHP_VERSION> <DISTRO> <COMMITHASH> [BUILD_PREFIX]
#
# Example:
# ./get-release-sha.sh fintechstudios/davical 8.1.3 bullseye b62fa33a latest
###

LATEST_DISTRO="bookworm"
LATEST_PHP="8.2.8"

IMAGE_NAME=$1
PHP_VERSION=$2
DISTRO=$3
COMMITHASH=$4
BUILD_PREFIX=$5

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

if [ "$BUILD_PREFIX" = "latest" ]; then
  is_nightly=false
else
  is_nightly=true
fi

# in the current build matrix, these are always specific enough to include unconditionally
tags="\
$davical_version-awl$awl_version-php$PHP_VERSION-$DISTRO-$short_hash \
$davical_version-awl$awl_version-php$PHP_VERSION-$DISTRO \
$davical_version-php$PHP_VERSION-$DISTRO"

if [ $PHP_VERSION = $LATEST_PHP ]; then
  # the distro tag only applies for the latest version of PHP
  tags="$tags $DISTRO"

  # and it should be suffixed with -nightly for nightly builds
  if $is_nightly; then
    tags="$tags-nightly"
  fi;
fi

if [ $DISTRO = $LATEST_DISTRO ] && [ $PHP_VERSION = $LATEST_PHP ]; then
  # the davical version tag only applies on the latest distro _and_ PHP version
  tags="$tags $davical_version"

  # as well as the latest/nightly tag
  if $is_nightly; then
    tags="$tags nightly"
  else
    tags="$tags latest"
  fi;
fi

echo "$tags"
