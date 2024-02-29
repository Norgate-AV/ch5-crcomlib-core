#!/usr/bin/env bash
# shellcheck disable=SC2129

set -e

. ./utils.sh

SCRIPT_DIR=$(get_script_dir)
echo "SCRIPT_DIR=${SCRIPT_DIR}"

UPSTREAM_AUTHOR=Crestron
UPSTREAM_PROJECT=CH5ComponentLibrary
UPSTREAM_PROJECT_BUILD_DIR=build_bundles
UPSTREAM_REPO=https://github.com/${UPSTREAM_AUTHOR}/${UPSTREAM_PROJECT}.git
UPSTREAM_NPM_PACKAGE=@crestron/ch5-crcomlib
UPSTREAM_NPM_PACKAGE_ENDPOINT=https://registry.npmjs.org/${UPSTREAM_NPM_PACKAGE}
UPSTREAM_NPM_PACKAGE_VERSION=latest

DOWNSTREAM_AUTHOR="Norgate AV"
DOWNSTREAM_AUTHOR_KEBAB=$(echo "${DOWNSTREAM_AUTHOR}" | awk '{print tolower($1)}')-$(echo "${DOWNSTREAM_AUTHOR}" | awk '{print tolower($2)}')
DOWNSTREAM_PROJECT=ch5-crcomlib
DOWNSTREAM_REPO=https://github.com/${DOWNSTREAM_AUTHOR_KEBAB}/${DOWNSTREAM_PROJECT}.git
DOWNSTREAM_NPM_PACKAGE=@norgate-av/ch5-crcomlib
DOWNSTREAM_NPM_PACKAGE_ENDPOINT=https://registry.npmjs.org/${DOWNSTREAM_NPM_PACKAGE}
DOWNSTREAM_VERSION_FILE=version.json

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
    if [[ "${CH5_LATEST}" == "yes" ]] || [[ ! -f ${DOWNSTREAM_VERSION_FILE} ]]; then
        echo "Retrieve lastest version"
        UPDATE_INFO=$(curl --silent --fail "${UPSTREAM_NPM_PACKAGE_ENDPOINT}/${UPSTREAM_NPM_PACKAGE_VERSION}")
    else
        echo "Get version from ${DOWNSTREAM_VERSION_FILE}"
        CH5_VERSION=$(jq -r '.version' ${DOWNSTREAM_VERSION_FILE})
    fi

    [[ -z "${CH5_COMMIT}" ]] && CH5_COMMIT=$(jq -r '.commit' ${DOWNSTREAM_VERSION_FILE})
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

    if [[ "${CH5_VERSION}" == "$(jq -r '.version' ${DOWNSTREAM_VERSION_FILE})" ]]; then
        CH5_COMMIT=$(jq -r '.commit' ${DOWNSTREAM_VERSION_FILE})
    else
        echo "Error: No CH5_COMMIT for ${RELEASE_VERSION}"
        exit 1
    fi
fi

echo "RELEASE_VERSION=\"${RELEASE_VERSION}\""

[[ ! -d ${UPSTREAM_PROJECT} ]] && mkdir -p ${UPSTREAM_PROJECT}
cd ${UPSTREAM_PROJECT} || {
    echo "'${UPSTREAM_PROJECT}' dir not found"
    exit 1
}

git init -q
git remote add origin ${UPSTREAM_REPO}

echo "CH5_VERSION=\"${CH5_VERSION}\""
echo "CH5_COMMIT=\"${CH5_COMMIT}\""

git fetch --depth 1 origin "${CH5_COMMIT}"
git checkout FETCH_HEAD

cd ${SCRIPT_DIR}

# Add to GH Actions environment
if [[ "${GITHUB_ENV}" ]]; then
    echo "CH5_VERSION=${CH5_VERSION}" >>"${GITHUB_ENV}"
    echo "CH5_COMMIT=${CH5_COMMIT}" >>"${GITHUB_ENV}"
    echo "RELEASE_VERSION=${RELEASE_VERSION}" >>"${GITHUB_ENV}"

    echo "UPSTREAM_AUTHOR=${UPSTREAM_AUTHOR}" >>"${GITHUB_ENV}"
    echo "UPSTREAM_PROJECT=${UPSTREAM_PROJECT}" >>"${GITHUB_ENV}"
    echo "UPSTREAM_PROJECT_BUILD_DIR=${UPSTREAM_PROJECT_BUILD_DIR}" >>"${GITHUB_ENV}"
    echo "UPSTREAM_REPO=${UPSTREAM_REPO}" >>"${GITHUB_ENV}"
    echo "UPSTREAM_NPM_PACKAGE=${UPSTREAM_NPM_PACKAGE}" >>"${GITHUB_ENV}"
    echo "UPSTREAM_NPM_PACKAGE_ENDPOINT=${UPSTREAM_NPM_PACKAGE_ENDPOINT}" >>"${GITHUB_ENV}"
    echo "UPSTREAM_NPM_PACKAGE_VERSION=${UPSTREAM_NPM_PACKAGE_VERSION}" >>"${GITHUB_ENV}"

    echo "DOWNSTREAM_AUTHOR=${DOWNSTREAM_AUTHOR}" >>"${GITHUB_ENV}"
    echo "DOWNSTREAM_AUTHOR_KEBAB=${DOWNSTREAM_AUTHOR_KEBAB}" >>"${GITHUB_ENV}"
    echo "DOWNSTREAM_PROJECT=${DOWNSTREAM_PROJECT}" >>"${GITHUB_ENV}"
    echo "DOWNSTREAM_REPO=${DOWNSTREAM_REPO}" >>"${GITHUB_ENV}"
    echo "DOWNSTREAM_NPM_PACKAGE=${DOWNSTREAM_NPM_PACKAGE}" >>"${GITHUB_ENV}"
    echo "DOWNSTREAM_NPM_PACKAGE_ENDPOINT=${DOWNSTREAM_NPM_PACKAGE_ENDPOINT}" >>"${GITHUB_ENV}"
    echo "DOWNSTREAM_VERSION_FILE=${DOWNSTREAM_VERSION_FILE}" >>"${GITHUB_ENV}"
fi

export CH5_VERSION
export CH5_COMMIT
export RELEASE_VERSION

export UPSTREAM_AUTHOR
export UPSTREAM_PROJECT
export UPSTREAM_PROJECT_BUILD_DIR
export UPSTREAM_REPO
export UPSTREAM_NPM_PACKAGE
export UPSTREAM_NPM_PACKAGE_ENDPOINT
export UPSTREAM_NPM_PACKAGE_VERSION

export DOWNSTREAM_AUTHOR
export DOWNSTREAM_AUTHOR_KEBAB
export DOWNSTREAM_PROJECT
export DOWNSTREAM_REPO
export DOWNSTREAM_NPM_PACKAGE
export DOWNSTREAM_NPM_PACKAGE_ENDPOINT
export DOWNSTREAM_VERSION_FILE
