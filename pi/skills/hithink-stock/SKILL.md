---
name: hithink-stock
description: Unified stock/finance data access through three sources — 同花顺问财 OpenAPI, Tushare daily bars, and 雪球/pysnowball. Use for A股/港股/美股/ETF/指数行情、财务指标、新闻、公告、研报、机构评级、经营数据、股东股本、基金理财、基本资料、行业板块、宏观数据、股票日线历史价格等查询。
license: Complete terms in upstream hithink-* skill LICENSE.txt files
---

# Hithink Stock

三个数据源的统一入口，覆盖 A 股 / 港股 / 美股 / ETF / 指数 / 基金 / 宏观等查询场景。

## 数据源概览

| 数据源 | 脚本 | 适用场景 |
|---|---|---|
| 同花顺问财 OpenAPI | `scripts/iwencai_query.py` | 行情、财务、公告、研报、事件、行业、宏观、基金、A股/港股/美股选股等自然语言查询 |
| Tushare | `scripts/tushare_query.py` | A 股日线 OHLCV + MA/趋势指标（精确、结构化） |
| 雪球/pysnowball | `scripts/xueqiu_query.py` | 实时行情详情、K 线、财报三表、主营业务、资金流、研报、股东等补充数据 |

## 覆盖的数据域

- `news`：财经新闻、政策动态、行业新闻、上市公司动态、舆情。
- `announcement`：A股/港股/基金/ETF公告，财报、分红、回购增减持、重组等。
- `report`：研报搜索，深度报告、目标价、投资评级、机构报告。
- `research`：机构研究与评级，盈利预测、一致预期、ESG/信用评级、券商金股。
- `market`：股票/ETF/指数行情，最新价、涨跌幅、成交量、资金流、技术指标等。
- `finance`：营收、净利润、ROE、负债率、现金流、毛利率、估值等。
- `event`：业绩预告、增发配股、质押、解禁、调研、监管函、公告事件等。
- `business`：主营业务构成、客户、供应商、参控股公司、重大合同等经营数据。
- `management`：股本结构、股东户数、前十大股东/流通股东、实控人、股权质押。
- `basicinfo`：股票/基金/债券/期货等基础资料，代码、上市日期、所属行业、费率、评级等。
- `industry`：行业/板块估值、涨跌幅、财务、排名等。
- `macro`：GDP、CPI、PPI、PMI、LPR、汇率、社融、M2、进出口等宏观指标。
- `fund`：基金理财，基金业绩、持仓、风险、评级、基金经理/公司、规模回撤等。
- `index`：指数数据，上证、沪深300、创业板、恒生、纳指等指数行情。
- `astock_selector`：A股选股器，按行业/概念/资金/趋势/估值/财务等条件筛选关注池。
- `hkstock_selector`：港股选股器，按港股/港股通/恒生科技/行业主题等条件筛选关注池。
- `usstock_selector`：美股选股器，按美股行业/主题/涨跌幅/成交额/估值/财务等条件筛选关注池。
- `daily`：股票日线历史价格/K线（优先使用 Tushare `daily` 接口）。
- `xueqiu`：雪球/pysnowball 补充数据，包括实时行情详情、K线、财报三表、主营业务、主要指标、股东、研报、业绩预告、资金流等。

## 使用前

问财数据需要环境变量 `IWENCAI_API_KEY`。用户已将 `IWENCAI_API_KEY` 配置在 `~/.zshenv`，脚本会优先读环境变量，其次直接从 `~/.zshenv` 读取。

如需重新配置：

1. 打开 https://www.iwencai.com/skillhub
2. 登录。
3. 点击任意具体 Skill，在“安装方式-Agent用户”中复制 `IWENCAI_API_KEY`。
4. 设置环境变量，例如：

```bash
export IWENCAI_API_KEY="your-api-key"
```

如果仍未读取到，提示用户按以上步骤配置。

股票日线价格优先使用 Tushare。用户已有账号，但权限只覆盖日线信息；`TUSHARE_TOKEN` 已配置在 `~/.zshenv`。脚本会优先读环境变量，其次直接从 `~/.zshenv` 读取 `export TUSHARE_TOKEN=...`。

