# Anima 生图适配

适配层 v0.3.1 · 2026-10-10。对象为 CircleStone Labs / Comfy Org 的 Anima 系列，不是同名应用。来源：[官方模型卡的 Prompting 与 Aesthetic Version Prompting](https://huggingface.co/circlestone-labs/Anima#prompting)。官方摘记为核对日快照，下面的输出组织是本项目约定。

本适配只在用户要求 Anima 生图提示词，或已明确设置 Anima 生成用途时启用，负责最后的静态提示词交付，不决定前期艺术设计。英文提示词配用户语言说明，用户明确指定其他语言时遵从。艺术概念和分镜等请求仍按任务交付。本文件属于统一创作系统的交付层，只在对应目标明确后读取。

## 官方摘记

支持标签、自然语言和混合提示。标签小写，通常用空格，评分标签保留下划线；冲突标签优先采用 Gelbooru 写法。作者标签用 `@` 前缀，纯自然语言建议至少两句，多人物应补外貌描述。Anima-Aesthetic 不依赖质量标签，但官方允许保留 `masterpiece, best quality`；正负均不建议用评分标签。普通版本有推荐质量前缀。权重写法受支持，但效果依配置，不能沿用其他架构的权重经验。[官方模型卡](https://huggingface.co/circlestone-labs/Anima#prompting)

## 固定输出结构

以下是本项目固定格式；官方允许混合提示自由排列，并未强制下面的自然语言段序。请求生图提示词时，先在代码块外写一行「建议画幅：宽:高｜简短构图理由」，再输出 `Positive` 与 `Negative` 两个标题，每个标题下各一个 `text` 代码块。具体像素分辨率由用户按配置决定；已指定比例时沿用，明确只要提示词正文时省略建议行。默认不输出其他创作说明、版本解释、候选方案、使用教程或参数；需要处理输入矛盾时，先给一条必要说明。概念或分镜任务遵从用户要求。

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

只写选定静态时刻的可见状态，不写未来动作、镜头推移或连续时间线。图像中的方向、支撑、遮挡与受光须能成立。生成参数、参考图绑定和 LoRA 配置不能夹进正文。

### 默认完整表达

默认将选定艺术设计完整转成提示词，保留人物、事件、环境、光色、材质及画法中有实际作用的细节与关系。不因 Anima 的模型规模、推测能力或以往生成遗漏主动删减、简化或重构设计；用户可以自行调整，明确要求压缩或模型专项重构时再处理。完整不等于堆砌或扩写，篇幅依据作品需要，不设固定词数。清晰的对象名称和有序表达继续使用，质量词与既有格式保持不变。

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

A young adult kite maker with a softly tousled plum-purple bob, amber eyes, and a small freckle beneath one eye sits cross-legged on a woven mat on a seaside workshop rooftop. She wears faded indigo canvas overalls over a loose cream shirt with rolled sleeves, a vermilion bandanna around her neck, and worn canvas sneakers. Leaning forward with quiet concentration and a slight satisfied smile, she presses a small translucent coral-paper patch over a tear in the wing of an enormous handmade fish-shaped kite. One hand smooths the patch flat while the other steadies the bamboo rib immediately beneath it. Her gaze rests precisely on their contact point. A shallow dish of paste and a small brush sit on a wooden board beside her knee. A loose spool of kite line and two folded paper offcuts complete the working area.

The kite rests partly across her lap and partly on a low wooden trestle to her right, its lightweight bamboo skeleton visible through the paper skin. Its rounded fish head, broad fin-like wings, and long forked ribbon tail stretch across most of the horizontal frame. The repaired wing has one narrow split and a few older rectangular patches, each carefully integrated into the paper surface. The large circular painted fish eye is visible beyond her hands. Viewed from slightly above in a three-quarter medium-wide composition, the maker occupies the left third and the kite opens across the center and right. A cropped roof beam in the upper foreground establishes a sheltered working corner. Terracotta roof tiles and a low parapet lead toward a harbor below, where compact boats and tightly clustered seaside roofs diminish in scale. A generous strip of pale blue sky gives the intricate kite silhouette room to breathe.

Low afternoon sunlight enters from the right through the suspended edge of the kite, turning its thin ivory and coral paper luminous while leaving the bamboo ribs as delicate darker lines. Overlapping patches appear slightly denser and warmer than the surrounding paper. A broad fish-shaped shadow falls across the mat and rooftop, with softer fin edges and thin rib shadows inside it. Her hands and the repair remain clearly readable against the glowing wing. Cool sky light fills the shaded side of her face and indigo overalls; small warm reflections from the kite connect her skin and cream sleeves to the coral paper. Dry terracotta, fibrous matte paper, smooth bamboo, and coarse canvas have distinct restrained textures. Keep the strongest color contrast around her face, hands, and the repaired section; the distant harbor uses softer blue-green and muted warm planes.

An original Japanese anime narrative illustration combining graceful character drawing with carefully painted architectural scenery. Tapered colored linework defines the face, fingers, bamboo joints, and kite contours. Broad cel-shaded forms organize the figure, while subtle gouache-like brushwork gives the rooftop and harbor tactile depth. Preserve large quiet shapes between clusters of fine detail. The patch, steadying hand, old repairs, and supported kite communicate patient craftsmanship within a single still image. The oversized fish shape creates gentle visual wonder without becoming a living creature or covering the maker's face.
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
