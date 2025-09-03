#!/bin/bash

# === CONFIGURATION ===
GITHUB_USER="akshay7272"
REPO="testRigor-Trigger-tests"
TOKEN="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"
WORKFLOW_FILE="testrigor.yml"
BRANCH="main"

echo "🚀 Triggering testRigor test suite via GitHub Actions..."

# === STEP 1: TRIGGER WORKFLOW ===
trigger_response=$(curl -s -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: Bearer $TOKEN" \
  "https://api.github.com/repos/$GITHUB_USER/$REPO/actions/workflows/$WORKFLOW_FILE/dispatches" \
  -d "{\"ref\":\"$BRANCH\"}")

if [[ -z "$trigger_response" ]]; then
  echo "✅ Workflow triggered successfully!"
else
  echo "⚠️ Failed to trigger workflow. Response:"
  echo "$trigger_response"
  exit 1
fi

# === STEP 2: WAIT BEFORE CHECKING STATUS ===
echo "⏳ Waiting for workflow to start..."
sleep 10

# === STEP 3: FETCH LATEST RUN ID ===
run_id=$(curl -s \
  -H "Authorization: Bearer $TOKEN" \
  "https://api.github.com/repos/$GITHUB_USER/$REPO/actions/runs" | jq -r '.workflow_runs[0].id')

if [[ "$run_id" == "null" ]]; then
  echo "❌ Could not fetch workflow run ID!"
  exit 1
fi

echo "📌 Workflow Run ID: $run_id"

# === STEP 4: POLL STATUS UNTIL COMPLETION ===
while true; do
  response=$(curl -s \
    -H "Authorization: Bearer $TOKEN" \
    "https://api.github.com/repos/$GITHUB_USER/$REPO/actions/runs/$run_id")

  status=$(echo "$response" | jq -r '.status')
  conclusion=$(echo "$response" | jq -r '.conclusion')

  echo "🔄 Current Status: $status"

  if [[ "$status" == "completed" ]]; then
    echo "----------------------------------"
    if [[ "$conclusion" == "success" ]]; then
      echo "✅ TestRigor Test Suite PASSED 🎉"
    elif [[ "$conclusion" == "failure" ]]; then
      echo "❌ TestRigor Test Suite FAILED ❌"
    else
      echo "⚠️ Workflow completed with conclusion: $conclusion"
    fi

    html_url=$(echo "$response" | jq -r '.html_url')
    echo "🔗 View logs: $html_url"
    echo "----------------------------------"
    exit 0
  fi

  sleep 10
done
