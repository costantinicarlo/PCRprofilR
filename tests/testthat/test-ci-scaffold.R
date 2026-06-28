test_that("R CMD check workflow scaffold exists", {
    path <- testthat::test_path("..", "..", ".github", "workflows", "r-cmd-check.yml")
    expect_true(file.exists(path))
})
