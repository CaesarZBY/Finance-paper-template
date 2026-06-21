# Data Sources / 数据来源

This document records all data sources used in the empirical paper.

本文件用于记录实证论文中使用的所有数据来源。

---

# 1. Purpose of This Document / 本文件目的

This document helps the researcher and Codex understand:

本文件帮助研究者和 Codex 明确：

1. where each dataset comes from
   每个数据来自哪里

2. when the dataset was downloaded
   数据是什么时候下载的

3. which raw files are used
   使用了哪些原始文件

4. whether the data can be uploaded to GitHub
   数据是否可以上传到 GitHub

5. how each dataset is merged into the final sample
   每个数据如何合并进最终样本

6. what restrictions or licenses apply
   数据是否有版权或使用限制

---

# 2. Data Safety Rule / 数据安全规则

Do not upload raw paid database files to GitHub.

不要把付费数据库的原始数据上传到 GitHub。

Examples of restricted data:

受限制数据示例：

1. CSMAR
2. Wind
3. WRDS
4. Compustat
5. CRSP
6. Bloomberg
7. Refinitiv
8. manually collected confidential firm-level data

Raw data should be stored locally or on a secure institutional server.

原始数据应保存在本地电脑、移动硬盘或学校安全服务器中。

Recommended raw data folder:

建议原始数据文件夹：

```text
data/raw/
```

But `data/raw/` should be ignored by Git.

但是 `data/raw/` 不应上传到 GitHub。

---

# 3. Main Dataset Summary / 数据来源总表

| Dataset / 数据集 | Provider / 来源            | Data Level / 数据层级    | Period / 时间范围 | Raw File Name / 原始文件名 | GitHub Upload? / 是否上传 GitHub | Notes / 备注                |
| ------------- | ------------------------ | -------------------- | ------------- | --------------------- | ---------------------------- | ------------------------- |
|               | CSMAR                    | firm-year / 企业-年份    |               |                       | No / 否                       | Paid database / 付费数据库     |
|               | Wind                     | firm-year / 企业-年份    |               |                       | No / 否                       | Paid database / 付费数据库     |
|               | WRDS                     | firm-year / 企业-年份    |               |                       | No / 否                       | Paid database / 付费数据库     |
|               | World Bank               | country-year / 国家-年份 |               |                       | Maybe / 视情况                  | Public data / 公开数据        |
|               | OECD                     | country-year / 国家-年份 |               |                       | Maybe / 视情况                  | Public data / 公开数据        |
|               | UNCTAD                   | country-year / 国家-年份 |               |                       | Maybe / 视情况                  | Public data / 公开数据        |
|               | Manual collection / 手工收集 |                      |               |                       | Unclear / 不确定                | Need documentation / 需要说明 |

---

# 4. Primary Firm-Level Data / 企业层面主数据

## Dataset name / 数据集名称

Name:

Provider:

Database module:

Download date:

Downloaded by:

Raw file name:

Raw file location:

```text
data/raw/[to_be_completed]
```

---

## Data level / 数据层级

* [ ] firm-year / 企业-年份
* [ ] firm-quarter / 企业-季度
* [ ] firm-country-year / 企业-国家-年份
* [ ] firm-subsidiary-year / 企业-子公司-年份
* [ ] other / 其他：

---

## Key identifiers / 关键识别码

List the variables used for merging.

列出用于合并数据的变量。

| Identifier / 识别码     | Meaning / 含义                     | Example / 示例 | Notes / 备注 |
| -------------------- | -------------------------------- | ------------ | ---------- |
| stock code / 股票代码    | listed firm identifier / 上市公司识别码 | 000001       |            |
| firm ID / 企业 ID      | firm identifier / 企业识别码          |              |            |
| year / 年份            | fiscal year / 财政年度               | 2015         |            |
| country code / 国家代码  | host country identifier / 东道国识别码 | USA          |            |
| industry code / 行业代码 | industry identifier / 行业识别码      | C39          |            |

---

## Raw variables used / 使用的原始变量

| Raw Variable / 原始变量 | Meaning / 含义 | Used to Construct / 用于构造 | Notes / 备注 |
| ------------------- | ------------ | ------------------------ | ---------- |
|                     |              |                          |            |
|                     |              |                          |            |

