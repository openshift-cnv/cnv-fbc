#!/usr/bin/env bash
# test-yq-boundary.sh - Automated boundary and regression test for generate-fbc.sh yq filters
set -eo pipefail

MIN_MINOR=12
YQ_BUNDLE_FILTER='select(.schema != "olm.bundle" or .name == null or (.name | capture("v(?<major>\d+)\.(?<minor>\d+)\.\d+") | (((.major // "0") | to_number) > 4 or (((.major // "0") | to_number) == 4 and ((.minor // "0") | to_number) >= '${MIN_MINOR}'))))'
YQ_CHANNEL_FILTER='select(.schema == "olm.channel") = {"entries": .entries | filter(.name | capture("v(?<major>\d+)\.(?<minor>\d+)\.\d+") | (((.major // "0") | to_number) > 4 or (((.major // "0") | to_number) == 4 and ((.minor // "0") | to_number) >= '${MIN_MINOR}'))), "name": .name, "package": .package, "schema": .schema}'

echo "=== Running yq Boundary Test Matrix (yq $(yq --version)) ==="

test_bundle() {
    local name="$1"
    local schema="$2"
    local expected="$3" # "keep" or "prune"
    local input="name: $name"$'\n'"schema: $schema"$'\n'
    local out
    out=$(echo "$input" | yq "$YQ_BUNDLE_FILTER")
    local actual="prune"
    if [[ -n "$out" ]]; then actual="keep"; fi
    if [[ "$actual" == "$expected" ]]; then
        printf "  [PASS] %-44s schema: %-12s -> %s (expected %s)\n" "$name" "$schema" "$actual" "$expected"
    else
        printf "  [FAIL] %-44s schema: %-12s -> %s (expected %s)\n" "$name" "$schema" "$actual" "$expected"
        exit 1
    fi
}

# 1. Bundle tests
test_bundle "kubevirt-hyperconverged-operator.v4.11.0" "olm.bundle" "prune"
test_bundle "kubevirt-hyperconverged-operator.v4.12.0" "olm.bundle" "keep"
test_bundle "kubevirt-hyperconverged-operator.v4.22.12" "olm.bundle" "keep"
test_bundle "kubevirt-hyperconverged-operator.v5.0.0" "olm.bundle" "keep"
test_bundle "kubevirt-hyperconverged-operator.v5.0.1" "olm.bundle" "keep"
test_bundle "invalid-non-versioned-bundle" "olm.bundle" "prune"
test_bundle "kubevirt-hyperconverged" "olm.package" "keep"

# 2. Channel entry tests
echo "=== Running yq Channel Entry Filter Test ==="
channel_doc=$(cat <<'EOF'
schema: olm.channel
name: stable
package: kubevirt-hyperconverged
entries:
  - name: kubevirt-hyperconverged-operator.v4.11.0
  - name: kubevirt-hyperconverged-operator.v4.12.0
  - name: kubevirt-hyperconverged-operator.v4.22.12
  - name: kubevirt-hyperconverged-operator.v5.0.0
  - name: kubevirt-hyperconverged-operator.v5.0.1
  - name: invalid-non-versioned-bundle
EOF
)

filtered_entries=$(echo "$channel_doc" | yq "$YQ_CHANNEL_FILTER" | yq '.entries[].name')
expected_entries="kubevirt-hyperconverged-operator.v4.12.0
kubevirt-hyperconverged-operator.v4.22.12
kubevirt-hyperconverged-operator.v5.0.0
kubevirt-hyperconverged-operator.v5.0.1"

if [[ "$filtered_entries" == "$expected_entries" ]]; then
    echo "  [PASS] Channel entries filtered cleanly:"
    echo "$filtered_entries" | sed 's/^/    - /'
else
    echo "  [FAIL] Channel entries mismatch!"
    echo "Actual:"
    echo "$filtered_entries"
    exit 1
fi

echo "=== All Boundary Tests PASSED Successfully ==="
