#!/usr/bin/env python3
"""Unified iWencai/Hithink stock-finance query CLI.

Uses the same OpenAPI gateway and X-Claw headers as the hithink-* skills, but
lets the caller choose a broad domain (or auto-detect one) instead of loading a
separate skill for market/finance/event/basicinfo/industry/macro queries.

Requires IWENCAI_API_KEY in the environment, unless --api-key is passed.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import secrets
import shlex
import sys
import urllib.error
import urllib.request
from typing import Any

API_URL = "https://openapi.iwencai.com/v1/query2data"
TUSHARE_URL = "http://api.tushare.pro"
VERSION = "1.0.0"

DOMAINS: dict[str, dict[str, Any]] = {
    "news": {
        "skill_id": "news-search",
        "label": "新闻搜索",
        "keywords": ["新闻", "资讯", "消息", "动态", "舆情", "政策", "媒体", "报道", "热点", "突发", "事件影响"],
    },
    "announcement": {
        "skill_id": "announcement-search",
        "label": "公告搜索",
        "keywords": ["公告", "港股公告", "A股公告", "财报公告", "定期报告", "年报", "季报", "中报", "分红派息", "回购公告", "增持公告", "减持公告", "资产重组公告"],
    },
    "report": {
        "skill_id": "report-search",
        "label": "研报搜索",
        "keywords": ["研报", "研究报告", "深度报告", "首次覆盖", "目标价", "买入评级", "增持评级", "投研", "机构报告"],
    },
    "research": {
        "skill_id": "hithink-insresearch-query",
        "label": "机构研究/评级",
        "keywords": ["评级", "机构评级", "研报评级", "盈利预测", "一致预期", "目标价", "ESG", "信用评级", "主体评级", "基金评级", "券商金股"],
    },
    "market": {
        "skill_id": "hithink-market-query",
        "label": "行情",
        "keywords": ["行情", "价格", "最新价", "涨跌", "涨幅", "跌幅", "成交", "换手", "量比", "资金", "主力", "净流入", "MACD", "KDJ", "RSI", "均线", "ETF", "指数", "港股通", "北向"],
    },
    "finance": {
        "skill_id": "hithink-finance-query",
        "label": "财务",
        "keywords": ["财务", "营收", "营业收入", "净利润", "利润", "ROE", "ROA", "毛利", "净利率", "负债", "现金流", "市盈率", "PE", "市净率", "PB", "估值"],
    },
    "event": {
        "skill_id": "hithink-event-query",
        "label": "事件",
        "keywords": ["公告", "业绩预告", "预增", "预减", "增发", "配股", "质押", "解禁", "调研", "监管函", "问询函", "股东大会", "分红", "回购", "减持", "增持"],
    },
    "business": {
        "skill_id": "hithink-business-query",
        "label": "公司经营",
        "keywords": ["主营业务", "业务构成", "主营构成", "产品结构", "收入构成", "地区构成", "主要客户", "客户", "供应商", "参控股", "子公司", "重大合同", "经营数据"],
    },
    "management": {
        "skill_id": "hithink-management-query",
        "label": "股东股本",
        "keywords": ["股本", "股本结构", "股权结构", "股东户数", "前十大股东", "十大流通股东", "实控人", "实际控制人", "控股股东", "主要持有人", "股权质押"],
    },
    "basicinfo": {
        "skill_id": "hithink-basicinfo-query",
        "label": "基本资料",
        "keywords": ["基本信息", "资料", "代码", "简称", "上市", "所属行业", "主营", "概念", "成分股", "基金", "期货", "债券", "转债", "费率", "评级"],
    },
    "industry": {
        "skill_id": "hithink-industry-query",
        "label": "行业/板块",
        "keywords": ["行业", "板块", "概念", "题材", "产业链", "申万", "中信", "行业排名", "板块排名"],
    },
    "macro": {
        "skill_id": "hithink-macro-query",
        "label": "宏观",
        "keywords": ["宏观", "GDP", "CPI", "PPI", "PMI", "LPR", "利率", "汇率", "社融", "M2", "工业增加值", "进出口", "消费", "投资"],
    },
    "fund": {
        "skill_id": "hithink-fund-query",
        "label": "基金理财",
        "keywords": ["基金", "货币基金", "短债", "中短债", "债基", "纯债", "同业存单", "基金经理", "基金公司", "基金持仓", "基金评级", "基金规模", "最大回撤", "夏普", "理财"],
    },
    "index": {
        "skill_id": "hithink-zhishu-query",
        "label": "指数数据",
        "keywords": ["指数", "上证指数", "沪深300", "中证", "创业板指", "科创50", "恒生指数", "恒生科技", "纳斯达克", "标普500", "道琼斯", "指数点位"],
    },
    "astock_selector": {
        "skill_id": "hithink-astock-selector",
        "label": "A股选股",
        "keywords": ["A股选股", "选股", "筛选股票", "股票池", "关注池", "候选股", "涨停", "突破", "放量", "主力资金", "北向资金", "概念龙头", "行业龙头"],
    },
    "hkstock_selector": {
        "skill_id": "hithink-hkstock-selector",
        "label": "港股选股",
        "keywords": ["港股选股", "港股股票池", "港股关注池", "港股通选股", "港股候选", "恒生科技选股", "港股筛选"],
    },
    "usstock_selector": {
        "skill_id": "hithink-usstock-selector",
        "label": "美股选股",
        "keywords": ["美股选股", "美股股票池", "美股关注池", "美股候选", "纳斯达克选股", "标普选股", "美股筛选", "美股芯片", "美股AI"],
    },
    "daily": {
        "skill_id": "tushare-daily",
        "label": "日线(Tushare)",
        "keywords": ["日线", "K线", "k线", "历史价格", "历史行情", "开盘价", "收盘价", "最高价", "最低价", "复权", "前复权", "后复权"],
    },
}

DOMAIN_ORDER = [
    "daily",
    "announcement",
    "news",
    "report",
    "research",
    "fund",
    "index",
    "astock_selector",
    "hkstock_selector",
    "usstock_selector",
    "market",
    "finance",
    "event",
    "business",
    "management",
    "basicinfo",
    "industry",
    "macro",
]


class QueryError(Exception):
    pass


def detect_domain(query: str) -> str:
    scores: dict[str, int] = {}
    q_lower = query.lower()
    for domain, meta in DOMAINS.items():
        score = 0
        for kw in meta["keywords"]:
            if kw.lower() in q_lower:
                score += 1
        scores[domain] = score
    best = max(DOMAIN_ORDER, key=lambda d: (scores[d], -DOMAIN_ORDER.index(d)))
    return best if scores[best] > 0 else "market"


def api_key(value: str | None) -> str:
    key = value or env_value("IWENCAI_API_KEY")
    if not key:
        raise QueryError(
            "缺少 IWENCAI_API_KEY。请打开 https://www.iwencai.com/skillhub 登录后，"
            "在具体 Skill 的“安装方式-Agent用户”处复制 IWENCAI_API_KEY，并设置环境变量。"
        )
    return key


def env_value(name: str) -> str:
    """Read env var, falling back to simple `export NAME=...` lines in ~/.zshenv."""
    value = os.environ.get(name, "")
    if value:
        return value
    zshenv = os.path.expanduser("~/.zshenv")
    try:
        with open(zshenv, "r", encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                if line.startswith("export "):
                    line = line[len("export "):]
                if not line.startswith(name + "="):
                    continue
                raw = line.split("=", 1)[1]
                try:
                    return shlex.split(raw)[0]
                except Exception:
                    return raw.strip().strip('"').strip("'")
    except FileNotFoundError:
        pass
    return ""


def tushare_token(value: str | None) -> str:
    token = value or env_value("TUSHARE_TOKEN")
    if not token:
        raise QueryError("缺少 TUSHARE_TOKEN。你说已在 ~/.zshenv 配置，请确认存在 export TUSHARE_TOKEN=...。")
    return token


def normalize_ts_code(value: str) -> str:
    v = value.strip().upper()
    if re.fullmatch(r"\d{6}\.(SH|SZ|BJ)", v):
        return v
    m = re.search(r"(\d{6})", v)
    if not m:
        raise QueryError("Tushare 日线查询需要股票代码，例如 600519.SH、000001.SZ，或在 query 中包含 6 位代码。")
    code = m.group(1)
    if code.startswith(("6", "9")):
        suffix = "SH"
    elif code.startswith(("8", "4")):
        suffix = "BJ"
    else:
        suffix = "SZ"
    return f"{code}.{suffix}"


def request_tushare_daily(ts_code: str, token: str, start_date: str, end_date: str, fields: str, timeout: int, limit: str) -> dict[str, Any]:
    payload = {
        "api_name": "daily",
        "token": token,
        "params": {"ts_code": ts_code},
        "fields": fields,
    }
    if start_date:
        payload["params"]["start_date"] = start_date
    if end_date:
        payload["params"]["end_date"] = end_date
    req = urllib.request.Request(
        TUSHARE_URL,
        data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace") if exc.fp else ""
        raise QueryError(f"Tushare HTTP {exc.code} {exc.reason}: {body[:1000]}")
    except urllib.error.URLError as exc:
        raise QueryError(f"Tushare 网络错误: {exc.reason}")

    if raw.get("code") != 0:
        raise QueryError(f"Tushare 返回错误: {raw.get('msg') or raw}")
    data = raw.get("data") or {}
    columns = data.get("fields") or []
    rows = data.get("items") or []
    datas = [dict(zip(columns, row)) for row in rows]
    total_count = len(datas)
    if limit:
        datas = datas[: int(limit)]
    return {
        "datas": datas,
        "code_count": total_count,
        "_meta": {
            "source": "Tushare",
            "source_url": "https://tushare.pro/",
            "domain": "daily",
            "domain_label": "日线(Tushare)",
            "api_name": "daily",
            "ts_code": ts_code,
            "start_date": start_date,
            "end_date": end_date,
            "fields": fields,
            "returned_count": len(datas),
        },
    }


def request_once(query: str, domain: str, page: str, limit: str, key: str, call_type: str, timeout: int) -> dict[str, Any]:
    trace_id = secrets.token_hex(32)
    skill_id = DOMAINS[domain]["skill_id"]
    headers = {
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json",
        "X-Claw-Call-Type": call_type,
        "X-Claw-Skill-Id": skill_id,
        "X-Claw-Skill-Version": VERSION,
        "X-Claw-Plugin-Id": "none",
        "X-Claw-Plugin-Version": "none",
        "X-Claw-Trace-Id": trace_id,
    }
    payload = {
        "query": query,
        "page": page,
        "limit": limit,
        "is_cache": "1",
        "expand_index": "true",
    }
    req = urllib.request.Request(API_URL, data=json.dumps(payload, ensure_ascii=False).encode("utf-8"), headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            body = resp.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace") if exc.fp else ""
        raise QueryError(f"HTTP {exc.code} {exc.reason}: {body[:1000]}")
    except urllib.error.URLError as exc:
        raise QueryError(f"网络错误: {exc.reason}")

    try:
        data: Any = json.loads(body) if body.strip() else {}
    except json.JSONDecodeError:
        data = {"text_response": body}
    if not isinstance(data, dict):
        data = {"data": data}
    data.setdefault("datas", [])
    data["_meta"] = {
        "source": "同花顺问财",
        "source_url": "https://www.iwencai.com/unifiedwap/chat",
        "domain": domain,
        "domain_label": DOMAINS[domain]["label"],
        "skill_id": skill_id,
        "query": query,
        "page": page,
        "limit": limit,
        "trace_id": trace_id,
    }
    return data


def relaxed_queries(query: str) -> list[str]:
    # Conservative fallback rewrites: remove very specific date/ranking qualifiers first.
    candidates = []
    q1 = re.sub(r"(最近|近[一二三四五六七八九十0-9]+[天日周月年]|今天|昨日|昨天|本周|本月|本年|今年|去年)", "", query).strip()
    q1 = re.sub(r"\s+", " ", q1)
    if q1 and q1 != query:
        candidates.append(q1)
    q2 = re.sub(r"(最高|最低|排名|前\d+|top\s*\d+|TOP\s*\d+)", "", q1 or query).strip()
    q2 = re.sub(r"\s+", " ", q2)
    if q2 and q2 not in candidates and q2 != query:
        candidates.append(q2)
    return candidates[:2]


def positive_int(value: str) -> str:
    if int(value) < 1:
        raise argparse.ArgumentTypeError("must be >= 1")
    return value


def main() -> int:
    parser = argparse.ArgumentParser(description="统一问财股票金融数据查询 CLI")
    parser.add_argument("-q", "--query", required=True, help="自然语言查询，如：贵州茅台最新价 / 宁德时代ROE / A股行业涨幅排名")
    parser.add_argument("-d", "--domain", choices=["auto", *DOMAIN_ORDER], default="auto", help="查询域，默认 auto 自动识别；日线历史价格会走 Tushare")
    parser.add_argument("--source", choices=["auto", "iwencai", "tushare"], default="auto", help="数据源，默认 auto；日线使用 tushare，其余使用 iwencai")
    parser.add_argument("--ts-code", default="", help="Tushare 股票代码，如 600519.SH；日线查询建议显式传入")
    parser.add_argument("--start-date", default="", help="Tushare 起始日期 YYYYMMDD")
    parser.add_argument("--end-date", default="", help="Tushare 截止日期 YYYYMMDD")
    parser.add_argument("--tushare-token", default=None, help="默认从 TUSHARE_TOKEN 或 ~/.zshenv 读取")
    parser.add_argument("--fields", default="ts_code,trade_date,open,high,low,close,pre_close,change,pct_chg,vol,amount", help="Tushare fields")
    parser.add_argument("--page", type=positive_int, default="1")
    parser.add_argument("--limit", type=positive_int, default="10")
    parser.add_argument("--api-key", default=None, help="默认从 IWENCAI_API_KEY 读取")
    parser.add_argument("--call-type", choices=["normal", "retry"], default="normal")
    parser.add_argument("--timeout", type=int, default=30)
    parser.add_argument("--retry-empty", action="store_true", help="当 datas 为空时，最多自动放宽查询重试 2 次")
    parser.add_argument("--compact", action="store_true", help="只输出 datas/code_count/_meta 等核心字段")
    args = parser.parse_args()

    try:
        domain = detect_domain(args.query) if args.domain == "auto" else args.domain
        use_tushare = args.source == "tushare" or (args.source == "auto" and domain == "daily")
        if use_tushare:
            ts_code = normalize_ts_code(args.ts_code or args.query)
            token = tushare_token(args.tushare_token)
            result = request_tushare_daily(ts_code, token, args.start_date, args.end_date, args.fields, args.timeout, args.limit)
            result.setdefault("_meta", {})["query"] = args.query
            print(json.dumps(result, ensure_ascii=False, indent=2))
            return 0

        key = api_key(args.api_key)
        result = request_once(args.query, domain, args.page, args.limit, key, args.call_type, args.timeout)
        attempts = [{"query": args.query, "domain": domain, "call_type": args.call_type}]
        if args.retry_empty and not result.get("datas"):
            for rq in relaxed_queries(args.query):
                result = request_once(rq, domain, args.page, args.limit, key, "retry", args.timeout)
                attempts.append({"query": rq, "domain": domain, "call_type": "retry"})
                if result.get("datas"):
                    break
        result.setdefault("_meta", {})["attempts"] = attempts
        if args.compact:
            result = {k: result.get(k) for k in ["datas", "code_count", "chunks_info", "text_response", "data", "_meta"] if k in result}
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0
    except (QueryError, ValueError, argparse.ArgumentTypeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
