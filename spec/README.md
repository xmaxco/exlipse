# Evidence format

How Exlipse describes a move, the hypotheses that may explain it and the dated evidence behind each one —
as a JSON Schema with reference types in **Go**, **TypeScript** and **Python**.

```json
{
  "move": { "chain": "solana", "token": "…", "kind": "pump", "started_at": "2026-10-07T14:32:00Z", "change": 3.87 },
  "hypotheses": [
    {
      "kind": "smart_money_buy",
      "confidence": 0.58,
      "level": "medium",
      "followed": false,
      "base_rate": { "samples": 140, "lift": 2.1, "sufficient": true },
      "evidence": [
        { "at": "2026-10-07T14:28:00Z", "source": "wallet", "summary": "wallet A bought 2.1% of liquidity" },
        { "at": "2026-10-07T14:30:00Z", "source": "wallet", "summary": "wallet B bought 1.4% of liquidity" }
      ]
    }
  ]
}
```

| Rule | Value |
|---|---|
| Levels | low < 0.35 ≤ medium < 0.65 ≤ high |
| Precedence | evidence after the start of the move is `followed`, never a cause |
| No base rate yet | confidence capped at 0.50 |
| A single piece of evidence | confidence capped at 0.64 — never *high* |
| Pump | +40% from a local low within 15 min, ≥ $2k liquidity, ≥ 20 trades |
| Dump | −50% within 15 min |

| Path | What |
|---|---|
| `schema/explanation.schema.json` | JSON Schema, draft 2020-12 |
| `go/` | types, `LevelOf`, `Followed`, `Cap`, `QualifiesAsPump`, `Validate` — `go test ./...` |
| `ts/evidence.ts` | the same types and rules, plus `problems()` and `rank()` |
| `python/evidence.py` | dataclasses and the same rules — `python evidence.py` runs a self-check |

This is the public contract of an explanation, not the engine that produces it.
