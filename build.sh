#!/usr/bin/env bash
# shellcheck disable=SC1091

set -ex

. ./utils.sh

SCRIPT_DIR=$(get_script_dir)
echo "SCRIPT_DIR=${SCRIPT_DIR}"

. get_build_version.sh

if [[ "${SHOULD_BUILD}" == "yes" ]]; then
    echo "CH5_COMMIT=\"${CH5_COMMIT}\""

    . prepare.sh

    cd ${UPSTREAM_PROJECT} || {
        echo "'${UPSTREAM_PROJECT}' dir not found"
        exit 1
    }

    npm run build:prod_all

    pwd
    ls -la ${UPSTREAM_PROJECT_BUILD_DIR}

    cd ${SCRIPT_DIR}
fi
