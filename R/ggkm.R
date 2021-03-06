#' @title Kaplan-Meier with ggplot2
#' @description Create a Kaplan-Meier plot using ggplot2
#' @param sfit a \code{\link[survival]{survfit}} object
#' @param returns logical: if \code{TRUE}, return an ggplot object
#' @param xlabs x-axis label
#' @param ylabs y-axis label
#' @param ystratalabs The strata labels. \code{Default = levels(summary(sfit)$strata)}
#' @param ystrataname The legend name. Default = "Strata"
#' @param timeby numeric: control the granularity along the time-axis
#' @param main plot title
#' @param pval logical: add the pvalue to the plot?
#' @return ggplot is produced. If returns=TRUE, a ggplot object
#' is returned
#' @author Abhijit Dasgupta with contributions by Gil Tomas
#' \url{http://statbandit.wordpress.com/2011/03/08/an-enhanced-kaplan-meier-plot/}
#' @examples
#' library(survival)
#' data(colon)
#' fit <- survfit(Surv(time,status)~rx, data=colon)
#' ggkm(fit, timeby=500)
#' @import ggplot2 gridExtra
#' @export
ggkm <- function(sfit, returns = FALSE,
                 xlabs = "Time", ylabs = "survival probability",
                 ystratalabs = NULL, ystrataname = NULL,
                 timeby = 100, main = "Kaplan-Meier Plot",
                 pval = TRUE) {
  surv <- NULL # to avoid build notes
  if(is.null(ystratalabs)) {
    ystratalabs <- as.character(levels(summary(sfit)$strata))
  }
  m <- max(nchar(ystratalabs))
  if(is.null(ystrataname)) ystrataname <- "Strata"
  times <- seq(0, max(sfit$time), by = timeby)
  .df <- data.frame(time = sfit$time, n.risk = sfit$n.risk,
                    n.event = sfit$n.event, surv = sfit$surv, 
                    strata = summary(sfit, censored = T)$strata,
                    upper = sfit$upper, lower = sfit$lower)
  levels(.df$strata) <- ystratalabs
  zeros <- data.frame(time = 0, surv = 1, 
                      strata = factor(ystratalabs, levels=levels(.df$strata)),
                      upper = 1, lower = 1)
  .df <- plyr::rbind.fill(zeros, .df)
  d <- length(levels(.df$strata))
  p <- ggplot(.df, aes(time, surv, group = strata)) +
    geom_step(aes(linetype = strata), size = 0.7) +
    theme_bw() +
    theme(axis.title.x = element_text(vjust = 0.5)) +
    scale_x_continuous(xlabs, breaks = times, limits = c(0, max(sfit$time))) +
    scale_y_continuous(ylabs, limits = c(0, 1)) +
    theme(panel.grid.minor = element_blank()) +
    theme(legend.position = c(ifelse(m < 10, .28, .35), ifelse(d < 4, .25, .35))) +
    theme(legend.key = element_rect(colour = NA)) +
    labs(linetype = ystrataname) +
    theme(plot.margin = grid::unit(c(0, 1, .5, ifelse(m < 10, 1.5, 2.5)), "lines")) +
    ggtitle(main)
  
  if(pval) {
    sdiff <- survdiff(eval(sfit$call$formula), data = eval(sfit$call$data))
    pval <- pchisq(sdiff$chisq, length(sdiff$n)-1, lower.tail = FALSE)
    pvaltxt <- ifelse(pval < 0.0001, "p < 0.0001", paste("p =", signif(pval, 3)))
    p <- p + annotate("text", x = 0.6 * max(sfit$time), y = 0.1, label = pvaltxt)
  }
  ## Plotting the graphs
  print(p)
  if(returns) return(p)
  
}
