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

if [[ -z "${RELEASE_VERSION}" ]]; then
    if [[ "${CH5_LATEST}" == "yes" ]] || [[ ! -f version.json ]]; then
        echo "Retrieve lastest version"
        UPDATE_INFO=$(curl --silent --fail "https://registry.npmjs.org/@crestron/ch5-crcomlib/latest")
    else
        echo "Get version from version.json"
        CH5_VERSION=$(jq -r '.version' version.json)
    fi

    [[ -z "${CH5_COMMIT}" ]] && CH5_COMMIT=$(jq -r '.commit' version.json)
    [[ -z "${CH5_VERSION}" ]] && CH5_VERSION=$(echo "${UPDATE_INFO}" | jq -r '.version')

    date=$(date +%Y%j)
    RELEASE_VERSION="${CH5_VERSION}.${date: -5}"
else
    if [[ "${RELEASE_VERSION}" =~ ^([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+$ ]]; then
        CH5_VERSION="${BASH_REMATCH[1]}"
    else
        echo "Error: Bad RELEASE_VERSION: ${RELEASE_VERSION}"
        exit 1
    fi

    if [[ "${CH5_VERSION}" == "$(jq -r '.version' stable.json)" ]]; then
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

echo "CH5_VERSION=\"${CH5_VERSION}\""
echo "CH5_COMMIT=\"${CH5_COMMIT}\""

git fetch --depth 1 origin "${CH5_COMMIT}"
git checkout FETCH_HEAD

cd ..

# for GH actions
if [[ "${GITHUB_ENV}" ]]; then
    echo "CH5_VERSION=${CH5_VERSION}" >>"${GITHUB_ENV}"
    echo "CH5_COMMIT=${CH5_COMMIT}" >>"${GITHUB_ENV}"
    echo "RELEASE_VERSION=${RELEASE_VERSION}" >>"${GITHUB_ENV}"
fi

export CH5_VERSION
export CH5_COMMIT
export RELEASE_VERSION
