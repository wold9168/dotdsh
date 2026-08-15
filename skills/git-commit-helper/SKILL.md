---
name: git-commit-helper
description: 当用户要求撰写、构思、生成 git commit 信息时触发。用户可能会说"写commit"、"构思commit"、"生成commit信息"、"根据暂存区内容写commit"、"帮我想个commit信息"等，也包括交互过程中需要从暂存区或工作区改动推断合适 commit message 的场景。
---

# git-commit-helper

根据 git 暂存区（或工作区）的变更内容，生成符合项目现有惯例的 commit message。**仅输出文本，不执行任何 git 写入操作。**

## 工作流程

# 1. 获取变更内容

优先读取**暂存区**的变更；**当且仅当**暂存区为空，读取**工作区（工作树）**的变更；**当且仅当**工作区也为空，读取git没有追踪的变更。

```bash
# 暂存区有内容时：
git diff --cached --stat     # 文件级概览
git diff --cached            # 完整差异

# 暂存区为空时，转用工作区：
git status --short           # 文件状态概览
git diff                     # 完整差异
```

如果没有任何可提交的变更，告知用户"当前没有可提交的改动"并终止。

# 2. 推断项目惯例

读取项目的 commit 历史来了解团队使用的格式风格：

```bash
git log --format=full -5     # 最近的完整 commit message（头部信息 + 正文）
git log --oneline -10        # 一行式概览，观察 type/subject 模式
```

重点观察：
- **type 风格**：`type: subject` 还是 `[type](scope) subject` 还是其他变体
- **scope 使用**：是否标注作用域，作用域的命名方式
- **正文语言**：英文还是中文
- **署名格式**：是否存在 `Signed-off-by`、`Assisted-by` 等尾部标记

# 3. 确定 commit 信息

基于变更内容和项目惯例，确定：

- **type**：从下文的 Type 速查表中选取最匹配的
- **scope**：如果项目惯例使用 scope 且变更在明确模块内，添加 scope；否则不添加
- **subject**：简要清晰，用祈使句，首字母小写（除非专有名词），不要句号结尾
- **body**：仅在需要补充说明变更原因或影响时添加，不冗余

# 4. 输出格式

**严格**按以下顺序输出：

```
<中文 commit message，严格遵循项目惯例>

Assisted-by: <实际模型名 (provided by <供应商>) + <Agent 名>>

---

<英文 commit message，严格遵循项目惯例>

Assisted-by: <实际模型名 (provided by <供应商>) + <Agent 名>>
```

中英文 commit message 均**完全依照**项目 git log 中观察到的格式，内容上相同，**仅有语言上的差异**。如果无法从 git log 推断出明确风格，使用以下推荐格式：

```
<type>: <subject>

<可选 body 行>

Assisted-by: <实际模型名 (provided by <供应商>) + <Agent 名>>
```

**Assisted-by 字段**：**不预设默认值**。根据当前运行环境的实际情况填入——模型名、供应商、Agent 名均使用当前上下文中的真实信息。不标注使用的工具名（如 bash、question 等）。

# 5. 重要约束

- 仅输出文本 commit message。**不执行** `git add`、`git commit`、`git commit --amend` 等任何 git 写入操作。
- 不询问用户"是否需要我代劳执行 git 操作"，直接输出 commit 信息即可。
- 不使用 emoji。
- 不添加与 commit 无关的说明或总结。

## Type 速查表

| Type | 用途 |
|------|------|
| fix | 修复 bug |
| feat / feature | 新增功能 |
| feat-wip / feature-wip | 开发中的功能 |
| build | 构建工具或脚本的修改 |
| chore | 周期性琐务、杂务 |
| ci | CI 配置修改 |
| style | 代码风格调整（不影响逻辑） |
| improvement | 对已有功能的优化和改进 |
| docs / typo | 文档或代码注释的勘误 |
| refactor | 代码重构（不涉及功能变动） |
| perf / performance / optimize | 性能优化 |
| test | 测试的添加或修复 |
| revert | 回滚之前的提交 |
| deps | 第三方依赖的添加/更新/删除 |
| community | 社区相关（Issue 模板、CONTRIBUTING.md 等） |

# 最后强调

不要输出Signed-off-by字段，不要输出除了commit message的任何其他信息，包括对当前工作内容的概述、讨论、评价。你输出的内容**有且只能有**commit message，你不需要解释你的动机。你的语言风格应当简短严谨，模仿人类commit风格，且不许生造名词。

# 示例

**输入**：暂存区包含 `scheduler.go` 中新增的超时重试逻辑

**输出**：

```
在调度器中增加任务超时重试机制

Assisted-by: DeepSeek V4 Flash Free (provided by OpenCode Zen) + OpenCode

---

feat: add task timeout with retry mechanism in scheduler

Assisted-by: DeepSeek V4 Flash Free (provided by OpenCode Zen) + OpenCode
```

**输入**：暂存区包含 `README.md` 中修正了拼写错误

**输出**：

```
修正 README.md 中的拼写错误

Assisted-by: DeepSeek V4 Flash Free (provided by OpenCode Zen) + OpenCode

---

docs: fix typos in README.md

Assisted-by: DeepSeek V4 Flash Free (provided by OpenCode Zen) + OpenCode
```

**输入**：暂存区包含对 `git-commit-helper` 技能的修改

**错误输出**：

```
项目惯例为自然语言祈使句，无 type 前缀。以下是 commit 信息：

优化 git-commit-helper SKILL.md

Assisted-by: deepseek-v4-flash-free (provided by opencode/deepseek-v4-flash-free) + OpenCode

---

Refine git-commit-helper SKILL.md

Assisted-by: deepseek-v4-flash-free (provided by opencode/deepseek-v4-flash-free) + OpenCode
```

像是`项目惯例为自然语言祈使句，无 type 前缀。以下是 commit 信息：`这样不属于commit message的句子，不要出现。