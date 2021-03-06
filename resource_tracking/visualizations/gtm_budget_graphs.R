# ----------------------------------------------
# Irena Chen
#
# 11/16/2017
# Make preliminary graphs of sicoin and fpm budget data 


# ----------------------------------------------
# Set up R
library(ggplot2)
library(dplyr)
library(tools)
library(data.table)
library(lubridate)
library(grDevices)
library(RColorBrewer)
library(readxl)
library(reshape)
library(scales)

# ----------------------------------------------
## Uncomment if necessary
# sicoin_data$start_date <- as.Date(sicoin_data$start_date,"%Y-%m-%d")

# gtm_total$data_source <- as.character(gtm_total$data_source)
# gtm_total$data_source[gtm_total$data_source=="pudr_budget"] <- "pudr"
# gtm_total$data_source <- as.factor(gtm_total$data_source)

# ----------------------------------------------
##plot national level data in aggregate 

sicoin_data <- data.table(read.csv("J:/Project/Evaluation/GF/resource_tracking/gtm/prepped/prepped_sicoin_data.csv"
                                   ,fileEncoding="latin1"))

sicoin_data$budget <- as.numeric(sicoin_data$budget)
sicoin_data$disbursement<- as.numeric(sicoin_data$disbursement)
sicoin_data$year <- year(sicoin_data$start_date)

sicoin_data[source=='gf', source:='Global Fund']
sicoin_data[source=='ghe', source:='Government Health Expenditure']
sicoin_data[source=='donacions', source:='Donacions']
sicoin_data$source <- factor(sicoin_data$source, c("Government Health Expenditure","Global Fund", "Donacions"))


sicoin_data<- disease_names_for_plots(sicoin_data)

##first look at data on a national level 
byVars = names(sicoin_data)[names(sicoin_data)%in%c('source', 'start_date', 'year', 'period', 'disease')]
nat_level = sicoin_data[, list(budget=sum(budget), disbursement=sum(disbursement), expenditure=sum(expenditure)), by=byVars]

nat_level[, end_date:=start_date + period-1]

# "melt" long
tmp = copy(nat_level)
tmp$start_date = NULL
setnames(tmp, 'end_date', 'start_date')
nat_level$end_date = NULL
national_data = rbind(nat_level, tmp)


primColors <- c('#dc143c', ##red
                '#3DCC3D', ##green
                '#0000b8') ## blue

names(primColors) <- c("Donacions", "Global Fund", "Government Health Expenditure")
colScale <- scale_color_manual(name="Source", values =primColors, drop=TRUE) 

# ----------------------------------------------
##make barcharts: 
graphData <- copy(national_data)
resource_plots <- list()
for (k in unique(graphData$disease)){
  subdata <- graphData[disease==k]
  colScale <- scale_fill_manual(name="Source", values =primColors) 
  plot <- (ggplot(data=subdata, aes(x = year(start_date), y= budget, fill=source)) + 
             geom_bar(position = "fill",
               stat="identity") + 
             colScale +
             theme_bw(base_size=14) +
             theme(strip.text.x = element_text(size = 8, colour = "black")) +
             scale_y_continuous(labels = percent_format()) +
             scale_x_continuous(name ="Year") +
             labs(title=paste(k, "Data at National Level"), y = "% of Total Budgeted Resources",
                  caption="Data Source: SICOIN" ))
  resource_plots[[k]] <- plot
}

pdf("J:/Project/Evaluation/GF/resource_tracking/gtm/visualizations/budget_disbursement_graphs/gf_perc_of_total_resources.pdf", height=6, width=9)
invisible(lapply(resource_plots, print))
dev.off()


# ----------------------------------------------
##Government Health Expenditures and GF data on same graph (linegraph over time)

graphData <- copy(nat_level)

##since we have monthly data, get the cumulative sum of it by year: 
graphData <-graphData[with(graphData, order(start_date, disease, source)), ]
graphData[, cumsum_budget:= cumsum(budget),by=c("year", "disease", "source")]
graphData[, cumsum_disb:= cumsum(disbursement),by=c("year", "disease", "source")]

# "melt" long
graphData[, end_date:=start_date + period-1]
tmp = copy(graphData)
tmp$start_date = NULL
setnames(tmp, 'end_date', 'start_date')
graphData$end_date = NULL
graphData = rbind(graphData, tmp)

graphData = melt(graphData, id.vars=c( "source", "year","period", "start_date", "disease"))
graphData$value[graphData$value<=0] <- NA


graphData[variable=='cumsum_budget', variable:='Cumulative Budget']
graphData[variable=='cumsum_disb', variable:='Cumulative Disb.']

