# Module UI
  
#' @title   mod_trend_ui and mod_trend_server
#' @description  A shiny Module.
#'
#' @param id shiny id
#' @param input internal
#' @param output internal
#' @param session internal
#'
#' @rdname mod_trend
#'
#' @keywords internal
#' @export 
#' @importFrom shiny NS tagList 
mod_trend_ui <- function(id){
  ns <- NS(id)
  tagList(
    f7Card(
      title = "Trend & Prediction",
      f7Toggle(ns("log"), "Logarithmic Scale"),
      echarts4r::echarts4rOutput(ns("trend"))
    )
  )
}

#' @rdname mod_trend
#' @export
#' @keywords internal
    
mod_trend_server <- function(input, output, session, df = df, type_filter = "confirmed"){
  ns <- session$ns

  output$trend <- echarts4r::renderEcharts4r({
    dat <- df %>% 
      dplyr::filter(type == type_filter) %>% 
      dplyr::group_by(date) %>% 
      dplyr::summarise(cases = sum(cases, na.rm = TRUE)) %>% 
      dplyr::mutate(date = as.Date(date)) %>% 
      dplyr::group_by(date) %>% 
      dplyr::filter(date == max(date)) %>% 
      dplyr::filter(cases == max(cases)) %>% 
      dplyr::ungroup() %>% 
      dplyr::arrange(dplyr::desc(date))
    
    x <- rev(1:nrow(dat))
    cases <- dat$cases
    model <- nls(cases ~ (x ^ b), start = c(b = 2), trace = T)

    predict_days <- 5

    x <- rev(1:(nrow(dat) + predict_days))
    pred <- x ^ coef(model)
    dates <- seq.Date(min(dat$date), max(dat$date) + predict_days, by = "days")

    df <- data.frame(
      date = rev(dates),
      cases = c(rep(NA, predict_days), cases),
      model = floor(pred)
    )

    type <- ifelse(input$log, "log", "value")
    ls <- list(
      shadowColor = "rgba(0, 0, 0, 0.8)",
      shadowBlur = 5,
      shadowOffsetY = 3
    )

    df %>% 
      echarts4r::e_charts(date) %>% 
      echarts4r::e_line(cases, name = "Confirmed Cases", lineStyle = ls) %>% 
      echarts4r::e_line(model, name = "Fit", lineStyle = ls) %>% 
      echarts4r::e_tooltip(trigger = "axis") %>% 
      echarts4r::e_theme(theme) %>%
      echarts4r::e_y_axis(type = type)
  })
}
    
## To be copied in the UI
# mod_trend_ui("trend_ui_1")
    
## To be copied in the server
# callModule(mod_trend_server, "trend_ui_1")
 
