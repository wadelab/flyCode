# put data in the clipboard from excel

# run this as 
# source('SSVEP_GraphandAnova.R', echo=TRUE, print.eval=TRUE)


## Gives count, mean, standard deviation, standard error of the mean, and confidence interval (default 95%).
##   data: a data frame.
##   measurevar: the name of a column that contains the variable to be summariezed
##   groupvars: a vector containing names of columns that contain grouping variables
##   na.rm: a boolean that indicates whether to ignore NA's
##   conf.interval: the percent range of the confidence interval (default is 95%)
##  http://www.cookbook-r.com/Graphs/Plotting_means_and_error_bars_(ggplot2)/


summarySE <- function(data=NULL, measurevar, groupvars=NULL, na.rm=FALSE,
conf.interval=.95, .drop=TRUE) {
    library(plyr)
    
    # New version of length which can handle NA's: if na.rm==T, don't count them
    length2 <- function (x, na.rm=FALSE) {
        if (na.rm) sum(!is.na(x))
        else       length(x)
    }
    
    # This does the summary. For each group's data frame, return a vector with
    # N, mean, and sd
    datac <- ddply(data, groupvars, .drop=.drop,
    .fun = function(xx, col) {
        c(N    = length2(xx[[col]], na.rm=na.rm),
        mean = mean   (xx[[col]], na.rm=na.rm),
        sd   = sd     (xx[[col]], na.rm=na.rm)
        )
    },
    measurevar
    )
    
    # Rename the "mean" column
    datac <- rename(datac, c("mean" = measurevar))
    
    datac$se <- datac$sd / sqrt(datac$N)  # Calculate standard error of the mean
    
    # Confidence interval multiplier for standard error
    # Calculate t-statistic for confidence interval:
    # e.g., if conf.interval is .95, use .975 (above/below), and use df=N-1
    ciMult <- qt(conf.interval/2 + .5, datac$N-1)
    datac$ci <- datac$se * ciMult
    
    return(datac)
}

xx <- read.table(pipe("pbpaste"), sep="\t", header=T, na.strings=c(""))
head (xx)
attach(xx)
library(ggplot2)
p1 <- ggplot(xx, aes(x=genotype,y=X1F1,color=genotype)) + geom_point(shape=1) + theme(axis.text.x = element_text(angle = 45, hjust = 1))
p1

xxSE=summarySE(xx, measurevar= "X1F1", groupvars=c("genotype"))

myANOVA= aov(X1F1 ~ genotype)
summary(myANOVA)
TukeyHSD(myANOVA)

p2 <- ggplot(xxSE, aes(x=genotype, y=X1F1, colour=genotype)) +
geom_errorbar(aes(ymin=X1F1-se, ymax=X1F1+se), width=.1) +
geom_line() +
geom_point()  + 
theme(axis.text.x = element_text(angle = 45, hjust = 1))

p2


p3 <- ggplot(xx, aes(x=genotype,y=X1F1,color=genotype)) + geom_boxplot() + geom_point(position=position_jitterdodge(dodge.width=0.75)) +
coord_cartesian(ylim = c(0, 1.05 * max(X1F1))) +
theme(axis.text.x = element_text(angle = 45, hjust = 1))

p4 <- p3 + annotate("text", x= xxSE$genotype, y = 10, label = xxSE$N, size = 3)
p3

#ggsave("1F1.pdf")

# see also https://www.datacamp.com/community/tutorials/15-questions-about-r-plots
# and https://www.rstudio.com/wp-content/uploads/2015/03/ggplot2-cheatsheet.pdf


# if you have age and genotype something like this:
# ggplot(hg, aes(x=genotype,y= X1F1,color=day,group= interaction(genotype,day))) + geom_boxplot(outlier.shape = NA) + geom_point(position=position_jitterdodge(jitter.width = 0.20)) +
# + coord_cartesian(ylim = c(0, 1.05 * max(X1F1))) +
# + theme(axis.text.x = element_text(angle = 45, hjust = 1))