#!/bin/bash

# get-session-token.sh
# ====================
#
# Get session token with MFA
#
# Options:
#   -h Show this help
#
# Examples:
#   # MFA
#   $ export AWS_PROFILE=<profile>
#   $ export AWS_SERIAL_NUMBER=arn:aws:iam::<aws-account-id>:mfa/<iam-user>
#   $ set-session-token.sh
#   Input duration seconds: 28800
#   Input token code: <one-time-password>
#   $ source .session-token
#
#   # MFA & swith role
#   $ export AWS_PROFILE=<profile>
#   $ export AWS_SERIAL_NUMBER=arn:aws:iam::<aws-account-id>:mfa/<iam-user>
#   $ export AWS_ROLE_ARN=arn:aws:iam::<aws-account-id>:role/<iam-role>
#   $ set-session-token.sh
#   Input duration seconds: 28800
#   Input token code: <one-time-password>
#   $ source .session-token


help() {
  awk 'NR > 2 {
    if (/^#/) { sub("^# ?", ""); print }
    else { exit }
  }' "${0}"
}


check_common_requirements() {
  if ! type 'aws' > /dev/null 2>&1; then
    echo 'Install aws command.'
    exit 1
  fi

  if ! type 'jq' > /dev/null 2>&1; then
    echo 'Install jq command.'
    exit 1
  fi

  if [ -z "$AWS_PROFILE" ]; then
    echo 'Export AWS_PROFILE.'
    echo '$ export AWS_PROFILE=<profile>'
    exit 1
  fi

  if [ -z "$AWS_SERIAL_NUMBER" ]; then
    echo 'Export AWS_SERIAL_NUMBER.'
    echo '$ export AWS_SERIAL_NUMBER=arn:aws:iam::<aws-account-id>:mfa/<iam-user>'
    exit 1
  fi
}


while getopts h option
do
  case "$option" in
    h) help; exit 0;;
    \?) help; exit 1;;
  esac
done


check_common_requirements


# Session token default duration seconds: 28800(8H)
duration_seconds=$((60 * 60 * 8))
read -e -r -p "Input duration seconds: " -i $duration_seconds duration_seconds
read -r -p "Input token code: " token_code


# Avoid the following error that occurs when obtaining a session token while the session token is already set
# An error occurred (AccessDenied) when calling the GetSessionToken operation: 
#   Cannot call GetSessionToken with session credentials
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN


if [ -z "$AWS_ROLE_ARN" ]; then
  output=$(aws sts get-session-token \
    --duration-seconds "$duration_seconds" \
    --serial-number "$AWS_SERIAL_NUMBER" \
    --token-code "$token_code")
else
  output=$(aws sts assume-role \
    --role-arn "$AWS_ROLE_ARN" \
    --role-session-name "$AWS_PROFILE" \
    --duration-seconds "$duration_seconds" \
    --serial-number "$AWS_SERIAL_NUMBER" \
    --token-code "$token_code")
fi


if [ $? -ne 0 ]; then
  echo "Make sure your aws profile, iam role, serial number, token code are correct."
  exit 1
fi


aws_access_key_id=$(echo "$output" | jq -r .Credentials.AccessKeyId)
aws_secret_access_key=$(echo "$output" | jq -r .Credentials.SecretAccessKey)
aws_session_token=$(echo "$output" | jq -r .Credentials.SessionToken)
expiration=$(echo "$output" | jq -r .Credentials.Expiration)


sessioin_token_file='.session-token'
touch $sessioin_token_file
chmod 600 $sessioin_token_file


echo "# Expiration time(UTC): $expiration" | tee $sessioin_token_file
echo "export AWS_PROFILE=$AWS_PROFILE" | tee -a $sessioin_token_file
echo "export AWS_ROLE_ARN=$AWS_ROLE_ARN" | tee -a $sessioin_token_file
echo "export AWS_ACCESS_KEY_ID=$aws_access_key_id" | tee -a $sessioin_token_file
echo "export AWS_SECRET_ACCESS_KEY=$aws_secret_access_key" | tee -a $sessioin_token_file
echo "export AWS_SESSION_TOKEN=$aws_session_token" | tee -a $sessioin_token_file
