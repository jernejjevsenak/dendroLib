#' plot_specific
#'
#' Graphs a line plot of a row with a selected window width in a matrix,
#' produced by \code{\link{daily_response}} function.
#'
#' @param result_daily_response a list with three objects as produced by
#' daily_response function
#' @param window_width integer representing window width to be displayed
#' @param title logical, if set to FALSE, no plot title is displayed
#'
#' @return A ggplot2 object containing the plot display
#' @export
#'
#' @examples
#' \dontrun{
#' data(daily_temperatures_example)
#' data(example_proxies_1)
#' Example1 <- daily_response(response = example_proxies_1,
#' env_data = daily_temperatures_example, method = "lm", measure = "r.squared",
#' lower_limit = 90, upper_limit = 150)
#' plot_specific(Example1, window_width = 90)
#'
#' Example2 <- daily_response(response = example_proxies_1,
#' env_data = daily_temperatures_example, method = "brnn",
#' measure = "adj.r.squared", lower_limit = 150, upper_limit = 155,
#' neurons = 1)
#' plot_specific(Example2, window_width = 153, title = TRUE)
#' }

plot_specific <- function(result_daily_response, window_width, title = TRUE) {

  # Short description of the function. It
  # - extracts matrix (the frst object of a list)
  # - verification of whetere we deal with negative correlations. In this case
  # we will expose globail minimum (and not maximum, as in the case of positive
  # correlations, r.squared and adj.r.squared)
  # - subseting extracted matrix to keep only row, as defined by the argument
  # window_width
  # In case of there are more than 366 columns (days), xlabs are properly
  # labeled

  # A) Extracting a matrix from a list and converting it into a data frame
  result_daily_element1 <- data.frame(result_daily_response[[1]])

  # warning msg in case of selected window_width not among row.names.
  # support_string suggests, which window_widths are avaliable.
  support_string <- paste(row.names(result_daily_element1), sep = "",
    collapse = ", ")

  if (as.character(window_width) %in% row.names(result_daily_element1)
    == FALSE) {
    stop(paste("Selected window_width is not avaliable.",
                "Select one among:", support_string, sep = ""))
  }

  # Subseting result_daily_element1 to keep only row with selected window_width.
  # Subset is transposed and converted to a data frame, so data is ready for
  # ggplot2
  temoporal_vector <-
    data.frame(t(result_daily_element1[row.names(result_daily_element1)
    == as.character(window_width), ]))

  # Removing missing values at the end of tempora_vector
  # It is important to remove missing values only at the end of the
  # temporal_vector!
  row_count <- nrow(temoporal_vector)
  delete_rows <- 0
  while (is.na(temoporal_vector[row_count, ] == TRUE)){
    delete_rows <- delete_rows + 1
    row_count <-  row_count - 1
  }
  # To check if the last row is a missing value
  if (is.na(temoporal_vector[nrow(temoporal_vector), ] == TRUE)) {
    temoporal_vector <- temoporal_vector[-c(row_count:(row_count +
                                                         delete_rows)), ]
  }
  temoporal_vector <- data.frame(temoporal_vector)




  # renaming the first column.
  # (I later use this name in the script for plotting)
  names(temoporal_vector) <- c("var1")


  # B) Sometime we have the case of negative correlations, the following code
  # examines minimum and compare it with the maximum, to get the information if
  # we have negative values. In this case, we will not be looking for max, but
  # for min!

  # With the following chunk, overall_maximum and overall_minimum values of
  # subset are calculated and compared.
  overall_max <- max(temoporal_vector$var1, na.rm = TRUE)
  overall_min <- min(temoporal_vector$var1, na.rm = TRUE)

  # absolute vales of overall_maximum and overall_minimum are compared and
  # one of the following two if functions is used
  if ((abs(overall_max) > abs(overall_min)) == TRUE) {

    # maximum value is calculated and index of column is stored as index
    # index represent the starting day (location) in the matrix, which gives
    # the maximum result
    max_result <- max(temoporal_vector, na.rm = TRUE)
    calculated_measure <- round(max_result, 3)
    index <- which(temoporal_vector$var1 == max_result, arr.ind = TRUE)
    plot_column <- index
  }

  if ((abs(overall_max) < abs(overall_min)) == TRUE) {

    # This is in case of negative values
    # minimum value is calculated and index of column is stored as index
    # index represent the starting day (location) in the matrix, which gives
    # the minimum result
    min_result <- min(temoporal_vector, na.rm = TRUE)
    calculated_measure <- round(min_result, 3)
    index <- which(temoporal_vector$var1 == min_result, arr.ind = TRUE)
    plot_column <- index
  }

  # In case of we have more than 366 days, we calculate the day of a year
  # (plot_column), considering 366 days of previous year.
  if (nrow(temoporal_vector) > 366 & plot_column > 366) {
    plot_column_extra <- plot_column %% 366
  } else {
    plot_column_extra <- plot_column
  }



  # C) The final plot is being created. The first part of a plot is universal,
  # the second part defines xlabs, ylabs and ggtitles.

  # The definition of theme
  journal_theme <- theme_bw() +
    theme(axis.text = element_text(size = 12, face = "bold"),
          axis.title = element_text(size = 16), text = element_text(size = 14),
          plot.title = element_text(size = 12,  face = "bold"))

  if (title == FALSE){
    journal_theme <- journal_theme +
      theme(plot.title = element_blank())
  }

  final_plot <- ggplot(temoporal_vector, aes_(y = ~var1,
    x = ~ seq(1, nrow(temoporal_vector)))) + geom_line(lwd = 1.2) +
    geom_vline(xintercept = plot_column, col = "red") +
    scale_x_continuous(breaks = sort(c(seq(0, nrow(temoporal_vector), 50),
      plot_column), decreasing = FALSE),
      labels = sort(c(seq(0, nrow(temoporal_vector), 50), plot_column))) +
    annotate("label", label = as.character(calculated_measure),
      y = calculated_measure, x = plot_column + 15) +
    journal_theme

  if ((nrow(temoporal_vector) > 366) &&  (plot_column > 366) &&
      (result_daily_response [[2]] == "cor")) {
    final_plot <- final_plot +
      ggtitle(paste("Maximal correlation coefficient:", calculated_measure,
                    "\nSelected window width:", window_width, "days",
                    "\nStarting day of selected window width: day",
                    plot_column_extra, "of current year")) +
      xlab("Day of Year  (Including Previous Year)") +
      ylab("Correlation Coefficient")
  }

  if ((nrow(temoporal_vector) > 366) &&  (plot_column < 366) &&
      (result_daily_response [[2]] == "cor")) {
    final_plot <- final_plot +
      ggtitle(paste("Maximal correlation coefficient:", calculated_measure,
                    "\nSelected window width:", window_width, "days",
                    "\nStarting day of selected window width: day",
                    plot_column_extra, "of previous year")) +
      xlab("Day of Year  (Including Previous Year)") +
      ylab("Correlation Coefficient")
  }

  if ((nrow(temoporal_vector) < 366) &&
      (result_daily_response [[2]] == "cor")) {
    final_plot <- final_plot +
      ggtitle(paste("Maximal correlation coefficient:", calculated_measure,
                    "\nSelected window width:", window_width, "days",
                    "\nStarting day of selected window width: day",
                    plot_column_extra)) +
       xlab("Day of Year") +
      ylab("Correlation Coefficient")
  }

  # plot for lm and brnn method; using r.squared
  if ((nrow(temoporal_vector) > 366) &&  (plot_column > 366) &&
      ((result_daily_response [[2]] == "lm") |
          (result_daily_response [[2]] == "brnn")) &&
      (result_daily_response [[3]] == "r.squared")) {
    final_plot <- final_plot +
      ggtitle(paste("Maximal R squared:", calculated_measure,
                    "\nSelected window width:", window_width, "days",
                    "\nStarting day of selected window width: day",
                    plot_column_extra, "of current year")) +
      xlab("Day of Year  (Including Previous Year)") +
      ylab("Explained Variance")
  }

  if ((nrow(temoporal_vector) > 366) && (plot_column < 366) &&
      (result_daily_response[[2]] == "lm" |
          result_daily_response[[2]] == "brnn") &&
      result_daily_response[[3]] == "r.squared") {
    final_plot <- final_plot +
      ggtitle(paste("Maximal R squared:", calculated_measure,
                    "\nSelected window width:", window_width, "days",
                    "\nStarting day of selected window width: day",
                    plot_column_extra, "of previous year")) +
      xlab("Day of Year  (Including Previous Year)") +
      ylab("Explained Variance")
  }

  if (nrow(temoporal_vector) < 366 &&
      (result_daily_response[[2]] == "lm" |
          result_daily_response[[2]] == "brnn") &&
      result_daily_response[[3]] == "r.squared") {
    final_plot <- final_plot +
      ggtitle(paste("Maximal R squared:", calculated_measure,
                    "\nSelected window width:", window_width, "days",
                    "\nStarting day of selected window width: day",
                    plot_column_extra)) +
      xlab("Day of Year") +
      ylab("Explained Variance")
  }

  # plot for lm and brnn method; using adj.r.squared
  if ((nrow(temoporal_vector) > 366) && (plot_column > 366) &&
      (result_daily_response[[2]] == "lm" |
          result_daily_response[[2]] == "brnn") &&
      (result_daily_response[[3]] == "adj.r.squared")) {
    final_plot <- final_plot +
      ggtitle(paste("Maximal Adjusted R squared:", calculated_measure,
                    "\nSelected window width:", window_width, "days",
                    "\nStarting day of selected window width: day",
                    plot_column_extra, "of current year")) +
      xlab("Day of Year  (Including Previous Year)") +
      ylab("Adjusted Explained Variance")
  }

  if ((nrow(temoporal_vector) > 366) &&  (plot_column < 366) &&
      ((result_daily_response [[2]] == "lm" |
          result_daily_response [[2]] == "brnn")) &&
      (result_daily_response [[3]] == "adj.r.squared")) {
    final_plot <- final_plot +
      ggtitle(paste("Maximal Adjusted R squared:", calculated_measure,
                    "\nSelected window width:", window_width, "days",
                    "\nStarting day of selected window width: day",
                    plot_column_extra,
                    "of previous year")) +
      xlab("Day of Year  (Including Previous Year)") +
      ylab("Adjusted Explained Variance")
  }

  if ((nrow(temoporal_vector) < 366) &&
      (result_daily_response [[2]] == "lm" |
          result_daily_response [[2]] == "brnn") &&
      (result_daily_response [[3]] == "adj.r.squared")) {
    final_plot <- final_plot +
      ggtitle(paste("Maximal Adjusted R squared:", calculated_measure,
                    "\nSelected window width:", window_width, "days",
                    "\nStarting day of selected window width: day",
                    plot_column_extra)) +
      xlab("Day of Year") +
      ylab("Adjusted Explained Variance")
  }

  print(final_plot)
}
