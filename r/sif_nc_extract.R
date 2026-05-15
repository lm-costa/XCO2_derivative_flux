my_sif_extractor <- function(ncdf4_file){
  df <- ncdf4::nc_open(ncdf4_file)
  if(df$ndims!=0){
    dft <- data.frame(
      'lon' = ncdf4::ncvar_get(df,varid='Longitude'),
      'lat' = ncdf4::ncvar_get(df,varid='Latitude'),
      'time' = ncdf4::ncvar_get(df,varid='Delta_Time'),
      'sza'= ncdf4::ncvar_get(df, varid = 'SZA'),
      'sif_740' = ncdf4::ncvar_get(df,varid='Daily_SIF_740nm'),
      'sif_757' = ncdf4::ncvar_get(df,varid='Daily_SIF_757nm'),
      'sif_771' = ncdf4::ncvar_get(df,varid='Daily_SIF_771nm'),
      'quality_flag' = ncdf4::ncvar_get(df,varid='Quality_Flag')
    ) |>
      dplyr::filter(lon < -35 & lon >-75 & lat < 5 & lat >-35)|>
      dplyr::filter(quality_flag==0) |>
      tibble::as_tibble()
  }
  ncdf4::nc_close(df)
  return(dft)
}
