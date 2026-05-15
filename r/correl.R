my_cor <- function(df,out='cor'){

  sif <- df$sif
  xco2 <- df$xco2

  corre <- cor.test(sif,xco2)
  correl_est <- as.numeric(corre$estimate)

  if(out=='cor'){
    return(correl_est)
  }
  if(out=='pvalue'){
    if(is.nan(correl_est)){
      correl_est <- 0
      p <- 1
    }else{
      p <- corre$p.value
      if(is.nan(p)) p <- 1
    }
    return(p)
  }else{
    return('erro')
  }
}
