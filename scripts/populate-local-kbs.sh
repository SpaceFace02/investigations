#!/bin/bash

set -ex

KBC=kbs-client
URL=http://localhost:8080
KEY=trustee/keys/private.key

cat <<EOF >secret
{ "key_type": "oct", "key": "2b442dd5db4478367729ef8bbf2e7480" }
EOF

$KBC --url $URL  config \
	--auth-private-key $KEY  \
	set-resource --path default/machine/root \
	--resource-file $(pwd)/secret

cat <<EOF > tmp/resource-policy.rego
package policy
import rego.v1

default allow := false

allow if {
  input.submods.cpu0["ear.status"] == "affirming"
#  input.submods.cpu0["ear.veraison.annotated-evidence"].init_data_claims.uuid == split(data["resource-path"], "/")[2]
}
EOF

$KBC --url http://localhost:8080  config \
	--auth-private-key $KEY  \
	set-resource-policy --policy-file tmp/resource-policy.rego


cat <<EOF > tmp/attestation-policy.rego
package policy
import rego.v1
default hardware := 97
default configuration := 36
default executables := 33

tpm_pcrs_valid if {
  input.tpm.pcr04 in query_reference_value("tpm_pcr4")
  input.tpm.pcr14 in query_reference_value("tpm_pcr14")
}

hardware := 2 if tpm_pcrs_valid
executables := 3 if tpm_pcrs_valid
configuration := 2 if tpm_pcrs_valid

default file_system := 0
default instance_identity := 0
default runtime_opaque := 0
default storage_opaque := 0
default sourced_data := 0
trust_claims := {
  "executables": executables,
  "hardware": hardware,
  "configuration": configuration,
  "file-system": file_system,
  "instance-identity": instance_identity,
  "runtime-opaque": runtime_opaque,
  "storage-opaque": storage_opaque,
  "sourced-data": sourced_data,
}
EOF

$KBC --url $URL  config \
	--auth-private-key $KEY  \
	set-sample-reference-value tpm_pcr4 "a396afc7b063562ec1f12225dd191bc80235b6566ae1966657d91cfa4e4e54bd"
$KBC --url $URL  config \
	--auth-private-key $KEY  \
	set-sample-reference-value tpm_pcr7 "e21b703ee69c77476bccb43ec0336a9a1b2914b378944f7b00a10214ca8fea93"
$KBC --url $URL  config \
	--auth-private-key $KEY  \
	set-sample-reference-value tpm_pcr14 "0000000000000000000000000000000000000000000000000000000000000000"

$KBC --url $URL  config \
	--auth-private-key $KEY  \
	set-attestation-policy --policy-file tmp/attestation-policy.rego --id default_cpu --type rego
