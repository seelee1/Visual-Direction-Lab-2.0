# Anima 生图适配

适配层 v0.2 · 2026-10-10。对象为 CircleStone Labs / Comfy Org 的 Anima 系列，不是同名应用。来源：[官方模型卡的 Prompting 与 Aesthetic Version Prompting](https://huggingface.co/circlestone-labs/Anima#prompting)。官方摘记为核对日快照，下面的输出组织是本项目约定。

本适配默认交付静态生图提示词，优先于通用核心的默认视频交付；英文提示词配用户语言说明，用户明确指定其他语言时遵从。艺术概念和分镜等请求仍按任务交付。本文件可配合核心或一个通用包独立加载，不依赖其他模型适配。

## 官方摘记

支持标签、自然语言和混合提示。标签小写，通常用空格，评分标签保留下划线；冲突标签优先采用 Gelbooru 写法。作者标签用 `@` 前缀，纯自然语言建议至少两句，多人物应补外貌描述。Anima-Aesthetic 不需要质量标签，正负均不建议用评分标签；普通版本可选质量前缀。权重写法受支持，但效果依配置，不能沿用其他架构的权重经验。[官方模型卡](https://huggingface.co/circlestone-labs/Anima#prompting)

## 本项目的成稿约定

默认输出一个英文 Positive 段和一个简短 Negative 段，二者独立可复制。Positive 采用少量清楚标签配连续描述：标签承担主体数量、媒介或明显属性，自然语言承担位置、姿态、视线、接触、光影、材料及相互关系。也可依作品采用纯自然语言；不用标签数量代替设计。

先从母版选定一个时刻，再写这个时刻真实可见的姿态与状态。动作的势能、材质受力、湿迹或环境反馈可以进入静帧，但未来动作、镜头推移和连续时序交给视频。关键帧需要给后续动作留空间时，在图中表达空间条件，不写“稍后回头”冒充当前可见内容。

权重版本未知时，使用不含评分标签的通用写法，并简短注明版本未定；不阻塞普通创作。用户确认 Base 后可选用官方质量前缀；确认 Aesthetic 时遵从其差异。Turbo 或自定义微调按实际权重说明处理，未确认时不自动给采样参数。不要把仅为版本条件的建议写成所有 Anima 的硬规则。

Negative 只写当前不想出现且确有作用的内容。可以采用少量质量缺陷词，不默认追加“禁止模糊、所有形变、所有遮挡”等与母版相冲突的套餐。作品需要运动模糊、断线、错位或压缩质感时保留它们。没有有效排除项时标为“无额外负面项”；接口是否启用负面条件另由执行环境确定。

角色名、系列名、作者标签仅在作品确有此需求时使用；自创角色不为了填槽自动补现有 IP 或作者。多主体以可辨外貌和位置绑定属性，不把所有服装颜色堆成无法归属的标签列表。风格由线、色面、影形、背景及质感的实际组织承担。

## 输出示范

以下是本项目手工格式示范，未生成图片；不是所有安静场景的模板。

Positive:

```text
1girl, solo, anime illustration. A girl with a short black bob and a muted blue cardigan sits on the left side of a classroom desk, viewed from a fixed three-quarter angle. Both forearms and her overlapping hands are clearly visible on the desktop; her gaze rests on the narrow dark gap between her fingers. Cool daylight from the window on the right draws a clean light shape across her shoulder and the warm wooden desk, while empty desks recede into the background. Restrained linework and flat shadow shapes preserve the quiet composition.
```

Negative:

```text
extra characters, text overlay, watermark
```

背景与限制来自这个具体方案，不自动加到其他作品。参考图、分辨率、随机种子和采样条件单独登记；本适配不承诺文字能保证构图、人物或接触正确。
