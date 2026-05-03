box::use(
    shiny[
        NS, tagList, div, p, icon, strong, br, tags,
        sliderInput, plotOutput, uiOutput, moduleServer,
        reactive, renderPlot, renderUI
    ],
    bslib[
        layout_columns, value_box
    ],
    dplyr[bind_rows, mutate, rename, select],
    fp = ./plots/forecast,
    ../modeling[fit_lag_model, predict_next_years, classify_risk],
    rr = ./info/render_risk
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
                max = 5,
                value = 2,
                step = 1,
                width = "300px"
            )
        ),
        ggiraph::girafeOutput(ns("forecast_plot"), width = "100%"),
        br(),
        gt::gt_output(ns("stat_out")),
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

        output$forecast_plot = ggiraph::renderGirafe({
            hist_df = national_ts() |>
                mutate(type = "Observed", lower = NA_real_, upper = NA_real_) |>
                rename(predicted = cases) |>
                select(year, predicted, lower, upper, type)

            fcast = forecast_df() |>
                mutate(type = "Forecast") |>
                select(year, predicted, lower, upper, type)

            df = bind_rows(hist_df, fcast)
            fp$forecast_plot(df, fcast$year)

        })

        output$stat_out = rr$statistical_output(model_obj()$model)

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

            rlang::exec(
                layout_columns,
                !!!list(
                    fill = FALSE,
                    col_widths = rep(12L / max(1L, nrow(fcast)), nrow(fcast)),
                    gap = "10px"
                ),
                !!!cards
            )
        })
    })
}
