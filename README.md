# AI Model Router 多模型智能路由指南

> A practical guide to intelligent AI model routing - save tokens while getting optimal results

## 为什么需要模型路由？

| 场景 | 问题 | 解决方案 |
|------|------|----------|
| 简单问答 | 浪费 GPT-4 能力 | → 用 MiniMax/Gemini Flash |
| 代码调试 | 需要强推理 | → 用 GPT-5.4 / Gemini Pro |
| 日常对话 | 成本太高 | → 用免费/低成本模型 |

**核心洞察**：80% 的任务不需要最强的模型，但 100% 都在被默认模型处理。

---

## 触发器 | Triggers

| 触发词 | 模型 | 适用场景 |
|--------|------|----------|
| `GPT` | GPT-5.4 (OpenAI Codex) | 复杂代码、深度推理、多步骤任务 |
| `GEM` | Gemini 3.1 Pro | 快速查询、中等复杂度、Google 生态任务 |
| (默认) | MiniMax 2.5 | 简单对话、日常任务 |

### 使用示例 | Examples

```
GPT 帮我写一个 React 组件，要求支持拖拽和主题切换
GEM 查一下最新的 BTC 价格分析
今天天气怎么样？ (默认走 MiniMax)
```

---

## 实现原理 | Implementation

### 1. 关键词检测 | Keyword Detection

使用正则表达式进行**整词匹配**，避免误触发：

```python
import re

# 匹配 "GPT xxx" 或 "GEM xxx"
GPT_PATTERN = r'\bGPT\b'      # 完整词，不匹配 "GPT4" 或 "gpt"
GEM_PATTERN = r'\bGEM\b'      # 完整词，不匹配 "emoji" 或 "gem"
```

**为什么不用 substring 匹配？**
- "GPT" 匹配 "GPT4" → 误触发
- "GEM" 匹配 "emoji" → 误触发
- `\b` (word boundary) 确保只匹配独立单词

### 2. 路由逻辑 | Routing Logic

```python
def route_task(message: str) -> dict:
    """
    根据触发词路由到不同模型
    """
    if re.search(r'\bGPT\b', message, re.IGNORECASE):
        return {
            "model": "openai-codex/gpt-5.4",
            "task": remove_trigger(message, "GPT"),
            "type": "subagent"
        }
    elif re.search(r'\bGEM\b', message, re.IGNORECASE):
        return {
            "model": "gemini-3.1-pro-preview",
            "prompt": remove_trigger(message, "GEM"),
            "type": "cli"
        }
    else:
        return {
            "model": "minimax-2.5",
            "prompt": message,
            "type": "default"
        }
```

### 3. Token 移除 | Token Removal

```python
def remove_trigger(message: str, trigger: str) -> str:
    """移除触发词，保留剩余内容"""
    # 使用正则替换，支持大小写
    pattern = r'\b' + trigger + r'\b'
    return re.sub(pattern, '', message, flags=re.IGNORECASE).strip()

# 示例
# "GPT 帮我写代码" → "帮我写代码"
# "GEM 查BTC" → "查BTC"
```

### 4. 子任务隔离 | Subtask Isolation

- **GPT 触发**：spawn 子任务到 OpenAI Codex
- **GEM 触发**：调用 Gemini CLI
- **默认**：在主上下文执行

---

## OpenClaw 配置示例 | OpenClaw Configuration

在 `AGENTS.md` 中添加以下配置：

```markdown
### GPT Trigger
- Pattern: `\bGPT\b` (case-insensitive)
- Action: Spawn subagent with model="openai-codex/gpt-5.4"

### GEM Trigger  
- Pattern: `\bGEM\b` (case-insensitive)
- Action: Run `gemini -m gemini-3.1-pro-preview -p "<prompt>"`
```

### 自定义模型 | Custom Models

修改配置中的模型名称：

```python
# 可选模型
GPT_MODELS = [
    "openai-codex/gpt-5.4",
    "gpt-4.5",
    "gpt-4o"
]

GEM_MODELS = [
    "gemini-3.1-pro-preview",
    "gemini-2.5-pro", 
    "gemini-1.5-pro"
]
```

---

## Token 节省效果 | Token Savings

| 场景 | 全量 GPT-4 | 智能路由 | 节省比例 |
|------|-----------|----------|----------|
| 简单问答 | ~500 tokens | ~50 tokens | **90%** |
| 代码审查 | ~2000 tokens | ~300 tokens | **85%** |
| 中等任务 | ~3000 tokens | ~800 tokens | **73%** |
| 复杂重构 | ~5000 tokens | ~5000 tokens | 0% |

### 成本计算示例 | Cost Calculation

假设定价（仅供参考）：
- GPT-4: $0.03/1K tokens
- Gemini Pro: $0.01/1K tokens  
- MiniMax: $0.001/1K tokens

| 任务类型 | 路由前成本 | 路由后成本 | 月省（1000次） |
|----------|-----------|-----------|----------------|
| 简单问答 | $0.015 | $0.0005 | **$14.5** |
| 代码审查 | $0.06 | $0.003 | **$57** |

---

## 进阶扩展 | Advanced Extensions

### 1. 自动判断模式 | Auto-Detection Mode

```python
def auto_route(message: str) -> str:
    """根据任务关键词自动判断"""
    complex_keywords = ["重构", "调试", "优化", "refactor", "debug"]
    medium_keywords = ["分析", "解释", "compare", "analyze"]
    
    if any(k in message for k in complex_keywords):
        return "GPT"
    elif any(k in message for k in medium_keywords):
        return "GEM"
    else:
        return "DEFAULT"
```

### 2. 多级路由 | Multi-Level Routing

```
SIMPLE → 免费/低成本模型
MEDIUM → Gemini Pro  
COMPLEX → GPT-5.4
RESEARCH → GPT-4 + 搜索增强
```

### 3. 成本追踪 | Cost Tracking

```python
def track_cost(model: str, input_tokens: int, output_tokens: int):
    """记录各模型消耗"""
    pricing = {
        "gpt-5.4": 0.03,
        "gemini-3.1-pro": 0.01,
        "minimax-2.5": 0.001
    }
    cost = (input_tokens + output_tokens) / 1000 * pricing[model]
    return cost
```

---

## 常见问题 | FAQ

**Q: 触发词大小写敏感吗？**
> A: 不敏感，`gpt`、`Gpt`、`GPT` 都可以触发。

**Q: 可以同时使用多个触发词吗？**
> A: 建议只用一个。当前逻辑优先 `GPT` > `GEM` > 默认。

**Q: 如何添加新的模型？**
> A: 修改配置中的模型映射表即可，支持任意 LLM。

**Q: 触发器不工作怎么办？**
> A: 检查正则表达式，确保使用 `\b` 边界匹配。

---

## 相关项目 | Related Projects

- [OpenClaw](https://github.com/openclaw/openclaw) - AI Agent 框架
- [Gemini CLI](https://github.com/google/gemini-cli) - Google AI CLI
- [OpenAI Codex](https://openai.com/codex) - OpenAI 编程模型

---

## 许可证 | License

MIT License - 欢迎 Fork 和 PR！

---

**维护者**: 0xUnite  
**项目地址**: https://github.com/0xUnite/ai-model-router
