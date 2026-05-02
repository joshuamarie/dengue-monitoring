box::use(
    ggplot2[
        ggplot, aes, scale_fill_gradient2, coord_sf,
        theme_void, theme, element_text, element_rect,
        labs
    ],
    ggiraph[
        geom_sf_interactive, girafe, girafe_options,
        opts_hover, opts_hover_inv, opts_toolbar,
        opts_sizing, opts_zoom
    ],
    scales[label_comma],
    stats[median]
)

regional_map = function(df, metric) {
    label = if (metric == "cases") "Cases" else "Incidence\n(per 100k)"
    fmt_val = if (metric == "cases") label_comma() else label_comma(accuracy = 0.01)

    p = ggplot(df) +
        geom_sf_interactive(
            aes(
                geometry = geometry,
                fill = .data[[metric]],
                tooltip = paste0(
                    "<b style='font-size:1rem;'>", .data$region_name, "</b><br/>",
                    "<span style='font-size:0.78rem; opacity:0.7;'>",
                    .data$area_label, "</span><br/>",
                    .data$areas_html, "<br/><br/>",
                    "<b>", label, ":</b> ", fmt_val(round(.data[[metric]], 2))
                ),
                data_id = .data$region_code
            ),
            color = "#ffffff",
            linewidth = 0.4
        ) +
        scale_fill_gradient2(
            low = "#2dc653",
            mid = "#f4a11d",
            high = "#e5383b",
            midpoint = median(df[[metric]], na.rm = TRUE),
            name = label,
            labels = fmt_val
        ) +
        coord_sf(expand = FALSE, clip = "on") +
        theme_void() +
        theme(
            legend.position = "right",
            legend.title = element_text(size = 9),
            legend.text = element_text(size = 8),
            plot.background = element_rect(fill = "transparent", color = NA),
            panel.background = element_rect(fill = "transparent", color = NA)
        ) +
        labs(title = NULL)

    girafe(
        ggobj = p,
        options = list(
            opts_hover(css = "fill-opacity:1; stroke:#ffffff; stroke-width:2px;"),
            opts_hover_inv(css = "fill-opacity:0.25;"),
            opts_toolbar(saveaspng = FALSE, hidden = c("zoom_rect", "zoom_reset")),
            opts_sizing(rescale = TRUE, width = 1),
            opts_zoom(min = 1, max = 5)
        )
    )
}
