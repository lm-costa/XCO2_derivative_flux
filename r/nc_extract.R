my_ncdf4_extractor <- function(ncdf4_file){
  df <- ncdf4::nc_open(ncdf4_file)
  if(df$ndims!=0){
    dft <- data.frame(
      'lon' = ncdf4::ncvar_get(df,varid='longitude'),
      'lat' = ncdf4::ncvar_get(df,varid='latitude'),
      'time' = ncdf4::ncvar_get(df,varid='time'),
      'xco2' = ncdf4::ncvar_get(df,varid='xco2'),
      'uncertanty' = ncdf4::ncvar_get(df,varid='xco2_uncertainty'),
      'quality_flag' = ncdf4::ncvar_get(df,varid='xco2_quality_flag')
    ) |>
      dplyr::filter(lon < -35 & lon >-75 & lat < 5 & lat >-35)|>
      dplyr::filter(quality_flag==0) |>
      tibble::as_tibble()
  }
  ncdf4::nc_close(df)
  return(dft)
}
