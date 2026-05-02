box::use(
    dplyr[tibble, bind_rows, mutate, left_join],
    stats[rnorm]
)

#' Region reference table
#'
#' A table in `tibble` format that approximates centroids,
#' populations (2020 PSA estimates), and climate profile
REGIONS = tibble(
    region_code = c(
        "NCR", "CAR", "I", "II", "III",
        "IV-A", "IV-B", "V", "VI", "VII",
        "VIII", "IX", "X", "XI", "XII",
        "XIII", "BARMM"
    ),
    region_name = c(
        "NCR", "CAR", "Ilocos Region", "Cagayan Valley", "Central Luzon",
        "CALABARZON", "MIMAROPA", "Bicol Region", "Western Visayas", "Central Visayas",
        "Eastern Visayas", "Zamboanga Peninsula", "Northern Mindanao", "Davao Region", "SOCCSKSARGEN",
        "Caraga", "BARMM"
    ),
    lat = c(
        14.599, 17.351, 16.049, 17.613, 15.480,
        14.101, 10.623, 13.421, 10.720, 10.311,
        11.244, 7.827, 8.023, 7.054, 6.271,
        8.801, 6.957
    ),
    lon = c(
        120.984, 121.171, 120.566, 121.773, 120.907,
        121.177, 119.468, 123.414, 122.562, 123.885,
        124.999, 123.294, 124.685, 125.612, 124.686,
        125.740, 124.248
    ),
    population = c(
        13484462, 1797660, 5301139, 3685744, 12422172,
        16195042, 3228558, 6082165, 7954723, 8081988,
        4547150, 3875576, 5022768, 5243536, 4901486,
        2804788, 4404288
    ),
    # Base yearly case multiplier reflecting endemic burden per region
    # Higher in densely populated urban and high-rainfall areas
    endemic_index = c(
        2.8, 0.6, 0.9, 0.7, 1.4,
        2.1, 0.8, 1.1, 1.3, 1.6,
        1.0, 1.1, 1.2, 1.5, 1.2,
        0.9, 1.0
    )
)

simulate_dengue_data =
    function(
        start_year = 2018,
        end_year = 2025,
        seed = 42
    ) {

        set.seed(seed)

        years = seq(start_year, end_year)
        n_years = length(years)
        n_regions = nrow(REGIONS)

        # National summary:
        # 1. Total cases
        # 2. Rainfall index
        # 3. Temperature anomaly
        national_rain_index = c(1.00, 1.30, 0.85, 0.90, 1.20, 1.10, 0.95, 1.05)
        national_rain_index = national_rain_index[seq_len(n_years)]
        temp_anomaly = c(0.0, 0.3, -0.1, 0.2, 0.4, 0.3, 0.1, 0.2)
        temp_anomaly = temp_anomaly[seq_len(n_years)]
        national_ts = tibble(
            year = years,
            rainfall_index = round(national_rain_index + rnorm(n_years, 0, 0.05), 3),
            temp_anomaly_c = round(temp_anomaly + rnorm(n_years, 0, 0.05), 2)
        ) |> mutate(
            cases = as.integer(pmax(0, round(
                70000 * rainfall_index * (1 + 0.15 * temp_anomaly_c) +
                    rnorm(n_years, 0, 5000)
            )))
        )
        # national_ts = tibble(
        #     year = years,
        #     rainfall_index = round(national_rain_index + rnorm(n_years, 0, 0.05), 3),
        #     temp_anomaly_c = round(temp_anomaly + rnorm(n_years, 0, 0.05), 2),
        #     cases = as.integer(
        #         pmax(
        #             0,
        #             round(
        #                 70000 *
        #                     national_rain_index *
        #                     (1 + 0.15 * temp_anomaly) +
        #                     rnorm(n_years, 0, 5000)
        #             )
        #         )
        #     )
        # )

        # Per year region breakdown
        region_rows = lapply(seq_len(n_years), function(i) {
            yr = years[i]
            rain_idx = national_ts$rainfall_index[i]
            temp_anom = national_ts$temp_anomaly_c[i]

            # Cases per region
            # 1. Scaled by population
            # 2. Endemic index
            # 3. National climate signal
            pop_wt = REGIONS$population / sum(REGIONS$population)
            base = national_ts$cases[i] * pop_wt * REGIONS$endemic_index
            base = base / mean(REGIONS$endemic_index)

            regional_cases = pmax(0, round(base + rnorm(n_regions, 0, base * 0.12)))

            tibble(
                year = yr,
                region_code = REGIONS$region_code,
                region_name = REGIONS$region_name,
                lat = REGIONS$lat,
                lon = REGIONS$lon,
                population = REGIONS$population,
                cases = as.integer(regional_cases),
                rainfall_index = round(rain_idx + rnorm(n_regions, 0, 0.08), 3),
                temp_anomaly_c = round(temp_anom + rnorm(n_regions, 0, 0.07), 2)
            )
        })

        region_ts = bind_rows(region_rows) |>
            mutate(incidence_rate = round(cases / population * 100000, 2))

        list(national = national_ts, regional = region_ts, regions = REGIONS)
    }
