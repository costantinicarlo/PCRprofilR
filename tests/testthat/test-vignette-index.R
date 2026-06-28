test_that("PCRprofilR tutorial vignette is indexed", {
    vignette_path <- testthat::test_path("..", "..", "vignettes", "PCRprofilR.Rmd")
    testthat::skip_if_not(
        file.exists(vignette_path),
        "Source vignette is not included in package build artifacts."
    )

    lines <- readLines(vignette_path, warn = FALSE)

    expect_true(any(grepl("VignetteIndexEntry\\{PCRprofilR tutorial:", lines)))
    expect_true(any(grepl("VignetteEngine\\{knitr::rmarkdown\\}", lines)))
    expect_true(any(grepl("^## What this tutorial is for$", lines)))
    expect_true(any(grepl("^## A minimal complete script$", lines)))
})
