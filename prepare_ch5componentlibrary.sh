#!/usr/bin/env bash
# shellcheck disable=SC1091,2154

set -e

# include common functions
. ./utils.sh

# cp -rp src/stable/* vscode/
# cp -f LICENSE vscode/LICENSE.txt

cd CH5ComponentLibrary || {
    echo "'CH5ComponentLibrary' dir not found"
    exit 1
}

# apply patches
{ set +x; } 2>/dev/null

for file in ../patches/*.patch; do
    if [[ -f "${file}" ]]; then
        echo applying patch: "${file}"
        if ! git apply --ignore-whitespace "${file}"; then
            echo failed to apply patch "${file}" >&2
            exit 1
        fi
    fi
done

set -x

CHILD_CONCURRENCY=1 yarn --frozen-lockfile --check-files --network-timeout 180000

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

setpath "package" "version" "$(echo "${RELEASE_VERSION}" | sed -n -E "s/^(.*)\.([0-9]+)(-insider)?$/\1/p")"
setpath "package" "release" "$(echo "${RELEASE_VERSION}" | sed -n -E "s/^(.*)\.([0-9]+)(-insider)?$/\2/p")"

replace 's|Crestron|Norgate AV|' package.json

cd ..
