# PBS Generic Price Erosion

What happens to price and to prescription volume when generic competition
enters the Australian pharmaceutical market?

**Dashboard:** https://public.tableau.com/app/profile/arya.kamat/viz/PBSGenericPriceErosion/PBSGenericPriceErosion

---

## Question

When a molecule comes off patent and generics enter, the listed price falls.
The commercial question is what happens next: does the cheaper price pull
additional volume through, or does the market simply pay less for the same
number of scripts?

The two scenarios have opposite implications. If volume responds, a price cut
is partly self-funding. If it does not, erosion is a pure revenue loss and the
only remaining lever is share.

## Data

PBS and RPBS Date of Supply supplementary reports, July 2022 to June 2026
(48 months), across four annual files. These reports include dispensing
pharmacy type but exclude Section 100 special arrangements, so the analysis
covers general community supply only.

Item codes were joined to molecule and form/strength labels using the PBS
item-to-drug mapping file, which is Latin-1 encoded rather than UTF-8. 192 of
789,577 rows found no matching drug name (0.02%) — most likely historical item
codes or the 99999Z placeholder used for unlisted RPBS items. These were left
in place rather than dropped.

| Stage | Rows |
|---|---|
| Raw, four files concatenated | 1,490,524 |
| After scope filters | 789,577 |
| Aggregated to item-month | 195,389 |
| Candidate items carried into event detection | 885 |

### Scope decisions

**Above co-payment only.** Under co-payment scripts record a zero government
contribution, so total cost is zero and cost per script would compute as $0.
Including them would fabricate price collapses that never happened. This
excludes roughly 16% of rows.

**S90 community pharmacies only.** Excludes public and private hospital
dispensing (S94) and approved medical practitioners (S92), where pricing
arrangements differ. Retail generic competition is the question here.

**Present in all 48 months.** A before-and-after comparison is impossible for
an item that appeared or disappeared partway through the window.

**Item code, not drug name.** This is the most consequential decision in the
project. A single drug name covers multiple strengths and pack sizes at
genuinely different prices, so aggregating by name lets a shift in product mix
appear as price movement when no price has changed. Item code is the level at
which PBS pricing actually operates, so a change there is a real price change.

## Method

Cost per script was computed as total cost divided by prescriptions, at
item-month level.

Candidate items were screened for step changes in that series and classified by
whether the fall was concentrated in a single month (share of decline ≥ 0.7) or
spread across successive price-disclosure cycles. The single-month drops are
analysed here, because a discrete step is what a competitive entry looks like;
a gradual decline could be any number of things.

This produced **19 item-level events**, which resolved to only **8 distinct
molecules** — four guanfacine strengths moving together, three apixaban
strengths, two dabigatran strengths, and so on. Treating 19 as an independent
sample would have badly overstated the evidence, so the analysis was redone at
molecule level with each molecule counted once.

Volume change was tested with a one-sample t-test against zero, and the
relationship between price fall and volume change with a Pearson correlation.

## Results

### Price

Mean price change across the eight molecules was **−32.0%**, median **−30.5%**,
ranging from −17.7% to −47.8%.

| Molecule | Price change (%) | Volume change (%) |
|---|---|---|
| APIXABAN | −24.4 | +5.7 |
| ARIPIPRAZOLE | −26.9 | +3.9 |
| DABIGATRAN | −35.4 | −18.7 |
| ENOXAPARIN SODIUM | −17.7 | +0.6 |
| GUANFACINE | −47.2 | +24.0 |
| PALONOSETRON | −34.2 | −47.6 |
| SACUBITRIL + VALSARTAN | −47.8 | −0.5 |
| TICAGRELOR | −22.7 | −14.3 |

### Volume

**No volume response was detectable.**

| Sample | n | t | p |
|---|---|---|---|
| All molecules | 8 | −0.78 | 0.46 |
| Excluding palonosetron | 7 | 0.02 | 0.99 |

Palonosetron was excluded as a sensitivity check because its −47.6% volume
change is confounded: it is an antiemetic used alongside chemotherapy, so its
script count moves with oncology practice rather than with its own price.

