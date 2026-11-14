# Anima 生图适配

能力判断遵循[交付层的意图理解与官方核验](README.md#从用户意图判断能力)：未收录的需求先核对官方支持情况，不把本文当作能力白名单。

适配层 v0.4.0 · 2026-11-13。对象为 CircleStone Labs / Comfy Org 的 Anima 系列，不是同名应用。来源：[官方模型卡的 Prompting 与 Aesthetic Version Prompting](https://huggingface.co/circlestone-labs/Anima#prompting)。官方摘记为 2026-10-10 核对日快照，下面的输出组织与长度约定是本项目约定，不是官方限制。

本适配只在用户要求 Anima 生图提示词，或已明确设置 Anima 生成用途时启用，负责最后的静态提示词交付，不决定前期艺术设计。英文提示词配用户语言说明，用户明确指定其他语言时遵从。艺术概念和分镜等请求仍按任务交付。本文件属于统一创作系统的交付层，只在对应目标明确后读取。

## 官方摘记

支持标签、自然语言和混合提示。标签小写，通常用空格，评分标签保留下划线；冲突标签优先采用 Gelbooru 写法。作者标签用 `@` 前缀，纯自然语言建议至少两句，多人物应补外貌描述。Anima-Aesthetic 不依赖质量标签，但官方允许保留 `masterpiece, best quality`；正负均不建议用评分标签。普通版本有推荐质量前缀。权重写法受支持，但效果依配置，不能沿用其他架构的权重经验。[官方模型卡](https://huggingface.co/circlestone-labs/Anima#prompting)

## 固定输出结构

以下是本项目固定格式；官方允许混合提示自由排列，并未强制下面的自然语言段序。按[默认交付](信息保留.md#默认交付)展示完整设计后，写一行「建议画幅：宽:高｜简短构图理由」，再输出 `Positive` 与 `Negative` 两个标题，每个标题下各一个 `text` 代码块。用户已指定比例时沿用，明确只要提示词时直接给正负提示。概念或分镜任务遵从用户要求。

### Positive：标签首行＋有序画面描述

第一行只放英文逗号分隔的标签。分组顺序固定为：

`质量／媒介／年份／内容分级 → 主体数量 → 角色 → 系列 → 作者 → 通用属性`

未指定或不适用的组直接省略，不填占位词。不自动添加年份、IP、作者或内容分级。普通标签小写、单词间用空格；评分标签保留下划线；作者标签使用 `@`。人物与系列名在自然语言中按正常英文大小写。质量策略见下表，不能混用不同权重版本的评分规则。

标签行后空一行，自然语言按以下顺序分段；不适用的段省略，其余保持顺序。代码块里不写 `Subject:`、`Lighting:` 等小标题，也不写编号或艺术分析。

| 段序 | 写入内容 |
|---|---|
| 1 · 主体与姿态 | 主体外貌、服装、当前姿态、表情、视线和必要接触；多人物逐个绑定外貌与位置 |
| 2 · 构图与空间 | 景别、视角、主体位置、环境布局及关键深度关系；写明实际遮挡与空间连接 |
| 3 · 光色与材质 | 光源方向、受光与影形、整体色调、关键材料的差异及联系 |
| 4 · 绘制与细节组织 | 线、色面、边缘、笔触、细节分布与完成方式；保留具体形式，不堆品质形容词 |

标签负责可识别属性，自然语言负责位置、联系与表现；不把同一属性在四段中反复重述。构思资源按相关性展开，段序只是成稿组织，不是要求每张图具有全部效果。简洁作品可用较少段落，不能为填结构添加无关装饰；纯自然语言仅在用户明确要求时使用，至少两句完整描述。

从用户要求和选定作品设计提取媒介标签与画法描述。使用 Anima 只确定交付规则。需要日式插画时可用 `anime illustration`，其他画法按作品选择标签，或用自然语言描述具体绘制方式。

单张角色或场景插画先表达已经选定的主构图：人物姿态与取景、前景怎样遮挡或框取、背景怎样衬托，以及主要明暗色块如何分布。物件细节只保留改变身份、行动、观看路径或画面大形的部分；不能用“精致背景、电影感构图”等概括词替代可见的位置与关系。由生成结果偶然形成的好构图，不能倒认作原提示词已经设计出的内容。

只写选定静态时刻的可见状态，不写未来动作、镜头推移或连续时间线。图像中的方向、支撑、遮挡与受光须能成立。生成参数、参考图绑定和 LoRA 配置不能夹进正文。

### 默认篇幅与信息保留

普通单张插画的 Positive 自然语言默认约 120–220 个英文词，通常不超过 260 个；标签首行只选关键属性，不把自然语言的细节再列一遍。Negative 只列确有必要的排除项。这是项目的交付篇幅约定，不是模型容量或最佳效果的实测结论。用户指定更短篇幅时从其要求；明确要求复杂完整设计且关键条件无法容纳时可以超过。

从完整设计提取 Anima 提示词，优先保留身份、动作、核心画面关系及必要的空间光色。将复杂关系拆成短句，合并重复描述，次要配饰或背景纹样按可见范围与画面作用取舍。若篇幅与用户指定的核心内容冲突，优先保留核心并简短说明取舍。

### 版本与质量标签

| 实际权重 | 固定处理 |
|---|---|
| Base | 普通优质插画默认正向使用 `masterpiece, best quality, score_7`；用户另指定质量目标时调整。负向可使用 `worst quality, low quality, score_1, score_2, score_3`，其他缺陷按画面取舍 |
| Aesthetic | 正向默认使用 `masterpiece, best quality`；正负都不使用 `score_*` |
| 未指定、Turbo 或未知微调 | 正向默认使用 `masterpiece, best quality`，不使用评分标签；不因缺少版本中断成稿。用户提供微调专用规则时按其规则处理 |

本项目的普通优质插画默认添加 `masterpiece, best quality`，包括未指定权重的请求；不要将质量词与 `score_*` 评分词混为一类。Base 额外使用 `score_7`，Aesthetic 和未知版本不加评分词。用户明确不用质量词或要求其他质量目标时遵从。内容分级另按实际需求选择。没有用户需求时不添加现有角色、系列或作者标签，不猜采样参数和权重数值。

### Negative：一行负面标签

负向代码块只写小写、英文逗号分隔的有效排除项，不写句子、说明和理由。顺序为 `版本适用的质量缺陷 → 当前作品要避免的结构／内容问题 → 文字／水印等排除项`，没有需要的组省略。无有效排除项时保留空代码块，不能把“无额外负面项”写成模型输入。

不默认排除所有模糊、遮挡、形变、色差或颗粒；需要的绘画和摄影效果保留。负向不得与正向及用户要求冲突。接口不接受负向时，在交接时省略该字段，不将负向拼入正向。

## 通用／Aesthetic 完整格式示范

手工格式示范，未生成图片。以下适用于未指定权重的普通优质插画，也适用于 Aesthetic：含质量词、不含评分词。Base 的首行替换见后文。不附模板占位符或说明段。

建议画幅：4:3｜人物与展开的纸鸢左右分布，海港提供背景层次。

Positive

```text
masterpiece, best quality, anime illustration, 1girl, solo, original character, short hair, purple hair, amber eyes, overalls, sitting, kite, rooftop, harbor, afternoon

A young adult kite maker with a tousled purple bob and amber eyes sits cross-legged on a seaside rooftop. She wears indigo overalls over a cream shirt. Leaning over a large fish-shaped kite, she smooths a coral-paper patch onto its torn wing while her other hand steadies the bamboo rib beneath it. Her gaze rests on the repair.

Viewed slightly from above, the maker occupies the left third of a horizontal frame. The kite rests across her lap and a low trestle, opening its broad fins and forked tail across the center and right. A roof beam crops the upper foreground; roof tiles and a low parapet lead toward a small harbor below. Pale sky surrounds the kite's silhouette.

Afternoon sunlight passes through the kite's thin ivory and coral paper, revealing its darker bamboo ribs. Its fish-shaped shadow falls across the rooftop mat. Cool sky light fills her shaded face and overalls, while the strongest warm contrast stays around her hands and the repaired wing. The distant harbor recedes in softer blue-green tones.

An anime-inspired narrative illustration with tapered colored linework on her face, hands, and kite, broad cel-shaded forms on the figure, and soft gouache-like brushwork in the background. Keep the repair sharply readable and leave quiet shapes between clusters of detail.
```

Negative

```text
extra people, extra arms, text overlay, watermark
```

## Base 示例的明确差异

相同作品确认使用 Base 时，保留以上四段画面描述，Positive 首行改为：

```text
masterpiece, best quality, score_7, anime illustration, 1girl, solo, original character, short hair, purple hair, amber eyes, overalls, sitting, kite, rooftop, harbor, afternoon
```

Negative 改为：

```text
worst quality, low quality, score_1, score_2, score_3, extra people, extra arms, text overlay, watermark
```

通用／Aesthetic 示例和 Base 示例都包含正向质量词；仅 Base 示例包含评分词。示范中的前缀与版本规则必须保持一致。
