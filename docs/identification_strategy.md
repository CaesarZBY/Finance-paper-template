# Identification Strategy / 识别策略

This document records the identification strategy, endogeneity concerns, robustness checks, and selection-bias tests of the empirical paper.

本文件用于记录实证论文的识别策略、内生性问题、稳健性检验和样本选择偏差处理方法。

---

# 1. Purpose of This Document / 本文件目的

The purpose of this document is not to list every possible method mechanically.

本文件的目的不是机械地罗列所有方法。

Instead, it should help the researcher and Codex decide:

而是帮助研究者和 Codex 判断：

1. What is the main identification problem?
   主要识别问题是什么？

2. Which method is appropriate?
   哪种方法适合？

3. What assumptions are required?
   该方法需要满足什么假设？

4. What limitations remain?
   还剩下哪些局限？

5. How should the result be reported in the paper?
   结果应该如何写进论文？

---

# 2. Core Causal Question / 核心因果问题

## Main research question / 主要研究问题

Write the main research question here.

在这里写出本文的主要研究问题。

Example:

How does informal institutional distance affect CSR decoupling?

写在这里：

[To be completed]

---

## Main causal relationship / 主要因果关系

```text
X → Y
```

X / 自变量：

Y / 因变量：

Expected direction / 预期方向：

* [ ] Positive / 正向
* [ ] Negative / 负向
* [ ] U-shaped / U 型
* [ ] Inverted U-shaped / 倒 U 型
* [ ] Uncertain / 不确定

---

# 3. Main Endogeneity Concerns / 主要内生性问题

## 3.1 Omitted Variable Bias / 遗漏变量偏误

Concern / 问题：

[To be completed]

Why this may bias the result / 为什么会造成偏误：

[To be completed]

Possible solutions / 可能解决方法：

* [ ] firm fixed effects / 企业固定效应
* [ ] year fixed effects / 年份固定效应
* [ ] industry-year fixed effects / 行业-年份固定效应
* [ ] country-year fixed effects / 国家-年份固定效应
* [ ] richer controls / 增加控制变量
* [ ] IV / 工具变量
* [ ] DID / 双重差分
* [ ] placebo tests / 安慰剂检验
* [ ] other / 其他：

---

## 3.2 Reverse Causality / 反向因果

Concern / 问题：

[To be completed]

Example logic / 可能逻辑：

Instead of X affecting Y, Y may also affect X.

不是 X 影响 Y，而是 Y 可能反过来影响 X。

Possible solutions / 可能解决方法：

* [ ] lagged independent variable / 滞后自变量
* [ ] lagged controls / 滞后控制变量
* [ ] DID / 双重差分
* [ ] IV / 工具变量
* [ ] dynamic specification / 动态模型
* [ ] other / 其他：

---

## 3.3 Measurement Error / 测量误差

Concern / 问题：

[To be completed]

Which variable may have measurement error? / 哪些变量可能有测量误差？

* [ ] dependent variable / 因变量
* [ ] independent variable / 自变量
* [ ] mechanism variable / 机制变量
* [ ] moderator variable / 调节变量
* [ ] control variables / 控制变量

Possible solutions / 可能解决方法：

* [ ] alternative dependent variable / 替换因变量
* [ ] alternative independent variable / 替换自变量
* [ ] alternative data source / 替换数据来源
* [ ] manually verified data / 人工核对数据
* [ ] IV / 工具变量
* [ ] other / 其他：

---

## 3.4 Sample Selection Bias / 样本选择偏差

Concern / 问题：

[To be completed]

Possible examples / 可能例子：

1. Only firms with CSR reports are observed.
   只有披露 CSR 报告的企业才被观察到。

2. Only firms with overseas subsidiaries are included.
   只有有海外子公司的企业才进入样本。

3. Only firms with analyst coverage are observed.
   只有有分析师覆盖的企业才进入样本。

4. Only firms with complete financial data are used.
   只有财务数据完整的企业才被使用。

Possible solutions / 可能解决方法：

