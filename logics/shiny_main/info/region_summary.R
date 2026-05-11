box::use(
    dplyr[group_by, summarise, mutate, select, arrange, desc],
    ../../modeling[classify_risk]
)

#' Shared region summary pipeline used by both table modules.
#' @param region_ts_filtered Already-filtered regional reactive data frame.
#' @return A summarised data frame with Region, Cases, Incidence, Risk columns.
compute_region_summary = function(region_ts_filtered) {
    region_ts_filtered |>
        group_by(region_code, region_name) |>
        summarise(
            cases = sum(cases, na.rm = TRUE),
            incidence_rate = round(
                sum(cases, na.rm = TRUE) /
                    sum(population, na.rm = TRUE) *
                    100000,
                1
            ),
            .groups = "drop"
        ) |>
        mutate(risk = classify_risk(incidence_rate)) |>
        select(
            region_code,
            Region = region_name,
            Cases = cases,
            `Incidence (per 100,000)` = incidence_rate,
            Risk = risk
        ) |>
        arrange(desc(Cases))
}
