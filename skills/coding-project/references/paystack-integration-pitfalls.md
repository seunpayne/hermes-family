# Paystack Integration Pitfalls (Streetwise)

## PITFALL 1 — Callback URL uses CORS_ORIGIN (comma-separated list)

### Anti-pattern
```typescript
callback_url: `${this.configService.get<string>('CORS_ORIGIN')}/v1/payments/callback`
```

Two problems:
1. `CORS_ORIGIN` is a comma-separated list of multiple allowed origins
   (`streetwyze.ng, www.streetwyze.ng, railway.app`). Reading it as a single
   string produces a broken URL with commas.
2. `/v1/payments/callback` is a BACKEND API path. After Paystack redirects the
   user there, their browser shows a raw JSON response instead of returning
   them to the app.

### Correct pattern
```typescript
callback_url: `${this.configService.get<string>('FRONTEND_URL')}/resident/levy?reference=${reference}`
```
- Use FRONTEND_URL (single origin, no commas)
- Point at the resident-facing levy page with a reference param
- The frontend page reads the param, shows "Payment received, confirming..."
  while the webhook catches up, then refreshes the levy list

### Verification
After deploying: pay a test levy → confirm the browser lands back on the
resident levy page, not stuck on Paystack's modal or a raw JSON endpoint.

---

## PITFALL 2 — Transaction charge hardcoded to 50 kobo

### Anti-pattern
```typescript
// paystack.service.ts — hardcoded test constant
payload.transaction_charge = 50; // 50 kobo = 0.5 NGN
```
Every transaction charges 50 kobo regardless of levy amount. A ₦35,000 levy
generates ₦175 in actual platform fees but Paystack only deducts 50 kobo.

### Root cause
The sub-agent that built the Paystack integration hardcoded a test constant
and the caller never passed the actual calculated platform fee through.

### Correct pattern
```typescript
// paystack.service.ts — accept the fee as a parameter
async initializeTransaction(..., platformFeeKobo?: number) {
  payload.transaction_charge = platformFeeKobo ?? Math.round(amount * 0.005);
}

// payment.service.ts — pass the fee through
await this.paystackService.initializeTransaction(
  ...,
  Math.round(platformFee * 100), // convert ₦ to kobo
);
```

### Detection
```bash
grep -rn "transaction_charge" --include="*.ts" | grep -v "platformFee"
```
If `transaction_charge` is a literal number, it's hardcoded.

---

## PITFALL 3 — Fee-inclusive pricing (gross-up)

### When to use
When the estate should net exactly the levy amount they invoiced, and the
resident absorbs the Paystack + platform fees.

### Paystack fee structure (Nigeria, 2026)
- Local cards: 1.5% + ₦100 (capped at ₦2,000)
- International cards: 3.9% + ₦100 (no cap, can't be predicted at initiation)
- Platform fee (Streetwise): 0.5% of original levy amount

### Gross-up formula (works for C ≤ ~₦126,667)
```
C = (1.005 × L + 100) / 0.985
```
Where L = original levy amount, C = charged amount.

Above ₦126,667: `C = L + platformFee + 2000`

### Implementation
```typescript
function computeGrossedUpAmount(levyAmount: number): number {
  const platformFee = levyAmount * 0.005;
  const rawCharge = (1.005 * levyAmount + 100) / 0.985;
  const paystackFeeAtRaw = rawCharge * 0.015 + 100;
  if (paystackFeeAtRaw > 2000) {
    return levyAmount + platformFee + 2000;
  }
  return rawCharge;
}
```

### Display
Show the breakdown transparently in the payment modal:
| Line item | Amount |
|-----------|--------|
| Levy amount | ₦35,000 |
| Processing fee | ₦812.69 |
| **Total to pay** | **₦35,812.69** |

Platform fee stays at 0.5% of the ORIGINAL levy (not grossed-up) — the
resident absorbs the extra, the platform's cut is unchanged.
