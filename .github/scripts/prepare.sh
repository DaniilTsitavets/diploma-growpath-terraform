#!/usr/bin/env bash
set -euo pipefail

layer="$1"
dir="infra/${layer}"

mask() {
  while IFS= read -r value; do
    [ -n "$value" ] && echo "::add-mask::${value}"
  done
}

echo "$STATE_BUCKET" | mask
printf 'bucket = "%s"\nregion = "eu-north-1"\n' "$STATE_BUCKET" > "${dir}/backend.hcl"

case "$layer" in
  00-org)
    jq -r '.[]' <<<"$ACCOUNT_EMAILS" | mask
    echo "$BUDGET_EMAIL" | mask
    jq -n --argjson emails "$ACCOUNT_EMAILS" --arg budget "$BUDGET_EMAIL" \
      '{account_emails: $emails, budget_notification_email: $budget}' > "${dir}/terraform.tfvars.json"
    ;;
  01-identity)
    jq -n --arg bucket "$STATE_BUCKET" '{state_bucket: $bucket}' > "${dir}/terraform.tfvars.json"
    ;;
  02-network)
    echo "$DOMAIN_NAME" | mask
    jq -n --arg domain "$DOMAIN_NAME" --arg bucket "$STATE_BUCKET" \
      '{domain_name: $domain, state_bucket: $bucket}' > "${dir}/terraform.tfvars.json"
    ;;
  03-prod)
    echo "$NETWORK_PEERING_ROLE_ARN" | mask
    jq -n --arg bucket "$STATE_BUCKET" --arg role "$NETWORK_PEERING_ROLE_ARN" \
      '{state_bucket: $bucket, network_role_arn: $role}' > "${dir}/terraform.tfvars.json"
    ;;
  *)
    echo "unknown layer: ${layer}" >&2
    exit 1
    ;;
esac
