test_that("PCRprofilR tutorial vignette is indexed", {
    vignette_path <- testthat::test_path("..", "..", "vignettes", "PCRprofilR.Rmd")
    installed_doc_path <- testthat::test_path("..", "..", "inst", "doc", "PCRprofilR.html")
    installed_source_path <- testthat::test_path("..", "..", "inst", "doc", "PCRprofilR.Rmd")
    installed_script_path <- testthat::test_path("..", "..", "inst", "doc", "PCRprofilR.R")
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
    expect_false(file.exists(source_meta_path))
})