* [ ] Heckman two-stage model / Heckman 两阶段模型
* [ ] PSM / 倾向得分匹配
* [ ] entropy balancing / 熵平衡
* [ ] sample selection discussion / 样本选择讨论
* [ ] compare included and excluded firms / 比较进入样本和未进入样本企业
* [ ] other / 其他：

---

## 3.5 Non-random Treatment Assignment / 非随机处理组分配

Concern / 问题：

[To be completed]

Possible solutions / 可能解决方法：

* [ ] DID / 双重差分
* [ ] PSM / 倾向得分匹配
* [ ] entropy balancing / 熵平衡
* [ ] covariate balance check / 协变量平衡性检验
* [ ] placebo treatment group / 虚假处理组
* [ ] other / 其他：

---

# 4. Baseline Identification Logic / 基准识别逻辑

## Baseline model / 基准模型

Write the planned baseline model.

写出计划使用的基准模型。

Example:

```text
Y_it = β0 + β1 X_it + Controls_it + Firm FE + Year FE + ε_it
```

Actual model / 实际模型：

```text
[To be completed]
```

---

## Source of identification / 识别来源

Explain where the identifying variation comes from.

解释系数识别来自哪里。

Possible examples:

* within-firm variation over time / 企业内部随时间变化
* within-country variation over time / 国家内部随时间变化
* between-firm variation within the same year / 同一年份不同企业之间差异
* policy-induced variation / 政策冲击带来的变化
* country-level institutional variation / 国家层面制度差异

Write here / 写在这里：

[To be completed]

---

# 5. Fixed Effects Strategy / 固定效应策略

| Fixed Effect / 固定效应          | Use? / 是否使用 | Purpose / 目的                                                     | Concern Addressed / 解决的问题 |
| ---------------------------- | ----------- | ---------------------------------------------------------------- | ------------------------- |
| Firm FE / 企业固定效应             |             | Controls for time-invariant firm characteristics / 控制不随时间变化的企业特征 |                           |
| Year FE / 年份固定效应             |             | Controls for common time shocks / 控制共同年份冲击                       |                           |
| Industry FE / 行业固定效应         |             | Controls for industry differences / 控制行业差异                       |                           |
| Province FE / 省份固定效应         |             | Controls for regional differences / 控制地区差异                       |                           |
| Country FE / 国家固定效应          |             | Controls for country-level differences / 控制国家差异                  |                           |
| Industry-Year FE / 行业-年份固定效应 |             | Controls for industry-specific time shocks / 控制行业层面年份冲击          |                           |
| Country-Year FE / 国家-年份固定效应  |             | Controls for country-specific time shocks / 控制国家层面年份冲击           |                           |

Notes / 备注：

[To be completed]

---

# 6. Standard Error Clustering / 标准误聚类

Planned clustering level / 计划聚类层级：

* [ ] firm level / 企业层面
* [ ] industry level / 行业层面
* [ ] province level / 省份层面
* [ ] country level / 国家层面
* [ ] year level / 年份层面
* [ ] firm and year two-way clustering / 企业和年份双向聚类
* [ ] country and year two-way clustering / 国家和年份双向聚类
* [ ] other / 其他：

Reason / 原因：

[To be completed]

---

# 7. DID or Policy Shock Design / DID 或政策冲击设计

## Is DID appropriate? / DID 是否适合？

* [ ] Yes / 是
* [ ] No / 否
* [ ] Unclear / 不确定

Reason / 原因：

[To be completed]

---

## Policy or event / 政策或事件

Name of policy/event / 政策或事件名称：

Timing / 发生时间：

Treatment group / 处理组：

Control group / 控制组：

Pre-treatment period / 政策前时期：

Post-treatment period / 政策后时期：

---

## DID model / DID 模型

```text
Y_it = β0 + β1 Treat_i × Post_t + Controls_it + FE + ε_it
```

Actual model / 实际模型：

```text
[To be completed]
```

---

## Required checks / 必须检查

* [ ] parallel trends / 平行趋势
* [ ] anticipation effects / 提前反应
* [ ] placebo treatment timing / 虚假政策时间
* [ ] placebo treatment group / 虚假处理组
* [ ] event-study plot / 事件研究图
* [ ] clustering at treatment level / 在处理层级聚类
* [ ] heterogeneous timing issue / 异质处理时间问题

