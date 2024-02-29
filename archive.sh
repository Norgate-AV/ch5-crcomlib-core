#!/usr/bin/env bash
# shellcheck disable=SC1091

set -e

. ./utils.sh

SCRIPT_DIR=$(get_script_dir)
echo "SCRIPT_DIR=${SCRIPT_DIR}"

pnpm add -g checksum

sum_file() {
    if [[ -f "${1}" ]]; then
        echo "Calculating checksum for ${1}"
        checksum -a sha256 "${1}" >"${1}".sha256
        checksum "${1}" >"${1}".sha1
    fi
}

[[ ! -d "assets" ]] && mkdir -p assets

git archive --format tar.gz --output="./assets/${APP_NAME}-${RELEASE_VERSION}.tar.gz" HEAD
git archive --format zip --output="./assets/${APP_NAME}-${RELEASE_VERSION}.zip" HEAD

cd assets

for FILE in *; do
    if [[ -f "${FILE}" ]]; then
        sum_file "${FILE}"
    fi
done

cd ${SCRIPT_DIR}
