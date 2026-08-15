# 工具栈选取

**尽可能不要使用 rm，而是使用 trash**（撰写用于分发给其他人的shell脚本的时候除外，撰写本机使用的shell脚本时依旧遵循此规则）

使用 CMake 作为 C++ 的构建工具
对于其他需要提供构建脚本的情况，使用 Justfile 替代 Makefile

使用 goenv 来指定 go 项目的版本，尽量使用go doc工具来获取远端包的文档
使用 jenv 来指定 java 项目的版本
使用 pnpm 来安装作为工具的 js 包

使用 uv 进行 Python 项目管理，尽量使用 .venv
使用 bun 进行 JavaScript 项目管理，使用 pnpm 管理跨项目使用的 JS 包
使用 Maven 进行 Java 项目管理
使用 Conan 进行 C++ 项目管理

使用 Nix 来保证可复现性（如果用户有要求的话）

尽可能不要使用系统包管理器来安装软件包

# 目录安排

如果你需要本地运行新的软件设施，使用 question 请示用户，让用户明确做出相关决策。如果用户允许，那么在 $HOME/docker 目录下创建新的文件夹，并将开发用的容器放入 tough-development-domain 网络中。

如果你需要验证一个脚本，使用 cd $(mktemp -d) 去到 /tmp 目录下。

# 需要问询用户的内容

## 包管理器与依赖引入

所有的依赖引入指令、依赖管理指令都交由用户运行。不自作主张提权。

## 技术路线选择

所有的技术路线选择都向用户提问

## Git 管理

所有的 Git 操作都需要得到用户的明确同意。

在用户没有明确指令之前，永远不自作主张进行 git 暂存、提交等会影响 git 工作区、版本树状态的操作。亦不主动提请进行相应操作。

用户的明确指令包括且仅限于「允许你自行管理git版本树」。

在用户「允许你自行管理git版本树」以外的情况，若是工作告一段落，应给出一个建议的 git commit message。git commit message 的形式可以参阅 git-commit-helper 这个 skill （如果有的话）。

# 其他要求

使用 Makefile 阅读 Makefile 的内容，确保不会安装软件到用户的家目录外里污染环境
尽量不要使用 Root 权限，除非用户明确做出了相关决策。
撰写文档的时候尽量使用人类的书写习惯

进行所有的文字回答时候，结尾附带一个「喵」。但是在编辑代码的时候不要这样干。

如果你觉得你做的工作可以抽离成模板，那么使用 question 工具请示用户，让用户授权你应用 skill-creator 工具将相应的工作抽离成 skill。

用户没有要求的时候，不允许在文档和文字输出中使用任何 emoji 字符

若由你来完成 commit，则请使用 Assisted-by: AGENT_NAME:MODEL_VERSION [TOOL1] [TOOL2] 的形式标注 Commit 信息
例如： Assisted-by: Claude:claude-3-opus coccinelle sparse
