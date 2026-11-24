# Verde Market — real fruit smoothie store

A bilingual (English / Portuguese) e-commerce concept for a fictional Miami smoothie brand, built with plain HTML, CSS and JavaScript, with real customer accounts powered by Supabase.

**Live demo:** _coming soon_

> Concept project by **KYNEX**. The brand, products and reviews are fictional. Payments are simulated and only public test cards are accepted, so nobody can be charged.

## Highlights

- **Flavor slider hero** — each flavor floods the screen with its color; the bottle, a giant word and floating fruit change with a measured panel wipe and parallax. Works with tabs, arrows, keyboard and swipe, and plays on its own.
- **Buy from the hero** — the flavor on screen can go straight to the cart.
- **Product catalog** — 25 products in 4 categories, with flavor, diet, price and rating filters, search and sorting.
- **Product page** — sizes, quantity and a weekly subscription with 15% off.
- **Build your own 6-pack** — pick any six bottles and get 15% off; the kit lands in the cart as one line.
- **Flavor quiz** — three questions and a scored product recommendation.
- **Cart and checkout** — saved cart, shipping estimate by US ZIP (same-day, standard, express), promo code, form validation.
- **Customer accounts (Supabase)** — sign up, sign in, password reset, saved address that pre-fills checkout, order history with "buy again", and account deletion.
- **Bilingual** — every string in English and Portuguese, switchable at any time.
- **Responsive and accessible** — tested at 1440 px and 390 px, no horizontal scroll, focus trapping in dialogs, `prefers-reduced-motion` respected.

## Tech stack

| Part | Choice |
|---|---|
| Front end | HTML, CSS, vanilla JavaScript (no framework, no build step) |
| Accounts and data | [Supabase](https://supabase.com) — Auth + Postgres with Row Level Security |
| Hosting | Cloudflare Pages |
| Fonts | Poppins and Baloo 2 (Google Fonts) |
| Product images | AI-generated cut-out sheets, cropped in CSS |

## Project structure

```
site/                 everything that is published
  index.html          the whole store (markup, styles and scripts)
  img/                product cut-out sheets and posters
  _headers            security and cache headers for Cloudflare Pages
supabase/
  schema.sql          tables, Row Level Security policies, grants and functions
```

## Security notes

- The Supabase key in `index.html` is the **publishable** key, which is designed to live in the browser. Every table has Row Level Security: each customer can only read and create their own rows, and visitors who are not signed in have no access at all.
- Orders can't be edited or deleted by customers once placed.
- Card numbers never leave the browser and are never stored. The checkout only accepts well-known public test cards (for example `4242 4242 4242 4242`) and disables card autofill.
- A customer can delete their own account, which removes their profile and order history.

## Run it locally

No install needed. From the `site` folder:

```bash
python -m http.server 8000
```

Then open http://localhost:8000.

## Set up your own Supabase project

1. Create a Supabase project.
2. Run `supabase/schema.sql` in the SQL Editor (it is safe to run more than once).
3. Optionally turn off **Confirm email** under Authentication → Sign In / Providers → Email.
4. Put your project URL and publishable key in `SB_URL` and `SB_KEY` in `site/index.html`.
5. Add your site address under Authentication → URL Configuration.

---

**Português:** loja-conceito bilíngue da marca fictícia Verde Market, feita pela KYNEX. Capa com slider de sabores, catálogo com filtros, kit de 6, quiz, carrinho com frete por ZIP, contas de cliente reais com Supabase e checkout com pagamento simulado.
