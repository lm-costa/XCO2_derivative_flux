functions_files <- list.files('fun/',full.names = T)
purrr::map(functions_files,source)

br <- geobr::read_country(showProgress = FALSE)
south_file <- list.files('South_America/',pattern = 'shp',full.names = T)
south_america <- sf::read_sf(south_file[1])

biomes <- geobr::read_biomes(showProgress = FALSE)


biomes2015 <- biomes |> dplyr::mutate(year=2015)
biomes2016 <- biomes |> dplyr::mutate(year=2016)
biomes2017 <- biomes |> dplyr::mutate(year=2017)
biomes2018 <- biomes |> dplyr::mutate(year=2018)
biomes2020 <- biomes |> dplyr::mutate(year=2020)
biomes2021 <- biomes |> dplyr::mutate(year=2021)
biomes2022 <- biomes |> dplyr::mutate(year=2022)

biomes <- rbind(biomes,biomes2015,biomes2016,
                biomes2017,biomes2018,biomes2020,
                biomes2021,biomes2022)

biomes

df <- read.csv('data/ctrac_oco2_flux.csv')

skimr::skim(df)


### Histograms

# OCO-2 Concentration
df |>
  dplyr::mutate(
    year=lubridate::year(date)
  ) |>
  dplyr::select(lon,lat,date,year,xco2,flux_CT) |>
  ggplot2::ggplot(ggplot2::aes(x=xco2)) +
  ggplot2::geom_histogram(color="black",fill="gray",
                          bins = 30) +
  ggplot2::facet_wrap(~year, scales = "free") +
  ggplot2::theme_bw()

# CarbonTracker fluxes
df |>
  dplyr::mutate(
    year=lubridate::year(date)
  ) |>
  dplyr::select(lon,lat,date,year,xco2,flux_CT) |>
  ggplot2::ggplot(ggplot2::aes(x=flux_CT)) +
  ggplot2::geom_histogram(color="black",fill="gray",
                          bins = 30) +
  ggplot2::facet_wrap(~year, scales = "free") +
  ggplot2::theme_bw()


#### regressão

# concentração
df |>
  tibble::as_tibble() |>
  dplyr::mutate(
    year=lubridate::year(date),
    date=lubridate::as_date(date)
  ) |>
  dplyr::select(lon,lat,date,year,xco2,flux_CT) |>
  dplyr::filter(year %in% 2015:2022) |>
  dplyr::group_by(year,date) |>
  dplyr::summarise(xco2_mean=mean(xco2)) |>
  ggplot2::ggplot(ggplot2::aes(x=date,y=xco2_mean))+
  ggplot2::geom_point(shape=21,color="black",fill="gray") +
  ggplot2::geom_line(color="red")+
  ggplot2::geom_smooth(method = "lm") +
  ggplot2::ylim(390,420)+
  ggpubr::stat_regline_equation(ggplot2::aes(
    label =  paste(..eq.label.., ..rr.label..,
                   sep = "*plain(\",\")~~")),
    label.y = 420) +
  ggplot2::facet_wrap(~year,scales ='free')+
  ggplot2::theme_bw()+
  ggplot2::labs(x='',y=expression('Xco'[2]~' (ppm)'),fill='' )

#fluxo
df |>
  tibble::as_tibble() |>
  dplyr::mutate(
    year=lubridate::year(date),
    date=lubridate::as_date(date)
  ) |>
  dplyr::select(lon,lat,date,year,xco2,flux_CT) |>
  dplyr::filter(year %in% 2015:2022) |>
  dplyr::group_by(year,date) |>
  dplyr::summarise(xco2_mean=mean(flux_CT)) |>
  ggplot2::ggplot(ggplot2::aes(x=date,y=xco2_mean))+
  ggplot2::geom_point(shape=21,color="black",fill="gray") +
  ggplot2::geom_line(color="red")+
  ggplot2::geom_smooth(method = "lm") +
  # ggplot2::ylim(390,420)+
  # ggpubr::stat_regline_equation(ggplot2::aes(
  #   label =  paste(..eq.label.., ..rr.label..,
  #                  sep = "*plain(\",\")~~")),
  #   label.y = 420) +
  ggplot2::facet_wrap(~year,scales ='free')+
  ggplot2::theme_bw()+
  ggplot2::labs(x='',y=expression('Xco'[2]~' (ppm)'),fill='' )





#####

xco2df_rationality <- df |>
  dplyr::filter(lon == -50, lat ==-19) |>
  dplyr::mutate(
    date=lubridate::as_date(date),
    year=lubridate::year(date),
    month=lubridate::month(date)
  ) |>
  #dplyr::select(-c(lon_grid,lat_grid)) |>
  dplyr::group_by(lon,lat,year,month) |>
  dplyr::summarise(
    xco2_mean= mean(xco2,na.rm=TRUE)
  ) |>
  dplyr::mutate(
    date = lubridate::make_date(year,month,'15')
  )

mod <- lm(xco2_mean~x,data =xco2df_rationality |>
            dplyr::mutate(
              x = 1:dplyr::n()
            ))
xco2df_rationality |>
  dplyr::filter(lubridate::year(date)<2023) |>
  dplyr::mutate(
    x=1:dplyr::n(),
    xco2_est = mod$coefficients[1] + mod$coefficients[2]*x,
    delta=xco2_est - xco2_mean,
    xco2r = (mod$coefficients[1]-delta)-(mean(xco2_mean)-mod$coefficients[1])
  ) |>
  dplyr::group_by(date) |>
  dplyr::summarise(xco2_mean=mean(xco2r)) |>
  ggplot2::ggplot(ggplot2::aes(x=date,y=xco2_mean )) +
  ggplot2::geom_point(shape=21,color="black",fill="gray") +
  ggplot2::geom_line(color="red") +
  ggplot2::geom_smooth(method = "lm") +
  ggpubr::stat_regline_equation(ggplot2::aes(
    label =  paste(..eq.label.., ..rr.label.., sep = "*plain(\",\")~~"))) +
  ggplot2::facet_wrap(~lubridate::year(date),scales = 'free_x')+
  ggplot2::theme_bw()+
  ggplot2::xlab('Month')+
  ggplot2::ylab(expression(
    'Xco'[2][R]~' (ppm)'
  ))