雪球补充数据使用 `pysnowball`（https://github.com/uname-yang/pysnowball）。用户已在 `~/.zshenv` 配置 `XUEQIU_TOKEN`；脚本也向后兼容旧拼写 `XUEQIU_TOEKN`。若雪球返回 `400016` / 需要重新登录，说明 token/cookie 可能已过期，需要用户更新雪球 token。

## 查询入口

### iWencai（问财）

```bash
python3 scripts/iwencai_query.py --query "贵州茅台最新价" --compact
```

常用参数：

```bash
# 自动识别查询域（默认）
python3 scripts/iwencai_query.py -q "宁德时代ROE 净利润" --compact

# 显式指定查询域
python3 scripts/iwencai_query.py -d finance -q "贵州茅台营业收入 净利润" --compact
python3 scripts/iwencai_query.py -d event -q "最近限售解禁股票" --limit 20 --compact
python3 scripts/iwencai_query.py -d news -q "贵州茅台 最新 新闻" --compact
python3 scripts/iwencai_query.py -d announcement -q "腾讯控股 最新 回购 公告" --compact
python3 scripts/iwencai_query.py -d report -q "英伟达 最新 研报" --compact
python3 scripts/iwencai_query.py -d research -q "贵州茅台 最新 研报评级 目标价" --compact
python3 scripts/iwencai_query.py -d business -q "比亚迪 主营业务构成 主要客户" --compact
python3 scripts/iwencai_query.py -d management -q "宁德时代 股东户数 前十大股东" --compact
python3 scripts/iwencai_query.py -d fund -q "短债基金 近1月收益率 最大回撤 规模" --compact
python3 scripts/iwencai_query.py -d index -q "恒生科技指数 最新点位 涨跌幅" --compact
python3 scripts/iwencai_query.py -d industry -q "A股行业涨跌幅排名" --compact
python3 scripts/iwencai_query.py -d macro -q "最近一期CPI PPI" --compact
python3 scripts/iwencai_query.py -d astock_selector -q "选出A股全市场近5日涨幅为正、成交额排名靠前、主力资金净流入、趋势走强的股票，返回所属行业、概念、近5日涨幅、成交额、换手率、主力资金、市盈率TTM、净利润同比" --limit 30 --compact
python3 scripts/iwencai_query.py -d hkstock_selector -q "选出港股全市场近5日涨幅为正、成交额排名靠前、趋势走强的股票，返回所属行业、概念、近5日涨幅、成交额、估值、机构评级" --limit 30 --compact
python3 scripts/iwencai_query.py -d usstock_selector -q "选出美股全市场近5日涨幅为正、成交额排名靠前、趋势走强的股票，返回所属行业、概念、近5日涨幅、成交额、市值、估值、机构评级" --limit 30 --compact

### Tushare（日线）

```bash
# 最近 60 个交易日日线 + MA5/MA20/趋势
python3 scripts/tushare_query.py --ts-code 600519.SH --days 60 --compact
python3 scripts/tushare_query.py --ts-code 000001.SZ --start-date 20240101 --end-date 20240630
```

也可通过 iwencai_query.py 的 `daily` 域路由到 Tushare：

```bash
python3 scripts/iwencai_query.py -d daily --ts-code 600519.SH -q "贵州茅台日线" --start-date 20240101 --end-date 20240131 --compact
```

### 雪球/pysnowball

```bash
uv run scripts/xueqiu_query.py -s 02400.HK -a detail --compact
uv run scripts/xueqiu_query.py -s 02400.HK -a kline --period day --count 30 --compact
uv run scripts/xueqiu_query.py -s SH600519 -a indicator --count 8 --compact
uv run scripts/xueqiu_query.py -s SH600519 -a income --annals --count 5 --compact
uv run scripts/xueqiu_query.py -s SH600519 -a business --annals --count 5 --compact
uv run scripts/xueqiu_query.py -a suggest -q "心动公司" --compact

