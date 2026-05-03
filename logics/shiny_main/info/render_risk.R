box::use(
    broom[tidy],
    gt[
        gt, render_gt, gt_output, cols_label, fmt_number, fmt_scientific,
        tab_header, tab_source_note, tab_style, tab_spanner,
        cell_text, cells_column_labels, cells_body, cols_align, px
    ],
    dplyr[mutate, recode]
)

statistical_output = function(model) {
    render_gt({
        tidy(model, conf.int = TRUE, conf.level = 0.95) |>
            mutate(
                term = recode(
                    term,
                    "(Intercept)" = "Intercept",
                    "lag1_rain" = "Rainfall Index (t−1)",
                    "temp_anomaly_c" = "Temperature Anomaly (t)"
                )
            ) |>
            gt() |>
            tab_header(
                title = "Lagged Regression — Model Coefficients",
                subtitle = "Cases ~ Rainfall Index (t−1) + Temperature Anomaly (t)"
            ) |>
            tab_spanner(
                label = "95% Confidence Interval",
                columns = c(conf.low, conf.high)
            ) |>
            cols_label(
                term = "Predictor",
                estimate = "Estimate",
                std.error = "Std. Error",
                statistic = "t-value",
                p.value = "p-value",
                conf.low = "Lower",
                conf.high = "Upper"
            ) |>
            fmt_number(
                columns = c(estimate, std.error, statistic, conf.low, conf.high),
                decimals = 3
            ) |>
            fmt_scientific(
                columns = p.value,
                decimals = 2
            ) |>
            cols_align(align = "center", columns = -term) |>
            tab_style(
                style = cell_text(weight = "bold"),
                locations = cells_column_labels()
            ) |>
            tab_style(
                style = cell_text(style = "italic", color = "grey40"),
                locations = cells_body(
                    columns = term,
                    rows = term == "Intercept"
                )
            ) |>
            tab_source_note("Fitted on national yearly data. Prediction intervals in forecast use 95% level.")
    })
}
