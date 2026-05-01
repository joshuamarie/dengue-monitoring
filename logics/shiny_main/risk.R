box::use(
    shiny[
        NS, tagList, div, p, icon, strong, br, tags,
        sliderInput, plotOutput, uiOutput, moduleServer,
        reactive, renderPlot, renderUI
    ],
    bslib[
        layout_columns, value_box
    ],
    ggplot2[
        ggplot, aes, geom_ribbon, geom_line, geom_point,
        geom_vline, scale_color_manual, scale_x_continuous,
        scale_y_continuous, labs, theme_minimal, theme,
        element_blank, element_text
    ],
    dplyr[bind_rows, mutate, rename, select, keep_when = filter],
    ../modeling[fit_lag_model, predict_next_years, classify_risk]
)

# ---- UI ----
risk_ui = function(id) {
    ns = NS(id)
    tagList(
        div(
            class = "module-header",
            p(
                "Short-term forecast using lagged regression on yearly national data",
                class = "module-subtitle"
            )
        ),
        div(
            class = "control-row",
            sliderInput(
                ns("n_years"),
                "Forecast horizon (years):",
                min = 1,
                max = 3,
                value = 2,
                step = 1,
                width = "300px"
            )
        ),
        plotOutput(ns("forecast_plot"), height = "300px"),
        br(),
        uiOutput(ns("risk_cards")),
        br(),
        div(
            class = "interpretation-box",
            icon("circle-info"),
            strong(" Model note: "),
            "Cases ~ Rainfall Index (t−1) + Temperature Anomaly (t). ",
            "Prediction intervals shown at 95%."
        )
    )
}

# ---- Server ----
risk_server = function(id, national_ts) {
    moduleServer(id, function(input, output, session) {

        model_obj = reactive({ fit_lag_model(national_ts()) })

        forecast_df = reactive({
            predict_next_years(model_obj(), n_years = input$n_years)
        })

        output$forecast_plot = renderPlot({
            hist_df = national_ts() |>
                mutate(type = "Observed", lower = NA_real_, upper = NA_real_) |>
                rename(predicted = cases) |>
                select(year, predicted, lower, upper, type)

            fcast = forecast_df() |>
                mutate(type = "Forecast") |>
                select(year, predicted, lower, upper, type)

            df = bind_rows(hist_df, fcast)

            ggplot(df, aes(x = year, y = predicted, color = type, group = 1)) +
                geom_ribbon(
                    data = keep_when(df, type == "Forecast"),
                    aes(ymin = lower, ymax = upper),
                    fill = "#ffe082",
                    alpha = 0.45,
                    color = NA
                ) +
                geom_line(linewidth = 1.15) +
                geom_point(size = 2.8) +
                geom_vline(
                    xintercept = min(fcast$year) - 0.5,
                    linetype = "dashed",
                    color = "grey50"
                ) +
                scale_color_manual(
                    values = c("Observed" = "#1565c0", "Forecast" = "#e65100")
                ) +
                scale_x_continuous(breaks = seq(2018, max(fcast$year))) +
                scale_y_continuous(labels = scales::comma) +
                labs(
                    x = NULL,
                    y = "Cases",
                    color = NULL,
                    caption = "Shaded band = 95% prediction interval"
                ) +
                theme_minimal(base_size = 13) +
                theme(
                    panel.grid.minor = element_blank(),
                    legend.position = "top",
                    plot.caption = element_text(color = "grey55", size = 10)
                )
        }, res = 110)

        output$risk_cards = renderUI({
            fcast = forecast_df()
            national_pop = 110000000L

            icon_map = c(
                Low = "circle-check",
                Medium = "triangle-exclamation",
                High = "circle-exclamation"
            )
            theme_map = c(Low = "success", Medium = "warning", High = "danger")

            cards = lapply(seq_len(nrow(fcast)), function(i) {
                row = fcast[i, ]
                incidence = row$predicted / national_pop * 1e5
                risk = classify_risk(incidence)

                value_box(
                    title = as.character(row$year),
                    value = format(row$predicted, big.mark = ","),
                    p("projected cases", style = "margin:0; font-size:0.8rem;"),
                    p(
                        tags$span(
                            class = paste0("badge text-bg-", theme_map[[risk]]),
                            toupper(risk)
                        ),
                        style = "margin: 4px 0 0;"
                    ),
                    showcase = icon(icon_map[[risk]]),
                    theme = theme_map[[risk]],
                    height = "160px"
                )
            })

            do.call(
                layout_columns,
                c(
                    list(
                        fill = FALSE,
                        col_widths = rep(12L / max(1L, nrow(fcast)), nrow(fcast)),
                        gap = "10px"
                    ),
                    cards
                )
            )
        })
    })
}
