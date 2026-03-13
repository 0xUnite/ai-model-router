#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-$HOME/.openclaw/workspace}"
AGENTS_FILE="$TARGET_DIR/AGENTS.md"
BACKUP_SUFFIX="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$TARGET_DIR"

if [[ -f "$AGENTS_FILE" ]]; then
  cp "$AGENTS_FILE" "$AGENTS_FILE.bak.ai-model-router.$BACKUP_SUFFIX"
  echo "[ai-model-router] Backup created: $AGENTS_FILE.bak.ai-model-router.$BACKUP_SUFFIX"
else
  cat > "$AGENTS_FILE" <<'EOF'
# AGENTS.md

EOF
  echo "[ai-model-router] Created new AGENTS.md at: $AGENTS_FILE"
fi

BLOCK_START="# >>> ai-model-router start >>>"
BLOCK_END="# <<< ai-model-router end <<<"

if grep -q "$BLOCK_START" "$AGENTS_FILE"; then
  echo "[ai-model-router] Routing block already exists in $AGENTS_FILE"
  exit 0
fi

cat >> "$AGENTS_FILE" <<'EOF'

# >>> ai-model-router start >>>
## AI Model Router | 多模型路由规则

### GPT Trigger
- Pattern: whole-word `GPT` (case-insensitive)
- Action:
  1. Remove only the `GPT` token from the user message
  2. Route to `openai-codex/gpt-5.4`
  3. Use for coding, deep reasoning, complex multi-step tasks

### GEM Trigger
- Pattern: whole-word `GEM` (case-insensitive)
- Action:
  1. Remove only the `GEM` token from the user message
  2. Run `gemini -m gemini-3.1-pro-preview -p "<prompt>"`
  3. Use for search, summaries, medium-complexity tasks

### Default Route
- Model: `MiniMax 2.5`
- Use for normal chat, simple drafting, and lightweight tasks

### Priority
- `GPT` > `GEM` > Default
- Whole-word matching only
- Do not trigger on substrings like `GPT4`, `emoji`, or `google`
# <<< ai-model-router end <<<
EOF

echo "[ai-model-router] Installed routing block into: $AGENTS_FILE"
echo "[ai-model-router] Next steps:"
echo "  1. Test with: GPT 帮我重构这个函数"
echo "  2. Test with: GEM 总结今天 AI 新闻"
echo "  3. Test with a normal message to confirm default routing"