xco2df_rationality <- df |>
  dplyr::filter(lon == -50, lat ==-19) |>
  dplyr::mutate(
    date=lubridate::as_date(date),
    year=lubridate::year(date),
    month=lubridate::month(date)
  ) |>
  #dplyr::select(-c(lon_grid,lat_grid)) |>
  dplyr::group_by(lon,lat,year,month) |>
  dplyr::summarise(
    xco2_mean= mean(flux_CT,na.rm=TRUE),
  ) |>
  dplyr::mutate(
    date = lubridate::make_date(year,month,'15')
  )


mod <- lm(xco2_mean~x,data =xco2df_rationality |>
            dplyr::mutate(
              x = 1:dplyr::n()
            ))
xco2df_rationality |>
  dplyr::filter(lubridate::year(date)<2023) |>
  dplyr::mutate(
    x=1:dplyr::n(),
    xco2_est = mod$coefficients[1] + mod$coefficients[2]*x,
    delta=xco2_est - xco2_mean,
    xco2r = (mod$coefficients[1]-delta)-(mean(xco2_mean)-mod$coefficients[1])
  ) |>
  dplyr::group_by(date) |>
  dplyr::summarise(xco2_mean=mean(xco2_mean)) |>
  ggplot2::ggplot(ggplot2::aes(x=lubridate::month(date),y=xco2_mean )) +
  ggplot2::geom_point(shape=21,color="black",fill="gray") +
  ggplot2::geom_line(color="red") +
  ggplot2::geom_smooth(method = "lm") +
  ggpubr::stat_regline_equation(ggplot2::aes(
    label =  paste(..eq.label.., ..rr.label.., sep = "*plain(\",\")~~"))) +
  ggplot2::facet_wrap(~lubridate::year(date),scales = 'free_x')+
  ggplot2::theme_bw()+
  ggplot2::xlab('Month')+
  ggplot2::ylab(expression(
    'Xco'[2][R]~' (ppm)'
  ))



### main LOOP

for(i in 2015:2020){
  if(i == 2015){

    xco2df_filter <- df |>
      dplyr::mutate(
        date=lubridate::as_date(date),
        year=lubridate::year(date),
        month=lubridate::month(date)
      ) |>
      dplyr::filter(year == i) |> ## filter by year
      dplyr::group_by(lon,lat,year,month) |> ## data month and grid cell aggregation
      dplyr::summarise(
        xco2_mean= mean(xco2,na.rm=TRUE),
      ) |>
      dplyr::mutate(
        date = lubridate::make_date(year,month,'15')
      )

    ### general model for the year

    mod <- lm(xco2_mean~x,data =xco2df_filter |>
                dplyr::mutate(
                  x = 1:dplyr::n()
                ))


    #### regionalization of XCO2
    xco2detrend <- xco2df_filter |>
      dplyr::mutate(
        x=1:dplyr::n(),
        xco2_est = mod$coefficients[1] + mod$coefficients[2]*x,
        delta=xco2_est - xco2_mean,
        xco2r = (mod$coefficients[1]-delta)-(mean(xco2_mean)-mod$coefficients[1])
      )
    xco2_aux_detrend <- xco2detrend |>
      dplyr::ungroup() |>
      dplyr::group_by(date) |>
      dplyr::summarise(
        xco2 = mean(xco2r)
      )

    ## general linear model
    mod_detrend <- lm(xco2 ~date,
                      data = xco2_aux_detrend )
    beta_r <-mod_detrend$coefficients[2] # regional beta
    ep <- summary(mod_detrend)$coefficients[2,2] # regional standard error

    ilbr <- beta_r-ep
    slbr <- beta_r+ep


    ### creating a nest object by grid cell
    xco2_nest <- xco2detrend |>
      tibble::as_tibble() |>
      dplyr::mutate(year =lubridate::year(date),
                    quarter = lubridate::quarter(date),
                    quarter_year = lubridate::make_date(year, quarter, 1)) |>
      dplyr::group_by(lon, lat,date) |>
      dplyr::summarise(xco2 = mean(xco2r, na.rm=TRUE)) |>
      dplyr::mutate(
        id_time = date
      ) |>
      dplyr::group_by(lon,lat) |>
      tidyr::nest()

    ### linear regression for each grid cell

    xco2_nest_detrend <- xco2_nest|>
      dplyr::mutate(
        beta_line = purrr::map(data,linear_reg, output="beta1"),
        p_value = purrr::map(data,linear_reg, output="p_value"),
        n_obs = purrr::map(data,linear_reg, output="n"),
        beta_error=purrr::map(data,linear_reg,output='betaerror'),
        model_error=purrr::map(data,linear_reg,output='modelerror')
      )

    ### creating a table

    xco2_aux_detrend_new <- xco2_nest_detrend |>
      dplyr::filter(n_obs > 4) |> ## criteria of minimum observation month for grid cell
      tidyr::unnest(cols = c(beta_line,beta_error,model_error)) |>
      dplyr::ungroup() |>
      dplyr::select(lon, lat, beta_line,beta_error,model_error) |>
      dplyr::mutate(year=i)

    q3_xco2 <- xco2_aux_detrend_new |> dplyr::pull(beta_line) |> quantile(.75)
    q1_xco2 <- xco2_aux_detrend_new |> dplyr::pull(beta_line) |> quantile(.25)

    dfall <- xco2_aux_detrend_new |> dplyr::mutate(
      xco2 = dplyr::case_when(
        beta_line > q3_xco2 ~ 'Source',
        beta_line < q1_xco2 ~'Sink',
        .default = 'Non Significant'
      )
    )
  }else{
    xco2df_filter <- df |>
      dplyr::mutate(
        date=lubridate::as_date(date),
        year=lubridate::year(date),
        month=lubridate::month(date)
      ) |>
      dplyr::filter(year == i) |> ## filter by year
      dplyr::group_by(lon,lat,year,month) |> ## data month and grid cell aggregation
      dplyr::summarise(
        xco2_mean= mean(xco2,na.rm=TRUE),
      ) |>
      dplyr::mutate(
        date = lubridate::make_date(year,month,'15')
      )

    ### general model for the year

    mod <- lm(xco2_mean~x,data =xco2df_filter |>
                dplyr::mutate(
                  x = 1:dplyr::n()
                ))


    #### regionalization of XCO2
    xco2detrend <- xco2df_filter |>
      dplyr::mutate(
        x=1:dplyr::n(),
        xco2_est = mod$coefficients[1] + mod$coefficients[2]*x,
        delta=xco2_est - xco2_mean,
        xco2r = (mod$coefficients[1]-delta)-(mean(xco2_mean)-mod$coefficients[1])
      )
    xco2_aux_detrend <- xco2detrend |>
      dplyr::ungroup() |>
      dplyr::group_by(date) |>
      dplyr::summarise(
        xco2 = mean(xco2r)
      )

    ## general linear model
    mod_detrend <- lm(xco2 ~date,
                      data = xco2_aux_detrend )
    beta_r <-mod_detrend$coefficients[2] # regional beta
    ep <- summary(mod_detrend)$coefficients[2,2] # regional standard error

    ilbr <- beta_r-ep
    slbr <- beta_r+ep


    ### creating a nest object by grid cell
    xco2_nest <- xco2detrend |>
      tibble::as_tibble() |>
      dplyr::mutate(year =lubridate::year(date),
                    quarter = lubridate::quarter(date),
                    quarter_year = lubridate::make_date(year, quarter, 1)) |>
      dplyr::group_by(lon, lat,date) |>
      dplyr::summarise(xco2 = mean(xco2r, na.rm=TRUE)) |>
      dplyr::mutate(
        id_time = date
      ) |>
      dplyr::group_by(lon,lat) |>
      tidyr::nest()

    ### linear regression for each grid cell

    xco2_nest_detrend <- xco2_nest|>
      dplyr::mutate(
        beta_line = purrr::map(data,linear_reg, output="beta1"),
        p_value = purrr::map(data,linear_reg, output="p_value"),
        n_obs = purrr::map(data,linear_reg, output="n"),
        beta_error=purrr::map(data,linear_reg,output='betaerror'),
        model_error=purrr::map(data,linear_reg,output='modelerror')
      )

    ### creating a table

    xco2_aux_detrend_new <- xco2_nest_detrend |>
      dplyr::filter(n_obs > 4) |> ## criteria of minimum observation month for grid cell
      tidyr::unnest(cols = c(beta_line,beta_error,model_error)) |>
      dplyr::ungroup() |>
      dplyr::select(lon, lat, beta_line,beta_error,model_error) |>
      dplyr::mutate(year=i)

    q3_xco2 <- xco2_aux_detrend_new |> dplyr::pull(beta_line) |> quantile(.75)
    q1_xco2 <- xco2_aux_detrend_new |> dplyr::pull(beta_line) |> quantile(.25)

    dfall_aux <- xco2_aux_detrend_new |> dplyr::mutate(
      xco2 = dplyr::case_when(
        beta_line > q3_xco2 ~ 'Source',
        beta_line < q1_xco2 ~'Sink',
        .default = 'Non Significant'
      )
    )

    dfall <- rbind(dfall,dfall_aux)
  }
}