---

# 5. Dependent Variable Data / 因变量数据

## Dataset name / 数据集名称

Name:

Provider:

Download date:

Raw file name:

Raw file location:

---

## Variable construction / 变量构造

Dependent variable:

Raw variables used:

Construction method:

Formula:

```text
[To be completed]
```

Alternative dependent variables:

1.
2.
3.

---

## Merge information / 合并信息

Merge keys:

* [ ] firm ID / 企业 ID
* [ ] stock code / 股票代码
* [ ] year / 年份
* [ ] country / 国家
* [ ] other / 其他：

Merge type:

* [ ] one-to-one / 一对一
* [ ] many-to-one / 多对一
* [ ] one-to-many / 一对多
* [ ] many-to-many / 多对多，通常要避免

Expected sample loss:

[To be completed]

---

# 6. Independent Variable Data / 自变量数据

## Dataset name / 数据集名称

Name:

Provider:

Download date:

Raw file name:

Raw file location:

---

## Variable construction / 变量构造

Independent variable:

Raw variables used:

Construction method:

Formula:

```text
[To be completed]
```

Alternative independent variables:

1.
2.
3.

---

## Merge information / 合并信息

Merge keys:

Merge type:

Expected sample loss:

Notes:

[To be completed]

---

# 7. Mechanism Variable Data / 机制变量数据

## Dataset name / 数据集名称

Name:

Provider:

Download date:

Raw file name:

Raw file location:

---

## Variable construction / 变量构造

Mechanism variable:

Raw variables used:

Construction method:

Formula:

```text
[To be completed]
```

Alternative mechanism variables:

1.
2.
3.

---

# 8. Moderator Variable Data / 调节变量数据

## Dataset name / 数据集名称

Name:

Provider:

Download date:

Raw file name:

Raw file location:

---

## Variable construction / 变量构造

Moderator variable:

Raw variables used:

Construction method:

Formula:

```text
[To be completed]
```

Alternative moderator variables:

1.
2.
3.

---

# 9. Control Variable Data / 控制变量数据

List all control variables and their sources.

列出所有控制变量及其数据来源。

| Control Variable / 控制变量         | Data Source / 数据来源 | Raw Variable / 原始变量 | Formula / 公式 | Notes / 备注 |
| ------------------------------- | ------------------ | ------------------- | ------------ | ---------- |
| Firm size / 企业规模                |                    |                     |              |            |
| Leverage / 资产负债率                |                    |                     |              |            |
| ROA / 资产收益率                     |                    |                     |              |            |
| Growth / 成长性                    |                    |                     |              |            |
| Firm age / 企业年龄                 |                    |                     |              |            |
| Cash flow / 现金流                 |                    |                     |              |            |
| Board size / 董事会规模              |                    |                     |              |            |
| Independent directors / 独立董事比例  |                    |                     |              |            |
| Ownership concentration / 股权集中度 |                    |                     |              |            |
| SOE / 国有企业                      |                    |                     |              |            |

---

# 10. Country-Level Data / 国家层面数据

Use this section if the paper uses host-country or home-country variables.

如果论文使用东道国或母国层面变量，在这里记录。

## Dataset name / 数据集名称

Name:

Provider:

Download date:

Raw file name:

Raw file location:

---

## Country identifier / 国家识别码

Country code type:

* [ ] ISO 2-letter code
* [ ] ISO 3-letter code
* [ ] country name
* [ ] manually harmonized country name
* [ ] other:

Country name cleaning needed?

* [ ] Yes / 是
* [ ] No / 否

Notes:

[To be completed]

---

## Country-year variables / 国家-年份变量

| Variable / 变量                             | Meaning / 含义 | Source / 来源 | Formula / 公式 | Notes / 备注 |
| ----------------------------------------- | ------------ | ----------- | ------------ | ---------- |
| GDP per capita / 人均 GDP                   |              |             |              |            |
| GDP growth / GDP 增长率                      |              |             |              |            |
| institutional quality / 制度质量              |              |             |              |            |
| financial development / 金融发展              |              |             |              |            |
| cultural distance / 文化距离                  |              |             |              |            |
| informal institutional distance / 非正式制度距离 |              |             |              |            |

---

