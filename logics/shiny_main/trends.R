box::use(
    shiny[
        NS, tagList, div, h4, p, icon, strong, selectInput,
        plotOutput, textOutput, moduleServer,
        renderPlot, renderText, conditionalPanel
    ],
    tp = ./plots/trend
)

trends_ui = function(id) {
    ns = NS(id)
    tagList(
        div(
            class = "module-header",
            h4("Epidemiological Trends"),
            p("Yearly dengue cases and rainfall index, 2018-2025", class = "module-subtitle")
        ),
        div(
            class = "control-row",
            selectInput(
                ns("view"), "View:",
                choices = c(
                    "National total" = "national",
                    "By region" = "regional"
                ),
                width = "200px"
            ),
            conditionalPanel(
                condition = "input.view == 'regional'",
                ns = ns,
                selectInput(
                    ns("region"), "Region (regional view):",
                    choices = NULL,
                    width = "260px"
                )
            )
        ),
        plotOutput(ns("trend_plot"), height = "360px"),
        div(
            class = "interpretation-box",
            icon("lightbulb"),
            strong(" Interpretation: "),
            textOutput(ns("interp"), inline = TRUE)
        )
    )
}

trends_server = function(id, national_ts, region_ts) {
    moduleServer(id, function(input, output, session) {

        shiny::observe({
            choices = unique(region_ts()$region_name)
            names(choices) = choices
            shiny::updateSelectInput(session, "region", choices = choices)
        })

        output$trend_plot = renderPlot({
            switch(
                input$view,
                "national" = tp$national_plot(national_ts()),
                "regional" = tp$regional_plot(region_ts(), input$region)
            )
        }, res = 110)

        output$interp = renderText({
            df = national_ts()
            peak_yr = df$year[which.max(df$cases)]
            peak_c = format(max(df$cases), big.mark = ",")
            rain_peak = df$rainfall_index[df$year == peak_yr]

            paste0(
                "National peak of ", peak_c, " cases occurred in ", peak_yr,
                " (rainfall index: ", rain_peak, "). ",
                "Elevated rainfall increases Aedes aegypti breeding sites, ",
                "driving case surges in the following transmission season."
            )
        })
    })
}
