box::use(
    rne = rnaturalearth,
    dplyr[summarise, mutate, case_when],
    sf[st_union, st_transform],
    readr[read_rds, write_rds]
)

cache_path = "./data/ph_regions.rds"

#' Build and cache dissolved Philippine region geometries
#'
#' Downloads province-level boundaries from rnaturalearth,
#' dissolves to 17 administrative regions, remaps to internal
#' region_code, reprojects to WGS84, and caches to disk.
build_ph_regions = function() {
    philippines = rne$ne_states(country = "Philippines", returnclass = "sf")

    ph_regions =
        philippines |>
        summarise(
            geometry = st_union(geometry),

            .by = region
        ) |>
        mutate(
            region_code = case_when(
                region == "National Capital Region" ~ "NCR",
                region == "Cordillera Administrative Region (CAR)" ~ "CAR",
                region == "Ilocos (Region I)" ~ "I",
                region == "Cagayan Valley (Region II)" ~ "II",
                region == "Central Luzon (Region III)" ~ "III",
                region == "CALABARZON (Region IV-A)" ~ "IV-A",
                region == "MIMAROPA (Region IV-B)" ~ "IV-B",
                region == "Bicol (Region V)" ~ "V",
                region == "Western Visayas (Region VI)" ~ "VI",
                region == "Central Visayas (Region VII)" ~ "VII",
                region == "Eastern Visayas (Region VIII)" ~ "VIII",
                region == "Zamboanga Peninsula (Region IX)" ~ "IX",
                region == "Northern Mindanao (Region X)" ~ "X",
                region == "Davao (Region XI)" ~ "XI",
                region == "SOCCSKSARGEN (Region XII)" ~ "XII",
                region == "Dinagat Islands (Region XIII)" ~ "XIII",
                region == "Autonomous Region in Muslim Mindanao (ARMM)" ~ "BARMM"
            )
        )

    write_rds(ph_regions, cache_path)
    ph_regions
}

#' Load Philippine region geometries
#'
#' Returns cached RDS if available, otherwise builds and caches it.
#' @export
load_ph_regions = function() {
    if (file.exists(cache_path)) {
        read_rds(cache_path)
    } else {
        message("Cache not found — fetching and building ph_regions...")
        build_ph_regions()
    }
}
