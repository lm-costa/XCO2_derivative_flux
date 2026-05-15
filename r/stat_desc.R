
meu_cv <- function(x){
  100*sd(x)/mean(x)
}

meu_erro_padrao <- function(x){
  sd(x)/sqrt(length(x))
}


est_desc <- function(x){
  n <- length(x)
  n_na <- sum(is.na(x)) # <<<<<<<------------
  x<- na.omit(x)
  m <- mean(x)
  dp <- sd(x)
  md <- median(x) # quantile(x, 0.50)
  cv <- meu_cv(x)
  mini <- min(x)
  maxi <- max(x)
  q1 <- quantile(x, 0.25)
  q3 <- quantile(x, 0.75)
  s2 <- var(x)
  g1 <- agricolae::skewness(x)
  g2 <- agricolae::kurtosis(x)
  epm <- meu_erro_padrao(x)
  normtest <- shapiro.test(x)


  return(c(N = n,
           N_perdidos = n_na, # <<<<<<<<<--------
           Mean = m,Median = md,
           Min = mini,Max = maxi,
           Var = s2,DP = dp,
           Q1 = q1,Q3 = q3,
           CV = cv,EPM = epm,
           Skewness = g1,Kurtosis = g2,
           Shapiro=normtest$p.value))
}
