#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pysnowball>=0.1.5"]
# ///
"""Xueqiu/pysnowball financial data query CLI.

Reads XUEQIU_TOKEN or the user's existing XUEQIU_TOEKN from the environment,
falling back to simple `export NAME=...` lines in ~/.zshenv.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shlex
import sys
from typing import Any, Callable

import pysnowball as ball

SOURCE_URL = "https://xueqiu.com/"


class QueryError(Exception):
    pass


def env_value(name: str) -> str:
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


def xueqiu_token(value: str | None = None) -> str:
    token = value or env_value("XUEQIU_TOKEN") or env_value("XUEQIU_TOEKN")
    if not token:
        raise QueryError("缺少 XUEQIU_TOKEN/XUEQIU_TOEKN。请在 ~/.zshenv 配置雪球 token。")
    return token


def normalize_symbol(value: str) -> str:
    v = value.strip().upper()
    v = re.sub(r"\s+", "", v)
    if re.fullmatch(r"(SH|SZ|BJ)\d{6}", v):
        return v
    # pysnowball/Xueqiu HK quote APIs expect bare HK codes like 02400/00700, not HK02400.
    if re.fullmatch(r"HK\d{5}", v):
        return v[2:]
    if re.fullmatch(r"\d{5}\.HK", v):
        return v[:5]
    if re.fullmatch(r"\d{4}\.HK", v):
        return "0" + v[:4]
    if re.fullmatch(r"\d{5}", v) and v.startswith("0"):
        return v
    if re.fullmatch(r"\d{4}", v):
        return "0" + v
    m = re.search(r"(\d{6})\.(SH|SZ|BJ)", v)
    if m:
        return m.group(2) + m.group(1)
    m = re.search(r"(\d{6})", v)
    if m:
        code = m.group(1)
        if code.startswith(("6", "9")):
            return "SH" + code
        if code.startswith(("8", "4")):
            return "BJ" + code
        return "SZ" + code
    # US symbols on Xueqiu are usually passed as-is, e.g. PDD/BABA/NVDA.
    if re.fullmatch(r"[A-Z.]{1,10}", v):
        return v
    raise QueryError("无法识别证券代码。示例：SH600519、600519.SH、SZ000001、HK02400、02400.HK、NVDA。")


def compact_result(data: Any, max_items: int) -> Any:
    if isinstance(data, dict):
        # Keep the common useful payloads but preserve unknown shapes.
        if isinstance(data.get("data"), dict):
            inner = data["data"]
            if isinstance(inner.get("quote"), dict):
                q = inner["quote"]
                keys = [
                    "symbol", "name", "current", "percent", "chg", "open", "high", "low", "last_close",
                    "volume", "amount", "turnover_rate", "market_capital", "float_market_capital",
                    "pe_ttm", "pe_lyr", "pb", "ps", "psr", "eps", "dividend_yield", "currency", "timestamp",
                ]
                return {k: q.get(k) for k in keys if k in q}
        if isinstance(data.get("data"), list):
            return {**data, "data": data["data"][:max_items]}
        if isinstance(data.get("list"), list):
            return {**data, "list": data["list"][:max_items]}
        if isinstance(data.get("data"), dict) and isinstance(data["data"].get("items"), list):
            inner = dict(data["data"])
            inner["items"] = inner["items"][:max_items]
            return {**data, "data": inner}
    return data


def call_api(args: argparse.Namespace) -> Any:
    action = args.action
    symbol = normalize_symbol(args.symbol) if args.symbol else ""
    annals = 1 if args.annals else 0
    mapping: dict[str, Callable[[], Any]] = {
        "quote": lambda: ball.quotec(symbol),
        "detail": lambda: ball.quote_detail(symbol),
        "kline": lambda: ball.kline(symbol, args.period, args.count),
        "indicator": lambda: ball.indicator(symbol, annals, args.count),
        "income": lambda: ball.income(symbol, annals, args.count),
        "balance": lambda: ball.balance(symbol, annals, args.count),
        "cash_flow": lambda: ball.cash_flow(symbol, annals, args.count),
        "business": lambda: ball.business(symbol, annals, args.count),
        "main_indicator": lambda: ball.main_indicator(symbol),
        "holders": lambda: ball.holders(symbol),
        "top_holders": lambda: ball.top_holders(symbol, 1),
        "report": lambda: ball.report(symbol),
        "earningforecast": lambda: ball.earningforecast(symbol),
        "capital_flow": lambda: ball.capital_flow(symbol),
        "capital_history": lambda: ball.capital_history(symbol, args.count),
        "capital_assort": lambda: ball.capital_assort(symbol),
        "suggest": lambda: ball.suggest_stock(args.query or args.symbol),
    }
    if action not in mapping:
        raise QueryError(f"不支持的 action: {action}")
    if action != "suggest" and not symbol:
        raise QueryError("该 action 需要 --symbol")
    return mapping[action]()


def main() -> int:
    parser = argparse.ArgumentParser(description="雪球 pysnowball 金融数据查询 CLI")
    parser.add_argument("-s", "--symbol", default="", help="证券代码：SH600519/600519.SH/SZ000001/HK02400/02400.HK/NVDA")
    parser.add_argument("-q", "--query", default="", help="suggest 搜索关键词")
    parser.add_argument(
        "-a", "--action",
        choices=["quote", "detail", "kline", "indicator", "income", "balance", "cash_flow", "business", "main_indicator", "holders", "top_holders", "report", "earningforecast", "capital_flow", "capital_history", "capital_assort", "suggest"],
        default="detail",
    )
    parser.add_argument("--period", default="day", help="kline 周期：day/week/month/60m/30m/1m")
    parser.add_argument("--count", type=int, default=10)
    parser.add_argument("--annals", action="store_true", help="财报类接口只取年报；默认季报/最近报告")
    parser.add_argument("--token", default=None, help="默认读取 XUEQIU_TOKEN 或 XUEQIU_TOEKN")
    parser.add_argument("--compact", action="store_true")
    args = parser.parse_args()

    try:
        token = xueqiu_token(args.token)
        ball.set_token(token)
        data = call_api(args)
        if args.compact:
            data = compact_result(data, args.count)
        result = {
            "data": data,
            "_meta": {
                "source": "雪球/pysnowball",
                "source_url": SOURCE_URL,
                "repo": "https://github.com/uname-yang/pysnowball",
                "action": args.action,
                "symbol": normalize_symbol(args.symbol) if args.symbol else "",
                "query": args.query,
                "compact": args.compact,
            },
        }
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0
    except Exception as exc:
        msg = str(exc)
        if msg.startswith("b'") or msg.startswith('b"'):
            try:
                raw = getattr(exc, "args", [b""])[0]
                if isinstance(raw, bytes):
                    msg = raw.decode("utf-8", errors="replace")
            except Exception:
                pass
        print(f"ERROR: {msg}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