df_oco2 <- dfall

for(i in 2015:2020){
  if(i == 2015){

    flux_df_filter <- df |>
      dplyr::mutate(
        date=lubridate::as_date(date),
        year=lubridate::year(date),
        month=lubridate::month(date)
      ) |>
      dplyr::filter(year == i) |> ## filter by year
      dplyr::group_by(lon,lat,year) |> ## data and grid cell aggregation
      dplyr::summarise(
        fco2= mean(flux_CT,na.rm=TRUE),
        nobs = dplyr::n(),
        fco2_erro=sd(flux_CT,na.rm=T)/sqrt(nobs)

      )

    ### creating a table

    flux_df_filter_aux<- flux_df_filter |>
      dplyr::filter(nobs > 4) |> ## criteria of minimum observation month for grid cell
      dplyr::ungroup() |>
      dplyr::select(lon, lat, fco2,fco2_erro,nobs) |>
      dplyr::mutate(year=i)

    q3_fco2 <- flux_df_filter_aux |> dplyr::pull(fco2) |> quantile(.75)
    q1_fco2 <- flux_df_filter_aux |> dplyr::pull(fco2) |> quantile(.25)

    dfall <- flux_df_filter_aux |> dplyr::mutate(
      xco2 = dplyr::case_when(
        fco2 > q3_fco2 ~ 'Source',
        fco2 < q1_fco2 ~'Sink',
        .default = 'Non Significant'
      )
    )
  }else{

    flux_df_filter <- df |>
      dplyr::mutate(
        date=lubridate::as_date(date),
        year=lubridate::year(date),
        month=lubridate::month(date)
      ) |>
      dplyr::filter(year == i) |> ## filter by year
      dplyr::group_by(lon,lat,year) |> ## data and grid cell aggregation
      dplyr::summarise(
        fco2= mean(flux_CT,na.rm=TRUE),
        nobs = dplyr::n(),
        fco2_erro=sd(flux_CT,na.rm=T)/sqrt(nobs)

      )

    ### creating a table

    flux_df_filter_aux<- flux_df_filter |>
      dplyr::filter(nobs > 4) |> ## criteria of minimum observation month for grid cell
      dplyr::ungroup() |>
      dplyr::select(lon, lat, fco2,fco2_erro,nobs) |>
      dplyr::mutate(year=i)

    q3_fco2 <- flux_df_filter_aux |> dplyr::pull(fco2) |> quantile(.75)
    q1_fco2 <- flux_df_filter_aux |> dplyr::pull(fco2) |> quantile(.25)

    dfall_aux <- flux_df_filter_aux |> dplyr::mutate(
      xco2 = dplyr::case_when(
        fco2 > q3_fco2 ~ 'Source',
        fco2 < q1_fco2 ~'Sink',
        .default = 'Non Significant'
      )
    )

    dfall <- rbind(dfall,dfall_aux)
  }
}


