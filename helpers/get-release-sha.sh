#!/bin/sh
###
# Get the SHA512 for the tarball of the specified davical and awl versions. Creates .versions.env
#
# Usage:
# ./get-release-sha.sh <DAVICAL_VERSION> <AWL_VERSION>
# ./source .versions.env
#
# Should work with tag names, branch names, or commit hashes as the version name, e.g.
# ./get-release-sha.sh r1.1.10 r0.62
###
set -e

DAVICAL_VERSION="$1"
AWL_VERSION="$2"

if [ -z $DAVICAL_VERSION ] || [  -z $AWL_VERSION ]; then
  echo "Must specify davical and awl version"
  exit 1
fi

DAVICAL_URL="https://gitlab.com/davical-project/davical/-/archive/${DAVICAL_VERSION}/davical.tar.gz"
AWL_URL="https://gitlab.com/davical-project/awl/-/archive/${AWL_VERSION}/awl.tar.gz"
ENV_FILENAME=".versions.env"

get_commit_hash() {
  echo "$1" | sed -nr 's/[^-]*-[^-]*-([a-z0-9]*)\.tar\.gz/\1/p'
}

temp_path="./.tmp-$(date +"%s")"

mkdir "$temp_path"
cd "$temp_path"

curl -JOSs "$DAVICAL_URL"
davical_filename=$(find . -name "davical-*.tar.gz")
DAVICAL_COMMITHASH=$(get_commit_hash "$davical_filename")
DAVICAL_SHA512=$(sha512sum "$davical_filename" | cut -d " " -f 1)

curl -JOSs "$AWL_URL"
awl_filename=$(find . -name "awl-*.tar.gz")
AWL_COMMITHASH=$(get_commit_hash "$awl_filename")
AWL_SHA512=$(sha512sum "$awl_filename" | cut -d " " -f 1)

cd ..
rm -r "$temp_path"

echo "\
DAVICAL_VERSION=\"$DAVICAL_COMMITHASH\"
DAVICAL_SHA512=\"$DAVICAL_SHA512\"
AWL_VERSION=\"$AWL_COMMITHASH\"
AWL_SHA512=\"$AWL_SHA512\"" > "$ENV_FILENAME"
echo "Created $ENV_FILENAME:"
cat "$ENV_FILENAME"