# blood-results-analysis

Structured analysis of Rythm Health (or comparable) blood-work panels uploaded as PDF or CSV. Runs a conversational intake interview first (training history, diet, sleep, goals, symptoms, medications), then loads the lab files and delivers a context-grounded report: wins, out-of-range markers, suboptimal-but-in-range markers, lifestyle confounds, drug/supplement interactions, follow-up tests, prioritized actions, and physician discussion points.

Honors long-training-history context (e.g. elevated creatinine/hematocrit/ferritin in heavy lifters) before flagging concerns. **Never gives medical advice or prescription dosing.**

## Trigger
Upload a blood-panel PDF/CSV, ask to "analyze my blood work / labs / panel / Rythm results", type `/blood-results`, `/bloodwork`, `/labs`, or paste marker values for interpretation.
