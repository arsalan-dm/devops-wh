#!/bin/bash

# Get user input - Salesforce authorisation variables
read -p "Enter the SFDX Auth URL: " sfdxAuthUrl

# Create temporary auth file
echo $sfdxAuthUrl > tmp-auth.txt

# Authorise Salesforce org
sf org login sfdx-url --sfdx-url-file tmp-auth.txt --set-default --alias ${PWD##*/}

# Delete temporary auth file
rm tmp-auth.txt