######

plot_ctrac <- biomes |>
  dplyr::filter(name_biome!="Sistema Costeiro") |>
  dplyr::filter(year<=2020) |>
  ggplot2::ggplot()+
  ggspatial::annotation_map_tile(type = "cartolight")+
  ggplot2::geom_sf(data=south_america,col='grey',fill='white')+
  ggplot2::geom_sf(col='black',fill='grey50')+
  ggplot2::ylim(-35,5.5)+
  ggplot2::xlim(-75,-35)+
  ggplot2::geom_tile(data=dfall |>
                       dplyr::filter(xco2!='Non Significant'),
                     ggplot2::aes(x=lon,y=lat,color=xco2,fill=xco2),
  )+
  ggplot2::facet_wrap(~year)+
  ggplot2::theme(axis.text = ggplot2::element_text(size=12),
                 axis.title = ggplot2::element_text(size=20),
                 text = ggplot2::element_text(size=20)
  )+
  map_theme_2()+
  # ggplot2::theme(legend.position = c(1,0),
  #                legend.justification = c(1, 0))+
  ggplot2::scale_color_manual(values = c('green','red'))+
  ggplot2::scale_fill_manual(values = c('green','red'))+
  ggplot2::labs(x='Longitude',y='Latitude',
                col=expression('CO'[2]),fill=expression('CO'[2]))


plot_oco2 <- biomes |>
  dplyr::filter(name_biome!="Sistema Costeiro") |>
  dplyr::filter(year<=2020) |>
  ggplot2::ggplot()+
  ggspatial::annotation_map_tile(type = "cartolight")+
  ggplot2::geom_sf(data=south_america,col='grey',fill='white')+
  ggplot2::geom_sf(col='black',fill='grey50')+
  ggplot2::ylim(-35,5.5)+
  ggplot2::xlim(-75,-35)+
  ggplot2::geom_tile(data=df_oco2 |>
                       dplyr::filter(xco2!='Non Significant'),
                     ggplot2::aes(x=lon,y=lat,color=xco2,fill=xco2),
  )+
  ggplot2::facet_wrap(~year)+
  ggplot2::theme(axis.text = ggplot2::element_text(size=12),
                 axis.title = ggplot2::element_text(size=20),
                 text = ggplot2::element_text(size=20)
  )+
  map_theme_2()+
  # ggplot2::theme(legend.position = c(1,0),
  #                legend.justification = c(1, 0))+
  ggplot2::scale_color_manual(values = c('green','red'))+
  ggplot2::scale_fill_manual(values = c('green','red'))+
  ggplot2::labs(x='Longitude',y='Latitude',
                col=expression('CO'[2]),fill=expression('CO'[2]))



ggpubr::ggarrange(
  plot_ctrac,plot_oco2,
  labels = c('A','B'),
  ncol=1,
  nrow=2
)

ggplot2::ggsave('img/xco2_class.png',units="in",
                width=11, height=15,
                dpi=300)
#####
plot_ctrac <- biomes |>
  dplyr::filter(name_biome!="Sistema Costeiro") |>
  dplyr::filter(year<=2020) |>
  ggplot2::ggplot()+
  ggspatial::annotation_map_tile(type = "cartolight")+
  ggplot2::geom_sf(data=south_america,col='grey',fill='white')+
  ggplot2::geom_sf(col='black',fill='grey50')+
  ggplot2::ylim(-35,5.5)+
  ggplot2::xlim(-75,-35)+
  ggplot2::geom_tile(data=dfall |>
                       dplyr::filter(xco2!='Non Significant'),
                     ggplot2::aes(x=lon,y=lat,color=fco2,
                                  fill=fco2),
  )+
  ggplot2::facet_wrap(~year)+
  ggplot2::theme(axis.text = ggplot2::element_text(size=12),
                 axis.title = ggplot2::element_text(size=20),
                 text = ggplot2::element_text(size=20)
  )+
  map_theme_2()+
  # ggplot2::theme(legend.position = c(1,0),
  #                legend.justification = c(1, 0))+
  ggplot2::scale_color_viridis_c(option = "inferno")+
  ggplot2::scale_fill_viridis_c(option = "inferno")+
  ggplot2::labs(x='Longitude',y='Latitude',
                col=expression('FCO'[2]),
                fill=expression('FCO'[2])
  )


plot_oco2 <- biomes |>
  dplyr::filter(name_biome!="Sistema Costeiro") |>
  dplyr::filter(year<=2020) |>
  ggplot2::ggplot()+
  ggspatial::annotation_map_tile(type = "cartolight")+
  ggplot2::geom_sf(data=south_america,col='grey',fill='white')+
  ggplot2::geom_sf(col='black',fill='grey50')+
  ggplot2::ylim(-35,5.5)+
  ggplot2::xlim(-75,-35)+
  ggplot2::geom_tile(data=df_oco2 |>
                       dplyr::filter(xco2!='Non Significant')|>
                       dplyr::mutate(
                         beta_molm=(10000*beta_line)*44/24.45,
                         beta_fco2 = beta_molm/1000,
                         beta_molm_erro=(10000*beta_error)*44/24.45,
                         betaerror_fco2 = beta_molm_erro*30/1000
                       ),
                     ggplot2::aes(x=lon,y=lat,color=beta_fco2,fill=beta_fco2),
  )+
  ggplot2::facet_wrap(~year)+
  ggplot2::theme(axis.text = ggplot2::element_text(size=12),
                 axis.title = ggplot2::element_text(size=20),
                 text = ggplot2::element_text(size=20)
  )+
  map_theme_2()+
  # ggplot2::theme(legend.position = c(1,0),
  #                legend.justification = c(1, 0))+
  ggplot2::scale_color_viridis_c(option = "inferno")+
  ggplot2::scale_fill_viridis_c(option = "inferno")+
  ggplot2::labs(x='Longitude',y='Latitude',
                col=expression('FCO'[2]),
                fill=expression('FCO'[2])
  )

