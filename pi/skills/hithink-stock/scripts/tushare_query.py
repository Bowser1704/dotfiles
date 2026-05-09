#!/usr/bin/env python3
"""Tushare daily bars CLI.

Fetches A-share daily OHLCV data from Tushare and computes simple technical
indicators (MA5/MA20, trend label, short-term returns).

Requires TUSHARE_TOKEN in the environment or ~/.zshenv.

Usage examples:
  python3 tushare_query.py --ts-code 600519.SH --days 60
  python3 tushare_query.py --ts-code 000001.SZ --start-date 20240101 --end-date 20240630
  python3 tushare_query.py --ts-code 601899.SH --days 30 --compact
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import math
import os
import re
import shlex
import sys
import urllib.error
import urllib.request
from typing import Any

TUSHARE_URL = "http://api.tushare.pro"
DEFAULT_FIELDS = "ts_code,trade_date,open,high,low,close,pre_close,change,pct_chg,vol,amount"


# ── env ───────────────────────────────────────────────────────────────────────

def env_value(name: str) -> str:
    value = os.environ.get(name, "")
    if value:
        return value
    zshenv = os.path.expanduser("~/.zshenv")
    try:
        with open(zshenv, encoding="utf-8") as fh:
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


# ── helpers ───────────────────────────────────────────────────────────────────

def num(v: Any) -> float | None:
    if v is None:
        return None
    try:
        x = float(v)
        return None if math.isnan(x) else x
    except (TypeError, ValueError):
        return None


def normalize_ts_code(value: str) -> str:
    v = value.strip().upper()
    if re.fullmatch(r"\d{6}\.(SH|SZ|BJ)", v):
        return v
    m = re.search(r"(\d{6})", v)
    if not m:
        raise ValueError(f"无法识别股票代码：{value!r}，请传入如 600519.SH / 000001.SZ 格式")
    code = m.group(1)
    suffix = "SH" if code.startswith(("6", "9")) else "BJ" if code.startswith(("8", "4")) else "SZ"
    return f"{code}.{suffix}"


# ── Tushare API ───────────────────────────────────────────────────────────────

def fetch_daily(
    ts_code: str,
    token: str,
    *,
    start_date: str = "",
    end_date: str = "",
    days: int = 60,
    fields: str = DEFAULT_FIELDS,
    timeout: int = 30,
) -> dict[str, Any]:
    """Fetch daily bars and compute MA5/MA20/trend.

    If start_date/end_date are not given, fetches roughly `days * 2` calendar
    days of history so that there are enough trading days to compute indicators.
    """
    if not end_date:
        end_date = dt.date.today().strftime("%Y%m%d")
    if not start_date:
        start = dt.date.today() - dt.timedelta(days=max(90, days * 2))
        start_date = start.strftime("%Y%m%d")

    payload = {
        "api_name": "daily",
        "token": token,
        "params": {"ts_code": ts_code, "start_date": start_date, "end_date": end_date},
        "fields": fields,
    }
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
        return {"error": f"HTTP {exc.code}: {body[:500]}"}
    except urllib.error.URLError as exc:
        return {"error": f"网络错误: {exc.reason}"}

    if raw.get("code") != 0:
        return {"error": raw.get("msg") or str(raw)}

    data = raw.get("data") or {}
    col = data.get("fields") or []
    rows = [dict(zip(col, r)) for r in (data.get("items") or [])]
    # Tushare returns newest-first; keep at most `days` rows
    rows = rows[:days]

    closes = [num(r.get("close")) for r in rows]
    closes = [c for c in closes if c is not None]

    ma5  = sum(closes[:5])  / 5  if len(closes) >= 5  else None
    ma20 = sum(closes[:20]) / 20 if len(closes) >= 20 else None
    ret_5d  = (closes[0] / closes[4]  - 1) if len(closes) >= 5  and closes[4]  else None
    ret_20d = (closes[0] / closes[19] - 1) if len(closes) >= 20 and closes[19] else None

    trend = None
    if closes and ma5 and ma20:
        c = closes[0]
        if c > ma5 > ma20:
            trend = "强势：收盘价 > MA5 > MA20"
        elif c < ma5 < ma20:
            trend = "弱势：收盘价 < MA5 < MA20"
        else:
            trend = "震荡：均线结构不一致"

    return {
        "ts_code": ts_code,
        "latest": rows[0] if rows else None,
        "ma5": ma5,
        "ma20": ma20,
        "ret_5d": ret_5d,
        "ret_20d": ret_20d,
        "trend": trend,
        "rows": rows,
        "_meta": {
            "source": "Tushare",
            "source_url": "https://tushare.pro/",
            "ts_code": ts_code,
            "start_date": start_date,
            "end_date": end_date,
            "returned_rows": len(rows),
        },
    }


# ── CLI ───────────────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(description="Tushare 日线查询")
    parser.add_argument("--ts-code", required=True, help="股票代码，如 600519.SH / 000001.SZ")
    parser.add_argument("--days", type=int, default=60, help="返回最近 N 个交易日（默认 60）")
    parser.add_argument("--start-date", default="", help="起始日期 YYYYMMDD（优先级高于 --days）")
    parser.add_argument("--end-date",   default="", help="截止日期 YYYYMMDD（默认今天）")
    parser.add_argument("--fields", default=DEFAULT_FIELDS)
    parser.add_argument("--timeout", type=int, default=30)
    parser.add_argument("--compact", action="store_true", help="只输出 latest/ma5/ma20/trend/ret_5d/ret_20d")
    parser.add_argument("--token", default=None, help="Tushare token（默认从 TUSHARE_TOKEN 或 ~/.zshenv 读取）")
    args = parser.parse_args()

    token = args.token or env_value("TUSHARE_TOKEN")
    if not token:
        print("ERROR: 缺少 TUSHARE_TOKEN，请在 ~/.zshenv 中配置 export TUSHARE_TOKEN=...", file=sys.stderr)
        return 1

    try:
        ts_code = normalize_ts_code(args.ts_code)
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    result = fetch_daily(
        ts_code, token,
        start_date=args.start_date,
        end_date=args.end_date,
        days=args.days,
        fields=args.fields,
        timeout=args.timeout,
    )

    if args.compact and "error" not in result:
        result = {k: result[k] for k in ("ts_code", "latest", "ma5", "ma20", "ret_5d", "ret_20d", "trend", "_meta")}

    print(json.dumps(result, ensure_ascii=False, indent=2, default=str))
    return 0 if "error" not in result else 1


if __name__ == "__main__":
    raise SystemExit(main())