---

## DID limitations / DID 局限

Write here / 写在这里：

[To be completed]

---

# 8. IV Design / 工具变量设计

## Is IV appropriate? / IV 是否适合？

* [ ] Yes / 是
* [ ] No / 否
* [ ] Unclear / 不确定

Reason / 原因：

[To be completed]

---

## IV information / 工具变量信息

Endogenous variable / 内生变量：

Instrument / 工具变量：

First-stage logic / 第一阶段相关性逻辑：

Exclusion restriction logic / 排除限制逻辑：

Possible violation of exclusion restriction / 可能违反排除限制的地方：

---

## IV model / IV 模型

First stage / 第一阶段：

```text
X_it = α0 + α1 Z_it + Controls_it + FE + υ_it
```

Second stage / 第二阶段：

```text
Y_it = β0 + β1 X_hat_it + Controls_it + FE + ε_it
```

Actual model / 实际模型：

```text
[To be completed]
```

---

## Required checks / 必须检查

* [ ] first-stage coefficient / 第一阶段系数
* [ ] first-stage F-statistic / 第一阶段 F 值
* [ ] weak instrument risk / 弱工具变量风险
* [ ] overidentification test if multiple IVs / 多工具变量时过度识别检验
* [ ] discussion of exclusion restriction / 排除限制讨论
* [ ] robustness using alternative IV / 替代工具变量稳健性

---

## IV limitations / IV 局限

Write here / 写在这里：

[To be completed]

---

# 9. PSM Design / 倾向得分匹配设计

## Is PSM appropriate? / PSM 是否适合？

* [ ] Yes / 是
* [ ] No / 否
* [ ] Unclear / 不确定

PSM is useful for reducing observable differences between treated and control groups.

PSM 适合缓解处理组和控制组之间可观测特征差异。

PSM does not solve selection on unobservable factors.

PSM 不能解决不可观测因素导致的选择偏差。

---

## Treatment definition / 处理组定义

Treatment group / 处理组：

Control group / 控制组：

Treatment timing / 处理时间：

---

## Matching variables / 匹配变量

Matching variables should be pre-treatment variables whenever possible.

匹配变量应尽量使用处理发生之前的变量。

Planned matching variables / 计划匹配变量：

1.
2.
3.
4.
5.

---

## Matching method / 匹配方法

* [ ] nearest neighbor matching / 最近邻匹配
* [ ] radius matching / 半径匹配
* [ ] kernel matching / 核匹配
* [ ] Mahalanobis matching / 马氏距离匹配
* [ ] exact matching / 精确匹配
* [ ] other / 其他：

Caliper / 卡尺：

Matching ratio / 匹配比例：

---

## Required checks / 必须检查

* [ ] propensity score distribution / 倾向得分分布
* [ ] common support / 共同支撑
* [ ] covariate balance before matching / 匹配前协变量平衡
* [ ] covariate balance after matching / 匹配后协变量平衡
* [ ] standardized mean differences / 标准化均值差异
* [ ] sample loss after matching / 匹配后样本损失
* [ ] regression in matched sample / 匹配样本回归

---

## PSM limitations / PSM 局限

Write here / 写在这里：

[To be completed]

---

# 10. Entropy Balancing Design / 熵平衡设计

## Is entropy balancing appropriate? / 熵平衡是否适合？

* [ ] Yes / 是
* [ ] No / 否
* [ ] Unclear / 不确定

Entropy balancing is useful for reweighting the control group to match the treated group on observable covariates.

熵平衡适合通过重新加权控制组，使控制组和处理组在可观测协变量上更加平衡。

Entropy balancing does not solve selection on unobservable factors.

熵平衡不能解决不可观测因素导致的选择偏差。

---

## Treatment definition / 处理组定义

Treatment group / 处理组：

Control group / 控制组：

---

## Balancing variables / 平衡变量

Planned balancing variables / 计划平衡变量：

1.
2.
3.
4.
5.

Balance targets / 平衡目标：

