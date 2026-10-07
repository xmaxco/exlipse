// Package evidence is the public shape of an Exlipse explanation: a move,
// the hypotheses that may explain it and the dated evidence behind each one.
// It mirrors the rules published in the project README; it is not the engine.
package evidence

import (
	"errors"
	"fmt"
	"time"
)

type MoveKind string

const (
	Pump MoveKind = "pump"
	Dump MoveKind = "dump"
)

type HypothesisKind string

const (
	SmartMoneyBuy    HypothesisKind = "smart_money_buy"
	KOLBuy           HypothesisKind = "kol_buy"
	BuyCluster       HypothesisKind = "buy_cluster"
	Migration        HypothesisKind = "migration"
	CreatorAction    HypothesisKind = "creator_action"
	TrendingEntry    HypothesisKind = "trending_entered"
	PaidPromotion    HypothesisKind = "dex_paid"
	ArtificialVolume HypothesisKind = "artificial_volume"
	XPost            HypothesisKind = "x_post"
	TelegramCall     HypothesisKind = "telegram_call"
)

type Level string

const (
	Low    Level = "low"
	Medium Level = "medium"
	High   Level = "high"
)

const (
	MediumFrom = 0.35
	HighFrom   = 0.65

	CapWithoutBaseRate = 0.5
	CapSingleEvidence  = 0.64

	PumpMinRise     = 0.40
	DumpMinDrop     = 0.50
	MoveWindow      = 15 * time.Minute
	MinLiquidityUSD = 2000.0
	MinWindowTrades = 20
)

type Move struct {
	Chain     string    `json:"chain"`
	Token     string    `json:"token"`
	Kind      MoveKind  `json:"kind"`
	StartedAt time.Time `json:"started_at"`
	Change    float64   `json:"change"`
}

type Evidence struct {
	At      time.Time `json:"at"`
	Source  string    `json:"source"`
	Summary string    `json:"summary"`
	URL     string    `json:"url,omitempty"`
}

type BaseRate struct {
	Samples    int     `json:"samples"`
	Lift       float64 `json:"lift"`
	Sufficient bool    `json:"sufficient"`
}

type Hypothesis struct {
	Kind       HypothesisKind `json:"kind"`
	Confidence float64        `json:"confidence"`
	Level      Level          `json:"level"`
	Followed   bool           `json:"followed"`
	BaseRate   BaseRate       `json:"base_rate"`
	Evidence   []Evidence     `json:"evidence"`
}

type Explanation struct {
	Move       Move         `json:"move"`
	Hypotheses []Hypothesis `json:"hypotheses"`
}

var ErrConfidenceRange = errors.New("confidence must be within [0, 1]")

func LevelOf(confidence float64) Level {
	switch {
	case confidence >= HighFrom:
		return High
	case confidence >= MediumFrom:
		return Medium
	default:
		return Low
	}
}

func Followed(m Move, e Evidence, grace time.Duration) bool {
	return e.At.After(m.StartedAt.Add(grace))
}

func Cap(confidence float64, rate BaseRate, pieces int) float64 {
	if !rate.Sufficient && confidence > CapWithoutBaseRate {
		confidence = CapWithoutBaseRate
	}
	if pieces <= 1 && confidence > CapSingleEvidence {
		confidence = CapSingleEvidence
	}
	return confidence
}

type Window struct {
	FromLow      float64
	Now          float64
	Elapsed      time.Duration
	LiquidityUSD float64
	Trades       int
}

func QualifiesAsPump(w Window) bool {
	if w.FromLow <= 0 || w.Elapsed > MoveWindow {
		return false
	}
	return (w.Now-w.FromLow)/w.FromLow >= PumpMinRise && w.LiquidityUSD >= MinLiquidityUSD && w.Trades >= MinWindowTrades
}

func QualifiesAsDump(fromHigh, now float64, elapsed time.Duration) bool {
	if fromHigh <= 0 || elapsed > MoveWindow {
		return false
	}
	return (fromHigh-now)/fromHigh >= DumpMinDrop
}

func (h Hypothesis) Validate(m Move, grace time.Duration) error {
	if h.Confidence < 0 || h.Confidence > 1 {
		return fmt.Errorf("%s: %w", h.Kind, ErrConfidenceRange)
	}
	if want := LevelOf(h.Confidence); h.Level != want {
		return fmt.Errorf("%s: level %q, expected %q for %.2f", h.Kind, h.Level, want, h.Confidence)
	}
	if capped := Cap(h.Confidence, h.BaseRate, len(h.Evidence)); capped < h.Confidence {
		return fmt.Errorf("%s: confidence %.2f exceeds its cap %.2f", h.Kind, h.Confidence, capped)
	}
	followed := len(h.Evidence) > 0
	for _, e := range h.Evidence {
		if !Followed(m, e, grace) {
			followed = false
			break
		}
	}
	if h.Followed != followed {
		return fmt.Errorf("%s: followed=%t, evidence says %t", h.Kind, h.Followed, followed)
	}
	return nil
}
