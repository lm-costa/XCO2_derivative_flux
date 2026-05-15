## function to create a correlation for each pixel
my_correl <- function(df,var, out='cor'){
  x <- df |> dplyr::pull(var)
  y <- df$Our

  correl <- cor.test(x,y)
  correl_est <- as.numeric(correl$estimate)

  if(out=='cor'){
    return(correl_est)
  }

  if(out=='pvalue'){

    if(is.nan(correl_est)){
      correl_est <- 0
      p <- 1

      }else{
        p <- correl$p.value
        if(is.nan(p)) p <- 1
      }

    return(p)

    }else{
      return('erro')
    }
}