# 11. Industry-Level Data / 行业层面数据

Use this section if the paper uses industry-level variables.

如果论文使用行业层面变量，在这里记录。

Dataset name:

Provider:

Industry classification:

* [ ] CSRC industry code / 证监会行业分类
* [ ] SIC
* [ ] NAICS
* [ ] CICS
* [ ] other:

Industry-year variables:

| Variable / 变量                         | Meaning / 含义 | Formula / 公式 | Notes / 备注 |
| ------------------------------------- | ------------ | ------------ | ---------- |
| industry competition / 行业竞争           |              |              |            |
| industry growth / 行业增长                |              |              |            |
| industry CSR norm / 行业 CSR 规范         |              |              |            |
| industry internationalization / 行业国际化 |              |              |            |

---

# 12. Data Merge Plan / 数据合并计划

Describe the planned merge order.

描述计划的数据合并顺序。

Recommended order:

建议顺序：

```text
1. Start with firm-year base sample
2. Merge dependent variable data
3. Merge independent variable data
4. Merge mechanism variables
5. Merge moderator variables
6. Merge control variables
7. Merge country-level variables
8. Merge industry-level variables
9. Apply sample restrictions
10. Generate final regression sample
```

Actual merge order:

```text
[To be completed]
```

---

# 13. Sample Loss Tracking / 样本流失记录

Track sample loss after every major cleaning or merge step.

每次清洗或合并后，都要记录样本流失。

| Step / 步骤                          | Observations Before / 处理前观测值 | Observations After / 处理后观测值 | Loss / 损失 | Reason / 原因 |
| ---------------------------------- | ---------------------------: | --------------------------: | --------: | ----------- |
| Initial sample / 初始样本              |                              |                             |           |             |
| Exclude financial firms / 剔除金融业    |                              |                             |           |             |
| Exclude ST firms / 剔除 ST 企业        |                              |                             |           |             |
| Merge dependent variable / 合并因变量   |                              |                             |           |             |
| Merge independent variable / 合并自变量 |                              |                             |           |             |
| Merge controls / 合并控制变量            |                              |                             |           |             |
| Remove missing values / 删除缺失值      |                              |                             |           |             |
| Final sample / 最终样本                |                              |                             |           |             |

---

# 14. Data Quality Checks / 数据质量检查

Before regression, check:

回归前必须检查：

* [ ] duplicate firm-year observations / 重复企业-年份观测
* [ ] missing values / 缺失值
* [ ] impossible values / 不可能值
* [ ] extreme values / 极端值
* [ ] merge success rate / 合并成功率
* [ ] industry code consistency / 行业代码一致性
* [ ] country name consistency / 国家名称一致性
* [ ] year coverage / 年份覆盖
* [ ] panel balance / 面板平衡性
* [ ] whether sample restrictions are documented / 样本筛选是否记录

---

# 15. Data License and Confidentiality / 数据授权与保密

## Can raw data be uploaded to GitHub? / 原始数据能否上传 GitHub？

* [ ] Yes / 是
* [ ] No / 否
* [ ] Unclear / 不确定

Reason:

[To be completed]

---

## Can processed data be uploaded to GitHub? / 处理后数据能否上传 GitHub？

* [ ] Yes / 是
* [ ] No / 否
* [ ] Unclear / 不确定

Reason:

[To be completed]

---

## Can summary statistics be shared? / 描述性统计能否分享？

* [ ] Yes / 是
* [ ] No / 否
* [ ] Unclear / 不确定

Reason:

[To be completed]

---

# 16. Notes for Codex / 给 Codex 的说明

Before writing data cleaning code, Codex must read this document.

在写数据清洗代码之前，Codex 必须先阅读本文件。

Codex should not assume file names, variable names, or merge keys without checking the data source documentation.

Codex 不应在没有检查数据来源说明的情况下假设文件名、变量名或合并键。

Codex should never modify files in:

Codex 绝不能修改以下文件夹中的文件：

```text
data/raw/
```

Codex should write cleaned data to:

Codex 应将清洗后的数据写入：

```text
data/interim/
data/processed/
```

Codex should generate sample-loss and data-quality reports in:

Codex 应将样本流失和数据质量报告写入：

```text
outputs/logs/
```
