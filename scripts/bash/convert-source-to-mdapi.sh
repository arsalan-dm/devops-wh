#!/bin/bash
# https://github.ibm.com/salesforce-emea/template-repo-salesforce/blob/master/scripts/bash/convert-source-to-mdapi.sh
source "$(dirname "$0")/common.sh"
# +x Disabling Shell Debug Mode for Embedded Script Job
set +x
# -e Exit immediately if a command exits with a non-zero status.
set -e
info "Starting Convert Source to Metadata"

VALID_ARGS=$(getopt -o r:u:o: --long root-dir:,username:,output-dir: -- "$@")
if [[ $? -ne 0 ]]; then
  exit 1;
fi

eval set -- "$VALID_ARGS"
while [ : ]; do
  case "$1" in
    -r | --root-dir)
        argRootDir=$2
        shift 2
        ;;
    -u | --username)
        argOrgUsername=$2
        shift 2
        ;;
    -o | --output-dir)
        argOutputDir=$2
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
  info "Processing convert metadata for $argOrgUsername"
fi
if [ -z "$argOutputDir" ]; then
  argOutputDir="deploy-workspace/deploy"
  info "--output-dir not provided. Default is set to: $argOutputDir"
fi

rm -rf $argOutputDir

if [ -z "$argRootDir" ]; then
  # Deploy pre-requisites
  info "--root-dir not provided. Using force-app as default"
  argRootDir="force-app"
fi

sf project convert source --root-dir $argRootDir --output-dir $argOutputDir

nonProdWorkFlowSender="<senderType>CurrentUser</senderType>"

# > supresses the output, &> supresses the output AND it's error/warning, 2> /dev/null supresses the error/warning output but stores the command outline in variable
orgDisplayInfo=`sf org display user --target-org $argOrgUsername`

# Ensure argOrgUsername is valid as username instead of Alias
currentOrgUsername=`echo "$orgDisplayInfo" | grep "Username" | awk '{print $2}'`
currentOrgInstance=`echo "$orgDisplayInfo" | grep "Instance Url" | awk '{print $3}'`
# cookirBannerUrl=`sfdx force:apex:execute -f ./scripts/apex/anonymous-with-system-debug.apex | grep "USER_DEBUG" | awk -F"|" '{print $5}'`

find "$argOutputDir/." -type f -exec sed -i "s,__REPLACE_WITH_USERNAME__,$currentOrgUsername,g;\
s,__REPLACE_WITH_ORG_INSTANCE__,$currentOrgInstance,g" {} +