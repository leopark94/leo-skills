#!/bin/zsh
# terraform-guard.sh — PreToolUse(Bash) hook: validate terraform commands
# Blocks destructive terraform apply without plan review
# Config-driven via .leo-hooks.yaml terraform-guard section

set -euo pipefail

# Load shared config
SCRIPT_DIR="${0:A:h}"
if [[ ! -f "$SCRIPT_DIR/_config.sh" ]]; then
  exit 0
fi
source "$SCRIPT_DIR/_config.sh"

# Check if terraform guard is enabled
if ! leo_config_enabled "terraform-guard.enabled"; then
  exit 0
fi

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

[[ "$TOOL_NAME" != "Bash" ]] && exit 0

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[[ -z "$COMMAND" ]] && exit 0

# Only inspect terraform commands
if ! echo "$COMMAND" | grep -q 'terraform'; then
  exit 0
fi

# Block banned actions unconditionally
if echo "$COMMAND" | grep -qE 'terraform\s+destroy'; then
  echo "BLOCKED: terraform destroy is banned"
  echo "-> Use terraform plan -destroy to preview, then get approval"
  exit 2
fi

if echo "$COMMAND" | grep -qE 'terraform\s+apply\s+.*-auto-approve'; then
  echo "BLOCKED: terraform apply -auto-approve is banned"
  echo "-> Run terraform plan first, review changes, then apply without -auto-approve"
  exit 2
fi

# Require plan before apply
if leo_config_enabled "terraform-guard.require-plan-before-apply"; then
  if echo "$COMMAND" | grep -qE 'terraform\s+apply' && ! echo "$COMMAND" | grep -qE 'terraform\s+plan'; then
    # Check if a plan file exists (terraform apply plan.out)
    if ! echo "$COMMAND" | grep -qE 'terraform\s+apply\s+\S+\.out|terraform\s+apply\s+\S+\.tfplan'; then
      echo "BLOCKED: terraform apply requires a plan file"
      echo "-> Run 'terraform plan -out=plan.out' first, review the output"
      echo "-> Then 'terraform apply plan.out'"
      exit 2
    fi
  fi
fi

exit 0
