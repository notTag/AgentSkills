# JDMatcher Calibration Anchors

Reference scores from past analyses, **manually curated by Nick**.

The skill reads this file before scoring a new JD to keep relative ordering honest.
The skill **never writes** to this file. Nick decides which scores become anchors —
only ones he trusts as fair representations of fit at that score.

To add an anchor: complete an analysis, decide the score is well-calibrated, then
append a row below.

---

## Active anchors

| Score | Band | Company | Role | Key reason |
|-------|------|---------|------|------------|
| 82 | Strong Fit | [Unnamed] | AI-native EM | Direct scope + AI tooling match. Gaps: operationalizing AI across team, customer-centric framing |
| 74 | Good Fit | Jimini Health | Engineering Manager (Backend/Infra) | Clean EM scope + Go/TS/Postgres + concrete agentic AI/ML evidence (pgVector, Golden-Lock, ~97% coverage). Caps: backend-specialist framing vs full-stack profile, HIPAA/PHI + GCP unproven, code-majority IC-heavy role |
| 72 | Good Fit | Harvey | Director / VP Engineering | AI-native legal-tech leadership. Gaps: GenAI product delivery examples, measurable impact framing |
| 58 | Partial Fit | Metabase | Engineering Manager | Blocker: deep React/TypeScript or Clojure frontend specialization required |
| 48 | Partial Fit | Upbound | Director, Control Planes & Ecosystem | Blocker: K8s / cloud-native infrastructure domain mismatch |

---

## Calibration notes

- **85+** is rare. Reserve for roles where the resume reads like it was written for the JD.
- **70–84** is the "tailor and apply" zone. Most strong leads land here.
- **55–69** is "compelling-only". Don't dilute the search by applying widely in this band.
- **<55** = stretch or pass. Apply only if logistics or domain-of-interest justify it.
