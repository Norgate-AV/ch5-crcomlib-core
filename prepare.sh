#!/usr/bin/env bash
# shellcheck disable=SC1091,2154

set -e

. ./utils.sh

SCRIPT_DIR=$(get_script_dir)
echo "SCRIPT_DIR=${SCRIPT_DIR}"

# Copy Files
cp -f LICENSE ${UPSTREAM_PROJECT}/LICENSE

cd ${UPSTREAM_PROJECT} || {
    echo "'${UPSTREAM_PROJECT}' dir not found"
    exit 1
}

# Apply Patches
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

# Remove use of environment variables for build date and version
build_date=$(date +%Y-%m-%d)
sed -i -E "s|\!\!process\.env\.BUILD_DATE\s+\?\s+process\.env\.BUILD_DATE\s+:\s+'BUILD_DATE_INVALID'|'${build_date}'|g" src/ch5-core/ch5-version.ts
sed -i -E "s|\!\!process\.env\.BUILD_VERSION\s+\?\s+process\.env\.BUILD_VERSION\s+:\s+'VERSION_NOT_SET'|'${CH5_VERSION}'|g" src/ch5-core/ch5-version.ts
cat src/ch5-core/ch5-version.ts

set -x

npm install

# Backup package.json
cp package.json{,.bak}

# Update package.json
setpath "package" "name" "${DOWNSTREAM_NPM_PACKAGE}"
setpath "package" "version" "$(echo "${RELEASE_VERSION}" | sed -n -E "s/^(.*)\.([0-9]+)$/\1/p")"
setpath "package" "author" "${DOWNSTREAM_AUTHOR}"
setpath "package" "license" "MIT"
setpath_json "package" "repository" "{ \"type\": \"git\", \"url\": \"${DOWNSTREAM_REPO}\" }"

cat package.json

cd ${SCRIPT_DIR}
