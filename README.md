# WIN-GO Router 多模型任务路由

> Multi-Model Task Router: 根据任务复杂度智能选择最适合的 AI 模型，节省 Token 消耗

## 核心价值

| 特性 | 说明 |
|------|------|
| **Token 节省** | 简单任务用 MiniMax，复杂任务用 GPT-5.4/Gemini 3.1，避免大炮打蚊子 |
| **任务匹配** | 不同模型擅长不同任务，按需选择最优方案 |
| **零配置** | 只需在消息前加 `WIN` 或 `GO` 关键字即可触发 |

## 触发器

| 触发词 | 模型 | 适用场景 |
|--------|------|----------|
| `WIN` | GPT-5.4 (OpenAI Codex) | 复杂代码、深度推理、多步骤任务 |
| `GO` | Gemini 3.1 Pro | 快速查询、中等复杂度任务、Google生态 |
| (默认) | MiniMax 2.5 | 简单对话、日常任务 |

## 使用方式

```
WIN 帮我写一个 React 组件，要求支持拖拽和主题切换
GO 查一下最新的 BTC 价格
1+1等于几？ (默认走 MiniMax)
```

## 实现原理

### 1. 关键词检测 (正则匹配)

```python
# 整个词匹配，避免误触发
WIN_PATTERN = r'\bWIN\b'      # 匹配 "WIN xxx"
GO_PATTERN = r'\bGO\b'        # 匹配 "GO xxx"
```

### 2. 模型路由逻辑

```python
def route_task(message: str) -> str:
    if re.search(r'\bWIN\b', message, re.IGNORECASE):
        return spawn_subagent(model="openai-codex/gpt-5.4", task=remove_trigger(message, "WIN"))
    elif re.search(r'\bGO\b', message, re.IGNORECASE):
        return exec_gemini(model="gemini-3.1-pro-preview", prompt=remove_trigger(message, "GO"))
    else:
        return run_minimax(message)  # 默认模型
```

### 3. 子任务隔离

- WIN 触发 spawn 子任务到 GPT-5.4
- GO 触发调用 Gemini CLI
- 默认任务在主上下文执行 MiniMax

## Token 节省效果

假设平均场景：

| 场景 | 全量 GPT-4 | WIN/GO 路由 | 节省 |
|------|-----------|-------------|------|
| 简单问答 | ~500 tokens | ~50 tokens (MiniMax) | **90%** |
| 代码审查 | ~2000 tokens | ~300 tokens (GO) | **85%** |
| 复杂重构 | ~5000 tokens | ~5000 tokens (WIN) | 0% |

> **关键洞察**：80% 的日常任务不需要 GPT-4 级别的能力，但往往被默认模型浪费。

## 适配其他平台

### OpenClaw 配置

在 `AGENTS.md` 中添加：

```markdown
### WIN Trigger
- Pattern: `\bWIN\b` (case-insensitive)
- Action: Spawn subagent with model="openai-codex/gpt-5.4"

### GO Trigger  
- Pattern: `\bGO\b` (case-insensitive)
- Action: Run `gemini -m gemini-3.1-pro-preview -p "<prompt>"`
```

### 自定义模型

修改配置中的模型名称即可：

```python
WIN_MODEL = "openai-codex/gpt-5.4"  # 或其他模型
GO_MODEL = "gemini-3.1-pro-preview"  # 或其他模型
```

## 扩展思路

1. **自动判断**：根据任务关键词自动路由（需结合 LLM 判断）
2. **多级路由**：添加 MEDIUM/HARD 等更多级别
3. **成本追踪**：记录每次路由的 Token 消耗

## 许可证

MIT License - 欢迎 fork 和 PR！

---

**维护者**: 0xUnite  
**项目地址**: https://github.com/0xUnite/win-go-router
