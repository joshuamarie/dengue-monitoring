box::use(
    shiny[NS, tagList, div, h4, p, selectInput, moduleServer],
    leaflet[
        leaflet, addProviderTiles, providers, setView,
        addCircleMarkers, addLegend, colorFactor, leafletOutput,
        renderLeaflet
    ],
    dplyr[keep_when = filter, mutate],
    ../modeling[classify_risk]
)

map_ui = function(id) {
    ns = NS(id)
    tagList(
        div(
            class = "module-header",
            h4("Regional Risk Map"),
            p(
                "Circle size = case count  |  Color = risk level (incidence per 100,000)",
                class = "module-subtitle"
            )
        ),
        div(
            class = "control-row",
            selectInput(
                ns("year"),
                "Year:",
                choices = 2018:2025,
                selected = 2025,
                width = "140px"
            ),
            selectInput(
                ns("metric"),
                "Display metric:",
                choices = c(
                    "Case Count" = "cases",
                    "Incidence Rate (per 100,000)" = "incidence_rate"
                ),
                width = "280px"
            )
        ),
        leafletOutput(ns("map"), height = "480px")
    )
}

map_server = function(id, region_ts) {
    moduleServer(id, function(input, output, session) {

        pal = colorFactor(
            palette = c("#2dc653", "#f4a11d", "#e5383b"),
            levels = c("Low", "Medium", "High")
        )

        output$map = renderLeaflet({
            df = region_ts() |>
                keep_when(year == as.integer(input$year)) |>
                mutate(risk = classify_risk(incidence_rate))

            vals = df[[input$metric]]

            leaflet(df) |>
                addProviderTiles(providers$CartoDB.Positron) |>
                setView(lng = 122.0, lat = 12.0, zoom = 5) |>
                addCircleMarkers(
                    lng = ~lon,
                    lat = ~lat,
                    radius = ~pmax(7, sqrt(vals / max(vals, na.rm = TRUE)) * 28),
                    color = ~pal(risk),
                    fillColor = ~pal(risk),
                    fillOpacity = 0.75,
                    stroke = TRUE,
                    weight = 1.5,
                    popup = ~paste0(
                        "<b>", region_name, "</b><br>",
                        "Year: <b>", year, "</b><br>",
                        "Cases: <b>", format(cases, big.mark = ","), "</b><br>",
                        "Incidence: <b>", incidence_rate, "</b> per 100,000<br>",
                        "Risk: <b>", risk, "</b>"
                    )
                ) |>
                addLegend(
                    position = "bottomright",
                    pal = pal,
                    values = ~risk,
                    title = "Risk Level",
                    opacity = 0.9
                )
        })
    })
}