ggpubr::ggarrange(
  plot_ctrac, plot_oco2,
  labels = c('A','B'),
  ncol=1,
  nrow=2
)

ggplot2::ggsave('img/oco2_CT_fco2.png',units="in",
                width=11, height=15,
                dpi=300)


####

plot_ctrac <- south_america |>
  ggplot2::ggplot()+
  ggspatial::annotation_map_tile(type = 'cartolight')+
  ggplot2::geom_sf(col='grey',fill='white')+
  ggplot2::geom_sf(data=br,col='red',fill='NA')+
  ggplot2::ylim(-35,5.5)+
  ggplot2::xlim(-75,-35)+
  ggplot2::geom_tile(data=dfall |>
                       dplyr::filter(xco2!='Non Significant'),
                     ggplot2::aes(x=lon,y=lat,
                                  color=fco2_erro,
                                  fill=fco2_erro),
  )+
  ggplot2::facet_wrap(~year)+
  ggplot2::theme(axis.text = ggplot2::element_text(size=12),
                 axis.title = ggplot2::element_text(size=20),
                 text = ggplot2::element_text(size=20)
  )+
  map_theme_2()+
  # ggplot2::theme(legend.position = c(1,0),
  #                legend.justification = c(1, 0))+
  ggplot2::scale_color_viridis_c(option = "inferno")+
  ggplot2::scale_fill_viridis_c(option = "inferno")+
  ggplot2::labs(x='Longitude',y='Latitude',
                col=expression(epsilon~'FCO'[2]),
                fill=expression(epsilon~'FCO'[2])
  )


plot_oco2 <- south_america |>
  ggplot2::ggplot()+
  ggspatial::annotation_map_tile(type = 'cartolight')+
  ggplot2::geom_sf(col='grey',fill='white')+
  ggplot2::geom_sf(data=br,col='red',fill='NA')+
  ggplot2::ylim(-35,5.5)+
  ggplot2::xlim(-75,-35)+
  ggplot2::geom_tile(data=df_oco2 |>
                       dplyr::filter(xco2!='Non Significant')|>
                       dplyr::mutate(
                         beta_molm=(10000*beta_line)*44/24.45,
                         beta_fco2 = beta_molm/1000,
                         beta_molm_erro=(10000*beta_error)*44/24.45,
                         betaerror_fco2 = beta_molm_erro/1000
                       ),
                     ggplot2::aes(x=lon,y=lat,color=betaerror_fco2,fill=betaerror_fco2),
  )+
  ggplot2::facet_wrap(~year)+
  ggplot2::theme(axis.text = ggplot2::element_text(size=12),
                 axis.title = ggplot2::element_text(size=20),
                 text = ggplot2::element_text(size=20)
  )+
  map_theme_2()+
  # ggplot2::theme(legend.position = c(1,0),
  #                legend.justification = c(1, 0))+
  ggplot2::scale_color_viridis_c(option = "inferno")+
  ggplot2::scale_fill_viridis_c(option = "inferno")+
  ggplot2::labs(x='Longitude',y='Latitude',
                col=expression(epsilon~'FCO'[2]),
                fill=expression(epsilon~'FCO'[2])
  )

ggpubr::ggarrange(
  plot_ctrac,plot_oco2,
  labels = c('A','B'),
  ncol=1,
  nrow=2
)

ggplot2::ggsave('img/xco2_fco2_erro.png',units="in", width=11, height=15,
                dpi=300)

#####

####

summary_nested <- dfall |>
  #dplyr::filter(xco2!="Non Significant") |>
  dplyr::select(lon,lat,year,fco2) |>
  dplyr::left_join(df_oco2 |>
                     dplyr::select(lon,lat,year,beta_line)
  ) |>
  na.omit() |>
  dplyr::mutate(
    beta_molm_oco2=(10000*beta_line)*44/24.45,
    beta_fco2 = beta_molm_oco2/1000,
  ) |>
  dplyr::select(lon,lat,year,fco2, beta_fco2) |>
  dplyr::rename(xco2_flux=beta_fco2,flux_ct=fco2) |>
  dplyr::mutate(Our=xco2_flux ) |>
  dplyr::group_by(lon,lat) |>
  tidyr::nest() |>
  dplyr::mutate(
    pvalue=purrr::map(data,linear_reg_fluxes,output='p_value'),
    r2=purrr::map(data,linear_reg_fluxes,output='r2'),
    rmse=purrr::map(data,linear_reg_fluxes,output='rmse'),
    nobs=purrr::map(data,linear_reg_fluxes,output='n'),
    beta_line=purrr::map(data,linear_reg_fluxes,output='beta1'),
    bias = purrr::map(data,linear_reg_fluxes,output='bias'),
  ) |>
  dplyr::filter(nobs>2) |>
  dplyr::mutate(cor_flux = purrr::map2(data,'flux_ct',my_correl,out='cor'),
                p_flux =purrr::map2(data,'flux_ct',my_correl,out='pvalue')
                ) |>
  #dplyr::filter(r2>=0) |>
  tidyr::unnest(cols = c(pvalue,r2,rmse,nobs,beta_line,bias,cor_flux,p_flux))



biomes |>
  dplyr::filter(year<=2020) |>
  dplyr::filter(name_biome!="Sistema Costeiro") |>
  ggplot2::ggplot()+
  ggspatial::annotation_map_tile(type = "cartolight")+
  ggplot2::geom_sf(data=south_america,col='grey',fill='white')+
  ggplot2::ylim(-35,5.5)+
  ggplot2::xlim(-75,-35)+
  ggplot2::geom_sf(fill="white", color="grey10",
                   size=.15, show.legend = FALSE)+
  ggplot2::geom_tile(
    data = summary_nested |>
      dplyr::filter(p_flux<0.2),
    ggplot2::aes(y=lat,x=lon,fill=cor_flux)
  )+
  map_theme_2()+
  # ggplot2::scale_fill_gradientn(colors=c("darkmagenta","navyblue",
  #                                        "white","darkorange","darkred"),
  #                               breaks=c(-1,-0.5,0,0.5,1))+
  ggplot2::scale_fill_viridis_c(option='inferno')+
  ggplot2::labs(x='Longitude',y='Latitude',fill=expression(R))+
  ggplot2::geom_sf(col='black',fill="NA")+
  ggplot2::theme_bw()

