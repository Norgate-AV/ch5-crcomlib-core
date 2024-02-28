#!/usr/bin/env bash

if [[ -z "${BUILD_SOURCEVERSION}" ]]; then
    if type -t "sha1sum" &>/dev/null; then
        BUILD_SOURCEVERSION=$(echo "${RELEASE_VERSION/-*/}" | sha1sum | cut -d' ' -f1)
    else
        pnpm add -g checksum

        BUILD_SOURCEVERSION=$(echo "${RELEASE_VERSION/-*/}" | checksum)
    fi

    echo "BUILD_SOURCEVERSION=\"${BUILD_SOURCEVERSION}\""

    # Add to GH Actions environment
    if [[ "${GITHUB_ENV}" ]]; then
        echo "BUILD_SOURCEVERSION=${BUILD_SOURCEVERSION}" >>"${GITHUB_ENV}"
    fi
fi

export BUILD_SOURCEVERSION
