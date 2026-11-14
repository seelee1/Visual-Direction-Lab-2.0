# Krea 2 生图适配（本地）

适配层 v0.6 · 官方资料核对：2026-11-14。“Krea 2”“Krea2”均可触发，面向本地使用的 Krea 2 开放权重版。官方指南推荐自然语言，并指出 Turbo 通常受益于较长、详细的描述。官方扩写范例强调让属性与动作归属具体主体、保留原有媒介及空间关系。用户的本地使用反馈是「越详细越好」，因此本项目默认详写。反馈未附原提示词、成图或具体版本，本项目尚未执行 Krea 2 生图验证。[官方提示词指南](https://github.com/krea-ai/krea-2/blob/main/docs/prompting.md) · [官方扩写范例](https://github.com/krea-ai/krea-2/blob/main/docs/expansion.txt)

用户明确要求 Krea 2 提示词或指定该生成用途时启用。先按创作系统完成设计，再按[信息保留](信息保留.md)把选定设计转换成静态画面提示词。

## 提示词写法

按[默认交付](信息保留.md#默认交付)展示完整设计后，用一个可复制的 `text` 代码块完整表达选定画面。正文用自然语言，默认采用英文（沿用官方示例语言的项目约定），用户指定语言时从其要求。画面文字保留指定原文，用引号标出并写清文字位置。横竖构图、裁切及留白等要求通过画面描述表达。

## 将选定设计写成详细画面

1. **建立整幅画面。** 尽早交代作品媒介、主要对象和观看位置，让后续细节有空间落点。根据作品明确景别、视角、主体在画幅中的占比、裁切或前后遮挡。多中心构图写出各区域的呼应。
2. **把关系与成立条件写在一起。** 每个主体的姿态、眼神、衣着和动作就近绑定。接触写清谁碰到哪里、由什么支撑、接点在当前视角是否可见。静态画面用姿态及可见痕迹呈现事件，截取项目选定的时刻。
3. **展开材质和美术语言。** 描述光从哪里来、落在哪些表面、形成怎样的亮部和影形。把色彩、笔触和纹理分配到具体对象或空间层次，例如暗部以大片蓝黑墨面组织，湿玻璃上的游移高光用几笔断开的细白线表现。用同样的方法转写参考图中希望延续的特征。
4. **按画面作用决定详略。** 决定构图、辨认、叙事或画法的细节可以充分展开。设计已经明确时，补写其在画面上的可见结果，并保留原有对象、动作和媒介。探索时也详写已确定的部分，把用户希望随机变化的维度留白。交付多个风格版本时，共享内容和构图条件，分别写出各自的视觉语言。
5. **对照设计读一遍成稿。** 核对读者能否从文字复原主体归属、空间、接触和关键形式。检查新增细节是否挡住关键部位、把重心移到别处或与媒介冲突。删去重复评价、无关装饰和推导过程。普通画面可用连贯一段，复杂画面可顺着对象或空间分成数段。

以上为项目交付约定。默认使用可观察的画面描述，省去通用质量标签、权重语法和独立负面词栏。必须排除的内容可就地写成明确约束。

用户希望画面华丽或有强烈的第一眼冲击时，先按[艺术语言](../能力/艺术语言.md#华美与视觉冲击)完成设计。正文开头写出能支撑整幅画面的轮廓、尺度或色块关系，再沿画面层次展开装饰、材质和局部动作。成稿时保留细节的分布与变化，例如裙摆的刺绣在裙边汇成连续纹带，向上沿褶峰逐渐散开。

## 写法示例

设计要点：雨夜车站的剪影插画。读图重点是旅客隔着湿玻璃看见对面亮着的窗口，玻璃上的雨线与铁窗框形成疏密对比。

```text
A two-tone screen-print illustration of a quiet station at night, viewed from inside the waiting room at seated eye level. A lone traveler sits in the lower-left foreground, seen in three-quarter back view, with their head turned toward a single lit ticket window across the tracks. Their coat and the bench merge into one broad blue-black silhouette, with a narrow amber edge along the shoulder nearest the window.

The waiting-room glass fills most of the frame. Two thick vertical iron mullions divide it into broad panes, and the distant ticket window is fully visible between them, slightly right of center. Thin, uneven rain trails gather along the edges of the glass, with wider gaps around the distant rectangle of warm light. Sparse amber flecks pick out drops near that rectangle. The platform and tracks read as low horizontal bands beneath it. Use solid ink shapes for the architecture and silhouette, broken fine lines for the rain, and visible paper grain inside the large blue-black areas.
```

本例为写法演示。展开的细节服务于三个可见关系：转头朝向远处亮窗、窗框包围而不遮住亮窗、雨线疏密让视线穿过玻璃。
