#!/bin/bash
# https://github.ibm.com/salesforce-emea/template-repo-salesforce/blob/master/scripts/bash/give-profile-access-to-all-fields.sh
source "$(dirname "$0")/common.sh"
# +x Disabling Shell Debug Mode for Embedded Script Job
set +x
# -e Exit immediately if a command exits with a non-zero status.
set -e

DIR=$(pwd)

VALID_ARGS=$(getopt \
    -o c:j:r:u:p: \
    --long client-id:,jwt-key-b64:,instance-url:,username:,profile-names: \
    -- "$@"
)

if [[ $? -ne 0 ]]; then
    fail "No attribute is provided"
fi

eval set -- "$VALID_ARGS"
while [ : ]; do
  case "$1" in
    -c | --client-id)
        # options are test, production
        argClientId=$2
        shift 2
        ;;
    -j | --jwt-key-b64)
        argJwtKeyB64=$2
        shift 2
        ;;
    -r | --instance-url)
        # options are delta, full
        argInstanceUrl=$2
        shift 2
        ;;
    -u | --username)
        argOrgUsername=$2
        shift 2
        ;;
    -p | --profile-names)
        argProfileNames=$2
        shift 2
        ;;
    --) shift; 
        break 
        ;;
  esac
done

if [ -z "$argOrgUsername" ]; then
    fail "Missing --username"
else
    info "Processing update for $argOrgUsername"
fi


if [ -z "$argProfileNames" ]; then
    fail "Missing --profile-names"
else
    info "Update the following profiles: $argOrgUsername"
fi

mkdir -p deploy-workspace

echo  > deploy-workspace/cci-org-details.json

# Delete profiles from update command
profileUpdateSource="${DIR}/deploy-workspace/profile-update/source"
profileDeployTarget="${DIR}/deploy-workspace/profile-update/mdapi"
rm -rf $profileUpdateSource
rm -rf $profileDeployTarget

mkdir -p $profileUpdateSource
mkdir -p $profileDeployTarget
cp -r ./force-app $profileUpdateSource

findProfilesNotAffectedCmd="find $profileUpdateSource/force-app/main/default/profiles/ -type f"
IFS=',' read -r -a profileNamesArray <<< $argProfileNames
for profileName in "${profileNamesArray[@]}"
do
    findProfilesNotAffectedCmd+=" \! -name  \"$profileName.profile-meta.xml\""
done
deletePtofilesNotAffectedFromDeployCmd="$findProfilesNotAffectedCmd -exec rm {} \;"
eval $deletePtofilesNotAffectedFromDeployCmd

# Create Full Package and Use Package XML to ensure FLS is added for all fields

./scripts/bash/convert-source-to-mdapi.sh --root-dir "$profileUpdateSource/force-app" --output-dir "$profileDeployTarget" --username $argOrgUsername
if [ ! -z "$argClientId" ]; 
then
    # Set Environment Details for CCI JWT Connection
    export CUMULUSCI_KEYCHAIN_CLASS=cumulusci.core.keychain.EnvironmentProjectKeychain
    export CUMULUSCI_ORG_targetorg="{\"username\": \"$argOrgUsername\", \"instance_url\": \"$argInstanceUrl\"}"
    export SFDX_CLIENT_ID=$argClientId
    export SFDX_HUB_KEY=`echo $argJwtKeyB64 | base64 --decode`
else
    # Import Environment as Scratch Orgs
    cci org import "$argOrgUsername" targetorg
fi

cci task run update_admin_profile --org targetorg --api_names "$argProfileNames" --package_xml "$profileDeployTarget/package.xml"