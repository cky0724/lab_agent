"""Agent 评估脚本。

用法（在 backend 目录下执行）：
    python -m evals.run_eval                  # 只跑只读用例（安全，不动数据库）
    python -m evals.run_eval --include-write  # 额外跑写库用例，结束后自动清理
    python -m evals.run_eval --only guard     # 按 id 前缀或 type 筛选
    python -m evals.run_eval --limit 5        # 只跑前 N 条

原理：直接消费 agent_service.stream_agent 产出的事件流（tool_start / token），
     用规则断言判断「工具选择」和「护栏」是否达标，不依赖任何第三方评估平台。
"""

import argparse
import asyncio
import json
import os
import sys
import time
from datetime import datetime
from pathlib import Path

# 离线模式：跳过 HuggingFace Hub 网络检查，避免每条用例都重试
os.environ["HF_HUB_OFFLINE"] = "1"

# 修复 Windows 控制台中文乱码
if sys.stdout:
    sys.stdout.reconfigure(encoding='utf-8')

# 让脚本被直接执行（python evals/run_eval.py）时也能 import app 包
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from sqlalchemy import func

from app.config import settings
from app.database import SessionLocal
from app.models.reservation import Reservation
from app.models.user import User
from app.schemas.ai import ChatMessage, ChatRequest
from app.services import agent_service

EVAL_DIR = Path(__file__).resolve().parent
CASES_PATH = EVAL_DIR / "cases.json"
REPORT_PATH = EVAL_DIR / "report.md"
TRACES_PATH = EVAL_DIR / "traces.jsonl"
PREVIEW_LIMIT = 120  # 轨迹里工具结果保留的字符数


def load_cases() -> list[dict]:
    """读取用例集"""
    with CASES_PATH.open(encoding="utf-8") as file:
        return json.load(file)


def pick_test_user(db) -> User:
    """挑一个可用的学生账号，作为 Agent 的调用者"""
    user = (
        db.query(User)
        .filter(User.role == "student", User.status == 1)
        .order_by(User.id)
        .first()
    )
    if not user:
        raise SystemExit("数据库里没有可用的 student 账号，请先注册一个再跑评估")
    return user


async def consume_turn(db, user, request: ChatRequest, timeout: int):
    """跑一轮对话，返回本轮调用的工具、本轮答案、事件轨迹"""
    tools, answer, events = [], [], []

    async def _run():
        async for event in agent_service.stream_agent(db, user, request):
            events.append(event)
            kind = event.get("type")
            if kind == "tool_start":
                tools.append(event.get("name") or "")
            elif kind == "token":
                answer.append(event.get("content") or "")

    await asyncio.wait_for(_run(), timeout=timeout)
    return tools, "".join(answer), events


def judge(case: dict, called_tools: list[str], answer: str) -> tuple[bool, list[str]]:
    """规则断言：该调的调了 + 不该调的没调 + 答案命中关键词"""
    called = set(called_tools)
    failures = []
    for tool in case.get("must_call", []):
        if tool not in called:
            failures.append(f"缺少必须调用的工具：{tool}")
    hit = [tool for tool in case.get("must_not_call", []) if tool in called]
    if hit:
        failures.append(f"禁止调用的工具被触发：{'、'.join(hit)}")
    keywords = case.get("answer_contains") or []
    if keywords and not any(word in answer for word in keywords):
        failures.append(f"答案未命中任一关键词：{keywords}")
    return (not failures), failures