nat_plots <- list()
for (k in unique(graphData$disease)){
  subdata <-graphData[disease==k&variable%in%c("Cumulative Budget", "Cumulative Disb.")]
  colScale <- scale_color_manual(name="Source", values =primColors, drop=TRUE) 
  plot <-  ggplot(subdata, aes(x = start_date, y= value/1000000)) + 
    geom_line(aes(color=source, linetype=variable), size=0.75) +
    facet_grid(~source) +
    colScale + 
    ggtitle(paste(k, "Data at National Level")) +
    labs(x = "Start Date", y = "USD (millions)") +
    theme_bw()
  nat_plots[[k]] <- plot
}

pdf("J:/Project/Evaluation/GF/resource_tracking/gtm/visualizations/sicoin_national_visualizations/gtm_by_source_and_resource.pdf", height=6, width=9)
invisible(lapply(nat_plots, print))
dev.off()
# ----------------------------------------------
##GF VS GHE VS DONACIONS: 
  




## do some malaria manipulations: 

malaria_data <- nat_level[disease== "tb"]
malaria_data$year <- year(malaria_data$start_date)
malaria_data$expenditure <- NULL

malaria_data<- malaria_data[with(malaria_data, order(start_date, disease, source)), ]
malaria_data[, cumsum_budget:= cumsum(budget),by=c("year", "disease", "source")]
malaria_data[, cumsum_disb:= cumsum(disbursement),by=c("year", "disease", "source")]
malaria_data<-malaria_data[with(malaria_data, order(source, year, start_date)),]

byVars = names(malaria_data)[names(malaria_data)%in%c('source', 'start_date', 'period', 'disease')]
malaria_data = malaria_data[, list(budget=sum(budget),disbursement = sum(disbursement)), by=byVars]



malData <- melt(malaria_data, id.vars=c( "source", "disease", 'start_date', 'period'))

malData[source=='gf', source:='Global Fund']
malData[source=='ghe', source:='Government Health Expenditure']
malData[source=='donacions', source:='Donacions']
malData[variable=='budget', variable:='Budget']
malData[variable=='disbursement', variable:='Disbursement']

malData <- malData[!source=="donacions"]

malaria_plots <- list()
for(k in unique(malData$disease)){
  malaria_plots[[k]] <- (ggplot(malData[disease==k], aes(x = start_date, y= value/1000000)) + 
  geom_line(aes(color=source , linetype=variable
  ), size=0.75) +
  colScale + 
  ggtitle("Malaria Data at National Level") + 
    facet_wrap(~source, scales="free")+
  # scale_linetype_manual(values=c("solid", "twodash"))+ 
  #ylim(0, 9) + 
  labs(x = "Start Date", y = "USD (millions)") +
  theme_bw())
}

malaria_plots[[2]] <- nat_plots[[1]]
malaria_plots[[3]] <- nat_plots[[2]]

pdf("gtm_resources_by_source.pdf", height=6, width=9)
invisible(lapply(malaria_plots, print))
dev.off()



# ----------------------------------------------

gf_nat<- subset(nat_level, source=="gf")
ghe_plot <- ggplot(ghe_nat, aes(x = start_date, y= value/1000000)) + 
  geom_line(aes(color=data_source, linetype=disease)) +
  facet_wrap(~variable) +
  ggtitle("GHE Resources by Data Source") +
  #ylim(0, 9) + 
  labs(x = "Start Date", y = "$$ in mil") +
  theme_bw()


gf_plot <- ggplot(gf_nat, aes(x = start_date, y= value/1000000)) + 
  geom_line(aes(color=data_source, linetype=disease)) +
  facet_wrap(~variable) +
  ggtitle(k + "Resources by Data Source") +
  #ylim(0, 9) + 
  labs(x = "Start Date", y = "$$ in mil") +
  theme_bw()

ggsave("gf resources by data source.pdf", 
       plot = last_plot(), # or give ggplot object name as in myPlot,
        height = 6, width=9,
       units = "in", # other options c("in", "cm", "mm"), 
       dpi = 300)





# ----------------------------------------------
##budget vs disbursements

colors = c('#CAF270', '#FF66CC')
mapColors = colorRampPalette(colors)
mapColors = mapColors(10)

budg_disburs<- nat_level


budg_disburs$disbursement[budg_disburs$disbursement==0] <- NA



ggplot(budg_disburs, aes(x = budget/1000000, y= disbursement/1000000)) + 
  geom_point(aes(color=start_date, shape=disease)) +
  geom_abline(intercept=0, slope=1) + 
  geom_smooth(method='lm') + 
  facet_wrap(~source, scales='free') +
  scale_colour_gradient(low = "#73D487", high = "#FF66CC",
                        space = "Lab", na.value = "grey50", guide = "colourbar", labels=as.Date_origin) +
  ggtitle("GTM Resources by Source") +
  #ylim(0, 9) + 
  labs(x = "budget $$ mil", y = "disbursement $$ in mil") 

ggsave("gtm_budget_vs_disbursement.pdf", 
       plot = last_plot(), # or give ggplot object name as in myPlot,
       height = 6, width=9,
       units = "in", # other options c("in", "cm", "mm"), 
       dpi = 300)


