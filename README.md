# aws-account-baseline

A first-hour baseline for a new AWS account: the guardrails worth having before anything else gets built in it.
One CloudFormation stack plus two short scripts, run from CloudShell.

**Status:** linted (`cfn-lint`) and reviewed offline. Not yet deployed to a live AWS account; this line changes
when it has been.

## What it sets up

| Control | Where | Why |
|---|---|---|
| Zero-spend budget alert | `baseline.yaml` (AWS Budgets) | Emails the first time the account would bill anything |
| IAM Access Analyzer (account) | `baseline.yaml` | Flags resources shared outside the account |
| Multi-region CloudTrail trail + its own bucket | `baseline.yaml` | A record of every management API call; the bucket blocks public access, encrypts, retains on stack delete, and expires old logs |
| S3 Block Public Access (account-wide) | `check.sh` | CloudFormation can't set it |
| EBS encryption by default | `check.sh` | CloudFormation can't set it |
| IAM password policy | `check.sh` | Only matters if console users exist; set anyway |

`check.sh` records the account's prior settings to `prior-settings.json` before changing anything, then reports each
control. `restore.sh` puts those prior settings back.

## Run it

```bash
aws cloudformation deploy --stack-name account-baseline --template-file baseline.yaml \
  --parameter-overrides AlertEmail=you@example.com
./check.sh
```

The alert address is a parameter so it never lands in the repo.

## Undo it

```bash
./restore.sh
aws cloudformation delete-stack --stack-name account-baseline
```

The trail bucket is retained on delete (logs outlive the stack by design); empty and delete it by hand if you mean to.

## What it doesn't do

No GuardDuty, Security Hub or Config: each is worth having and each bills after its trial. No organization-level
controls (SCPs); this is for a single account.

MIT licence. Independent project by Alex Alvord, CloudLab Works.
