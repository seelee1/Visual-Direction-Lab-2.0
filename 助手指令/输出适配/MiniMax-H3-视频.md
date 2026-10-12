# MiniMax-H3 视频适配

适配层 v0.3.1 · 2026-10-10。来源为官方 [模型卡](https://huggingface.co/MiniMaxAI/MiniMax-H3)、[基础提示指南](https://huggingface.co/MiniMaxAI/MiniMax-H3/blob/main/docs/VIDEO_PROMPT_WRITING_GUIDE_base_en.md)与[全参考指南](https://huggingface.co/MiniMaxAI/MiniMax-H3/blob/main/docs/VIDEO_PROMPT_WRITING_GUIDE_ref_en.md)。以下规则用于格式适配，未接通生成环境。

本适配只在用户要求 MiniMax-H3 视频提示词，或已明确设置 H3 生成用途时启用，负责最后的字段与参考交付，不决定前期艺术设计。英文提示词配用户语言说明，台词和画面文字保持原文，用户明确指定其他语言时遵从。启用本适配后，没有参考默认 T2VA；实际参考角色不明且影响模式时简短澄清。本文件可配合核心或通用创作版独立加载，不依赖生图适配。

## 官方格式摘记

基础任务分为 T2VA、I2VA、FL2VA、L2VA。正文字段依次为 `integrated_multimodal_description`、`overall_soundscape`、`non_diegetic_music`；关键帧任务在最前写图像与起止时间对齐说明。[基础指南](https://huggingface.co/MiniMaxAI/MiniMax-H3/blob/main/docs/VIDEO_PROMPT_WRITING_GUIDE_base_en.md)

全参考任务依次用 `subject_definitions`、`summary`、`retention_analysis`、`detailed_description`、`overall_soundscape`、`non_diegetic_music`，采用英文，台词和画面文字保留原文。参考标签表示实际内容、图像、视频或音频角色，跨段含义保持一致；官方建议生成任务主描述通常为 350–500 英文词，不机械填字数。[全参考指南](https://huggingface.co/MiniMaxAI/MiniMax-H3/blob/main/docs/VIDEO_PROMPT_WRITING_GUIDE_ref_en.md)

官方模型卡区分 FL2VA 与 Ref2VA 权重，以及托管 Context-IR 处理与本地基础生成；因此格式相同不代表执行流程等效。时长范围为 4–15 秒，实际环境需另核对。[模型卡](https://huggingface.co/MiniMaxAI/MiniMax-H3)

## 固定输出结构

请求可用视频提示词时，先在代码块外写一行「建议画幅：宽:高｜简短构图理由」，再交付一个 `text` 代码块。比例依据构图及运动范围选择，具体像素分辨率由用户按配置决定；已指定比例时沿用，明确只要提示词正文时省略建议行。代码块内仅有当前模式需要的对齐句和官方字段；不加艺术方案说明、任务清单、Positive／Negative、JSON 包装或翻译版。字段名大小写与下划线保持不变，字段之间空一行，不能自创“镜头”“动作”“声音”等替代字段。用户明确要求接口 JSON 时再按已知接口封装，不猜 API 参数。

模式按实际参考职责选择，不能仅因上传文件就切到某一模式。默认纯文字 T2VA；参考角色不明且会改变模式时，只询问缺失的角色信息。概念、分镜等任务仍遵从用户指定交付。

### 基础模式：三个字段，不增不减

T2VA 正文直接从以下字段开始；I2VA、FL2VA、L2VA 在三个字段前添加对应对齐句和一个空行：

```text
integrated_multimodal_description: [Shot 1] ...

overall_soundscape: ...

non_diegetic_music: ...
```

上面的省略号仅说明模板，实际成稿必须填完整内容。`integrated_multimodal_description` 按 `风格与初始构图 → 主体及空间锚点 → 按时间发展的动作与关系 → 结束状态` 组织，声音事件写在相应动作处；每镜独立一段，段首使用 `[Shot N]`。静止镜头可持续保持，不强迫起承转合。运镜写成当前镜头中的自然语言，需要时明确幅度和速度；不能把运镜标签堆到最后。

`[Shot 1]` 不带起镜时间。真实切镜才新增 `[Shot N] At MM:SS.mmm, ...`，镜号连续，切镜时间严格递增且小于总时长。单镜头只能有 `[Shot 1]`；动作阶段不是切镜。

对齐句固定如下，单独位于代码块首行，后面空一行再写字段：

- I2VA：`For the target video, at 0.00 seconds into the target video, <Picture 1> (from [Shot 1]) is fully referenced.`
- FL2VA：`How the reference pictures align with the target video — Picture 1 (from Shot 1) aligns with the 0.00-second mark of the target video; Picture 2 (from Shot N) aligns with the S.SS-second mark of the target video.`
- L2VA：`How the reference pictures align with the target video — <Picture 1> (from [Shot N]) aligns with the S.SS-second mark of the target video.`

将 `N` 替换为实际最后镜号，`S.SS` 替换为两位小数的有效总时长。单镜头最后镜号为 1；例如八秒视频的终点为 `8.00`。不能保留模板占位符，也不能用未提供的图填引用。

### 全参考模式：六个字段，不增不减

```text
subject_definitions:
...

summary:
...

retention_analysis:
...

detailed_description:
...

overall_soundscape:
...

non_diegetic_music:
...
```

`subject_definitions` 每个需要单独追踪的参考内容一行；标签只用实际定义的 `<Subject N>`、`<Picture N>`、`<Video N>`、`<Audio N>`。图像仅提供角色外貌时，在 Subject 定义中引用来源，不自动给它新增独立 Picture 条目。视频与音频分开编号；只追踪确实启用的音轨。

`summary` 为一个简短英文段落，先写方括号任务类型前缀，再概括目标与参考职责。类型取 `keyframe completion`、`reference generation`、`video editing`、`video continuation`、`audio reuse`、`audio reference`；同时成立时用 ` + ` 连接，不重复，不因素材扩展名自动选择类型。

`retention_analysis` 每个需追踪的标签一行，写明对应镜头或职责、官方关系标记和具体保留／改变内容。视觉标记限 `fully_preserved`、`partially_preserved`、`attribute_transfer`、`weak_reference`；音频限 `fully_copy`、`partially_copy`、`reference`、`weak_reference`。不在此处写发声者 `(Sx)`，不引入未定义标签。

`detailed_description` 先用一至两句英文确立总体形式，再按 `[Shot 1]`、后续真实切镜顺序写画面和声音，首次出现的重要主体描述可见外貌、位置与动作，参考标签放在实际发生作用的位置。生成任务主描述遵循官方通常 350–500 英文词的建议，完整对白时间线与实际编辑任务优先，不用重复装饰凑字数。

### 声音、文字与语言的固定处理

正文默认英文；用户要求其他语言时遵从并保留字段／标签语法。用户提供的对白和画面文字保持原文。基础模式对白使用稳定 `(S1)` 等发声者 ID 和 `<d>[Language] 原文</d>`；参考音频的复用／重演另按全参考指南 §5.4 处理原词、听不清片段与基本标点，不能自动把只参考音色的素材台词带入作品。

`overall_soundscape` 用一个连续段落的 1–4 句写环境、物理声音和非语言人声，不重复完整对白或歌词。用户明确全程静音才填 `N/A`。`non_diegetic_music` 有配乐时用 1–3 句写乐器、节奏与动态；无配乐填 `N/A`。默认不添加对白、歌唱或配乐。场内可听见的音乐放在对应镜头正文。

画面文字使用英文双引号包围原文。旁白、跨切对白与结尾截断分别采用官方 `says in an off-screen voiceover`、`<scenetrans>`、`<cutoff>` 规则；旁白后明确画内人物嘴唇保持闭合，跨切两端标记衔接并写明声音继续。结构定稿后核对字段顺序、模式、引用角色、镜号、时间与声音分工，实际成稿不展示检查过程。

## 本项目的任务选择

| 用户提供材料的实际职责 | 当前适配 |
|---|---|
| 只有文字 | T2VA，三字段，无虚构图像引用 |
| 一张实际首帧 | I2VA，先说明首帧对齐，再描述从该状态发展的关系 |
| 实际首帧与末帧 | FL2VA，明确两端与连续中间路径，不能只串联两张静态说明 |
| 一张实际末帧 | L2VA，明确末帧角色与终点，不能当成起始画面 |
| 身份、风格、动作或声音等参考 | Ref2VA，全参考六字段；先确定每项资产用途 |

上传图片不自动意味着首帧；用户明确资产角色时直接采用。已有起止帧相互矛盾时先处理母版或路径，不能暗中替换输入图。未取得图片内容时，可以交付文字方案和待绑定说明，不能声称已对齐其外貌与构图。H3 所需资产清单和调用参数放在提示词外，不伪造文件绑定。

## 无参考单镜头格式示范

手工格式示范，未生成视频。此处没有实际输入图，因此是 T2VA。

建议画幅：4:3｜同时保留左侧人物、桌面接触与后方教室层次。

```text
integrated_multimodal_description: [Shot 1] A restrained 2D-animated classroom scene unfolds over eight seconds in a static three-quarter medium shot. A girl with a short black bob and a muted blue cardigan sits on the left, with both forearms and her overlapping hands visible on the desk. Empty desks recede behind her. Cool window light remains fixed across her shoulder and the warm desktop. She holds her gaze toward the window, then slowly lowers her eyes to the dark gap between her fingers. As her head inclines, a small lock of hair briefly interrupts the light shape on her shoulder and then settles. The desk layout and background light remain unchanged; clean linework and flat shadow shapes carry the quiet movement. There is no dialogue or cut.

overall_soundscape: Low classroom room tone continues beneath a faint rustle from her sleeve as her head inclines.

non_diegetic_music: N/A
```

若这张图实际作为首帧输入，需要改为 I2VA 并采用官方对齐说明，核对图中的姿态是否支持后续动作；不能仅加一句“使用图片”就宣称已经适配。请求超过当前支持时长或实际接口容量时，保留完整母版并说明适配取舍，不在艺术构思阶段先减掉关系。
