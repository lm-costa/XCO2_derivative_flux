path_carbon_tracker <- 'https://gml.noaa.gov/aftp//products/carbontracker/co2/CT2022/fluxes/monthly/CT2022.flux1x1.'
functions_files <- list.files('fun/',full.names = T)
purrr::map(functions_files,source)


br_biome <- geobr::read_biomes()
br_biome <- br_biome |>
  dplyr::filter(name_biome!='Sistema Costeiro') |>
  dplyr::mutate(
    name_biome = c("Amazon","Caatinga","Cerrado",
                   "Atlantic Forest","Pampa","Pantanal")
  )

br_biome <- br_biome |>terra::vect() |> terra::project('EPSG:4326')

terra::plot(br_biome)

dates_ <- expand.grid(year=c(2015:2020),
                      month = c(01:12),
                      day = c(01:31)) |>
  tibble::as_tibble() |>
  dplyr::mutate(
    data = lubridate::make_date(year,month,day) |> as.character()
  ) |>
  na.omit() |>
  dplyr::mutate(
    my_url_date = dplyr::case_when(
      month<10 ~ paste0(year,'0',month),
      .default = paste0(year,month)
    )
  ) |>
  dplyr::pull(my_url_date) |> unique()

dates_
my_url <- paste0(path_carbon_tracker,dates_,'.nc')
my_url[1:3]

furrr::future_map(my_url,my_download)



flux_files <- list.files('data-raw/',pattern = 'flux',full.names = T)

# teste <- ncdf4::nc_open(flux_files[1])

#unit mol m-2 s-1

terra::rast(flux_files[1]) |>
  #sum() |>
  terra::crop(br_biome) |>
  sum() |>
  terra::plot()



for (i in 1:length(flux_files)){
  if(i == 1){
    df <- df.flux.creat(flux_files[i],br_biome)
  }else{
    dfa <- df.flux.creat(flux_files[i],br_biome)
    df <- rbind(df,dfa)
  }
}


df_summary <- df |>
  dplyr::rename('flux'='sum') |>
  dplyr::mutate(
    flux = flux*44.01*2592000
  ) |>
  dplyr::mutate(
    year=lubridate::year(date),
    month=lubridate::month(date)
  ) |>
  dplyr::rename(lon=x,
                lat=y) |>
  dplyr::group_by(lon,lat,year,month) |>
  dplyr::summarise(flux=mean(flux)) |>
  dplyr::mutate(
    date=lubridate::make_date(year,month,'15')
  )


writexl::write_xlsx(df_summary,'data/df_flux_summary.xlsx')
writexl::write_xlsx(df,'data/df__flux_full.xlsx')


###

df <- readxl::read_excel('data/df_flux_summary.xlsx')

df |>
  dplyr::select(-c(year,month)) |>
  tidyr::pivot_wider(
    names_from = date,
    values_from = flux
  )


df_oco2 <- readr::read_rds('data/xco2_1deg_full_trend.rds')


df_oco2_agg <- df_oco2 |>
  dplyr::filter(dist_xco2<0.5) |>
  dplyr::mutate(
    lon = lon_grid,
    lat = lat_grid,
  ) |>
  dplyr::select(-c(lon_grid,lat_grid)) |>
  dplyr::group_by(lon,lat,year,month) |>
  dplyr::summarise(xco2=mean(xco2)) |>
  dplyr::mutate(date=lubridate::make_date(year,month,'15')) |>
  dplyr::ungroup()


ext_carbon_Tra <- raster::rasterFromXYZ(
  df |>
    dplyr::select(-c(year,month)) |>
    tidyr::pivot_wider(
      names_from = date,
      values_from = flux
    )
) |>
  terra::rast() |>
  terra::extract(df_oco2_agg |>
                   dplyr::select(lon,lat) |>
                   terra::vect() ,
                 xy=T

  )

df_all <- cbind(df_oco2_agg,ext_carbon_Tra)

df_all <- df_all |>
  tidyr::pivot_longer(cols = 'X2015.01.15':'X2020.12.15',
                      names_to = 'date_new',
                      values_to = 'flux_CT') |>
  dplyr::mutate(
    year=substr(date_new,2,5),
    month=substr(date_new,7,8),
    day=substr(date_new,10,11),
    date_new=lubridate::make_date(year,month,day)
  ) |>
  dplyr::select(lon,lat,date,date_new,xco2,x,y,flux_CT) |>
  dplyr::group_by(lon,lat,date) |>
  dplyr::mutate(
    flux_CT=dplyr::case_when(
      lubridate::date(date) == lubridate::date(date_new)~flux_CT,
      .default = NA
    )
  ) |>
  #dplyr::select(date,date_new,xco2,xco2_ctrac,xco2_ctrac_new) |>
  na.omit()

df_all

write.csv(df_all,'data/ctrac_oco2_flux_1dg.csv')
