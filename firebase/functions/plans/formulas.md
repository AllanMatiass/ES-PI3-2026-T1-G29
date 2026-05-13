# Token Pricing Engine

## Objective

Dynamic pricing system for startup investment tokens.

The token price changes based on:

1. Primary Market purchases
2. Secondary Market trades
3. External market events

---

# Variables

| Variable     | Description                              |
| ------------ | ---------------------------------------- |
| P_atual      | Current token price                      |
| P_novo       | New token price after recalculation      |
| P_oferta     | Offer price defined by seller            |
| Q_tokens     | Quantity of traded tokens                |
| TotalTokens  | Total issued startup tokens              |
| K_primario   | Primary market sensitivity coefficient   |
| K_secundario | Secondary market sensitivity coefficient |
| Delta_evento | External event percentage impact         |

---

# 1. Primary Market Formula

## Context

Used when an investor buys tokens directly from the startup.

## Effect

The token price increases proportionally to the amount purchased relative to total supply.

## Formula

$$
P_{novo} =
P_{atual}
\times
\left(
1 +
\left(
\frac{Q_{tokens}}{TotalTokens}
\times
K_{primario}
\right)
\right)
$$

---

# 2. Secondary Market Formula

## Context

Used when an investor buys tokens from another investor through offers.

## Effect

The token price reacts to the difference between market price and accepted offer price.

## Formula

$$
P_{novo} =
P_{atual}
\times
\left(
1 +
\left(
\frac{P_{oferta} - P_{atual}}{P_{atual}}
\times
\frac{Q_{tokens}}{TotalTokens}
\times
K_{secundario}
\right)
\right)
$$

---

# 3. Tertiary Market Formula

## Context

Used for external events affecting startup valuation.

Examples:

- News
- Economic events
- Partnerships
- Scandals
- Viral growth

## Effect

Applies a direct percentage increase or decrease.

## Formula

$$
P_{novo} =
P_{atual}
\times
(1 + \Delta_{evento})
$$

---

# Suggested Default Values

| Variable     | Suggested Value |
| ------------ | --------------- |
| K_primario   | 0.1             |
| K_secundario | 0.5             |

---

# Examples

## Positive Event

Delta_evento = +0.15

Current Price = 10

New Price = 11.5

---

## Negative Event

Delta_evento = -0.10

Current Price = 10

New Price = 9

---

# Suggested Backend Flow

Trade Executed
↓
Load Startup Data
↓
Apply Pricing Formula
↓
Update currentTokenPrice
↓
Update valuation
↓
Save valuation snapshot
↓
Update charts/history

---

# Suggested Valuation Formula

$$
Valuation =
P_{novo}
\times
TotalTokens
$$

---

# Anti-Manipulation Recommendation

To avoid market manipulation:

- Use low sensitivity coefficients
- Ignore extremely small trades
- Apply max daily variation limits
- Use weighted average pricing if necessary

Example:

$$
\Delta_{max} = 0.05
$$

Maximum allowed variation:

- +5%
- -5%
