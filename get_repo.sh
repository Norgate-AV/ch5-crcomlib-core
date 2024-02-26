#!/usr/bin/env bash
# shellcheck disable=SC2129

set -e

# git workaround
if [[ "${CI_BUILD}" != "no" ]]; then
    git config --global --add safe.directory "/__w/$(echo "${GITHUB_REPOSITORY}" | awk '{print tolower($0)}')"
fi

if [[ -n "${PULL_REQUEST_ID}" ]]; then
    BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)

    git config --global user.email "$(echo "${GITHUB_USERNAME}" | awk '{print tolower($0)}')-ci@not-real.com"
    git config --global user.name "${GITHUB_USERNAME} CI"
    git fetch --unshallow
    git fetch origin "pull/${PULL_REQUEST_ID}/head"
    git checkout FETCH_HEAD
    git merge --no-edit "origin/${BRANCH_NAME}"
fi

#
if [[ -z "${RELEASE_VERSION}" ]]; then
    # if [[ "${CH5_LATEST}" == "yes" ]] || [[ ! -f stable.json ]]; then
    #     echo "Retrieve lastest version"
    #     UPDATE_INFO=$(curl --silent --fail "https://update.code.visualstudio.com/api/update/darwin/${VSCODE_QUALITY}/0000000000000000000000000000000000000000")
    # else
    echo "Get version from stable.json"
    CH5_COMMIT=$(jq -r '.commit' stable.json)
    CH5_TAG=$(jq -r '.tag' stable.json)
    # fi

    if [[ -z "${CH5_COMMIT}" ]]; then
        CH5_COMMIT=$(echo "${UPDATE_INFO}" | jq -r '.version')
        CH5_TAG=$(echo "${UPDATE_INFO}" | jq -r '.name')
    fi

    date=$(date +%Y%j)
    RELEASE_VERSION="${CH5_TAG}.${date: -5}"
else
    if [[ "${RELEASE_VERSION}" =~ ^([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+$ ]]; then
        CH5_TAG="${BASH_REMATCH[1]}"
    else
        echo "Error: Bad RELEASE_VERSION: ${RELEASE_VERSION}"
        exit 1
    fi

    if [[ "${CH5_TAG}" == "$(jq -r '.tag' stable.json)" ]]; then
        CH5_COMMIT=$(jq -r '.commit' stable.json)
    else
        echo "Error: No CH5_COMMIT for ${RELEASE_VERSION}"
        exit 1
    fi
fi

echo "RELEASE_VERSION=\"${RELEASE_VERSION}\""

mkdir -p CH5ComponentLibrary
cd CH5ComponentLibrary || {
    echo "'CH5ComponentLibrary' dir not found"
    exit 1
}

git init -q
git remote add origin https://github.com/Crestron/CH5ComponentLibrary.git

# figure out latest tag by calling MS update API
# if [[ -z "${CH5_TAG}" ]]; then
#     UPDATE_INFO=$(curl --silent --fail "https://update.code.visualstudio.com/api/update/darwin/${VSCODE_QUALITY}/0000000000000000000000000000000000000000")
#     CH5_COMMIT=$(echo "${UPDATE_INFO}" | jq -r '.version')
#     CH5_TAG=$(echo "${UPDATE_INFO}" | jq -r '.name')
# elif [[ -z "${CH5_COMMIT}" ]]; then
if [[ -z "${CH5_COMMIT}" ]]; then
    REFERENCE=$(git ls-remote --tags | grep -x ".*refs\/tags\/${CH5_TAG}" | head -1)

    if [[ -z "${REFERENCE}" ]]; then
        echo "Error: The following tag can't be found: ${CH5_TAG}"
        exit 1
    elif [[ "${REFERENCE}" =~ ^([[:alnum:]]+)[[:space:]]+refs\/tags\/([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
        CH5_COMMIT="${BASH_REMATCH[1]}"
        CH5_TAG="${BASH_REMATCH[2]}"
    else
        echo "Error: The following reference can't be parsed: ${REFERENCE}"
        exit 1
    fi
fi

echo "CH5_TAG=\"${CH5_TAG}\""
echo "CH5_COMMIT=\"${CH5_COMMIT}\""

git fetch --depth 1 origin "${CH5_COMMIT}"
git checkout FETCH_HEAD

cd ..

# for GH actions
if [[ "${GITHUB_ENV}" ]]; then
    echo "CH5_TAG=${CH5_TAG}" >>"${GITHUB_ENV}"
    echo "CH5_COMMIT=${CH5_COMMIT}" >>"${GITHUB_ENV}"
    echo "RELEASE_VERSION=${RELEASE_VERSION}" >>"${GITHUB_ENV}"
fi

export CH5_TAG
export CH5_COMMIT
export RELEASE_VERSION
