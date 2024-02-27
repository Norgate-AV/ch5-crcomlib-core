#!/usr/bin/env bash
# shellcheck disable=SC2129

set -e

if [[ -z "${GITHUB_TOKEN}" ]]; then
    echo "Will not build because no GITHUB_TOKEN defined"
    exit 0
fi

APP_NAME_LC="$(echo "${APP_NAME}" | awk '{print tolower($0)}')"
LATEST_VERSION=$(curl --silent --fail "https://registry.npmjs.org/@crestron/ch5-crcomlib/latest" | jq -r '.version')

if [[ "${LATEST_VERSION}" =~ ^([0-9]+\.[0-9]+\.[0-9]+) ]]; then
    if [[ "${CH5_VERSION}" != "${BASH_REMATCH[1]}" ]]; then
        echo "New CH5 version, new build"
        export SHOULD_BUILD="yes"
    elif [[ "${NEW_RELEASE}" == "true" ]]; then
        echo "New release build"
        export SHOULD_BUILD="yes"
    fi

    if [[ "${SHOULD_BUILD}" != "yes" ]]; then
        export RELEASE_VERSION="${LATEST_VERSION}"
        echo "RELEASE_VERSION=${RELEASE_VERSION}" >>"${GITHUB_ENV}"
        echo "Switch to release version: ${RELEASE_VERSION}"
    fi
fi

echo "SHOULD_BUILD=${SHOULD_BUILD}" >>"${GITHUB_ENV}"
