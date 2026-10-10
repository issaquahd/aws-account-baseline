#!/usr/bin/env bash
# Put the account-level settings back to what check.sh recorded in prior-settings.json. Run in CloudShell.
set -u
R=${AWS_REGION:-us-east-2}; ACCT=$(aws sts get-caller-identity --query Account --output text)
P=prior-settings.json
if [ "$(python3 -c 'import json;print(json.load(open("'$P'"))["s3_bpa"] is None)')" = True ]; then aws s3control delete-public-access-block --account-id "$ACCT"
else aws s3control put-public-access-block --account-id "$ACCT" --public-access-block-configuration "$(python3 -c 'import json;print(json.dumps(json.load(open("'$P'"))["s3_bpa"]))')"; fi
[ "$(python3 -c 'import json;print(json.load(open("'$P'"))["ebs_default_encryption"])')" = False ] && aws ec2 disable-ebs-encryption-by-default --region "$R" >/dev/null
[ "$(python3 -c 'import json;print(json.load(open("'$P'"))["password_policy"] is None)')" = True ] && aws iam delete-account-password-policy
echo restored
