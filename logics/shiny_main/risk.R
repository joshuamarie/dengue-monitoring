box::use(
    shiny[
        NS, tagList, div, h4, p, icon, strong, span, br,
        sliderInput, plotOutput, uiOutput, moduleServer,
        reactive, renderPlot, renderUI
    ],
    ggplot2[
        ggplot, aes, geom_ribbon, geom_line, geom_point,
        geom_vline, scale_color_manual, scale_x_continuous,
        scale_y_continuous, labs, theme_minimal, theme,
        element_blank, element_text
    ],
    dplyr[bind_rows, mutate, rename, select, keep_when = filter],
    stats[lm],
    ../modeling[fit_lag_model, predict_next_years, classify_risk],
)

risk_ui = function(id) {
    ns = NS(id)
    tagList(
        div(
            class = "module-header",
            h4("Risk Prediction"),
            p("Short-term forecast using lagged regression on yearly national data", class = "module-subtitle")
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
        div(
            class = "risk-cards",
            uiOutput(ns("risk_cards"))
        ),
        div(
            class = "interpretation-box",
            icon("circle-info"),
            strong(" Model note: "),
            "Cases ~ Rainfall Index (t-1) + Temperature Anomaly (t). Prediction intervals shown at 95%."
        )
    )
}

risk_server = function(id, national_ts) {
    moduleServer(id, function(input, output, session) {

        model_obj = reactive({
            fit_lag_model(national_ts())
        })

        forecast_df = reactive({
            predict_next_years(model_obj(), n_years = input$n_years)
        })

        output$forecast_plot = renderPlot({
            hist_df = national_ts() |>
                mutate(type = "Observed", lower = NA, upper = NA) |>
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
                    linetype = "dashed", color = "grey50"
                ) +
                scale_color_manual(values = c("Observed" = "#1565c0", "Forecast" = "#e65100")) +
                scale_x_continuous(breaks = seq(2018, max(fcast$year))) +
                scale_y_continuous(labels = scales::comma) +
                labs(
                    x = NULL, y = "Cases", color = NULL,
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
            # Risk cards use predicted national incidence: cases / ~110M national population
            national_pop = 110000000
            cards = lapply(seq_len(nrow(fcast)), function(i) {
                row = fcast[i, ]
                incidence = row$predicted / national_pop * 100000
                risk = classify_risk(incidence)
                cls = tolower(risk)
                div(
                    class = paste("risk-card", cls),
                    strong(row$year),
                    br(),
                    span(format(row$predicted, big.mark = ","), " cases"),
                    br(),
                    span(class = "risk-label", risk)
                )
            })
            div(class = "risk-card-row", tagList(cards))
        })
    })
}
