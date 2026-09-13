# 建造与物件交互 UI：从放置到使用

![装备台：装备进化关系、分类、详情与制作材料](../media/screenshots/Equipment_Workbench.png)

从选择、放置建造物件，到制造装备和存取道具，让界面操作始终对应当前的世界上下文。

**Evan（Yaxin）Ge · C++ / Lua / UMG · ProjectZ**

[English](../README.md) · [五张截图与英文图注](../README.md#gameplay-screenshots)

*图中为与装备台交互后打开的制造界面，当前操作是“停止打造”。[素材来源与标签翻译](../media/README.md)。*

## 我的工作

建造系统由我起头开发，工作覆盖 gameplay 与配套 UI，也包括建造物件交互逻辑和面板的开发、维护。实现连接 C++ 世界操作、Lua 界面逻辑与 UMG 控件。

本案例包括建造目录和放置操作、装备台与工艺台、储存箱，以及武器架选择面板。

## 三个问题与决策

### 1. 界面操作如何与世界状态保持一致？

我通过原生放置流程的 operation mask 驱动 Lua 控件，并在派发动作前检查输入上下文与 HUD 状态。位置无效时仍允许玩家尝试确认并得到失败原因，但原生校验会阻止创建物件。

关键是区分“获得反馈”和“获准执行”。[放置流程](CASE_STUDY.md#1-from-catalogue-selection-to-placement)。

### 2. 玩家不能制造时，主按钮应该做什么？

我先判断正在生产、暂停或可领取等已有状态，再判断新制造的等级、材料和携带上限条件。等级不足进入升级引导，缺材料进入追踪，携带达到上限则阻止制造。

这让限制对应有意义的下一步，而不是统一变成灰色按钮。[装备台操作与状态](WORKBENCH_INTERACTIONS.md)。

### 3. 专用界面与通用能力的边界在哪里？

装备进化关系和按分类变化的排版，主要在加工台内部频繁迭代，因此保留专用面板。储存箱的数据结构稳定，适合共享道具／容器约定与可配置的背包式展示。材料追踪复用配方数据驱动的共同入口；武器架复用选择界面，但保留兼容规则。

复用边界取决于数据形态与变化范围，而不仅是画面是否相似。[决策故事](DECISIONS.md) · [武器架交互](SHARED_INTERACTIONS.md)。

## 实际结果

- 目录选择、上下文操作与原生校验通过明确契约连接。
- 制造操作区区分进行中的工作、可领取产物与条件恢复入口。
- 装备专属排版变化保留在功能内部，储存与选择类界面复用稳定约定。

## 深入阅读

- **案例与架构：**[完整案例](CASE_STUDY.md) · [架构](ARCHITECTURE.md) · [决策](DECISIONS.md)。
- **实现：**[代码阅读路线](CODE_TOUR.md) · [装备台](WORKBENCH_INTERACTIONS.md) · [共用交互](SHARED_INTERACTIONS.md)。
- **质量与开销：**[问题定位](DEBUGGING.md) · [储存刷新成本](PERFORMANCE.md)。
- **验证：**[为 Portfolio 新增的定向测试](TESTING.md)。
- **材料范围：**[历史工作、代码节选、测试与素材说明](EVIDENCE.md)。

关键词：input context · actionable feedback · specialised composition · shared inventory contract · scope of change。

**其他案例：**[组队 UI](https://github.com/seak123/multiplayer-ui-portfolio) · [机械兽与头顶 UI](https://github.com/seak123/mechanical-workers-ui-portfolio)。