ggplot2::ggsave('img/r_oco2.png',units="in",
                width=7, height=7,
                dpi=300)

biomes |>
  dplyr::filter(year<=2020) |>
  dplyr::filter(name_biome!="Sistema Costeiro") |>
  ggplot2::ggplot()+
  ggspatial::annotation_map_tile(type = "cartolight")+
  ggplot2::geom_sf(data=south_america,col='grey',fill='white')+
  ggplot2::ylim(-35,5.5)+
  ggplot2::xlim(-75,-35)+
  ggplot2::geom_sf(fill="white", color="grey10",
                   size=.15, show.legend = FALSE)+
  ggplot2::geom_tile(
    data = summary_nested |>
      dplyr::filter(p_flux<0.2),
    ggplot2::aes(y=lat,x=lon,fill=r2)
  )+
  map_theme_2()+
  # ggplot2::scale_fill_gradientn(colors=c("darkmagenta","navyblue",
  #                                        "white","darkorange","darkred"),
  #                               breaks=c(-1,-0.5,0,0.5,1))+
  ggplot2::scale_fill_viridis_c(option = 'inferno')+
  ggplot2::labs(x='Longitude',y='Latitude',fill=expression(R^2))+
  ggplot2::geom_sf(col='black',fill="NA")+
  ggplot2::theme_bw()

ggplot2::ggsave('img/r2_oco2.png',units="in",
                width=7, height=7,
                dpi=300)


biomes |>
  dplyr::filter(year<=2020) |>
  dplyr::filter(name_biome!="Sistema Costeiro") |>
  ggplot2::ggplot()+
  ggspatial::annotation_map_tile(type = "cartolight")+
  ggplot2::geom_sf(data=south_america,col='grey',fill='white')+
  ggplot2::ylim(-35,5.5)+
  ggplot2::xlim(-75,-35)+
  ggplot2::geom_sf(fill="white", color="grey10",
                   size=.15, show.legend = FALSE)+
  ggplot2::geom_tile(
    data = summary_nested |>
      dplyr::filter(p_flux<0.2),
    ggplot2::aes(y=lat,x=lon,fill=rmse)
  )+
  map_theme_2()+
  # ggplot2::scale_fill_gradientn(colors=c("darkmagenta","navyblue",
  #                                        "white","darkorange","darkred"),
  #                               breaks=c(-1,-0.5,0,0.5,1))+
  ggplot2::scale_fill_viridis_c(option='inferno')+
  ggplot2::labs(x='Longitude',y='Latitude',
                fill=expression('RMSE'))+
  ggplot2::geom_sf(col='black',fill="NA")+
  ggplot2::theme_bw()

ggplot2::ggsave('img/rmse_oco2.png',units="in",
                width=7, height=7,
                dpi=300)

biomes |>
  dplyr::filter(year<=2020) |>
  dplyr::filter(name_biome!="Sistema Costeiro") |>
  ggplot2::ggplot()+
  ggspatial::annotation_map_tile(type = "cartolight")+
  ggplot2::geom_sf(data=south_america,col='grey',fill='white')+
  ggplot2::ylim(-35,5.5)+
  ggplot2::xlim(-75,-35)+
  ggplot2::geom_sf(fill="white", color="grey10",
                   size=.15, show.legend = FALSE)+
  ggplot2::geom_tile(
    data = summary_nested |>
      dplyr::filter(p_flux<0.2),
    ggplot2::aes(y=lat,x=lon,fill=bias)
  )+
  map_theme_2()+
  # ggplot2::scale_fill_gradientn(colors=c("darkmagenta","navyblue",
  #                                        "white","darkorange","darkred"),
  #                               breaks=c(-1,-0.5,0,0.5,1))+
  ggplot2::scale_fill_viridis_c(option='inferno')+
  ggplot2::labs(x='Longitude',y='Latitude',
                fill=expression('Bias'))+
  ggplot2::geom_sf(col='black',fill="NA")+
  ggplot2::theme_bw()

ggplot2::ggsave('img/bias_oco2.png',units="in",
                width=7, height=7,
                dpi=300)




####
dfall |>
  dplyr::filter(xco2!="Non Significant") |>
  dplyr::select(lon,lat,year,fco2) |>
  dplyr::left_join(df_oco2 |>
                     dplyr::select(lon,lat,year,beta_line)
  ) |>
  na.omit() |>
  dplyr::mutate(
    beta_molm_oco2=(10000*beta_line)*44/24.45,
    beta_fco2 = beta_molm_oco2/1000,
  ) |>
  dplyr::select(lon,lat,year,fco2, beta_fco2) |>
  ggplot2::ggplot(
    ggplot2::aes(x=fco2,y=beta_fco2)
  )+
  ggplot2::geom_point()+
  ggplot2::geom_smooth(method='lm')+
  ggpmisc::stat_poly_eq(formula = y ~ x,
                        ggplot2::aes(label = paste(..eq.label..,
                                                   ..rr.label..,
                                                   ..p.value.label..,
                                                   sep = "*`,`~")),
                        label.y = 0.01,
                        parse = TRUE
  )+
  #ggplot2::facet_wrap(~year,scales ='free_x')+
  ggplot2::theme_bw()+
  ggplot2::labs(x='',y=expression('Fco'[2]~''),fill='' )


######

