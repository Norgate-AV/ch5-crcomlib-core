#!/usr/bin/env bash

function get_script_dir() {
    local scriptDir
    scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "${scriptDir}"
}

exists() { type -t "$1" &>/dev/null; }

is_gnu_sed() {
    sed --version &>/dev/null
}

replace() {
    echo "${1}"
    if is_gnu_sed; then
        sed -i -E "${1}" "${2}"
    else
        sed -i '' -E "${1}" "${2}"
    fi
}

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

if ! exists gsed; then
    if is_gnu_sed; then
        function gsed() {
            sed -i -E "$@"
        }
    else
        function gsed() {
            sed -i '' -E "$@"
        }
    fi
fi
