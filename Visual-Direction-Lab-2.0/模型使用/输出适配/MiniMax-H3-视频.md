# MiniMax-H3 视频适配

适配层 v0.2 · 2026-10-10。来源为官方 [模型卡](https://huggingface.co/MiniMaxAI/MiniMax-H3)、[基础提示指南](https://huggingface.co/MiniMaxAI/MiniMax-H3/blob/main/docs/VIDEO_PROMPT_WRITING_GUIDE_base_en.md)与[全参考指南](https://huggingface.co/MiniMaxAI/MiniMax-H3/blob/main/docs/VIDEO_PROMPT_WRITING_GUIDE_ref_en.md)。以下规则用于格式适配，未接通生成环境。

本适配默认交付视频提示词，特定字段优先于通用核心的自然段默认交付；英文提示词配用户语言说明，台词和画面文字保持原文，用户明确指定其他语言时遵从。没有参考默认 T2VA；实际参考角色不明且影响模式时简短澄清。本文件可配合核心或一个通用包独立加载，不依赖生图适配。

## 官方格式摘记

基础任务分为 T2VA、I2VA、FL2VA、L2VA。正文字段依次为 `integrated_multimodal_description`、`overall_soundscape`、`non_diegetic_music`；关键帧任务在最前写图像与起止时间对齐说明。[基础指南](https://huggingface.co/MiniMaxAI/MiniMax-H3/blob/main/docs/VIDEO_PROMPT_WRITING_GUIDE_base_en.md)

全参考任务依次用 `subject_definitions`、`summary`、`retention_analysis`、`detailed_description`、`overall_soundscape`、`non_diegetic_music`，采用英文，台词和画面文字保留原文。参考标签表示实际内容、图像、视频或音频角色，跨段含义保持一致；官方建议生成任务主描述通常为 350–500 英文词，不机械填字数。[全参考指南](https://huggingface.co/MiniMaxAI/MiniMax-H3/blob/main/docs/VIDEO_PROMPT_WRITING_GUIDE_ref_en.md)

官方模型卡区分 FL2VA 与 Ref2VA 权重，以及托管 Context-IR 处理与本地基础生成；因此格式相同不代表执行流程等效。时长范围为 4–15 秒，实际环境需另核对。[模型卡](https://huggingface.co/MiniMaxAI/MiniMax-H3)

## 本项目的任务选择

| 用户提供材料的实际职责 | 当前适配 |
|---|---|
| 只有文字 | T2VA，三字段，无虚构图像引用 |
| 一张实际首帧 | I2VA，先说明首帧对齐，再描述从该状态发展的关系 |
| 实际首帧与末帧 | FL2VA，明确两端与连续中间路径，不能只串联两张静态说明 |
| 一张实际末帧 | L2VA，明确末帧角色与终点，不能当成起始画面 |
| 身份、风格、动作或声音等参考 | Ref2VA，全参考六字段；先确定每项资产用途 |

上传图片不自动意味着首帧；用户明确资产角色时直接采用。已有起止帧相互矛盾时先处理母版或路径，不能暗中替换输入图。未取得图片内容时，可以交付文字方案和待绑定说明，不能声称已对齐其外貌与构图。H3 所需资产清单和调用参数放在提示词外，不伪造文件绑定。

## 画面与声音的转换

正文采用可独立理解的英文画面关系，按当前任务保留事件、连接、方向、光影、风格和节奏；单镜头保持单镜头。标签与字段只负责表达，不负责创造技巧。静帧已经规定的身份和布局与时间变化分别写清，不逐字重描所有背景装饰。

镜头标记从 `[Shot 1]` 开始，首镜不加切镜时间，后续实际切镜才增加递增时间；运镜用自然语言写在对应画面中。发声者用稳定 ID，台词以 `<d>[Language] ...</d>` 承载，保留用户原文。环境和实体声音放入 soundscape，角色能听到的音乐属于场内事件；无配乐用 `N/A`，只有明确全程无声才将 soundscape 设为 `N/A`。[基础指南](https://huggingface.co/MiniMaxAI/MiniMax-H3/blob/main/docs/VIDEO_PROMPT_WRITING_GUIDE_base_en.md)

本项目默认不为视觉任务添加台词或配乐；可以补与已选事件相符的环境声和实体声音。用户指定静音、对白、音乐或声画关系时优先保留。不要为凑字段把安静镜头写成音乐高潮，也不将模型支持音频误解为必须有音乐。

全参考中，先建立实际资产和目标内容的关系，再写保留或转移职责；这些是生成指令，不是已验证保真度。完整描述承担具体画面，不能被六段资产清单代替。没有真实参考材料时不输出假 `<Subject N>` 或 `<Audio N>`。

官方要求的对齐句、复杂声画跨切标记和保留关系枚举，遇到相关任务时从已提供的指南取用；本摘要不假装替代全部语法。直接本地运行时提供对应指南全文或核验后的接口转换，不能把第三方 `@image1` 写法自动当作官方格式。

对齐的必要信息不可省略：I2VA 的 Picture 1 对齐 Shot 1 的 0.00 秒；FL2VA 的 Picture 1 对齐起点，Picture 2 对齐实际最后一镜的总时长终点；L2VA 的 Picture 1 只对齐终点。起止时刻保留两位小数，镜号和时长按当前作品填写。[基础指南](https://huggingface.co/MiniMaxAI/MiniMax-H3/blob/main/docs/VIDEO_PROMPT_WRITING_GUIDE_base_en.md)

全参考标签为 `<Subject N>`、`<Picture N>`、`<Video N>`、`<Audio N>`。视觉保留关系采用 `fully_preserved`、`partially_preserved`、`attribute_transfer` 或 `weak_reference`；音频采用 `fully_copy`、`partially_copy`、`reference` 或 `weak_reference`，只对已定义角色评判，不能把新增剧情当成参考丢失。[全参考指南](https://huggingface.co/MiniMaxAI/MiniMax-H3/blob/main/docs/VIDEO_PROMPT_WRITING_GUIDE_ref_en.md)

## 无参考单镜头格式示范

手工格式示范，未生成视频。此处没有实际输入图，因此是 T2VA。

```text
integrated_multimodal_description: [Shot 1] A restrained 2D-animated classroom scene unfolds over eight seconds in a static three-quarter medium shot. A girl with a short black bob and a muted blue cardigan sits on the left, with both forearms and her overlapping hands visible on the desk. Empty desks recede behind her. Cool window light remains fixed across her shoulder and the warm desktop. She holds her gaze toward the window, then slowly lowers her eyes to the dark gap between her fingers. As her head inclines, a small lock of hair briefly interrupts the light shape on her shoulder and then settles. The desk layout and background light remain unchanged; clean linework and flat shadow shapes carry the quiet movement. There is no dialogue or cut.

overall_soundscape: Low classroom room tone continues beneath a faint rustle from her sleeve as her head inclines.

non_diegetic_music: N/A
```

若这张图实际作为首帧输入，需要改为 I2VA 并采用官方对齐说明，核对图中的姿态是否支持后续动作；不能仅加一句“使用图片”就宣称已经适配。请求超过当前支持时长或实际接口容量时，保留完整母版并说明适配取舍，不在艺术构思阶段先减掉关系。
