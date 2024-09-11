#!/usr/bin/env bash

declare -A OPM_VERSIONS=(["v4.12"]="v1.27.1" ["v4.13"]="v1.27.1" ["v4.14"]="v1.27.1" ["v4.15"]="v1.27.1" ["v4.16"]="v1.27.1" ["v4.17"]="v1.39.0" )
DEFAULT_OPM_VERSION="v1.39.0"

download_opm_clients () {
  for opm_version in "${OPM_VERSIONS[@]}"; do wget "https://github.com/operator-framework/operator-registry/releases/download/${opm_version}/linux-$(uname -m | sed 's/aarch64/arm64/;s/x86_64/amd64/')-opm" -O "opm-${opm_version}"; chmod +x "opm-${opm_version}"; done
}

opm_per_ocp_minor() {
  echo opm-"${OPM_VERSIONS[$1]:-${DEFAULT_OPM_VERSION}}"
}
