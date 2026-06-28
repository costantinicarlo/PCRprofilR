test_that("R CMD check workflow scaffold exists", {
    path <- testthat::test_path("..", "..", ".github", "workflows", "r-cmd-check.yml")
    testthat::skip_if_not(
        file.exists(dirname(path)),
        "Workflow files are not included in package build artifacts."
    )
    expect_true(file.exists(path))
})
