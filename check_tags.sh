#!/usr/bin/env bash
# shellcheck disable=SC2129

set -e

if [[ -z "${GITHUB_TOKEN}" ]]; then
    echo "Will not build because no GITHUB_TOKEN defined"
    exit 0
fi

APP_NAME_LC="$(echo "${APP_NAME}" | awk '{print tolower($0)}')"
GITHUB_RESPONSE=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/${ASSETS_REPOSITORY}/releases/latest")
LATEST_VERSION=$(echo "${GITHUB_RESPONSE}" | jq -c -r '.tag_name')

if [[ "${LATEST_VERSION}" =~ ^([0-9]+\.[0-9]+\.[0-9]+) ]]; then
    if [[ "${CH5_TAG}" != "${BASH_REMATCH[1]}" ]]; then
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
