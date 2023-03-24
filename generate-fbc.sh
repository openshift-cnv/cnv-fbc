#!/usr/bin/env bash
OCP_VERSION=4.11

echo "Current OPM version is: $(opm version)"
echo "Requires OPM v1.26.4+"

if [ -z "$1" ]; then
  echo "usage: <script> <step #>"
  exit 1
fi

mkdir -p v${OCP_VERSION}/catalog/kubevirt-hyperconverged/

opm alpha render-template basic components/v${OCP_VERSION}-${1}.yaml > v${OCP_VERSION}/catalog/kubevirt-hyperconverged/catalog.yaml