# ----------------------------------------------
##plot sicoin vs fpm budget data only 


ggplot(sicoin_fpm_plot, aes(x = start_date, y=value/100000)) + 
  geom_line(aes(color=disease, linetype=data_source)) +
  facet_wrap(~variable) +
  geom_point() +
  ggtitle("FPM Budget vs. Sicoin Data") +
  #ylim(0, 9) + 
  labs(x = "Start Date", y = "$$ in mil")


pdf("all.pdf", height=6, width=9)
invisible(lapply(plot_list, print))
dev.off()


# ----------------------------------------------
##plot muni level sicoin data 

# collapse cost categories
byVars = names(gtm_total)[!names(gtm_total)%in%c('budget','disbursement','expenditure','cost_category', 'coeff', 'code')]
muni_level = gtm_total[, list(budget=sum(budget), disbursement=sum(disbursement), expenditure=sum(expenditure)), by=byVars]


# "melt" long
tmp = copy(muni_level)
tmp$start_date = NULL
setnames(tmp, 'end_date', 'start_date')
muni_level$end_date = NULL
muni_level = rbind(muni_level, tmp)

muni_melt = melt(muni_level, id.vars=c('loc_id', 'source', 'start_date', 'period', 'disease', 'data_source', 'grant_number'))

muni_melt <- muni_melt[-grep(paste(c("gtm", "GUAT"),  collapse="|"), muni_melt$loc_id),]

muni_melt <- muni_melt[, list(start_date, disease, variable, value),by="loc_id"]
muni_melt$value[muni_melt$value == 0] <- NA
muni_melt$loc_id <- as.factor(muni_melt$loc_id)
muni_mapping <- cbind(unique(levels(muni_melt$loc_id)), as.numeric(1:length(unique(levels((muni_melt$loc_id))))))

colnames(muni_mapping) <- c("loc_id", "muni_code")

muni_merge <- merge(muni_melt, muni_mapping, by="loc_id")
muni_merge$muni_code <- as.numeric(muni_merge$muni_code)


muni_merge$loc_id<- chartr("???", " ", muni_merge$loc_id)

library(gsubfn)
muni_merge$loc_id <- gsubfn("�'A","�A", muni_merge$loc_id)

### use a loop to create plots and store them into a pdf 
plot_list = list()
for (i in 1:48){
  subdata <- subset(muni_merge, muni_code%%48==i)
  plot <- ggplot(subdata, aes(x = start_date, y = value)) + 
    geom_line(aes(color=variable, linetype=disease)) +
    facet_wrap(~loc_id, scales='free') +
    theme(text = element_text(size=5),axis.text.x = element_text(angle=90, hjust=1)) +
    geom_point() +
    ggtitle("Municipality Level Resources by Disease") +
    labs(x = "Start Date", y = "Resource $$", caption="data source:SICOIN")
  plot_list[[i]] <- plot
  
  }


pdf("gtm municipalities by disease.pdf", height=6, width=9)
invisible(lapply(plot_list, print))
dev.off()





### working on this code, it's broken for now:  
##-------------------------------------------
## plot sicoin vs fpm budget over time by disease 


fpm_sicoin <- subset(nat_level, data_source !="pudr")

byVars = names(fpm_sicoin)[!names(fpm_sicoin)%in%c('budget','disbursement','expenditure', 'source')]
fpm_sicoin = fpm_sicoin[, list(budget=sum(budget), disbursement=sum(disbursement), expenditure=sum(expenditure)), by=byVars]

fpm_sicoin  = melt(fpm_sicoin , id.vars=c("start_date", "data_source", "disease", "source", "period", "grant_number"))
fpm_sicoin$value[fpm_sicoin$value == 0] <- NA

fpm_sicoin <- subset(fpm_sicoin, variable=="budget")
fpm_sicoin$sicoin_ind <- 0
fpm_sicoin$fpm_ind <- 0
for(i in 1: length(fpm_sicoin$sicoin_ind)){
  if (fpm_sicoin$data_source[i]=="SICOIN"){
    fpm_sicoin$sicoin_ind[i] <- fpm_sicoin$value[i]
    fpm_sicoin$fpm_ind[i] <- 0
  } else if (fpm_sicoin$data_source[i]!="SICOIN"){
    fpm_sicoin$sicoin_ind[i] = fpm_sicoin$sicoin_ind[i]
    fpm_sicoin$fpm_ind[i] <- fpm_sicoin$value[i]
  }
}


pdf("fpm_vs_sicoin", height=6, width=9)
invisible(lapply(fpm_sicoin_plots, print))
dev.off()

ggsave("fpm vs sicoin budget data.pdf", 
       plot = last_plot(), # or give ggplot object name as in myPlot,
       height = 6, width=9,
       units = "in", # other options c("in", "cm", "mm"), 
       dpi = 300)







