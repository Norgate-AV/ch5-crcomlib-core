#!/usr/bin/env bash

set -e

if [[ "${SHOULD_BUILD}" != "yes" ]]; then
    echo "Will not update ${DOWNSTREAM_VERSION_FILE} because we did not build"
    exit 0
fi

if [[ -z "${GITHUB_TOKEN}" ]]; then
    echo "Will not update ${DOWNSTREAM_VERSION_FILE} because no GITHUB_TOKEN defined"
    exit 0
fi

jsonTmp=$(cat ${DOWNSTREAM_VERSION_FILE} | jq --arg 'version' "${CH5_VERSION}" --arg 'commit' "${CH5_COMMIT}" '. | .version=$version | .commit=$commit')
echo "${jsonTmp}" >${DOWNSTREAM_VERSION_FILE} && unset jsonTmp

jsonTmp=$(cat ${DOWNSTREAM_VERSION_FILE} | jq --arg 'release' "${RELEASE_VERSION}" --arg 'build' "${BUILD_SOURCEVERSION}" '. | .release=$release | .build=$build')
echo "${jsonTmp}" >${DOWNSTREAM_VERSION_FILE} && unset jsonTmp

git config user.email "$(echo "${GITHUB_USERNAME}" | awk '{print tolower($0)}')-ci@not-real.com"
git config user.name "${GITHUB_USERNAME} CI"

cat ${DOWNSTREAM_VERSION_FILE}

CHANGES=$(git status --porcelain)
echo "CHANGE=${CHANGES}"

if [[ -n "${CHANGES}" ]]; then
    git commit -am "build: update to commit ${CH5_COMMIT:0:7}"
    git tag -a "${RELEASE_VERSION}" -m "${RELEASE_VERSION}"

    BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)

    if ! git push origin "${BRANCH_NAME}" --follow-tags --quiet; then
        git pull origin "${BRANCH_NAME}"
        git push origin "${BRANCH_NAME}" --follow-tags --quiet
    fi
fi
