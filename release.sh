#!/usr/bin/env bash

set -e

if [[ -z "${GITHUB_TOKEN}" ]]; then
    echo "Will not release because no GITHUB_TOKEN defined"
    exit
fi

REPOSITORY_OWNER="${ASSETS_REPOSITORY/\/*/}"
REPOSITORY_NAME="${ASSETS_REPOSITORY/*\//}"

pnpm add -g github-release-cli

if [[ $(gh release view --repo "${ASSETS_REPOSITORY}" "${RELEASE_VERSION}" 2>&1) =~ "release not found" ]]; then
    echo "Creating release '${RELEASE_VERSION}'"

    NOTES="update ch5-crcomlib to [${CH5_VERSION}](${UPSTREAM_NPM_PACKAGE_ENDPOINT}/v$(echo "${CH5_VERSION//./_}" | cut -d'_' -f 1,2))"
    CREATE_OPTIONS="--generate-notes"

    gh release create "${RELEASE_VERSION}" --repo "${ASSETS_REPOSITORY}" --title "${RELEASE_VERSION}" --notes "${NOTES}" ${CREATE_OPTIONS}
fi
