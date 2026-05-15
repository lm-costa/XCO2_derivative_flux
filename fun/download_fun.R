my_download <- function(url_unique){
  n_split <- length(stringr::str_split(url_unique,"/",simplify=TRUE))
  filenames_nc <- stringr::str_split(url_unique,"/",simplify = TRUE)[,n_split]

  repeat{
    dw <- try(
      download.file(
        url_unique,
        paste0("data-raw/",filenames_nc),
        method="wget",
        quiet = T
      )
    )

    if(!(inherits(dw,"try-error")))
      break
  }
}
