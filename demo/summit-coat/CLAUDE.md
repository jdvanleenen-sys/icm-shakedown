# Summit Coat Painting: office workspace

A made-up demo business for trying the ICM Shakedown. Summit Coat is a 4-person house painting
company. This folder is how its office AI writes quotes and chases unpaid invoices.

## Where things go

| Job | Start here |
|---|---|
| Write a quote for a customer | `01-quote/CONTEXT.md` |
| Follow up on an unpaid invoice | `02-follow-up/CONTEXT.md` |
| Our prices | `pricing/rates-2025.md` |
| How we sound (approved by the owner) | `voice.md` |
| A job we are working on | `jobs/` (one folder per job, named date and street) |

## Rules
- Never send a quote or an email without the owner's OK. The AI drafts, the owner sends.
- Prices come from the pricing file only. Never guess a price.
- The quote template in `templates/quote.md` is a draft. Do not use it yet.
