#!/bin/bash
###
# Get the SHA512 for the tarball of the specified davical and awl versions.
#
# Usage:
# ./get-release-sha.sh <DAVICAL_VERSION> <AWL_VERSION>
#
# Should work with tag names, branch names, or commit hashes as the version name, e.g.
# ./get-release-sha.sh r1.1.10 r0.62
###
set -e

DAVICAL_VERSION="$1"
AWL_VERSION="$2"

DAVICAL_URL=https://gitlab.com/davical-project/davical/-/archive/${DAVICAL_VERSION}/davical.tar.gz
AWL_URL=https://gitlab.com/davical-project/awl/-/archive/${AWL_VERSION}/awl.tar.gz

echo "DAViCal $DAVICAL_VERSION sha512sum:"
curl -s $DAVICAL_URL | sha512sum -

echo "AWL $AWL_VERSION sha512sum:"
curl -s $AWL_URL | sha512sum -
