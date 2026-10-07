"""The public shape of an Exlipse explanation, mirrored from spec/go and spec/ts."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum

MEDIUM_FROM = 0.35
HIGH_FROM = 0.65
CAP_WITHOUT_BASE_RATE = 0.5
CAP_SINGLE_EVIDENCE = 0.64
PUMP_MIN_RISE = 0.40
MOVE_WINDOW = timedelta(minutes=15)
MIN_LIQUIDITY_USD = 2000.0
MIN_WINDOW_TRADES = 20


class Level(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


class HypothesisKind(str, Enum):
    SMART_MONEY_BUY = "smart_money_buy"
    KOL_BUY = "kol_buy"
    BUY_CLUSTER = "buy_cluster"
    MIGRATION = "migration"
    CREATOR_ACTION = "creator_action"
    TRENDING_ENTERED = "trending_entered"
    DEX_PAID = "dex_paid"
    ARTIFICIAL_VOLUME = "artificial_volume"
    X_POST = "x_post"
    TELEGRAM_CALL = "telegram_call"


@dataclass(frozen=True)
class Move:
    chain: str
    token: str
    kind: str
    started_at: datetime
    change: float


@dataclass(frozen=True)
class Evidence:
    at: datetime
    source: str
    summary: str
    url: str | None = None


@dataclass(frozen=True)
class BaseRate:
    samples: int
    lift: float
    sufficient: bool


@dataclass(frozen=True)
class Hypothesis:
    kind: HypothesisKind
    confidence: float
    level: Level
    followed: bool
    base_rate: BaseRate
    evidence: tuple[Evidence, ...] = field(default_factory=tuple)


def level_of(confidence: float) -> Level:
    if confidence >= HIGH_FROM:
        return Level.HIGH
    if confidence >= MEDIUM_FROM:
        return Level.MEDIUM
    return Level.LOW


def followed(move: Move, evidence: Evidence, grace: timedelta = timedelta(minutes=1)) -> bool:
    return evidence.at > move.started_at + grace


def cap(confidence: float, rate: BaseRate, pieces: int) -> float:
    if not rate.sufficient:
        confidence = min(confidence, CAP_WITHOUT_BASE_RATE)
    if pieces <= 1:
        confidence = min(confidence, CAP_SINGLE_EVIDENCE)
    return confidence


def qualifies_as_pump(from_low: float, now: float, elapsed: timedelta, liquidity_usd: float, trades: int) -> bool:
    if from_low <= 0 or elapsed > MOVE_WINDOW:
        return False
    return (now - from_low) / from_low >= PUMP_MIN_RISE and liquidity_usd >= MIN_LIQUIDITY_USD and trades >= MIN_WINDOW_TRADES


def problems(move: Move, hypotheses: list[Hypothesis], grace: timedelta = timedelta(minutes=1)) -> list[str]:
    out: list[str] = []
    for h in hypotheses:
        if not 0 <= h.confidence <= 1:
            out.append(f"{h.kind.value}: confidence {h.confidence} is outside [0, 1]")
        if h.level != level_of(h.confidence):
            out.append(f"{h.kind.value}: level {h.level.value}, expected {level_of(h.confidence).value}")
        if cap(h.confidence, h.base_rate, len(h.evidence)) < h.confidence:
            out.append(f"{h.kind.value}: confidence exceeds its cap")
        after = bool(h.evidence) and all(followed(move, e, grace) for e in h.evidence)
        if after != h.followed:
            out.append(f"{h.kind.value}: followed={h.followed}, evidence says {after}")
    return out


if __name__ == "__main__":
    start = datetime(2026, 10, 7, 14, 32)
    m = Move("solana", "So11111111111111111111111111111111111111112", "pump", start, 3.87)
    h = Hypothesis(
        HypothesisKind.SMART_MONEY_BUY,
        0.58,
        Level.MEDIUM,
        False,
        BaseRate(140, 2.1, True),
        (Evidence(start - timedelta(minutes=4), "wallet", "wallet A bought 2.1% of liquidity"),
         Evidence(start - timedelta(minutes=2), "wallet", "wallet B bought 1.4% of liquidity")),
    )
    assert problems(m, [h]) == [], problems(m, [h])
    assert level_of(0.35) is Level.MEDIUM and level_of(0.65) is Level.HIGH
    assert cap(0.9, BaseRate(4, 0, False), 3) == CAP_WITHOUT_BASE_RATE
    assert qualifies_as_pump(100_000, 141_000, timedelta(minutes=9), 18_000, 64)
    assert not qualifies_as_pump(100_000, 141_000, timedelta(minutes=9), 18_000, 3)
    print("evidence spec: ok")
