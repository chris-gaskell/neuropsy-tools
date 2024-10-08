utils::globalVariables(c("x", "z", "label"))

#' Plot Bell Curve
#'
#' @param input A numeric value (or vector of numbers) representing the score of interest.
#' @param metric A character string specifying the metric of the input score: "percentile", "t", "index", "scaled", or "z" (default).
#' @param score.label.text A character string (or vector of character strings) for the label text of the input score(s).
#' @param axis.label.metric A character string specifying the preferred metric label for x-axis labels: "percentile", "t", "index", "scaled", or "z" (default).
#' @param descriptors A logical indicating whether to include AAN descriptor labels (default is TRUE).
#'
#' @return A ggplot2 object.
#' @export
#'
#' @examples
#' plot_bell(input = 2, score.label.text = "Test Score", axis.label.metric = "z")
plot_bell <- function(input, metric = "z", score.label.text = "test", axis.label.metric = metric, descriptors = TRUE) {
  if (!is.numeric(input)) stop("Input must be numeric.")
  valid.labels <- c("percentile", "t", "index", "scaled", "z")
  if (!axis.label.metric %in% valid.labels) stop(glue::glue("{axis.label.metric} is invalid. Choose from: {paste(valid.labels, collapse = ', ')}"))
  if (metric != "z") input <- neuropsytools::convert_standard(input, metric = metric, metric.new = "z")
  input[input >= 3.5] <- 3.49
  input[input < -3.5] <- -3.49

  curve.area <- function(x, above = TRUE, input) {
    y <- stats::dnorm(x)
    if (above) y[!(x >= min(input)-0.03 & x <= 3.5)] <- NA
    else y[!(x <= max(input)+0.03 & x >= -3.5)] <- NA
    y
  }

  label.types <- c("percentile", "t", "index", "scaled", "z")
  label.names <- c("Percentile", "T Score", "Index Score", "Scaled Score", "Z Score")
  labeling.functions <- list(
    percentile = function(x) paste0(neuropsytools::convert_standard(x, metric = "z", metric.new = "percentile"), "%"),
    t = function(x) format(neuropsytools::convert_standard(x, metric = "z",  metric.new = "t")),
    index = function(x) format(neuropsytools::convert_standard(x, metric = "z", metric.new = "index")),
    scaled = function(x) format(neuropsytools::convert_standard(x, metric = "z", metric.new = "scaled")),
    z = function(x) as.character(x)
  )

  labeling.function <- labeling.functions[[match(axis.label.metric, label.types)]]
  x.label.text <- label.names[match(axis.label.metric, label.types)]

  segment.data <- data.frame(input = input, y = stats::dnorm(input))

  p <- ggplot2::ggplot(data.frame(x = c(-3.5, 3.5)), ggplot2::aes(x = x)) +
    ggplot2::stat_function(fun = stats::dnorm) +
    ggplot2::labs(x = x.label.text, y = NULL) +
    plot_theme() +
    ggplot2::theme(panel.grid.major.y = ggplot2::element_blank(),
                   panel.grid.minor = ggplot2::element_blank(),
                   axis.text.y = ggplot2::element_blank()
                   ) +
    ggplot2::scale_x_continuous(n.breaks = 10, expand = c(0, 0), labels = labeling.function) +
    ggplot2::scale_y_continuous(expand = c(0, 0.01))

  if (length(input) == 1) {
    p <- p +
      ggplot2::stat_function(fun = curve.area, args = list(above = TRUE, input = input), geom = "area", fill = "#ced4da", alpha = 0.3) +
      ggplot2::stat_function(fun = curve.area, args = list(above = FALSE, input = input), geom = "area", fill = "#2fa4e7", alpha = 0.3)
  } else {
    p <- p +
      ggplot2::stat_function(fun = curve.area, args = list(above = TRUE, input = input[1]), geom = "area", fill = "#2fa4e7", alpha = 0.3) +
      ggplot2::stat_function(fun = curve.area, args = list(above = FALSE, input = input[1]), geom = "area", fill = "#2fa4e7", alpha = 0.3)
  }

  p <- p +
    ggplot2::geom_segment(data = segment.data, ggplot2::aes(x = input, y = 0, xend = input, yend = 0.4), color = "black", linewidth = 0.8) +
    ggplot2::geom_label(data = segment.data, ggplot2::aes(x = input, y = 0.2, label = score.label.text), label.padding = grid::unit(0.45, "lines"), label.size = 0.45, color = "#00688b", size = 4.5, alpha = 1, angle = 90)

  if (descriptors) {
    descriptor.labels <- data.frame(z = c(-2.5, -1.5, -0.5, 0.5, 1.5, 2.5), label = c("Below", "Low", "Average", "Average", "High", "Above"))
    p <- p +
      ggplot2::geom_text(data = descriptor.labels, ggplot2::aes(x = z, y = 0.4, label = label), size = 4, color = "black", angle = 0, hjust = 0.5)
  }

  return(p)
}

# plot_bell(input = 100, metric = "index",
#                 score.label.text = "Test Score",
#                 axis.label.metric = "percentile"
#                 )