dfall |>
  dplyr::filter(xco2!="Non Significant") |>
  dplyr::select(lon,lat,year,fco2,xco2) |>
  dplyr::left_join(df_oco2 |>
                     dplyr::filter(xco2!="Non Significant") |>
                     dplyr::rename(
                       'xco2_oco2'='xco2'
                     ) |>
                     dplyr::select(lon,lat,year,beta_line,xco2_oco2)
  ) |>
  na.omit() |>
  dplyr::group_by(lon, lat) |>
  dplyr::mutate(
    new_class = dplyr::case_when(
      xco2 == "Source" & xco2_oco2 == "Source" ~ "TP",
      xco2 == "Source" & xco2_oco2 == "Sink" ~ "FN",
      xco2 == "Sink" & xco2_oco2 == "Source" ~ "FP",
      xco2 == "Sink" & xco2_oco2 == "Sink" ~ "TN"
    )
  ) |>
  dplyr::group_by(new_class) |>
  dplyr::summarise(
    nobs = dplyr::n()
  ) |>
  tidyr::pivot_wider(
    names_from = new_class,
    values_from = nobs,
    values_fill = 0
  ) |>
  dplyr::mutate(
    #ratio = NP/(NP+NN),
    acu = (TP+TN)/(TP+TN+FP+FN),
    pre = TP/(TP+FP),
    recal=TP/(TP+FN),
    fscore=2*((pre*recal)/(pre+recal))
  )

dfall |>
  dplyr::filter(xco2!="Non Significant") |>
  dplyr::select(lon,lat,year,fco2,xco2) |>
  dplyr::left_join(df_oco2 |>
                     dplyr::filter(xco2!="Non Significant") |>
                     dplyr::rename(
                       'xco2_oco2'='xco2'
                     ) |>
                     dplyr::select(lon,lat,year,beta_line,xco2_oco2)
  ) |>
  na.omit() |>
  dplyr::mutate(
    xco2=as.factor(xco2),
    xco2_oco2=as.factor(xco2_oco2)
  ) |>
  dplyr::select(xco2_oco2,xco2) |>
  table() |>
  caret::confusionMatrix(mode = "prec_recall")


cm <- dfall |>
  dplyr::filter(xco2!="Non Significant") |>
  dplyr::select(lon,lat,year,fco2,xco2) |>
  dplyr::left_join(df_oco2 |>
                     dplyr::filter(xco2!="Non Significant") |>
                     dplyr::rename(
                       'xco2_oco2'='xco2'
                     ) |>
                     dplyr::select(lon,lat,year,beta_line,xco2_oco2)
  ) |>
  na.omit() |>
  dplyr::mutate(
    xco2=as.factor(xco2),
    xco2_oco2=as.factor(xco2_oco2)
  ) |>
  yardstick::conf_mat(
    xco2,xco2_oco2
  )
summary(cm)


ggplot2::autoplot(cm,type='heatmap')+
  ggplot2::scale_fill_viridis_c(direction=-1)+
  ggplot2::theme_bw()

171+142+140+136

##
biomas <- c("AF","CERR","CAAT","PMP","PNT","AMZ")

for(i in 1:6){
  print(biomas[i])
  cm <- dfall |>
    dplyr::group_by(lon,lat) |>
    dplyr::mutate(
      biome = get_geobr_biomes(lon,lat)
    ) |>
    dplyr::mutate(
      biome_n = dplyr::case_when(
        biome=='Other'& lon>= -45 & lat < -6~'AF',
        biome == "Amazônia" ~ "AMZ",
        biome== 'Other'&lat>-15~"AMZ",
        biome=='Other'& lon< -45 & lat >=-10 ~'AMZ',
        biome=='Other'& lon< -50 & lat >-25 ~'PNT',
        biome == 'Mata Atlântica' & lon> -40 & lat < -20 ~'Other',
        biome == 'Mata Atlântica' & lon> -34 & lat > -5 ~'Other',
        biome == 'Mata Atlântica' ~ 'AF',
        biome=='Cerrado'~'CERR',
        biome =='Pampa'~'PMP',
        biome == 'Pantanal' ~ 'PNT',
        biome=='Caatinga'~'CAAT',
        TRUE ~ 'PMP'
      )
    ) |>
    dplyr::filter(biome_n==biomas[i]) |>
    dplyr::filter(xco2!="Non Significant") |>
    dplyr::select(lon,lat,year,fco2,xco2) |>
    dplyr::left_join(df_oco2 |>
                       dplyr::filter(xco2!="Non Significant") |>
                       dplyr::rename(
                         'xco2_oco2'='xco2'
                       ) |>
                       dplyr::select(lon,lat,year,beta_line,xco2_oco2)
    ) |>
    na.omit() |>
    dplyr::ungroup() |>
    dplyr::mutate(
      xco2=as.factor(xco2),
      xco2_oco2=as.factor(xco2_oco2)
    ) |>
    dplyr::select(xco2_oco2,xco2) |>
    table() |>
    caret::confusionMatrix(mode = "prec_recall")


  print(cm)


  cm <- dfall |>
    dplyr::group_by(lon,lat) |>
    dplyr::mutate(
      biome = get_geobr_biomes(lon,lat)
    ) |>
    dplyr::mutate(
      biome_n = dplyr::case_when(
        biome=='Other'& lon>= -45 & lat < -6~'AF',
        biome == "Amazônia" ~ "AMZ",
        biome== 'Other'&lat>-15~"AMZ",
        biome=='Other'& lon< -45 & lat >=-10 ~'AMZ',
        biome=='Other'& lon< -50 & lat >-25 ~'PNT',
        biome == 'Mata Atlântica' & lon> -40 & lat < -20 ~'Other',
        biome == 'Mata Atlântica' & lon> -34 & lat > -5 ~'Other',
        biome == 'Mata Atlântica' ~ 'AF',
        biome=='Cerrado'~'CERR',
        biome =='Pampa'~'PMP',
        biome == 'Pantanal' ~ 'PNT',
        biome=='Caatinga'~'CAAT',
        TRUE ~ 'PMP'
      )
    ) |>
    dplyr::filter(biome_n==biomas[i]) |>
    dplyr::filter(xco2!="Non Significant") |>
    dplyr::select(lon,lat,year,fco2,xco2) |>
    dplyr::left_join(df_oco2 |>
                       dplyr::filter(xco2!="Non Significant") |>
                       dplyr::rename(
                         'xco2_oco2'='xco2'
                       ) |>
                       dplyr::select(lon,lat,year,beta_line,xco2_oco2)
    ) |>
    na.omit() |>
    dplyr::ungroup() |>
    dplyr::mutate(
      xco2=as.factor(xco2),
      xco2_oco2=as.factor(xco2_oco2)
    ) |>
    yardstick::conf_mat(xco2,xco2_oco2)
  plot <- ggplot2::autoplot(cm,type='heatmap')+
    ggplot2::ggtitle(biomas[i])
  print(plot)
}