async def run_case(db, user, case: dict, timeout: int) -> dict:
    """跑一条用例（支持多轮），返回结果记录"""
    history: list[ChatMessage] = []
    called_tools, events, answer, error = [], [], "", ""
    started = time.time()

    for question in case["turns"]:
        history.append(ChatMessage(role="user", content=question))
        request = ChatRequest(messages=list(history))
        try:
            turn_tools, turn_answer, turn_events = await consume_turn(
                db, user, request, timeout
            )
        except asyncio.TimeoutError:
            error = f"超过 {timeout}s 未返回"
            break
        except Exception as exc:  # 单条用例失败不影响整体评估
            error = f"执行异常：{exc}"
            break
        called_tools.extend(turn_tools)
        events.extend(turn_events)
        answer = turn_answer
        history.append(ChatMessage(role="assistant", content=turn_answer))

    passed, failures = judge(case, called_tools, answer)
    if error:
        passed, failures = False, [error]
    else:
        # 事件流里如果出现过 error，说明模型或工具报错了，直接记为失败
        stream_errors = [item.get("message") for item in events if item.get("type") == "error"]
        if stream_errors:
            passed, failures = False, [f"对话流返回错误：{stream_errors[-1]}"]

    return {
        "id": case["id"],
        "type": case["type"],
        "turns": case["turns"],
        "note": case.get("note", ""),
        "called_tools": called_tools,
        "answer": answer,
        "passed": passed,
        "failures": failures,
        "duration": round(time.time() - started, 1),
        "guard_checked": bool(case.get("must_not_call")),
        "events": events,
    }


def cleanup_written_reservations(db, start_max_id: int) -> int:
    """删除评估期间新增的预约记录，保证演示数据不被污染"""
    removed = (
        db.query(Reservation)
        .filter(Reservation.id > start_max_id)
        .delete(synchronize_session=False)
    )
    db.commit()
    return removed


def summarize(results: list[dict]) -> dict:
    """汇总指标"""
    total = len(results)
    passed = sum(1 for item in results if item["passed"])
    guard_results = [item for item in results if item["guard_checked"]]
    guard_ok = sum(
        1
        for item in guard_results
        if not any("禁止调用" in failure for failure in item["failures"])
    )
    durations = [item["duration"] for item in results] or [0]
    tool_counts = [len(item["called_tools"]) for item in results] or [0]
    return {
        "total": total,
        "passed": passed,
        "pass_rate": passed / total if total else 0.0,
        "guard_total": len(guard_results),
        "guard_ok": guard_ok,
        "guard_rate": guard_ok / len(guard_results) if guard_results else 0.0,
        "avg_duration": round(sum(durations) / len(durations), 1),
        "avg_tools": round(sum(tool_counts) / len(tool_counts), 1),
    }


def compact_events(events: list[dict]) -> list[dict]:
    """压缩轨迹：丢掉逐字 token，只留工具调用等关键事件"""
    compact = []
    for event in events:
        kind = event.get("type")
        if kind == "token":
            continue
        item = {"type": kind}
        for key in ("name", "label", "message"):
            if event.get(key):
                item[key] = event[key]
        if event.get("preview"):
            item["preview"] = str(event["preview"])[:PREVIEW_LIMIT]
        compact.append(item)
    return compact


def esc(text: str) -> str:
    """转义 Markdown 表格里的竖线"""
    return str(text).replace("|", "\\|")


def write_report(
    results: list[dict],
    summary: dict,
    started_at: str,
    skipped: list[str],
    include_write: bool,
    removed: int,
) -> None:
    """生成 Markdown 报告"""
    lines = [
        "# Agent 评估报告",
        "",
        f"- 运行时间：{started_at}",
        f"- 模型：{settings.LLM_MODEL}",
        f"- 用例总数：{summary['total']}（通过 {summary['passed']} / 失败 {summary['total'] - summary['passed']}）",
        f"- 整体通过率：{summary['pass_rate']:.1%}",
        f"- 护栏遵守率：{summary['guard_rate']:.1%}（{summary['guard_ok']}/{summary['guard_total']}）",
        f"- 平均耗时：{summary['avg_duration']}s",
        f"- 平均工具调用：{summary['avg_tools']} 次",
    ]
    if skipped:
        lines.append(f"- 已跳过写库用例：{'、'.join(skipped)}（加 --include-write 可启用）")
    if include_write:
        lines.append(f"- 写库用例已执行，结束后清理新增预约记录：{removed} 条")

    lines += [
        "",
        "## 结果明细",
        "",
        "| 用例 | 类型 | 输入 | 实际调用工具 | 结果 | 耗时 | 失败原因 |",
        "| --- | --- | --- | --- | --- | --- | --- |",
    ]
    for item in results:
        lines.append(
            "| {id} | {type} | {question} | {tools} | {status} | {duration}s | {reason} |".format(
                id=item["id"],
                type=item["type"],
                question=esc(" → ".join(item["turns"])),
                tools=esc("、".join(item["called_tools"]) or "-"),
                status="通过" if item["passed"] else "失败",
                duration=item["duration"],
                reason=esc("；".join(item["failures"]) or "-"),
            )
        )

    failed = [item for item in results if not item["passed"]]
    if failed:
        lines += ["", "## 失败详情", ""]
        for item in failed:
            lines.append(f"### {item['id']}（{item['type']}）")
            lines.append("")
            lines.append(f"- 输入：{' → '.join(item['turns'])}")
            lines.append(f"- 实际调用工具：{'、'.join(item['called_tools']) or '无'}")
            lines.append(f"- 失败原因：{'；'.join(item['failures'])}")
            lines.append(f"- 实际回答：{item['answer'][:300] or '（空）'}")
            lines.append("")

    REPORT_PATH.write_text("\n".join(lines), encoding="utf-8")