* [ ] mean / 均值
* [ ] variance / 方差
* [ ] skewness / 偏度
* [ ] higher moments / 更高阶矩

---

## Required checks / 必须检查

* [ ] balance before weighting / 加权前平衡性
* [ ] balance after weighting / 加权后平衡性
* [ ] effective sample size / 有效样本量
* [ ] extreme weights / 极端权重
* [ ] weighted regression results / 加权回归结果

---

## Entropy balancing limitations / 熵平衡局限

Write here / 写在这里：

[To be completed]

---

# 11. Heckman Two-Stage Selection Model / Heckman 两阶段样本选择模型

## Is Heckman correction appropriate? / Heckman 是否适合？

* [ ] Yes / 是
* [ ] No / 否
* [ ] Unclear / 不确定

Heckman correction is appropriate only when there is a meaningful sample selection process.

只有在存在明确样本选择过程时，Heckman 修正才适合。

---

## Selection issue / 样本选择问题

What is observed only after selection?

什么变量或样本只有在选择发生后才能观察到？

[To be completed]

Examples:

1. CSR decoupling is observed only for firms with CSR disclosure.
2. Overseas investment outcomes are observed only for firms with overseas subsidiaries.
3. Loan contract terms are observed only for firms that obtain loans.
4. Analyst forecast variables are observed only for firms covered by analysts.

---

## First-stage selection equation / 第一阶段选择方程

Selection dependent variable / 选择方程因变量：

Selection predictors / 选择方程解释变量：

Possible exclusion restriction / 可能的排除变量：

```text
Selection_it = α0 + α1 Z_it + Controls_it + FE + υ_it
```

---

## Second-stage outcome equation / 第二阶段结果方程

Outcome variable / 结果变量：

Key independent variable / 核心自变量：

Inverse Mills ratio / 逆米尔斯比率：

```text
Y_it = β0 + β1 X_it + β2 IMR_it + Controls_it + FE + ε_it
```

---

## Required checks / 必须检查

* [ ] theoretical reason for selection / 样本选择的理论原因
* [ ] first-stage selection equation / 第一阶段选择方程
* [ ] second-stage outcome equation / 第二阶段结果方程
* [ ] exclusion restriction if available / 排除变量
* [ ] inverse Mills ratio / 逆米尔斯比率
* [ ] significance of inverse Mills ratio / 逆米尔斯比率是否显著
* [ ] robustness of main coefficient / 主结果是否稳健

---

## Heckman limitations / Heckman 局限

Write here / 写在这里：

[To be completed]

---

# 12. Lagged Variable Design / 滞后变量设计

## Purpose / 目的

Lagged variables may reduce concerns about reverse causality.

滞后变量可以在一定程度上缓解反向因果问题。

However, lagged variables do not fully solve omitted variable bias.

但是，滞后变量不能完全解决遗漏变量偏误。

---

## Planned lag structure / 计划滞后结构

* [ ] X_t-1 / 自变量滞后一期
* [ ] X_t-2 / 自变量滞后两期
* [ ] controls_t-1 / 控制变量滞后一期
* [ ] dependent variable_t-1 / 因变量滞后一期
* [ ] other / 其他：

Reason / 原因：

[To be completed]

---

## Required checks / 必须检查

* [ ] theoretical reason for lag / 滞后的理论依据
* [ ] sample loss after lagging / 滞后后样本损失
* [ ] whether results remain consistent / 结果是否一致
* [ ] whether interpretation changes / 解释是否发生变化

---

# 13. Placebo and Falsification Tests / 安慰剂与反事实检验

## Purpose / 目的

Placebo tests check whether the main result may be driven by spurious correlation.

安慰剂检验用于判断主结果是否可能来自伪相关。

---

## Planned placebo tests / 计划安慰剂检验

| Placebo Test / 安慰剂检验                    | Purpose / 目的 | Expected Result / 预期结果 |
| --------------------------------------- | ------------ | ---------------------- |
| Fake treatment timing / 虚假政策时间          |              | Insignificant / 不显著    |
| Fake treatment group / 虚假处理组            |              | Insignificant / 不显著    |
| Irrelevant dependent variable / 无关因变量   |              | Insignificant / 不显著    |
| Pre-treatment outcome / 政策前因变量          |              | Insignificant / 不显著    |
| Randomized treatment assignment / 随机处理组 |              | Insignificant / 不显著    |
| Permutation test / 随机置换检验               |              | Insignificant / 不显著    |