# 返回更多记录 / 翻页
python3 scripts/iwencai_query.py -q "主力资金净流入排名" --limit 30 --page 1 --compact

# 空数据时最多自动放宽查询重试 2 次
python3 scripts/iwencai_query.py -q "非常精确的查询条件" --retry-empty --compact
```

输出是 JSON，核心字段：

- `datas`：数据数组。
- `code_count`：符合条件总数，可能大于本页 `datas` 数量。
- `chunks_info`：问财对查询条件的解析。
- `_meta`：查询域、底层 hithink skill id、最终查询语句、trace id、数据源。

## 回答规范

- 用用户原始问题判断是否需要改写查询；改写要保持原意。
- 默认先用 `--domain auto`；当意图明确或自动分类容易误判时显式传 `-d`。
- 用户问“日线 / K线 / 历史价格 / 开盘收盘最高最低”等股票历史价格时，优先用 `-d daily` 或 `--source tushare`；Tushare 日线需要 `ts_code`，如 `600519.SH`、`000001.SZ`。
- 如果 `datas` 为空，最多放宽查询重试 2 次，或直接使用 `--retry-empty`。
- 如果 `code_count > len(datas)`，说明有更多记录；必要时用 `--page` 翻页。
- 港股/A股个股的 F10、行情详情、财报三表、主营业务、主要指标、股东、资金流可用 `uv run scripts/xueqiu_query.py ...` 交叉验证或补充问财字段不足。
- 将 `datas` 整理成清晰表格或要点，字段多时优先保留股票代码/简称、日期、关键指标。
- 回答中必须注明数据源：问财结果注明同花顺问财（https://www.iwencai.com/unifiedwap/chat）；日线价格注明 Tushare（https://tushare.pro/）；雪球补充数据注明雪球/pysnowball（https://xueqiu.com/，https://github.com/uname-yang/pysnowball）。
- 这是数据查询工具，不构成投资建议；涉及买卖建议时要说明风险，并结合用户持仓、市场环境和新闻再分析。

## 底层映射

本封装使用同一个问财 OpenAPI：`https://openapi.iwencai.com/v1/query2data`。

| domain | X-Claw-Skill-Id |
|---|---|
| news | `news-search` |
| announcement | `announcement-search` |
| report | `report-search` |
| research | `hithink-insresearch-query` |
| market | `hithink-market-query` |
| finance | `hithink-finance-query` |
| event | `hithink-event-query` |
| business | `hithink-business-query` |
| management | `hithink-management-query` |
| basicinfo | `hithink-basicinfo-query` |
| industry | `hithink-industry-query` |
| macro | `hithink-macro-query` |
| fund | `hithink-fund-query` |
| index | `hithink-zhishu-query` |
| astock_selector | `hithink-astock-selector` |
| hkstock_selector | `hithink-hkstock-selector` |
| usstock_selector | `hithink-usstock-selector` |

日线价格不走问财映射，使用 Tushare：

| domain | source | api |
|---|---|---|
| daily | Tushare | `daily` |

雪球补充入口不走问财映射，使用 `scripts/xueqiu_query.py`：

| action | pysnowball API | 用途 |
|---|---|---|
| `detail` / `quote` | `quote_detail` / `quotec` | 行情详情、估值、市值、股息率等 |
| `kline` | `kline` | K线，支持 day/week/month/60m/30m/1m |
| `indicator` / `main_indicator` | `indicator` / `main_indicator` | 业绩指标、主要指标 |
| `income` / `balance` / `cash_flow` | 三表接口 | 利润表、资产负债表、现金流量表 |
| `business` | `business` | 主营业务/收入构成 |
| `holders` / `top_holders` | 股东接口 | 股东与前十大股东 |
| `report` / `earningforecast` | 研报/业绩预告 | 机构评级、业绩预告 |
| `capital_flow` / `capital_history` / `capital_assort` | 资金流接口 | 当日/历史资金流、成交分布 |
| `suggest` | `suggest_stock` | 股票搜索与代码识别 |