def write_traces(results: list[dict]) -> None:
    """把每条用例的关键轨迹写成 jsonl，供排查与后续分析"""
    with TRACES_PATH.open("w", encoding="utf-8") as file:
        for item in results:
            record = {
                "id": item["id"],
                "turns": item["turns"],
                "called_tools": item["called_tools"],
                "answer": item["answer"],
                "passed": item["passed"],
                "failures": item["failures"],
                "duration": item["duration"],
                "events": compact_events(item["events"]),
            }
            file.write(json.dumps(record, ensure_ascii=False) + "\n")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="实验室 Agent 评估脚本")
    parser.add_argument(
        "--include-write",
        action="store_true",
        help="额外跑会写库的用例（结束后自动清理新增记录）",
    )
    parser.add_argument(
        "--only", default="", help="只看某类用例：id 前缀或 type，如 guard / knowledge"
    )
    parser.add_argument("--limit", type=int, default=0, help="只跑前 N 条用例")
    parser.add_argument("--timeout", type=int, default=180, help="单轮对话超时秒数")
    return parser.parse_args()


async def main() -> None:
    args = parse_args()
    cases = load_cases()
    if args.only:
        cases = [
            case
            for case in cases
            if case["id"].startswith(args.only) or case["type"] == args.only
        ]
    if args.limit:
        cases = cases[: args.limit]
    if not cases:
        raise SystemExit("没有匹配的用例，请检查 --only / --limit 参数")

    db = SessionLocal()
    try:
        user = pick_test_user(db)
        start_max_id = db.query(func.max(Reservation.id)).scalar() or 0

        selected, skipped = [], []
        for case in cases:
            if case.get("need_write") and not args.include_write:
                skipped.append(case["id"])
            else:
                selected.append(case)

        started_at = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(
            f"用例 {len(selected)} 条（跳过写库用例 {len(skipped)} 条）"
            f"｜测试账号：{user.username}｜模型：{settings.LLM_MODEL}"
        )
        if args.include_write:
            print("注意：已开启写库用例，结束后会自动清理本次新增的预约记录")
        print("-" * 72)

        results = []
        for index, case in enumerate(selected, start=1):
            result = await run_case(db, user, case, args.timeout)
            results.append(result)
            mark = "通过" if result["passed"] else "失败"
            tools = "、".join(result["called_tools"]) or "无工具调用"
            print(
                f"[{index:>2}/{len(selected)}] {result['id']:<10} {mark}"
                f"  {result['duration']:>6}s  工具：{tools}"
            )
            for failure in result["failures"]:
                print(f"            └ {failure}")

        removed = (
            cleanup_written_reservations(db, start_max_id) if args.include_write else 0
        )
        summary = summarize(results)
        write_report(results, summary, started_at, skipped, args.include_write, removed)
        write_traces(results)

        print("-" * 72)
        print(
            f"整体通过率 {summary['pass_rate']:.1%}（{summary['passed']}/{summary['total']}）"
            f"｜护栏遵守率 {summary['guard_rate']:.1%}（{summary['guard_ok']}/{summary['guard_total']}）"
        )
        print(f"报告：{REPORT_PATH}")
        print(f"轨迹：{TRACES_PATH}")
    finally:
        db.close()


if __name__ == "__main__":
    asyncio.run(main())