The correlation between the size of the price fall and the size of the volume
change was also not significant (r = −0.15, p = 0.72 across all eight;
r = −0.35, p = 0.44 excluding palonosetron). The sign is negative in both
cases, the opposite of what a demand response would predict, but neither
estimate is distinguishable from zero.

### Event timing

All 19 events fall on the first of a month, and cluster on just six dates:

| Date | Items |
|---|---|
| 1 October 2023 | 4 |
| 1 December 2023 | 2 |
| 1 April 2024 | 5 |
| 1 August 2024 | 3 |
| 1 February 2025 | 1 |
| 1 April 2025 | 4 |

Within each date the items belong to the same molecule — all four guanfacine
strengths on 1 October 2023, both dabigatran strengths on 1 December 2023, all
three apixaban strengths on 1 August 2024.

Prices do not move on arbitrary dates. They move together, on the first of the
month, for every strength of a molecule at once. That is the signature of an
administered price change rather than firms independently repricing, which
means the timing is scheduled and therefore predictable in advance.

## Where this analysis is weak

**Seven molecules is very little power.** The honest statement is not that
there is no volume response, but that this analysis could not detect one and
would have missed a modest one. Dropping a single molecule moves t from −0.78
to 0.02, which shows how sensitive the estimate is to individual points.

**Equal weighting.** The molecule-level average weights each drug equally, so
apixaban at roughly 330,000 scripts per month counts the same as enoxaparin at
roughly 2,900. This answers "what happens to a typical drug" rather than "what
happens to the market". A volume-weighted analysis would be a reasonable
extension.

**Volume change is not causally attributed.** Prescription volumes move for
clinical reasons — guideline changes, new competitors in the same class,
seasonality — none of which are controlled for here. Palonosetron is the
obvious case, but it is unlikely to be the only one.

**Entry is inferred, not observed.** The data records dispensing, not market
structure. A price step is treated as evidence of competitive entry, but the
number of entrants, their timing and their share are all unobserved. Some of
what is measured may be scheduled price disclosure reductions independent of
any new entrant.

## What a commercial team could take from this

1. **Do not model a volume offset into erosion forecasts.** Across eight
   molecules there is no evidence of one. Assume the revenue loss from a price
   fall is close to the full price fall.

2. **The timing is predictable.** Events land on the first of the month and
   affect every strength of a molecule simultaneously. Erosion can be planned
   against a calendar rather than treated as a shock.

3. **The spread is wide and unexplained.** Falls ranged from 18% to 48% with no
   obvious pattern from this data alone. Understanding what drives that spread
   — number of entrants, class dynamics, originator response — is worth more
   than a better point estimate of the average.

## Repository

| File | Contents |
|---|---|
| `pbs_generic_erosion.ipynb` | Full analysis: cleaning, event detection, statistics |
| `sql/queries.sql` | SQL reimplementation of the pandas pipeline |
| `event_summary.csv` | 19 item-level events with dates, pre/post prices and volumes |
| `molecule_summary.csv` | 8-molecule rollup used by the dashboard |
| `monthly_series.csv` | Monthly cost-per-script series for the event items |

`sql/queries.sql` reimplements the pandas pipeline in SQLite as a skills
demonstration. It reproduces the row counts exactly at every stage — 789,577,
195,389 and 885 — using joins, subqueries, `HAVING`, chained CTEs, `LAG()`,
`ROW_NUMBER()` and conditional aggregation.

`event_summary.csv` is not consumed by the dashboard. It is the item-level
layer that `molecule_summary.csv` was aggregated from, and it is the evidence
for the event-timing pattern described above.

Source data files (`dos-jul-2022-to-jun-2023-phrmcy-type.csv` and three
subsequent years, plus `pbs-item-drug-map.csv`) are not committed; they are
available from the source below.

## Source

Department of Health, Disability and Ageing 2026, *PBS and RPBS date of supply
supplementary reports*, Australian Government, Canberra, viewed 5 September
2026, &lt;https://www.pbs.gov.au&gt;.
