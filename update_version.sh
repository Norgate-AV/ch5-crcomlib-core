#!/usr/bin/env bash

set -e

if [[ "${SHOULD_BUILD}" != "yes" ]]; then
    echo "Will not update version.json because we did not build"
    exit 0
fi

if [[ -z "${GITHUB_TOKEN}" ]]; then
    echo "Will not update version.json because no GITHUB_TOKEN defined"
    exit 0
fi

jsonTmp=$(cat "version.json" | jq --arg 'version' "${CH5_VERSION}" --arg 'commit' "${CH5_COMMIT}" '. | .version=$version | .commit=$commit')
echo "${jsonTmp}" >"version.json" && unset jsonTmp

# git config user.email "$(echo "${GITHUB_USERNAME}" | awk '{print tolower($0)}')-ci@not-real.com"
# git config user.name "${GITHUB_USERNAME} CI"
# git add .

CHANGES=$(git status --porcelain)
echo "CHANGE=${CHANGES}"
# if [[ -n "${CHANGES}" ]]; then
#     git commit -m "build(stable): update to commit ${CH5_COMMIT:0:7}"

#     BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)

#     if ! git push origin "${BRANCH_NAME}" --quiet; then
#         git pull origin "${BRANCH_NAME}"
#         git push origin "${BRANCH_NAME}" --quiet
#     fi
# fi

cd ..
