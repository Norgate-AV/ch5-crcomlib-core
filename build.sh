#!/usr/bin/env bash
# shellcheck disable=SC1091

set -ex

. version.sh

if [[ "${SHOULD_BUILD}" == "yes" ]]; then
    echo "CH5_COMMIT=\"${CH5_COMMIT}\""

    . prepare_ch5componentlibrary.sh

    cd CH5ComponentLibrary || {
        echo "'CH5ComponentLibrary' dir not found"
        exit 1
    }

    npm run build:prod_all

    cd ..
fi
