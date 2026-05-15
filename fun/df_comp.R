df.creat <- function(raster_file, my_mask){

  if(missing(my_mask)){
    r <- terra::rast(raster_file,'xco2')
    mytime <- terra::time(r)

    r2df <- terra::as.data.frame(r,xy=T)
    r2df <- r2df |> dplyr::mutate(date = lubridate::as_date(mytime))

    return(r2df)
  }else{
    r <- terra::rast(raster_file,'xco2') |>
      terra::crop(my_mask,mask=T)
    mytime <- terra::time(r)

    r2df <- terra::as.data.frame(r,xy=T)
    r2df <- r2df |> dplyr::mutate(date = lubridate::as_date(mytime))

    return(r2df)
  }
}

df.flux.creat <- function(raster_file, my_mask){

  if(missing(my_mask)){
    r <- terra::rast(raster_file)
    mytime <- terra::time(r) |> unique()

    r <- r |> sum()

    r2df <- terra::as.data.frame(r,xy=T)
    r2df <- r2df |> dplyr::mutate(date = lubridate::as_date(mytime))

    return(r2df)
  }else{
    r <- terra::rast(raster_file) |>
      terra::crop(my_mask,mask=T)
    mytime <- terra::time(r) |> unique()

    r <- r |> sum()

    r2df <- terra::as.data.frame(r,xy=T)
    r2df <- r2df |> dplyr::mutate(date = lubridate::as_date(mytime))

    return(r2df)
  }
}

