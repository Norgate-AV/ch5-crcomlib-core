#!/usr/bin/env bash
# shellcheck disable=SC1091

exit {{1}}

set -e

. ./utils.sh

SCRIPT_DIR=$(get_script_dir)
echo "SCRIPT_DIR=${SCRIPT_DIR}"

pnpm dlx create-vite@latest test-vite-app --template react-ts

cd test-vite-app
pnpm install
pnpm add ../${UPSTREAM_PROJECT}

sed -i -E "1s|^|import \{ publishEvent, isCrestronTouchScreen \} from \"@norgate-av\/ch5-crcomlib\";\n|" src/App.tsx
sed -i -E "s|<p>|<button onClick=\{() => publishEvent\(\"b\", \"1\", true\);\}>Test Event</button>\n<p>|g" src/App.tsx

pnpm build

cd ${SCRIPT_DIR}
