#!/usr/bin/env bash

GEMINI_API_KEY="${GEMINI_API_KEY:?GEMINI_API_KEY env var not set}"
MODEL="gemini-3.1-flash-lite"

DIFF=$(git diff --cached)

if [ -z "$DIFF" ]; then
  echo "No staged changes found. Stage your files first with git add."
  exit 1
fi

if [ ${#DIFF} -gt 10000 ]; then
  DIFF="${DIFF:0:10000}"
  DIFF="$DIFF\n\n[WARNING: Diff was truncated because it exceeded the character limit]"
fi

PROMPT="Analyze the following git diff and generate a single commit message following the Conventional Commits specification (e.g. feat: ..., fix: ..., docs: ...). Output ONLY the commit message, nothing else, no markdown, no explanation.\n\nDiff:\n$DIFF"

PAYLOAD=$(jq -n --arg prompt "$PROMPT" '{
  contents: [{parts: [{text: $prompt}]}]
}')

RESPONSE=$(curl -s \
  "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${GEMINI_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

MESSAGE=$(echo "$RESPONSE" | jq -r '.candidates[0].content.parts[0].text // empty' | tr -d '\n' | xargs)

if [ -z "$MESSAGE" ]; then
  echo "Failed to generate commit message. API response:"
  echo "$RESPONSE" | jq .
  exit 1
fi

echo "$MESSAGE commit"

