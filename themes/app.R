box::use(
    bslib[bs_theme, font_google]
)

app_theme = bs_theme(
    version = 5,
    bootswatch = "flatly",
    primary = "#1b3a5c",
    secondary = "#607d8b",
    success = "#2dc653",
    warning = "#f4a11d",
    danger = "#e5383b",
    info = "#1565c0",
    base_font = font_google("IBM Plex Sans"),
    heading_font = font_google("IBM Plex Sans Condensed"),
    code_font = font_google("IBM Plex Mono"),
    "navbar-bg" = "#0d1b2a",
    "navbar-dark" = TRUE
)
