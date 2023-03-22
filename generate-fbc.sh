#!/usr/bin/env bash

set -ex

package_name="kubevirt-hyperconverged"

helpFunction()
{
   echo "Usage: $0"
   echo -e "\t--help :   see all commands of this script"
   echo -e "\t--init-basic :   initialize a new composite fragment"
   echo -e "\t--render : render the FBC fragments"
   exit 1
}

devfile()
{
    cat <<EOT >> $1/devfile.yaml 
schemaVersion: 2.2.0
metadata:
  name: fbc-$1
  displayName: FBC $1
  description: 'File based catalog'
  language: fbc
  provider: Red Hat
components:
  - name: image-build
    image:
      imageName: ""
      dockerfile:
        uri: catalog.Dockerfile
        buildContext: "$1"
  - name: kubernetes
    kubernetes:
      inlined: placeholder
    attributes:
      deployment/container-port: 50051
      deployment/cpuRequest: "100m"
      deployment/memoryRequest: 512Mi
      deployment/replicas: 1
      deployment/storageRequest: "0"
commands:
  - id: build-image
    apply:
      component: image-build
EOT
}

composite() {
    cat <<EOT >> composite.yaml 
  - name: "$1"
    destination:
      path: $1/catalog
    strategy:
      name: basic
      template:
        schema: olm.builder.basic
        config: 
          input: components/$1.yaml
          output: catalog.json
EOT
}

config() {
    cat <<EOT >> catalog-config.yaml 
  - name: "$1"
    destination:
      baseImage: quay.io/operator-framework/opm:v1.26
      workingDir: .
    builders:
      - olm.builder.basic
EOT
}

cmd="$1"
case $cmd in
    "--help")
        helpFunction
    ;;
     "--init-basic")
        frag=$2
        from=registry.redhat.io/redhat/redhat-operator-index:v$frag
        yqOrjq=$3
        case $yqOrjq in
            "yq")
                touch components/$frag.yaml
                opm render $from -o yaml | yq "select( .package == \"$package_name\" or .name == \"$package_name\")" | yq 'select(.schema == "olm.bundle") = {"schema": .schema, "image": .image}' | yq 'select(.schema == "olm.package") = {"schema": .schema, "name": .name, "defaultChannel": .defaultChannel}' >> components/$frag.yaml
            ;;
            "jq")
                opm render $from | jq "select( .package == \"$package_name\" or .name == \"$package_name\")" | jq 'if (.schema == "olm.bundle") then {schema: .schema, image: .image} else (if (.schema == "olm.package") then {schema: .schema, name: .name, defaultChannel: .defaultChannel} else . end) end' >> components/$frag.json
            ;;
            *)
                echo "please specify if yq or jq"
                exit 1
            ;;
        esac
        mkdir $frag "$frag/catalog"
        devfile $frag 
        composite $frag
        config $frag
    ;;
    "--render")
        opm alpha render-template composite -f catalog-config.yaml -c composite.yaml --validate
    ;;
    *)
        echo "$cmd not one of the allowed flags"
        helpFunction
    ;;
esac
