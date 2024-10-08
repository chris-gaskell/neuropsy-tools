#' Bayesian Dissociation Single Case Analysis
#'
#' This function performs a Bayesian single-case analysis to assess the
#' abnormality of a given score compared to a control group. It generates
#' simulated distributions of scores based on the control group's mean,
#' standard deviation, and sample size, and provides Bayesian credible
#' intervals, p-values, and abnormality percentages.
#'
#' @details NEEDS WRITING
#'
#' @inheritParams deficit
#' @param conf.level Numeric value specifying the confidence level for the credible interval (default is 0.95 for 95%).
#' @param sims Integer specifying the number of simulations to perform. Default is 10000.
#' @param treshold Numeric value for the abnormality threshold. Default is 0.1.
#'
#' @return A list of statistical input, parameters, and results. Key outputs
#'   include:
#'   - t-value: The t-value calculated for the test.
#'   - p-value: The p-value for the test, indicating statistical significance.
#'   - effect-size (z-cc): The z-score (effect-size) corrected for the control group.
#'   - abnormality: The percentage of the population expected to score a more extreme score.
#'
#' @importFrom bayestestR hdi
#' @importFrom stats rchisq rnorm pnorm
#'
#' @references
#'   - Crawford, J.R., & Garthwaite, P.H. (2007). Comparison of a single case to a control or normative sample in neuropsychology: Development of a Bayesian approach. *Cognitive Neuropsychology, 24*(4), 343-372.
#'   - NEEDS WRITING.
#'   - NEEDS WRITING.
#'   - NEEDS WRITING.
#'   - NEEDS WRITING.
#' @seealso
#'   - [deficit()]: Assessing For a frequentist single dissociation between a test score and a control sample.
#'   - [deficit_bayes()]: For a Bayesian approach to assessing for a dissociation between a single test score and a control sample for a single case.
#'   - [discrep()]: For assessing a dissociation between two test scores for a single case.
#'   - [bayestestR::hdi()]
#'
#' @examples
#' deficit_bayes(
#'   score = 90,
#'   ctrl.mean = 100,
#'   ctrl.sd = 15,
#'   ctrl.n = 30,
#'   conf.level = 0.95,
#' )
#'
#' @export
deficit_bayes <- function(
    score,
    ctrl.mean,
    ctrl.sd,
    ctrl.n,
    conf.level = .95,
    direction = "lower",
    tail = "one.tailed",
    dp = 2,
    sims = 10000,
    treshold = 0.1) {

  if (direction != "higher" & direction != "lower") {
    stop("Invalid direction. Options are 'higher' or 'lower'.")
  }

  df <-  ctrl.n-1
  ctrl.var <- ctrl.sd^2

  p.sims <- c()
  for (i in 1:sims) {
    psi <- rchisq(1, df = df, ncp = 0)
    o <- (ctrl.n - 1) * ctrl.var / psi
    z.sim <- rnorm(1, 0, 1)
    u <- ctrl.mean + z.sim * sqrt((o / ctrl.n))
    z <- (score - u) / sqrt(o)

    # Calculate p-value based on the specified direction
    if (direction == "lower") {
      p <- pnorm(z, lower.tail = TRUE)  # Lower tail probability
    } else if (direction == "higher") {
      p <- pnorm(z, lower.tail = FALSE)  # Lower tail probability
    }


    p.sims <- c(p.sims, p)
  }

  z.scores <- c()
  for (i in 1:sims) {
    psi <- rchisq(1, df = df, ncp = 0)
    o <- (ctrl.n - 1) * ctrl.var / psi
    z.sim <- rnorm(1, 0, 1)
    u <- ctrl.mean + z.sim * sqrt((o / ctrl.n))
    z <- (score - u) / sqrt(o)
    z.scores <- c(z.scores, z)
  }

  z <- (score - ctrl.mean) / ctrl.sd
  percentile <- pnorm(z)*100
  z.ci <- bayestestR::hdi(z.scores, ci = conf.level)
  z.ci.lb <- min(z.ci$CI_low, z.ci$CI_high)
  z.ci.ub <- max(z.ci$CI_high, z.ci$CI_low)

  p <- mean(p.sims)


# abnormality -------------------------------------------------------------

  abn <- p * 100
  abn.ci <- bayestestR::hdi(p.sims, ci = conf.level)
  abn.ci.lb <- min(abn.ci$CI_low, abn.ci$CI_high) * 100
  abn.ci.ub <- max(abn.ci$CI_low, abn.ci$CI_high) * 100

  if (tail == "two.tailed") {p <- 2 * min(p, 1 - p)}

# rounding ----------------------------------------------------------------
  z <- round(z, dp)
  z.ci.lb <- round(z.ci.lb, dp)
  z.ci.ub <- round(z.ci.ub, dp)
  percentile <- round(percentile, dp)
  p <- round(p, dp)
  #p.two.tailed<-= round(p.two.tailed, dp)
  abn <- round(abn, dp)
  abn.ci.lb <- round(abn.ci.lb, dp)
  abn.ci.ub <- round(abn.ci.ub, dp)

# output ------------------------------------------------------------------

  input_df <- data.frame(
    Item = c("Sample mean", "Sample SD", "Sample size", "Case's test score"),
    Value = c(ctrl.mean, ctrl.sd, ctrl.n, score),
    stringsAsFactors = FALSE
  )

  parameters_df <- data.frame(
    item = c("Deficit Method", "Confidence Interval Method", "Confidence Intervals", "Hypothesis", "Direction Indicating Impairment"),
    value = c(
      "Bayesian (Crawford & Garthwaite, 2007)",
      "Bayesian",
      paste(conf.level * 100, "%", sep = ""),
      stringr::str_to_title(gsub("\\.", "-", tail)),
      stringr::str_to_title(direction)
    ),
    stringsAsFactors = FALSE
  )

  output_df <- data.frame(
    item = c(
      paste("p-value (", direction, ")", sep = ""),
      "Effect size (z-cc)",
      "Abnormality"
    ),
    value = c(
      format(p, nsmall = dp),
      format(z, nsmall = dp),
      paste(format(abn, nsmall = dp), "%", sep = "")
    ),
    ci = c(
      "",
      paste(format(z.ci.lb, dp), "to", format(z.ci.ub, dp), sep = " "),
      paste(abn.ci.lb, "% to", abn.ci.ub, "%", sep = " ")
    ),
    stringsAsFactors = FALSE
  )

  result <- list(
    score = score,
    ctrl.mean = ctrl.mean,
    ctrl.sd = ctrl.sd,
    ctrl.n = ctrl.n,
    conf.level = conf.level,
    sims = sims,
    treshold = treshold,
    direction = direction,
    tail = tail,
    dp = dp,
    df = df,
    ctrl.var = ctrl.var,
    z = z,
    z.ci.lb = z.ci.lb,
    z.ci.ub = z.ci.ub,
    percentile = percentile,
    p = p,
    abn = abn,
    abn.ci.lb = abn.ci.lb,
    abn.ci.ub = abn.ci.ub,
    input_df = input_df,
    output_df = output_df,
    parameters_df = parameters_df
  )

  class(result) <- 'deficit_bayes'
  return(result)
}

