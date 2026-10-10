# Visual Direction Lab 2.0

面向 GPT、DeepSeek 等语言模型的独立视觉艺术与动画创作助手。让模型充分调动已有知识，主动发现具体表现、组织元素关系并作出艺术选择。重点研究日式二维，同时支持其他媒介和风格；默认交付完整视频提示词，也可用于艺术构思、静态画面、分镜与制作交接。

当前为 **v0.5 文档候选版**，整体交付已整理；不代表模型能力或成片效果全面验证。

- [开始使用](Visual-Direction-Lab-2.0/模型使用/README.md)：当前 Anima 生图 / MiniMax-H3 视频使用版，以及通用包与模块加载。
- [完整项目入口](Visual-Direction-Lab-2.0/README.md)：资源、研究与版本关系。
- [整体交付与当前状态](Visual-Direction-Lab-2.0/交付/整体交付与当前状态.md)：逐项对应项目目标，区分已交付与待验证。
- [体系架构与设计原则](Visual-Direction-Lab-2.0/交付/体系架构与设计原则.md)：核心资产、知识覆盖及创作责任。
- [艺术设计到提示词与制作交接规范](Visual-Direction-Lab-2.0/交付/艺术设计到提示词与制作交接规范.md)：模型无关的完整转换规范候选。
- [跨模型部署与任务用法](Visual-Direction-Lab-2.0/交付/跨模型部署与任务用法.md)：ChatGPT 项目、一般聊天、API 与 Codex/ComfyUI 交接。
- [评估入口](Visual-Direction-Lab-2.0/评估/README.md)：已执行测试、未执行实验及原始记录。

使用时先选一个单文件包，或使用核心与相关模块；不需要把研究报告和测试答案都交给创作模型。本项目不是现成的视频生成应用，未附生成服务密钥或已验证的 ComfyUI 工作流。

维护检查使用 PowerShell 7：

```powershell
pwsh -File ./Visual-Direction-Lab-2.0/维护/检查项目.ps1
```

检查范围和冻结文件约定见[维护说明](Visual-Direction-Lab-2.0/维护/README.md)。[原始参考样本](测试样本-1.md)保留原文，历史研究与实验不得追认成当前版本实测。局部修订与扩大效果验证留作后续工作。
