package evidence

import (
	"encoding/json"
	"errors"
	"testing"
	"time"
)

var start = time.Date(2026, 10, 7, 14, 32, 0, 0, time.UTC)

func move() Move {
	return Move{Chain: "solana", Token: "So11111111111111111111111111111111111111112", Kind: Pump, StartedAt: start, Change: 3.87}
}

func TestLevelOf(t *testing.T) {
	cases := []struct {
		in   float64
		want Level
	}{
		{0, Low}, {0.349, Low}, {0.35, Medium}, {0.64, Medium}, {0.65, High}, {1, High},
	}
	for _, c := range cases {
		if got := LevelOf(c.in); got != c.want {
			t.Errorf("LevelOf(%.3f) = %s, want %s", c.in, got, c.want)
		}
	}
}

func TestCap(t *testing.T) {
	thin := BaseRate{Samples: 4, Sufficient: false}
	known := BaseRate{Samples: 120, Lift: 2.4, Sufficient: true}
	if got := Cap(0.9, thin, 3); got != CapWithoutBaseRate {
		t.Errorf("no base rate: got %.2f, want %.2f", got, CapWithoutBaseRate)
	}
	if got := Cap(0.9, known, 1); got != CapSingleEvidence {
		t.Errorf("single evidence: got %.2f, want %.2f", got, CapSingleEvidence)
	}
	if got := Cap(0.9, known, 3); got != 0.9 {
		t.Errorf("uncapped: got %.2f, want 0.90", got)
	}
}

func TestFollowed(t *testing.T) {
	m := move()
	before := Evidence{At: start.Add(-3 * time.Minute), Source: "wallet", Summary: "three tracked wallets bought"}
	after := Evidence{At: start.Add(6 * time.Minute), Source: "market", Summary: "entered the 1m trending list"}
	if Followed(m, before, time.Minute) {
		t.Error("evidence before the start must not be followed")
	}
	if !Followed(m, after, time.Minute) {
		t.Error("evidence after the start must be followed")
	}
}

func TestQualifiesAsPump(t *testing.T) {
	base := Window{FromLow: 100_000, Now: 141_000, Elapsed: 9 * time.Minute, LiquidityUSD: 18_000, Trades: 64}
	if !QualifiesAsPump(base) {
		t.Fatal("a 41% rise in 9 minutes with liquidity and trades is a pump")
	}
	thin := base
	thin.Trades = 3
	if QualifiesAsPump(thin) {
		t.Error("one swap in an empty pool is not a pump")
	}
	slow := base
	slow.Elapsed = 40 * time.Minute
	if QualifiesAsPump(slow) {
		t.Error("a rise outside the window is not a pump")
	}
	if !QualifiesAsDump(200_000, 90_000, 12*time.Minute) {
		t.Error("a 55% drop in 12 minutes is a dump")
	}
}

func TestValidate(t *testing.T) {
	m := move()
	h := Hypothesis{
		Kind:       SmartMoneyBuy,
		Confidence: 0.58,
		Level:      Medium,
		BaseRate:   BaseRate{Samples: 140, Lift: 2.1, Sufficient: true},
		Evidence: []Evidence{
			{At: start.Add(-4 * time.Minute), Source: "wallet", Summary: "wallet A bought 2.1% of liquidity"},
			{At: start.Add(-2 * time.Minute), Source: "wallet", Summary: "wallet B bought 1.4% of liquidity"},
		},
	}
	if err := h.Validate(m, time.Minute); err != nil {
		t.Fatalf("valid hypothesis rejected: %v", err)
	}
	over := h
	over.Confidence, over.Level = 0.9, High
	over.BaseRate.Sufficient = false
	if err := over.Validate(m, time.Minute); err == nil {
		t.Error("confidence above the no-base-rate cap must be rejected")
	}
	bad := h
	bad.Confidence = 1.2
	if err := bad.Validate(m, time.Minute); !errors.Is(err, ErrConfidenceRange) {
		t.Errorf("want ErrConfidenceRange, got %v", err)
	}
}

func TestJSONShape(t *testing.T) {
	raw, err := json.Marshal(Explanation{Move: move(), Hypotheses: []Hypothesis{{Kind: Migration, Confidence: 0.4, Level: Medium, Evidence: []Evidence{}}}})
	if err != nil {
		t.Fatal(err)
	}
	var back map[string]any
	if err := json.Unmarshal(raw, &back); err != nil {
		t.Fatal(err)
	}
	for _, key := range []string{"move", "hypotheses"} {
		if _, ok := back[key]; !ok {
			t.Errorf("missing %q in %s", key, raw)
		}
	}
}