####

dfall |>
  dplyr::group_by(lon,lat) |>
  dplyr::mutate(
    biome = get_geobr_biomes(lon,lat)
  ) |>
  dplyr::mutate(
    biome_n = dplyr::case_when(
      biome=='Other'& lon>= -45 & lat < -6~'AF',
      biome == "Amazônia" ~ "AMZ",
      biome== 'Other'&lat>-15~"AMZ",
      biome=='Other'& lon< -45 & lat >=-10 ~'AMZ',
      biome=='Other'& lon< -50 & lat >-25 ~'PNT',
      biome == 'Mata Atlântica' & lon> -40 & lat < -20 ~'Other',
      biome == 'Mata Atlântica' & lon> -34 & lat > -5 ~'Other',
      biome == 'Mata Atlântica' ~ 'AF',
      biome=='Cerrado'~'CERR',
      biome =='Pampa'~'PMP',
      biome == 'Pantanal' ~ 'PNT',
      biome=='Caatinga'~'CAAT',
      TRUE ~ 'PMP'
    )
  ) |>
  dplyr::filter(xco2!="Non Significant") |>
  dplyr::select(lon,lat,year,fco2,xco2,biome_n) |>
  dplyr::left_join(df_oco2 |>
                     dplyr::filter(xco2!="Non Significant") |>
                     dplyr::rename(
                       'beta_oco2'='beta_line',
                       'xco2_oco2'='xco2'
                     ) |>
                     dplyr::select(lon,lat,year,beta_oco2,xco2_oco2)
  ) |>
  na.omit() |>
  dplyr::ungroup() |>
  #dplyr::filter(beta_line < 50) |>
  dplyr::pull(beta_oco2) |>
  min()*(10000/1000)*(44/24.45)

####

summary_biome <- summary_nested |>
  dplyr::filter(p_flux<0.2) |>
  dplyr::mutate(
    biome = get_geobr_biomes(lon,lat)
  ) |>
  dplyr::mutate(
    biome_n = dplyr::case_when(
      biome=='Other'& lon>= -45 & lat < -6~'AF',
      biome == "Amazônia" ~ "AMZ",
      biome== 'Other'&lat>-15~"AMZ",
      biome=='Other'& lon< -45 & lat >=-10 ~'AMZ',
      biome=='Other'& lon< -50 & lat >-25 ~'PNT',
      biome == 'Mata Atlântica' & lon> -40 & lat < -20 ~'Other',
      biome == 'Mata Atlântica' & lon> -34 & lat > -5 ~'Other',
      biome == 'Mata Atlântica' ~ 'AF',
      biome=='Cerrado'~'CERR',
      biome =='Pampa'~'PMP',
      biome == 'Pantanal' ~ 'PNT',
      biome=='Caatinga'~'CAAT',
      TRUE ~ 'PMP'
    )
  )


summary_biome |>
  tidyr::unnest() |>
  #dplyr::filter(xco2!="Non Significant") |>
  ggplot2::ggplot(
    ggplot2::aes(x=flux_ct, y=xco2_flux)
  )+
  ggplot2::geom_point()+
  ggplot2::geom_smooth(method='lm')+
  ggpmisc::stat_poly_eq(formula = y ~ x,
                        ggplot2::aes(label = paste(..eq.label..,
                                                   ..rr.label..,
                                                   ..p.value.label..,
                                                   sep = "*`,`~")),
                        label.y = 0.01,
                        parse = TRUE
  )+
  ggplot2::facet_wrap(~biome_n,scales ='free_x')+
  ggplot2::theme_bw()+
  ggplot2::labs(x='',y=expression('Xco'[2]~' (ppm)'),fill='' )


summary_biome |>
  dplyr::ungroup() |>
  #dplyr::group_by(biome_n) |>
  dplyr::summarise(r2=mean(r2),
                   rmse=mean(rmse),
                   bias=min(bias),
                   cor=mean(cor_flux),
                   nobs=sum(nobs),
                   n = dplyr::n()
                   )



summary_biome |>
  tidyr::unnest() |>
  dplyr::ungroup() |>
  #dplyr::filter(flux_ct < 50) |>
  #dplyr::group_by(biome_n) |>
  dplyr::summarise(
    xco2 = min(xco2_flux),
    ct = max(flux_ct),
    xco2_sd = sd(xco2_flux),
    ct_sd = sd(flux_ct),
    cv = ct_sd/ct
    )

summary_biome |>
  tidyr::unnest() |>
  dplyr::filter(flux_ct>100)
  dplyr::group_by(lon,lat) |>
  dplyr::mutate(
    ct_mean = purrr::map(
      data,function(df)(mean(df$flux_ct))
    ),
    ct_sd = purrr::map(
      data,function(df)(sd(df$flux_ct))
    ),
    xco2_mean = purrr::map(
      data,function(df)(mean(df$Our))
    ),
    xco2_sd = purrr::map(
      data,function(df)(sd(df$Our))
    ),
    ct_min = purrr::map(
      data,function(df)(min(df$flux_ct))
    ),
    ct_max = purrr::map(
      data,function(df)(max(df$flux_ct))
    ),
    xco2_min = purrr::map(
      data,function(df)(min(df$Our))
    ),
    xco2_max = purrr::map(
      data,function(df)(max(df$Our))
    )
  ) |>
  dplyr::select(ct_mean,ct_sd,ct_min,ct_max,xco2_mean,xco2_sd,xco2_min,xco2_max) |>
  dplyr::ungroup() |>
  tidyr::unnest() |>
  dplyr::filter(ct_)

