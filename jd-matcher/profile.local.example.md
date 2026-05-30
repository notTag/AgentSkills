# jd-matcher — local profile config (TEMPLATE)

Copy this file to `profile.local.md` (same directory) and fill in your own values.
`profile.local.md` is gitignored so your personal paths and name never get committed.

The skill reads `profile.local.md` at runtime for everything candidate-specific. If it's
missing, the skill will ask you to create it from this template.

---

## Candidate

- **Name:** <Your Full Name>
- **Address as:** <preferred first name>
- **Search context:** <e.g. active senior-engineering-leadership search; target scopes>

## Profile sources

- **Canonical profile doc:** `</absolute/path/to/GoodFitDoc.md>`
  Defines what counts as a "good fit". Always read first.
- **Resume variants dir:** `</absolute/path/to/resumes/>`
  - **DoE** (Director of Engineering): `<relative/path/to/doe-resume.tex>`
  - **SrEM** (Senior Engineering Manager): `<relative/path/to/srem-resume.tex>`
  - **EM** (Engineering Manager): `<relative/path/to/em-resume.tex>`
  - PDFs sit alongside each `.tex` (same basename).
- **Calibration anchors:** `</absolute/path/to/anchors.md>`

## Output

- **Analyses root:** `</absolute/path/to/analyses/>`
