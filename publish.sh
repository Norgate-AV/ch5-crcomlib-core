#!/usr/bin/env bash

set -e

if [[ -z "${GITHUB_TOKEN}" ]]; then
    echo "Will not release because no GITHUB_TOKEN defined"
    exit
fi

if [[ -z "${NPM_TOKEN}" ]]; then
    echo "Will not publish because no NPM_TOKEN defined"
    exit
fi

pnpm add -g @jsdevtools/npm-publish

if ! npm-publish --token "${NPM_TOKEN}" --tag "${CH5_VERSION}" --access public --debug "${UPSTREAM_PROJECT}/package.json"; then
    echo "Failed to publish to npm"
    exit 1
fi
