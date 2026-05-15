my_ncdf4_download <- function(url_unique,
                              user="input your user",
                              password="input your password"){
  if(is.character(user)==TRUE & is.character(password)==TRUE){
    n_split <- length(
      stringr::str_split(url_unique,
                         "/",
                         simplify=TRUE))
    filenames_nc <- stringr::str_split(url_unique,
                                       "/",
                                       simplify = TRUE)[,n_split]
    repeat{
      dw <- try(download.file(url_unique,
                              paste0("data-raw/",filenames_nc),
                              method="wget",
                              extra= c(paste0("--user=", user,
                                              " --password ",
                                              password))
      ))
      if(!(inherits(dw,"try-error")))
        break
    }
  }else{
    print("input a string")
  }
}
