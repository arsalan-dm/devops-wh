#!/bin/bash
# https://github.ibm.com/salesforce-emea/template-repo-salesforce/blob/master/scripts/bash/common.sh
# Begin Standard 'imports'
set -o pipefail

gray="\\e[94m"
blue="\\e[36m"
red="\\e[31m"
green="\\e[32m"
reset="\\e[0m"

info() { echo -e "${blue}INFO: $*${reset}"; }
error() { echo -e "${red}ERROR: $*${reset}"; }
debug() {
    if [[ "${DEBUG}" == "true" ]]; then
        echo -e "${gray}DEBUG: $*${reset}";
    fi
}

success() { echo -e "${green}✔ $*${reset}"; }
fail() { echo -e "${red}✖ $*${reset}"; exit 1; }

## Enable debug mode.
enable_debug() {
  if [[ "${DEBUG}" == "true" ]]; then
    info "Enabling debug mode."
    set -x
  fi
}

generate_getop_shift_based_on_input() {
  getoptInput=$1
  if [[ $getoptInput == *"--"* ]]; then
    echo 1
  else
    echo 2
  fi
}

# Execute a command, saving its output and exit status code, and echoing its output upon completion.
# Globals set:
#   status: Exit status of the command that was executed.
#   output: Output generated from the command.
#
run() {
  echo "$@"
  set +e
  output=$("$@" 2>&1)
  status=$?
  set -e
  echo "${output}"
}

# End standard 'imports'