Notes / 备注：

[To be completed]

---

# 14. Robustness Checks / 稳健性检验

Every robustness check must correspond to a clear empirical concern.

每一个稳健性检验都必须对应一个明确的实证问题。

Do not randomly run robustness checks only to search for significance.

不要为了寻找显著性而随机更换模型。

---

## Planned robustness checks / 计划稳健性检验

| Robustness Check / 稳健性检验                 | Concern Addressed / 解决的问题      | Planned? / 是否计划 | Notes / 备注 |
| ---------------------------------------- | ------------------------------ | --------------- | ---------- |
| Alternative dependent variable / 替换因变量   | Measurement error / 测量误差       |                 |            |
| Alternative independent variable / 替换自变量 | Measurement error / 测量误差       |                 |            |
| Alternative controls / 替换控制变量            | Model specification / 模型设定     |                 |            |
| Alternative fixed effects / 替换固定效应       | Omitted variables / 遗漏变量       |                 |            |
| Alternative clustering / 替换聚类标准误         | Inference robustness / 推断稳健性   |                 |            |
| Alternative winsorization / 替换缩尾标准       | Outlier influence / 极端值影响      |                 |            |
| Excluding special years / 剔除特殊年份         | Macro shocks / 宏观冲击            |                 |            |
| Excluding special industries / 剔除特殊行业    | Industry confounds / 行业混杂      |                 |            |
| Balanced panel / 平衡面板                    | Sample composition / 样本构成      |                 |            |
| PSM sample / PSM 样本                      | Observable selection / 可观测选择偏差 |                 |            |
| Entropy-balanced sample / 熵平衡样本          | Observable selection / 可观测选择偏差 |                 |            |
| Heckman correction / Heckman 修正          | Sample selection / 样本选择偏差      |                 |            |
| Lagged X / 滞后自变量                         | Reverse causality / 反向因果       |                 |            |
| Placebo test / 安慰剂检验                     | Spurious correlation / 伪相关     |                 |            |

---

# 15. Identification Strength Evaluation / 识别强度评价

## Overall evaluation / 总体评价

* [ ] Strong causal identification / 强因果识别
* [ ] Moderate identification / 中等识别强度
* [ ] Mainly association with robustness checks / 主要是相关性加稳健性
* [ ] Weak identification / 识别较弱

Reason / 原因：

[To be completed]

---

## What causal language is allowed? / 可以使用什么因果语言？

* [ ] X causes Y
* [ ] X leads to Y
* [ ] X affects Y
* [ ] X is associated with Y
* [ ] X predicts Y
* [ ] Results are consistent with the proposed mechanism

Recommended wording / 推荐表述：

[To be completed]

---

# 16. Reviewer Attack Points / 审稿人可能攻击点

## Concern 1

Potential criticism / 可能批评：

Possible response / 可能回应：

Required analysis / 需要补充的分析：

---

## Concern 2

Potential criticism / 可能批评：

Possible response / 可能回应：

Required analysis / 需要补充的分析：

---

## Concern 3

Potential criticism / 可能批评：

Possible response / 可能回应：

Required analysis / 需要补充的分析：

---

# 17. Notes for Codex / 给 Codex 的说明

Before suggesting or running endogeneity tests, Codex must read this document.

在建议或运行内生性检验之前，Codex 必须先阅读本文件。

Codex should not mechanically run DID, IV, PSM, entropy balancing, or Heckman correction.

Codex 不应机械地运行 DID、IV、PSM、熵平衡或 Heckman 修正。

Each method must be justified by a specific identification concern.

每一种方法都必须对应一个具体的识别问题。

If a method is not appropriate, Codex should clearly explain why.

如果某种方法不适合，Codex 应明确说明原因。

Codex should not treat robustness checks as proof of causality.

Codex 不应把稳健性检验当作因果识别的证明。
