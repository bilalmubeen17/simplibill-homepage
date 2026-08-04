# SimpliBill Homepage

Marketing homepage for SimpliBill — a prevention-first practice management and billing platform.

Single self-contained HTML file. No build step, no dependencies, no framework.

## Structure

Everything (markup, CSS, and JS) lives in one file: `simplibill-homepage.html`. This includes:

- Hero with an animated claim-pipeline demo (CSS keyframe animation)
- Problem section with scroll-triggered stat reveals
- Product pillars, lifecycle, and AI/human sections
- "Receipts" section with count-up animated stats
- A "Book a demo" modal with client-side validation
- Scroll-reveal animations via a small vanilla JS `IntersectionObserver`

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

## Deploying

This is a static file, so it works as-is on GitHub Pages, Netlify, Vercel, S3,
or any static host. For GitHub Pages specifically, rename the file to `index.html`
at the repo root and enable Pages in the repo settings.

## License

See [LICENSE.md](./LICENSE.md).
