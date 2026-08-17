# England and Wales house prices, 2025

## The question

Which districts saw the strongest house price growth in 2025, and is that growth real or just noise in the data?

## Headline finding

Most districts didn't grow at all. The median district saw prices fall 0.63% per quarter in 2025, around 2.5% over the year. A small group of ten districts bucked that trend, led by Monmouthshire, Islington, Carmarthenshire and Camden.

I only got to that finding after getting it wrong twice first, which is most of what this README is about.

## The data

HM Land Registry Price Paid data, full year 2025, around 933,000 raw transactions. Loaded into DuckDB, analysed in SQL, visualised in Tableau.

Cleaning decisions (see `01_exploration.sql` and `02_clean_table.sql`):
- Category A sales only (arm's-length, full market value - excludes repossessions, buy-to-lets and transfers not at market value, about 16.5% of rows)
- Residential property types only (excludes commercial/land)
- Price between £1,000 and £10,000,000 (excludes family transfers and portfolio deals recorded as a single line)
- Non-blank postcode

This leaves around 779,000 transactions to work with.

## What went wrong, twice

First pass: I ranked districts by average month-on-month price growth. Top 10 came back as Epsom and Ewell, Hyndburn, Merthyr Tydfil, Pendle, Isle of Anglesey - mostly small, low-volume places.

Two things were wrong with this and I didn't catch either until I checked.

The maths was wrong. Epsom and Ewell's actual January-to-December move was about 14%, roughly 1.2% a month compounding. I'd reported 3.08% a month. Averaging month-over-month percentage changes with a plain arithmetic mean overstates growth when the series is volatile - a 40% fall followed by a 46% rise averages to +3% even though the price ended up back where it started. Should have used a geometric mean from the start.

And the finding itself was mostly noise. Epsom and Ewell's median price went £585k in March, £350k in April, £510k in May. Prices don't fall 40% and recover the next month in a real market. With only 20-30 sales in some months, the median swings on whatever happened to sell that month rather than on anything real.

Second pass: switched to a geometric mean, added a minimum of 30 sales per month, required all 12 months to qualify. Growth numbers came down to a more believable 0.9-1.9% a month, but the district list barely moved - still Isle of Anglesey, Merthyr Tydfil, Lincoln, Hyndburn, Burnley. Once I indexed all ten to January = 100 on one chart it was obvious why: Hyndburn still dropped 25% in one month and bounced back the next. 30 sales/month wasn't a high enough bar - it dulled the problem rather than fixing it.

Third pass: aggregated to quarters instead of months, raised the floor to 100 sales/quarter, still required a full year of qualifying quarters. This changed things properly - 316 districts survived (far more than I expected), and the top 10 now includes large, liquid markets like Islington and Camden that the monthly version had completely missed, because monthly noise in tiny districts was drowning them out.

I checked the new #1, Monmouthshire, by breaking its sales down by property type per quarter, to rule out the median being pulled up by a shift toward pricier property types in later quarters. The mix stayed roughly stable across all four quarters and prices rose within every type, so the growth looks real rather than a composition effect.

## A limitation I kept rather than hid

Camden and Islington's ~3.5%/quarter ranking comes almost entirely from a sharp Q2 spike followed by a decline through Q3 and Q4 (Islington: 100 → 125 → 112 → 111). A geometric mean from Q1 to Q4 can't tell the difference between "grew steadily all year" and "spiked once and has been falling since" - both score the same if the start and end points match. I didn't rebuild the metric a third time to fix this. Instead it's called out directly on the dashboard: anyone who bought into either district in Q2 is currently down, not up. Monmouthshire's top ranking rests on a similar single-quarter jump in Q4.

A regression slope across all four quarters instead of just the endpoints would handle this better. That's the next thing I'd build if I extended this.

## Dashboard

Three linked views plus a distribution chart, so the top 10 isn't just asserted:
1. A histogram of all 316 qualifying districts' growth rates, top 10 highlighted, showing most of the distribution sits below zero
2. Small multiples - each top-10 district's quarterly trajectory shown separately (an earlier version tried to fit all 10 on one axis and was unreadable)
3. A ranking bar chart of the top 10 by average quarterly growth

Built in Tableau Public: [link to be added]

## Exclusions and caveats

- Category A, residential only, at least 100 sales/quarter per district. This trades district coverage for reliability and disproportionately excludes rural and small-urban areas, so the finding is really about liquid markets, not England and Wales as a whole.
- England and Wales only. Price Paid data doesn't cover Scotland or Northern Ireland.
- The geometric mean measures net change from Q1 to Q4 and won't distinguish steady growth from a single-quarter spike - see Camden/Islington above.

## What I'd tell someone using this

Camden and Islington's 2025 gains happened almost entirely in Q2 and have been fading since, so their ranking is worth treating with some caution. Monmouthshire, Three Rivers and Chichester look steadier and more recent, and might be lower-risk if that pattern holds.

## Repo structure

```
01_exploration.sql          initial data profiling, quality checks
02_clean_table.sql          exclusion rules, builds clean_sales
03_quarterly_analysis.sql   geometric mean growth, volume-filtered, quarterly
04_composition_check.sql    property-type mix check on Monmouthshire
README.md                   this file
```

The `.duckdb` database file is excluded via `.gitignore`. SQL is written for DuckDB, run against a table loaded from the public [HM Land Registry Price Paid Data](https://www.gov.uk/government/statistical-data-sets/price-paid-data-downloads), 2025 file.
