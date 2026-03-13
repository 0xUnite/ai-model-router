# AI Model Router 多模型智能路由指南

> A practical guide to intelligent AI model routing — save tokens while getting optimal results.
>
> 一个实用的多模型智能路由指南：把贵的模型留给难题，把便宜的模型留给日常。

<div align="center">

[Quick Start](#-quick-start--5分钟上手) ·
[Triggers](#-触发器--triggers) ·
[Implementation](#-实现原理--implementation) ·
[Examples](#-实际案例--real-world-examples) ·
[Contributing](./CONTRIBUTING.md)

</div>

---

## 为什么需要模型路由？

| 场景 | 问题 | 解决方案 |
|------|------|----------|
| 简单问答 | 浪费 GPT-4 / GPT-5 级别能力 | → 用 MiniMax / Gemini Flash / 轻量模型 |
| 代码调试 | 需要更强推理与长上下文 | → 用 GPT-5.4 / Gemini Pro |
| 日常对话 | 默认模型成本太高 | → 用免费或低成本模型 |

**核心洞察 | Core Insight**

> 80% 的任务不需要最强模型，但如果没有路由，100% 的任务都可能被默认送去最贵的模型。

---

## 🚀 Quick Start | 5分钟上手

### 方案 A：一键安装脚本 | One-line install

```bash
curl -fsSL https://raw.githubusercontent.com/0xUnite/ai-model-router/main/install.sh | bash
```

如果你想指定安装目录：

```bash
curl -fsSL https://raw.githubusercontent.com/0xUnite/ai-model-router/main/install.sh | bash -s -- ~/.openclaw/workspace
```

### 方案 B：手动安装 | Manual setup

```bash
git clone https://github.com/0xUnite/ai-model-router.git
cd ai-model-router
chmod +x install.sh
./install.sh ~/.openclaw/workspace
```

### 安装后会做什么？

The installer will:

- 备份现有 `AGENTS.md` 为 `AGENTS.md.bak.ai-model-router.<timestamp>`
- 将本项目的路由片段追加到你的 OpenClaw `AGENTS.md`
- 输出下一步检查说明
- 不会覆盖你的其他工作区文件

### 安装完成后验证 | Verify after install

把下面三条消息发给你的 OpenClaw / agent：

```text
GPT 帮我重构这个 Python 函数
GEM 查一下今天的 AI 新闻
帮我写一个会议纪要模板
```

预期结果：

- `GPT ...` → 路由到 GPT-5.4
- `GEM ...` → 路由到 Gemini Pro
- 普通消息 → 留在默认模型（如 MiniMax）

---

## 触发器 | Triggers

| 触发词 | 模型 | 适用场景 | 优先级 |
|--------|------|----------|--------|
| `GPT` | GPT-5.4 (OpenAI Codex) | 复杂代码、深度推理、多步骤任务 | 高 |
| `GEM` | Gemini 3.1 Pro | 快速查询、中等复杂度、Google 生态任务 | 中 |
| (默认) | MiniMax 2.5 | 简单对话、日常任务、轻量草稿 | 默认 |

### 使用示例 | Examples

```text
GPT 帮我写一个 React 组件，要求支持拖拽和主题切换
GEM 查一下最新的 BTC 价格分析
今天天气怎么样？（默认走 MiniMax）
```

### 路由思路 | Routing philosophy

- **显式触发优先**：用户明确说 `GPT` / `GEM`，就不要猜。
- **默认模型兜底**：普通消息交给便宜模型处理。
- **把贵模型留给难题**：这才是省 token 的关键。

---

## 实现原理 | Implementation

### 1. 关键词检测 | Keyword Detection

使用正则表达式进行**整词匹配**，避免误触发：

```python
import re

# 匹配独立的 "GPT" 或 "GEM"
GPT_PATTERN = r'\bGPT\b'
GEM_PATTERN = r'\bGEM\b'
```

**为什么不用 substring 匹配？ | Why not substring matching?**

- `GPT` 匹配 `GPT4` → 容易误触发
- `GEM` 匹配 `emoji` → 这就离谱了
- `\b`（word boundary）确保只匹配独立单词

### 2. 路由逻辑 | Routing Logic

```python
def route_task(message: str) -> dict:
    """根据触发词路由到不同模型"""
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
    pattern = r'\b' + trigger + r'\b'
    return re.sub(pattern, '', message, flags=re.IGNORECASE).strip()

# 示例
# "GPT 帮我写代码" → "帮我写代码"
# "GEM 查BTC" → "查BTC"
```

### 4. 子任务隔离 | Subtask Isolation

- **GPT 触发**：spawn 子任务到 OpenAI Codex / GPT-5.4
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

## 实际案例 | Real-world Examples

下面这些案例，是这个路由方案真正有价值的地方。

### 1. 代码重构 | Code refactor

**输入 | Input**

```text
GPT 把这个 Node.js 脚本重构成 TypeScript，并补上类型定义
```

**为什么走 GPT？ | Why GPT?**

- 涉及多文件修改
- 需要更强代码理解
- 需要生成结构化结果

**收益 | Benefit**

避免把高复杂度编码任务塞给便宜模型，减少来回修正。

---

### 2. 快速资料查询 | Fast research lookup

**输入 | Input**

```text
GEM 查一下今天 Gemini CLI 最新发布说明
```

**为什么走 GEM？ | Why GEM?**

- 中等复杂度
- 偏搜索/整理/摘要
- 通常不需要最贵的模型

**收益 | Benefit**

查询类任务速度更快，成本更低。

---

### 3. 日常办公 | Daily office work

**输入 | Input**

```text
帮我写一份会议纪要模板，包含结论、待办和负责人
```

**为什么走默认模型？ | Why default model?**

- 模板生成属于低复杂度任务
- 不需要最强推理

**收益 | Benefit**

把预算留给真正难的任务，而不是模板活。

---

### 4. Bug 排查 | Debugging workflow

**输入 | Input**

```text
GPT 帮我分析这个 Python traceback，找出根因并给出修复方案
```

**适合场景 | Good fit**

- 有日志 + 代码上下文
- 需要逐步推理
- 需要明确修复路径

---

### 5. 投研/行情摘要 | Market / research summary

**输入 | Input**

```text
GEM 总结一下今天 BTC、ETH、SOL 的市场表现，并给 3 点观察
```

**适合场景 | Good fit**

- 检索 + 摘要 + 轻分析
- 不一定要最强模型，但要比默认模型更稳

---

### 6. 多语言润色 | Translation and polishing

**输入 | Input**

```text
把这段英文产品文案润色成更自然的中文
```

**推荐路由 | Recommended route**

- 普通润色 → 默认模型
- 高要求品牌文案 / 复杂双语改写 → `GEM` 或 `GPT`

---

## Token 节省效果 | Token Savings

| 场景 | 全量 GPT-4 / 高端模型 | 智能路由 | 节省比例 |
|------|----------------------|----------|----------|
| 简单问答 | ~500 tokens | ~50 tokens | **90%** |
| 代码审查 | ~2000 tokens | ~300 tokens | **85%** |
| 中等任务 | ~3000 tokens | ~800 tokens | **73%** |
| 复杂重构 | ~5000 tokens | ~5000 tokens | 0% |

### 成本计算示例 | Cost Calculation

假设定价（仅供参考）：

- GPT-4 / GPT-5 级别模型：`$0.03 / 1K tokens`
- Gemini Pro：`$0.01 / 1K tokens`
- MiniMax：`$0.001 / 1K tokens`

| 任务类型 | 路由前成本 | 路由后成本 | 月省（1000次） |
|----------|-----------:|-----------:|---------------:|
| 简单问答 | $0.015 | $0.0005 | **$14.5** |
| 代码审查 | $0.06 | $0.003 | **$57** |
| FAQ 生成 | $0.03 | $0.001 | **$29** |

> 真正的收益不是“所有任务都便宜”，而是“只有值得的任务才贵”。

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

```text
SIMPLE   → 免费 / 低成本模型
MEDIUM   → Gemini Pro
COMPLEX  → GPT-5.4
RESEARCH → GPT-4 + 搜索增强
```

### 3. 成本追踪 | Cost Tracking

```python
def track_cost(model: str, input_tokens: int, output_tokens: int):
    """记录各模型消耗"""
    pricing = {
        "gpt-5.4": 0.03,
        "gemini-3.1-pro": 0.01,
        "minimax-2.5": 0.001,
    }
    cost = (input_tokens + output_tokens) / 1000 * pricing[model]
    return cost
```

### 4. 企业团队玩法 | Team workflow ideas

- 为客服、研发、运营设置不同默认路由规则
- 为高风险任务（生产变更、财务分析）强制升级模型
- 按周统计各模型调用量、成本、成功率

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

**Q: 这个方案适合所有团队吗？**  
> A: 适合绝大多数“任务复杂度差异很大”的团队。如果你所有请求都高度复杂，那就没必要折腾路由。

---

## 贡献指南 | Contributing

欢迎提交：

- 新模型映射示例
- 更真实的成本数据
- 不同 Agent 框架的接入方式
- 多语言版本优化

详细说明见：[CONTRIBUTING.md](./CONTRIBUTING.md)

---

## 相关项目 | Related Projects

- [OpenClaw](https://github.com/openclaw/openclaw) - AI Agent 框架
- [Gemini CLI](https://github.com/google/gemini-cli) - Google AI CLI
- [OpenAI Codex](https://openai.com/codex) - OpenAI 编程模型

---

## 许可证 | License

MIT License — 欢迎 Fork 和 PR。

---

**维护者 | Maintainer**: 0xUnite  
**项目地址 | Repository**: https://github.com/0xUnite/ai-model-router
