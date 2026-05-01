box::use(
    dplyr[lag, filter, mutate, group_by, summarise, arrange, desc, pull, tibble],
    stats[rnorm, lm, predict],
    utils[tail]
)

#' Lagged regression on national yearly data
#'
#' This function fits a lagged regression based on:
#' Cases ~ rainfall_index(t-1) + temp_anomaly(t)
#'
#' @export
fit_lag_model = function(national_ts) {
    df = national_ts |>
        mutate(lag1_rain = lag(rainfall_index, 1)) |>
        filter(!is.na(lag1_rain))

    model = lm(cases ~ lag1_rain + temp_anomaly_c, data = df)
    list(model = model, data = df)
}

#' Forecast by `n_years` horizon
#'
#' @export
predict_next_years = function(model_obj, n_years = 2) {
    df = model_obj$data
    model = model_obj$model
    last = tail(df, 1)

    future = tibble(
        lag1_rain = last$rainfall_index + rnorm(n_years, 0, 0.07),
        temp_anomaly_c = last$temp_anomaly_c + seq(0.05, by = 0.05, length.out = n_years)
    )

    preds = predict(model, newdata = future, interval = "prediction")
    future |>
        mutate(
            year = last$year + seq_len(n_years),
            predicted = pmax(0, round(preds[, "fit"])),
            lower = pmax(0, round(preds[, "lwr"])),
            upper = pmax(0, round(preds[, "upr"]))
        )
}

#' Risk classification
#'
#' A helper function that helps to classify risks
#' based on incidence rate per 100,000
#'
#' @export
classify_risk = function(incidence_rate, thresholds = c(low = 30, medium = 80)) {
    dplyr::case_when(
        incidence_rate <= thresholds["low"] ~ "Low",
        incidence_rate <= thresholds["medium"] ~ "Medium",
        TRUE ~ "High"
    )
}

#' Metrics Calculation function
#'
#' This functions obtains the metrics from national time series
#'
#' @export
compute_metrics = function(national_ts) {
    n = nrow(national_ts)

    if (n == 0) return(list(
        latest_year = NA, latest_cases = NA, growth_pct = NA,
        peak_year = NA, peak_cases = NA, total_all_years = NA
    ))

    recent = tail(national_ts, 1)

    growth = if (n >= 2) {
        prev = national_ts[n - 1, ]
        if (!is.na(prev$cases) && prev$cases > 0)
            round((recent$cases - prev$cases) / prev$cases * 100, 1)
        else
            NA
    } else {
        NA
    }

    list(
        latest_year = recent$year,
        latest_cases = recent$cases,
        growth_pct = growth,
        peak_year = national_ts$year[which.max(national_ts$cases)],
        peak_cases = max(national_ts$cases),
        total_all_years = sum(national_ts$cases)
    )
}
