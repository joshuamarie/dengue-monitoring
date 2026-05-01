box::use(
    dplyr[tibble]
)

#' Region metadata: provinces (or cities for NCR)
#' Source: PSGC 2023
#' @export
REGIONS_META = tibble(
    region_code = c(
        "NCR", "CAR", "I", "II", "III",
        "IV-A", "IV-B", "V", "VI", "VII",
        "VIII", "IX", "X", "XI", "XII",
        "XIII", "BARMM"
    ),
    area_label = c(
        "Cities", "Provinces", "Provinces", "Provinces", "Provinces",
        "Provinces", "Provinces", "Provinces", "Provinces", "Provinces",
        "Provinces", "Provinces", "Provinces", "Provinces", "Provinces",
        "Provinces", "Provinces"
    ),
    areas = list(
        # NCR (cities)
        c(
            "Manila", "Quezon City", "Caloocan", "Las Piñas",
            "Makati", "Malabon", "Mandaluyong", "Marikina",
            "Muntinlupa", "Navotas", "Parañaque", "Pasay",
            "Pasig", "San Juan", "Taguig", "Valenzuela",
            "Pateros"
        ),
        # CAR
        c("Abra", "Apayao", "Benguet", "Ifugao", "Kalinga", "Mountain Province"),
        # Region I
        c("Ilocos Norte", "Ilocos Sur", "La Union", "Pangasinan"),
        # Region II
        c("Batanes", "Cagayan", "Isabela", "Nueva Vizcaya", "Quirino"),
        # Region III
        c("Aurora", "Bataan", "Bulacan", "Nueva Ecija", "Pampanga", "Tarlac", "Zambales"),
        # Region IV-A
        c("Batangas", "Cavite", "Laguna", "Quezon", "Rizal"),
        # Region IV-B
        c("Marinduque", "Occidental Mindoro", "Oriental Mindoro", "Palawan", "Romblon"),
        # Region V
        c("Albay", "Camarines Norte", "Camarines Sur", "Catanduanes", "Masbate", "Sorsogon"),
        # Region VI
        c("Aklan", "Antique", "Capiz", "Guimaras", "Iloilo", "Negros Occidental"),
        # Region VII
        c("Bohol", "Cebu", "Negros Oriental", "Siquijor"),
        # Region VIII
        c("Biliran", "Eastern Samar", "Leyte", "Northern Samar", "Samar", "Southern Leyte"),
        # Region IX
        c("Zamboanga del Norte", "Zamboanga del Sur", "Zamboanga Sibugay"),
        # Region X
        c("Bukidnon", "Camiguin", "Lanao del Norte", "Misamis Occidental", "Misamis Oriental"),
        # Region XI
        c("Davao de Oro", "Davao del Norte", "Davao del Sur", "Davao Occidental", "Davao Oriental"),
        # Region XII
        c("Cotabato", "Sarangani", "South Cotabato", "Sultan Kudarat"),
        # Region XIII
        c("Agusan del Norte", "Agusan del Sur", "Dinagat Islands", "Surigao del Norte", "Surigao del Sur"),
        # BARMM
        c("Basilan", "Lanao del Sur", "Maguindanao del Norte", "Maguindanao del Sur", "Sulu", "Tawi-Tawi")
    )
)
