#!/usr/bin/env bash
# shellcheck disable=SC1091,2154

set -e

# include common functions
. ./utils.sh

cp -f LICENSE ${UPSTREAM_PROJECT}/LICENSE

cd ${GITHUB_WORKSPACE}/${UPSTREAM_PROJECT} || {
    echo "'${UPSTREAM_PROJECT}' dir not found"
    exit 1
}

# apply patches
{ set +x; } 2>/dev/null

for file in ../patches/*.patch; do
    if [[ -f "${file}" ]]; then
        echo applying patch: "${file}"
        if ! git apply --ignore-whitespace --verbose "${file}"; then
            echo failed to apply patch "${file}" >&2
            exit 1
        fi
    fi
done

build_date=$(date +%Y-%m-%d)
sed -i -E "s|\!\!process\.env\.BUILD_DATE\s+\?\s+process\.env\.BUILD_DATE\s+:\s+'BUILD_DATE_INVALID'|'${build_date}'|g" src/ch5-core/ch5-version.ts
sed -i -E "s|\!\!process\.env\.BUILD_VERSION\s+\?\s+process\.env\.BUILD_VERSION\s+:\s+'VERSION_NOT_SET'|'${CH5_VERSION}'|g" src/ch5-core/ch5-version.ts
cat src/ch5-core/ch5-version.ts

set -x

npm install

setpath() {
    local jsonTmp
    { set +x; } 2>/dev/null
    jsonTmp=$(jq --arg 'path' "${2}" --arg 'value' "${3}" 'setpath([$path]; $value)' "${1}.json")
    echo "${jsonTmp}" >"${1}.json"
    set -x
}

setpath_json() {
    local jsonTmp
    { set +x; } 2>/dev/null
    jsonTmp=$(jq --arg 'path' "${2}" --argjson 'value' "${3}" 'setpath([$path]; $value)' "${1}.json")
    echo "${jsonTmp}" >"${1}.json"
    set -x
}

# package.json
cp package.json{,.bak}

setpath "package" "name" "${DOWNSTREAM_NPM_PACKAGE}"
setpath "package" "version" "$(echo "${RELEASE_VERSION}" | sed -n -E "s/^(.*)\.([0-9]+)$/\1/p")"
setpath "package" "author" "${DOWNSTREAM_AUTHOR}"
setpath "package" "license" "MIT"
setpath_json "package" "repository" "{ \"type\": \"git\", \"url\": \"${DOWNSTREAM_REPO}\" }"

cat package.json

cd ${GITHUB_WORKSPACE} || ..
