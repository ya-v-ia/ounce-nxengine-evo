#!/bin/bash
# Runs inside the container: build and report the exit status.
set -o pipefail
bash ./build-switch2.sh 2>&1 | tee /tmp/build.log
status=${PIPESTATUS[0]}
echo "BUILD_EXIT=${status}"
exit "${status}"
