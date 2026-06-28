test_that("PCRprofilR tutorial vignette is indexed", {
    vignette_path <- testthat::test_path("..", "..", "vignettes", "PCRprofilR.Rmd")
    installed_doc_path <- testthat::test_path("..", "..", "inst", "doc", "PCRprofilR.html")
    installed_source_path <- testthat::test_path("..", "..", "inst", "doc", "PCRprofilR.Rmd")
    installed_script_path <- testthat::test_path("..", "..", "inst", "doc", "PCRprofilR.R")
    installed_plot_path <- testthat::test_path("..", "..", "inst", "doc", "figure", "classified-plot-1.png")
    source_meta_path <- testthat::test_path("..", "..", "inst", "Meta", "vignette.rds")
    testthat::skip_if_not(
        file.exists(vignette_path),
        "Source vignette is not included in package build artifacts."
    )

    lines <- readLines(vignette_path, warn = FALSE)

    expect_true(any(grepl("VignetteIndexEntry\\{PCRprofilR tutorial:", lines)))
    expect_true(any(grepl("VignetteEngine\\{knitr::rmarkdown\\}", lines)))
    expect_true(any(grepl("^## What this tutorial is for$", lines)))
    expect_true(any(grepl("^## A minimal complete script$", lines)))

    expect_true(file.exists(installed_doc_path))
    expect_true(file.exists(installed_source_path))
    expect_true(file.exists(installed_script_path))
    expect_true(file.exists(installed_plot_path))
    expect_false(file.exists(source_meta_path))

    html <- readLines(installed_doc_path, warn = FALSE)
    expect_true(any(grepl("<h1>PCRprofilR tutorial:", html, fixed = TRUE)))
    expect_false(any(grepl("VignetteIndexEntry", html, fixed = TRUE)))
    expect_false(any(grepl("output: rmarkdown::html_vignette", html, fixed = TRUE)))
    expect_false(any(grepl("there is no package called 'PCRprofilR'", html, fixed = TRUE)))
    expect_false(any(grepl("data set 'mosquito' not found", html, fixed = TRUE)))
})