#' @export
print.deficit_bayes <- function(x, ...) {

  input_table <- knitr::kable(x$input_df, format = "simple", col.names = c("Inputs", "Value"))
  parameters_table <- knitr::kable(x$parameters_df, format = "simple", col.names = c("Parameter", "Value"))
  output_table <- knitr::kable(x$output_df, format = "simple", col.names = c("Outputs", "Value", glue::glue("{x$conf.level*100}% Credible Interval")))

  header <- "Assessing For a Bayesian Deficit Between a Test Score and a Control Sample."
  footnote <- "See documentation for further information on how scores are computed."
  key <- paste("- Abnormality = The percentage of controls expected to show a higher deficit.", "\n",
               "- z-cc = Z for the case control.", sep = ""
  )
  result <- paste(header, "\n\n",
                  "INPUTS:", paste(capture.output(input_table), collapse = "\n"), "\n\n",
                  "PARAMETERS:", paste(capture.output(parameters_table), collapse = "\n"), "\n\n",
                  "OUTPUTS:", paste(capture.output(output_table), collapse = "\n"), "\n\n",
                  "Note.", "\n", key, "\n\n",
                  footnote, "\n",
                  sep = "")

  cat(result)
}

# Example usage:
# deficit_bayes(
#   score = 90,
#   ctrl.mean = 100,
#   ctrl.sd = 15,
#   ctrl.n = 30,
#   conf.level = 0.95,
# )
