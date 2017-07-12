#!/bin/bash

if [ "$0" != "./scripts/generate-warden-manifest.sh" ]; then
    echo "'build-release.sh' should be run from repository root"
    exit 1
fi

spruce merge templates/artifactory-warden-manifest.yml my-params.yml > artifactory-warden-manifest.yml
