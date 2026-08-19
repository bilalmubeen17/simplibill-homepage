# SimpliBill Homepage

Marketing homepage for SimpliBill — a prevention-first practice management and billing platform.

Four self-contained HTML files, each with its markup, CSS, and JS inlined. No build step,
no framework, no shared includes between them — each page duplicates the design-system
CSS and nav/footer/demo-modal markup on its own. The blog and admin pages are the one
exception to "no dependencies": they talk to a Supabase project over `fetch()` (see below).

## Structure

- **`simplibill-homepage.html`** — the marketing site:
  - Hero with an animated claim-pipeline demo (CSS keyframe animation)
  - Problem section with scroll-triggered stat reveals
  - Product pillars, lifecycle, and AI/human sections
  - "Receipts" section with count-up animated stats
  - A "Book a demo" modal with client-side validation
  - Scroll-reveal animations via a small vanilla JS `IntersectionObserver`
- **`careers.html`** — open roles and the "Apply for this role" flow.
- **`blog.html`** — public post list and article view, backed by Supabase.
- **`admin.html`** — password-gated post editor (create/edit/delete/publish), also backed
  by Supabase. Not linked from anywhere except the nav — there's no public signup here.

All four pages link to each other from the nav's Platform/How it works/Intelligence/
Services/Careers/Blog items. Since the pages don't share includes, updating shared pieces
(design tokens, nav links, the demo modal) means editing all four files.

## Running it locally

No server required — just open the file directly:

```bash
open simplibill-homepage.html        # macOS
start simplibill-homepage.html       # Windows
xdg-open simplibill-homepage.html    # Linux
```

Or, for a closer approximation of production (recommended, since some browsers
handle local `file://` requests differently than real HTTP requests):

```bash
python3 -m http.server 8000
# then visit http://localhost:8000/simplibill-homepage.html
```

## The "Book a demo" form

Form submissions post directly to HubSpot's Forms API — no backend required.
The portal/form IDs are hardcoded in the `<script>` block:

```js
const HUBSPOT_PORTAL_ID = '246830964';
const HUBSPOT_FORM_GUID = '757866e9-eebb-463a-8451-6d95e1a5c6a7';
```

This posts a `fields` array (plus a `context` object with `pageUri`/`pageName`) to
`https://api.hsforms.com/submissions/v3/integration/submit/{portalId}/{formGuid}`,
HubSpot's public anonymous submission endpoint — no API key involved.

**Field mapping — two entries are unverified guesses.** The form fields map to
these HubSpot internal property names:

| Homepage field | HubSpot property | Confidence |
|---|---|---|
| First name | `firstname` | High — standard HubSpot property |
| Last name | `lastname` | High — standard, and confirmed **required** on this form (see below) |
| Email | `email` | High — standard |
| Phone | `phone` | High — standard, and confirmed **required** on this form |
| Practice / organization | `company` | High — standard |
| Role | `jobtitle` | High — standard, but not part of the originally confirmed field list; confirmed **required** on this form |
| State / region | `state` | High — standard HubSpot contact property |
| Practice size | `practice_size` | **Low — custom property, name is a guess** |
| Billing headache / notes | `message` | **Low — custom property, name is a guess** |

`practice_size` and `message` are marked with `// LOW CONFIDENCE` comments at the
fetch call site in `simplibill-homepage.html`. If HubSpot rejects the submission
or silently drops those values, get the real internal property names from
whoever has access to the HubSpot form editor and swap them in.

**Required fields confirmed via direct API testing:** posting deliberately blank
values to the live HubSpot endpoint returns a `REQUIRED_FIELD` error naming the
field, which is how `lastname`, `phone`, and `jobtitle` were confirmed required
(not just guessed). The form was updated to match: full name is now split into
separate required First/Last name fields, and Phone/Role are required inputs
with validation (previously Phone was marked optional and Role wasn't validated
at all — submissions omitting either used to be silently rejected by HubSpot).

To point the form at a different HubSpot form/portal, change the two ID constants
above. To swap in a different provider entirely (FormSubmit, EmailJS, a real
backend, etc.), replace the `fetch()` call in the form's `submit` event listener.

## The careers "Apply for this role" form

Applications post directly to [FormSubmit](https://formsubmit.co/), which emails the
submission (including the attached resume) to `hr@simplibill.io` — no backend required.

```js
const APPLY_ENDPOINT = 'https://formsubmit.co/hr@simplibill.io';
```

**One-time activation step:** the first submission FormSubmit receives for a new
target address triggers a confirmation email to that address. Someone with access to
`hr@simplibill.io` needs to click the activation link in that email before further
applications will actually be delivered.

To point applications at a different address, change `APPLY_ENDPOINT`. To swap in a
real ATS (Greenhouse, Lever, etc.), replace the `fetch()` call in the apply form's
`submit` event listener.

## The blog and admin pages (Supabase)

`blog.html` (public) and `admin.html` (post editor) both talk directly to a Supabase
project's auto-generated REST API and Auth endpoints via `fetch()` — no server, no SDK.
Right now they point at placeholder values:

```js
const SUPABASE_URL = 'https://YOUR-PROJECT.supabase.co';
const SUPABASE_ANON_KEY = 'YOUR-ANON-PUBLIC-KEY';
```

**One-time setup:**

1. Create a free project at [supabase.com](https://supabase.com).
2. In the SQL Editor, run [`supabase-schema.sql`](./supabase-schema.sql) — it creates the
   `articles` table and the row-level-security policies (public can read published posts
   only; signed-in users can read/write everything, including drafts).
3. In **Authentication → Users**, manually create one user per admin (email + password).
   There is no public sign-up flow anywhere on the site — accounts only get created here.
4. In **Project Settings → API**, copy the Project URL and the `anon` public key, and
   paste them into the two constants above in *both* `blog.html` and `admin.html`.

**How it works:**

- `blog.html` lists posts where `published = true` (anonymous reads, via the `anon` key)
  and renders a single post at `blog.html?post=<slug>`.
- `admin.html` signs in against Supabase Auth (`/auth/v1/token?grant_type=password`),
  keeps the access token in `sessionStorage` (cleared when the tab closes), and uses it
  to list/create/update/delete rows in `articles` — including unpublished drafts, which
  the public page can't see.
- Article bodies are stored and rendered as plain text (rendered via `textContent`, not
  raw HTML, to avoid XSS) with line breaks preserved via CSS `white-space: pre-wrap`. No
  markdown rendering — if you want that, it's a small addition to the `renderArticle()`
  function in `blog.html`.
- Cover images are a plain URL field, not a file upload — anyone editing a post pastes a
  hosted image URL. Adding real image uploads would mean wiring up Supabase Storage,
  which isn't done here.

## Deploying

These are static files, so they work as-is on GitHub Pages, Netlify, Vercel, S3,
or any static host — deploy all four HTML files together so the nav links resolve.
Do the Supabase setup above before (or right after) launch, or `blog.html`/`admin.html`
will just show "could not load posts."

**Vercel:** no filename changes needed. [`vercel.json`](./vercel.json) rewrites `/` to
`/simplibill-homepage.html` so the bare domain serves the homepage instead of 404ing;
`careers.html`, `blog.html`, and `admin.html` are already reachable at their own paths
with no extra config. Just import the repo in Vercel with framework preset "Other" (or
no preset) — there's no build step to run.

**GitHub Pages:** doesn't support rewrites the same way, so instead rename
`simplibill-homepage.html` to `index.html` at the repo root (leave the other three
filenames as-is) and enable Pages in the repo settings.

## License

See [LICENSE.md](./LICENSE.md).
