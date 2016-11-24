# put data in the clipboard from excel

# run this as 
# source('RGraphandAnova.R', echo=TRUE, print.eval=TRUE)

xx <- read.table(pipe("pbpaste"), sep="\t", header=T, na.strings=c(""))
head (xx)
attach(xx)
library(ggplot2)
ggplot(xx, aes(x=genotype,y=peak.peak,color=genotype)) + geom_point(shape=1)
myANOVA= aov(peak.peak ~ genotype)
summary(myANOVA)
TukeyHSD(myANOVA)