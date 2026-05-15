biomes_vec <- geobr::read_biomes(showProgress = FALSE) #brazilian biomes shp

get_geobr_biomes_pol <- function(i) {
  biomes_vec$geom |> purrr::pluck(i) |> as.matrix()
}

names_biomes<- biomes_vec |>
  dplyr::filter(name_biome!='Sistema Costeiro') |>
  dplyr::pull(name_biome)

list_pol_biomes <- purrr::map(1:6, get_geobr_biomes_pol)
names(list_pol_biomes) <- names_biomes

get_geobr_biomes <- function(x,y){
  x <- as.vector(x[1])
  y <- as.vector(y[1])
  resul <- "Other"
  lgv <- FALSE
  for(i in 1:6){
    lgv <- def_pol(x,y,list_pol_biomes[[i]])
    if(lgv){
      resul <- names(list_pol_biomes[i])
    }else{
      resul <- resul
    }
  }
  return(as.vector(resul))
}
