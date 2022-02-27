#!/bin/bash

# get-session-token.sh
# ====================
#
# Get a session token when doing multi-factor authentication(MFA) or switch roles.
#
# Options:
#   -h Show this help
#
# Examples:
#   # Without MFA
#     # Switch role
#     $ export AWS_PROFILE=<profile>
#     $ export AWS_ROLE_ARN=arn:aws:iam::<aws-account-id>:role/<iam-role>
#     $ export AWS_ROLE_SESSION_NAME=<iam-user>
#     $ eval $(get-session-token.sh)
#     Input duration seconds: 28800
#
#   # With MFA
#     # Only MFA
#     $ export AWS_PROFILE=<profile>
#     $ export AWS_SERIAL_NUMBER=arn:aws:iam::<aws-account-id>:mfa/<iam-user>
#     $ eval $(get-session-token.sh)
#     Input duration seconds: 28800
#     Input token code: <one-time-password>
#
#     # MFA & swith role
#     $ export AWS_PROFILE=<profile>
#     $ export AWS_SERIAL_NUMBER=arn:aws:iam::<aws-account-id>:mfa/<iam-user>
#     $ export AWS_ROLE_ARN=arn:aws:iam::<aws-account-id>:role/<iam-role>
#     $ export AWS_ROLE_SESSION_NAME=<iam-user>
#     $ eval $(get-session-token.sh)
#     Input duration seconds: 28800
#     Input token code: <one-time-password>


help() {
  awk 'NR > 2 {
    if (/^#/) { sub("^# ?", ""); print }
    else { exit }
  }' "${0}"
}


check_common_requirements() {
  if ! type 'aws' > /dev/null 2>&1; then
    echo 'Install aws cli.' >&2
    exit 1
  fi

  if ! type 'session-manager-plugin' > /dev/null 2>&1; then
    echo 'Install session manager plugin.' >&2
    exit 1
  fi

  if ! type 'jq' > /dev/null 2>&1; then
    echo 'Install jq command.' >&2
    exit 1
  fi

  if [ -z "$AWS_PROFILE" ]; then
    echo 'Export AWS_PROFILE.' >&2
    echo '$ export AWS_PROFILE=<profile>' >&2
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

# Avoid the following error that occurs when obtaining a session token while the session token is already set
# An error occurred (AccessDenied) when calling the GetSessionToken operation: 
#   Cannot call GetSessionToken with session credentials
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN


# Session token default duration seconds: 28800(8H)
duration_seconds=$((60 * 60 * 8))
read -e -r -p "Input duration seconds: " -i $duration_seconds duration_seconds


if [ -z "$AWS_SERIAL_NUMBER" ]; then
  # Without MFA
  # Siwtch role
  credential=$(aws sts assume-role \
    --role-arn "$AWS_ROLE_ARN" \
    --role-session-name "$AWS_ROLE_SESSION_NAME")
else
  # With MFA
  read -r -p "Input token code: " token_code

  if [ -z "$AWS_ROLE_ARN" ]; then
    # Only MFA
    credential=$(aws sts get-session-token \
      --duration-seconds "$duration_seconds" \
      --serial-number "$AWS_SERIAL_NUMBER" \
      --token-code "$token_code")
  else
    # MFA and Switch Role
    credential=$(aws sts assume-role \
      --role-arn "$AWS_ROLE_ARN" \
      --role-session-name "$AWS_ROLE_SESSION_NAME" \
      --serial-number "$AWS_SERIAL_NUMBER" \
      --token-code "$token_code")
  fi
fi


if [ $? -ne 0 ]; then
  echo "Make sure your aws profile, iam role, serial number, token code are correct." >&2
  exit 1
fi


aws_access_key_id=$(echo "$credential" | jq -r .Credentials.AccessKeyId)
aws_secret_access_key=$(echo "$credential" | jq -r .Credentials.SecretAccessKey)
aws_session_token=$(echo "$credential" | jq -r .Credentials.SessionToken)
expiration=$(echo "$credential" | jq -r .Credentials.Expiration)


echo "export AWS_PROFILE=$AWS_PROFILE"
echo "export AWS_SERIAL_NUMBER=$AWS_SERIAL_NUMBER"
echo "export AWS_ROLE_ARN=$AWS_ROLE_ARN"
echo "export AWS_ROLE_SESSION_NAME=$AWS_ROLE_SESSION_NAME"
echo "export AWS_ACCESS_KEY_ID=$aws_access_key_id"
echo "export AWS_SECRET_ACCESS_KEY=$aws_secret_access_key"
echo "export AWS_SESSION_TOKEN=$aws_session_token"
echo "# Expiration time(UTC): $expiration" >&2