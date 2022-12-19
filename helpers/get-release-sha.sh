#!/bin/sh
###
# Get the SHA512 for the tarball of the specified davical and awl versions. Creates .versions.env
# Requires curl and jq
#
# Usage:
# ./get-release-sha.sh <DAVICAL_VERSION> <AWL_VERSION>
# ./source .versions.env
#
# Should work with tag names, branch names, or commit hashes as the version name, e.g.
# ./get-release-sha.sh r1.1.10 r0.62
###
set -e

DAVICAL_PROJECT_ID="36163" # from https://gitlab.com/davical-project/davical
AWL_PROJECT_ID="36166" # from https://gitlab.com/davical-project/awl
ENV_FILENAME=".versions.env"

curl_and_sha() {
  project_name=$1
  version=$2
  curl -s "https://gitlab.com/davical-project/$project_name/-/archive/$version/$project_name.tar.gz" \
    | sha512sum - \
    | cut -d " " -f 1
}

get_latest_commit() {
  project_id=$1
  curl -sS "https://gitlab.com/api/v4/projects/$project_id/repository/commits?per_page=1&page=1" | jq -r '.[0].id'
}

DAVICAL_VERSION="$1"
AWL_VERSION="$2"

if [ -z $DAVICAL_VERSION ] || [  -z $AWL_VERSION ]; then
  echo "Must specify davical and awl version"
  exit 1
fi

if [ "$DAVICAL_VERSION" = "master" ]; then
  DAVICAL_VERSION=$(get_latest_commit "$DAVICAL_PROJECT_ID")
fi

if [ "$AWL_VERSION" = "master" ]; then
  AWL_VERSION=$(get_latest_commit "$AWL_PROJECT_ID")
fi

DAVICAL_SHA512=$(curl_and_sha "davical" "$DAVICAL_VERSION")
AWL_SHA512=$(curl_and_sha "awl" "$AWL_VERSION")

echo "\
DAVICAL_VERSION=$DAVICAL_VERSION
DAVICAL_SHA512=$DAVICAL_SHA512
AWL_VERSION=$AWL_VERSION
AWL_SHA512=$AWL_SHA512" > "$ENV_FILENAME"
echo "Created $ENV_FILENAME:"
cat "$ENV_FILENAME"