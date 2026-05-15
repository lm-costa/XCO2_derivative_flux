## function to create a linear model for each pixel
linear_reg_fluxes <- function(df,output="beta1"){
  # model for each grid cell
  modelo <- lm(xco2_flux ~ flux_ct, data=df)
  beta_1 <- c(summary(modelo)$coefficients[2])

  if(output=="beta1"){
    return(beta_1)
  }
  if(output=="p_value"){
    if(is.nan(beta_1)){
      beta_1 <- 0
      p <- 1
    }else{
      p <- summary(modelo)$coefficients[2,4]
      if(is.nan(p)) p <- 1
    }
    return(p)
  }
  #
  if(output == "r2"){
    my_r2 <- summary(modelo)$adj.r.squared
    return(my_r2)
  }
  if(output == "bias"){
    my_bias <- mean((df$xco2_flux - df$flux_ct),na.rm = T)
    return(my_bias)
  }

  if(output == "rmse"){
    valid_idx <- !is.na(df$flux_ct) & !is.na(df$xco2_flux)

    my_rmse <- Metrics::rmse(df$flux_ct[valid_idx],df$xco2_flux[valid_idx])
    return(my_rmse)
  }
  if(output == "n"){
    return(nrow(df))
  }

}


