#!/usr/bin/env bash
# Turn on the two account-level settings CloudFormation can't, then report every baseline control. Run in CloudShell.
set -u
R=${AWS_REGION:-us-east-2}; ACCT=$(aws sts get-caller-identity --query Account --output text)
aws s3control put-public-access-block --account-id "$ACCT" --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
aws ec2 enable-ebs-encryption-by-default --region "$R" >/dev/null
aws iam update-account-password-policy --minimum-password-length 14 --require-symbols --require-numbers \
  --require-uppercase-characters --require-lowercase-characters --max-password-age 90 --password-reuse-prevention 12
ok(){ printf '%-34s %s\n' "$1" "$2"; }
ok "root MFA" "$(aws iam get-account-summary --query 'SummaryMap.AccountMFAEnabled' --output text | sed 's/1/on/;s/0/OFF/')"
ok "S3 Block Public Access (account)" "$(aws s3control get-public-access-block --account-id "$ACCT" --query 'PublicAccessBlockConfiguration.[BlockPublicAcls,IgnorePublicAcls,BlockPublicPolicy,RestrictPublicBuckets]' --output text | tr '\t' ' ')"
ok "EBS default encryption ($R)" "$(aws ec2 get-ebs-encryption-by-default --region "$R" --query EbsEncryptionByDefault --output text)"
ok "Access Analyzer" "$(aws accessanalyzer list-analyzers --region "$R" --query 'analyzers[?name==`baseline-external-access`].status' --output text)"
ok "CloudTrail logging" "$(aws cloudtrail get-trail-status --name baseline-trail --region "$R" --query IsLogging --output text)"
ok "Password policy min length" "$(aws iam get-account-password-policy --query PasswordPolicy.MinimumPasswordLength --output text)"
ok "Root access keys" "$(aws iam get-account-summary --query 'SummaryMap.AccountAccessKeysPresent' --output text | sed 's/0/none/;s/1/PRESENT/')"
