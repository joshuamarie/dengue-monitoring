# Dengue Early Warning & Surveillance System 

*Click [here](https://joshuamarieshine.shinyapps.io/dengue-surveillance/) to see the app.*

A modular R Shiny application for dengue outbreak monitoring across all 17 Philippine regions, covering 2018–2025. Built as a portfolio project demonstrating epidemiological modeling, spatial data visualization, and scalable Shiny architecture.

> **Note:** This application uses simulated data. Case counts, rainfall indices, and temperature anomalies are procedurally generated to reflect realistic epidemiological patterns but do not represent official recordings.

## Features

- *Regional risk map:* interactive Leaflet map showing case counts and incidence rates per 100,000 population across all regions, with risk classification (Low / Medium / High)
- *Trend dashboard:* yearly national and per-region time series overlaying dengue cases with a rainfall index
- *Risk prediction:* 1–3 year forward forecast using a lagged regression model with 95% prediction intervals
- *Key metrics:* KPI cards summarising year-on-year growth, peak year, and cumulative national burden

## Modeling Approach

A lagged ordinary least squares regression model is fitted on the national yearly time series:

$$
\hat{y}_t = \beta_0 + \beta_1 x_{1,\ t-1} + \beta_2 x_{2,\ t} + \varepsilon_t
$$

Where:

- $\hat{y}_t$: predicted dengue cases at year $t$
- $x_{1,\, t-1}$: rainfall index lagged by one year
- $x_{2,\, t}$: temperature anomaly (°C) at year $t$
- $\beta_0, \beta_1, \beta_2$: estimated coefficients
- $\varepsilon_t$: error term

The one-year lag on rainfall reflects the biological lifecycle of *Aedes aegypti*: elevated rainfall expands breeding sites, and the resulting increase in mosquito density translates into elevated case counts in the following transmission season. Temperature anomaly is included as a concurrent predictor, as warmer conditions accelerate both mosquito development and viral replication.

## Prerequisites

- R >= 4.3
- The `{box}` package (`install.packages("box")`)

## Deployment

This app is deployed to [shinyapps.io](https://www.shinyapps.io) via GitHub Actions on every push to `main`. Three repository secrets are required:

| Secret | Description |
|---|---|
| `SHINYAPPS_ACCOUNT` | shinyapps.io username |
| `SHINYAPPS_TOKEN` | Token from Account (Tokens) |
| `SHINYAPPS_SECRET` | Secret from Account (Tokens) |

[See the full workflow](https://github.com/joshuamarie/dengue-monitoring/blob/main/.github/workflows/deploy-shiny.yml).

## Upgrading to Real Data

The simulation layer is isolated in `R/data_simulation.R`. To replace it with real data, swap out `simulate_dengue_data()` with a loader that returns the same list structure:

```r
list(
    national = <data.frame: year, cases, rainfall_index, temp_anomaly_c>,
    regional = <data.frame: year, region_code, region_name, lat, lon,
                            population, cases, rainfall_index,
                            temp_anomaly_c, incidence_rate>,
    regions  = <data.frame: region reference table>
)
```

| Simulated field | Suggested real source |
|---|---|
| `cases` | DOH Philippines Epidemiology Bureau |
| `rainfall_index` | PAGASA station data / NOAA GPCC |
| `temp_anomaly_c` | PAGASA / NASA GISS Surface Temperature |
| Region coordinates | PSA / NAMRIA administrative boundaries |

<!--  No changes to `app.R` or any module are required as long as the structure above is preserved. -->

## License

MIT © Joshua Marie

