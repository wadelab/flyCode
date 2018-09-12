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


multiplot <- function(..., plotlist=NULL, cols) {
    require(grid)

    # Make a list from the ... arguments and plotlist
    plots <- c(list(...), plotlist)

    numPlots = length(plots)

    # Make the panel
    plotCols = cols                          # Number of columns of plots
    plotRows = ceiling(numPlots/plotCols) # Number of rows needed, calculated from # of cols

    # Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(plotRows, plotCols)))
    vplayout <- function(x, y)
        viewport(layout.pos.row = x, layout.pos.col = y)

    # Make each plot, in the correct location
    for (i in 1:numPlots) {
        curRow = ceiling(i/plotCols)
        curCol = (i-1) %% plotCols + 1
        print(plots[[i]], vp = vplayout(curRow, curCol ))
    }

}
#or use cowplot
 myVar <- X1F1
 p1 <- ggplot(r10, aes(x=g2,y= myVar,color=disco,group= interaction(g2,disco))) + geom_boxplot(outlier.shape = NA) + geom_point(position=position_jitterdodge(jitter.width = 0.20)) + coord_cartesian(ylim = c(0, 1.05 * max(myVar, na.rm=TRUE))) +theme_classic() + theme(axis.text.x = element_text(angle = 45, hjust = 1)) + xlab("") + ylab("photoreceptors") + scale_colour_manual(values=cbbPalette)
 myVar <- X2F1
 p2 <- ggplot(r10, aes(x=g2,y= myVar,color=disco,group= interaction(g2,disco))) + geom_boxplot(outlier.shape = NA) + geom_point(position=position_jitterdodge(jitter.width = 0.20)) + coord_cartesian(ylim = c(0, 1.05 * max(myVar, na.rm=TRUE))) +theme_classic() + theme(axis.text.x = element_text(angle = 45, hjust = 1)) + xlab("") + ylab("lamina neurons") + scale_colour_manual(values=cbbPalette)
 multiplot(p1,p2,cols=1)

xx <- read.table(pipe("pbpaste"), sep="\t", header=T, na.strings=c(""))
head (xx)
attach(xx)

yy<-subset(xx, !duplicated(xx))	
r10_dark <- r10[r10$disco == "N ", ] #note spaces
LC <- na.omit(LC) #remove all rows that have a NA in any variable
LC <-[!is.na(LC$B), ] # remove if NA is in column B


xxSE<-summarySE(xx, measurevar= "X1F1", groupvars=c("genotype"))

myANOVA= aov(X1F1_masked ~ genotype)
summary(myANOVA)
TukeyHSD(myANOVA)

myANOVA= aov(X2F1_masked ~ genotype)
summary(myANOVA)
TukeyHSD(myANOVA)

library(ggplot2)
p1 <- ggplot(xx, aes(x=genotype,y=X1F1,color=genotype)) + geom_point(shape=1) + theme(axis.text.x = element_text(angle = 45, hjust = 1))
p1

#install.packages('psych')
library(psych)
describeBy(CCAll, genotype)

library(doBy)
summaryBy(1F1 ~ genotype, data=data, FUN=c(length,mean,sd)) #watch out for NA

th5 <- read.table(pipe("pbpaste"), sep="\t", header=T, na.strings=c(""))
th3 <- stack(th5)
names(th3) <- c("1F1","genotype")
na.omit(th3)



p2 <- ggplot(xxSE, aes(x=genotype, y=X1F1, colour=genotype)) +
geom_errorbar(aes(ymin=X1F1-se, ymax=X1F1+se), width=.1) +
geom_line() +
geom_point()  + 
theme(axis.text.x = element_text(angle = 45, hjust = 1))

p2


p3 <- ggplot(xx, aes(x=genotype,y=X1F1,color=genotype)) + geom_boxplot() + geom_point(position=position_jitterdodge(dodge.width=0.75)) +
coord_cartesian(ylim = c(0, 1.05 * max(X1F1))) +
theme(axis.text.x = element_text(angle = 45, hjust = 1))

p32 <- ggplot(xx, aes(x=genotype,y=X2F1,color=genotype)) + geom_boxplot() + geom_point(position=position_jitterdodge(dodge.width=0.75)) +
coord_cartesian(ylim = c(0, 1.05 * max(X2F1))) +
theme(axis.text.x = element_text(angle = 45, hjust = 1))

p4 <- p3 + annotate("text", x= xxSE$genotype, y = 10, label = xxSE$N, size = 3)
p4

myVar <- X1F1_masked
ggplot(ee, aes(x=genotype,y= myVar,color=genotype)) + geom_boxplot() + geom_point(position=position_jitterdodge(dodge.width=0.75)) + coord_cartesian(ylim = c(0, 1.05 * max(myVar, na.rm=TRUE))) + theme_classic() + theme(axis.text.x = element_text(angle = 45, hjust = 1))  + ylab("photoreceptor")

#ggsave("1F1.pdf")

# see also https://www.datacamp.com/community/tutorials/15-questions-about-r-plots
# and https://www.rstudio.com/wp-content/uploads/2015/03/ggplot2-cheatsheet.pdf


# if you have two factors, eg two UAS lines, or age and genotype something like this:
xx$age <- as.factor(xx$age) #if the no of df is wrong, age may be trweated as numeric
attach(xx) # need to reattach the data it seems
myANOVA= aov(X1F1 ~ l2*s15)
summary(myANOVA)
TukeyHSD(myANOVA)

myANOVA= aov(X2F1 ~ l2*s15)
summary(myANOVA)
TukeyHSD(myANOVA)

kruskal.test(myVar~genotype)
pairwise.wilcox.test(xx$X1F1, xx$genotype, p.adjust.method = "BH")

xxSE=summarySE(xx, measurevar= "X1F1", groupvars=c("l2","s15"),na.rm=TRUE)
xxSE

ggplot(xx, aes(x=s15,y= X1F1,color=l2,group= interaction(s15,l2))) + geom_boxplot(outlier.shape = NA) + geom_point(position=position_jitterdodge(jitter.width = 0.20))
+ coord_cartesian(ylim = c(0, 1.05 * max(X1F1, na.rm=TRUE)))
+ theme(axis.text.x = element_text(angle = 45, hjust = 1))

myVar <- X2F1
ggplot(r3, aes(x=g2,y= myVar,color=disco,group= interaction(g2,disco))) + geom_boxplot(outlier.shape = NA) + geom_point(position=position_jitterdodge(jitter.width = 0.20)) + coord_cartesian(ylim = c(0, 1.05 * max(myVar, na.rm=TRUE))) +theme_classic() + theme(axis.text.x = element_text(angle = 45, hjust = 1)) + xlab("") + ylab("lamina neuron") 

#line graph
ggplot(xxSE, aes(x = age, y = X1F1_masked, colour = genotype))+
+   geom_line(stat='identity', position=dodge) + geom_errorbar(limits, position=dodge, width=0.25) + geom_point(shape=2, position=dodge)

#age v genotype; note this is 95% CI
limits = aes(ymax = X2F1_masked + (1.96*se), ymin= X2F1_masked - (1.96*se))
dodge <- position_dodge(width=0.25)
ggplot(xxSE, aes(x = age, y = X2F1_masked, colour = genotype)) +
geom_line(aes(linetype=genotype), size=1, position=dodge) + geom_errorbar(limits, position=dodge, width=0.25) + geom_point(position=dodge) +
scale_colour_manual(values=c("#FF00FF", "#0000FF", "#00FF00","#FF00FF", "#0000FF", "#00FF00"))+ scale_linetype_manual(values = c(1,1,3,3,3,1))

#same with SE, and linestyle according to TNT
xxSE=summarySE(xx, measurevar= "X2F1_masked", groupvars=c("genotype","age","hasTNT"))
limits = aes(ymax = X2F1_masked + se, ymin= X2F1_masked - se)
ggplot(xxSE, aes(x = age, y = X2F1_masked, colour = genotype)) +
geom_line(aes(linetype=hasTNT), size=1, position=dodge) + geom_errorbar(limits, position=dodge, width=0.25) + geom_point(position=dodge) +
scale_colour_manual(values=c("#FF00FF", "#0000FF", "#00FF00","#FF00FF", "#0000FF", "#00FF00"))
xxSE


xx$Gal4 <- substr(xx$genotype,1,3)
xx$G2 <- substr(xx$genotype, regexpr(" R", xx$genotype),1111) # 1111 is the max length
xx$G2 <- sub('1 female fly blue N', '', xx$G2)
ggplot(xx, aes(x=G2,y= X2F1,color=Gal4,group= interaction(Gal4,G2))) + geom_boxplot(outlier.shape = NA) + geom_point(position=position_jitterdodge(jitter.width = 0.20)) + theme(axis.text.x = element_text(angle = 45, hjust = 1)) + xlab("")


> # The colour blind friendly palette with black:
cbbPalette <- c("#000000", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")

ggplot(dc, aes(x=cell.group,y= neurons,color=status, group=interaction(cell.group,status))) + geom_boxplot() + geom_point(position=position_jitterdodge(dodge.width=0.75)) + coord_cartesian(ylim = c(0, 1.05 * max(neurons))) + theme(axis.text.x = element_text(angle = 45, hjust = 1)) + theme_classic() + ylab("neuron count") + scale_colour_manual(values=cbbPalette)


cbbPalette <- c("springgreen4", "magenta", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")
ggplot(myData, aes(x=g2,y= myVar,color=disco,group= interaction(g2,disco))) + geom_boxplot(outlier.shape = NA) + geom_point(position=position_jitterdodge(jitter.width = 0.20)) + coord_cartesian(ylim = c(0, 1.05 * max(myVar, na.rm=TRUE))) +theme_classic() + theme(axis.text.x = element_text(angle = 45, hjust = 1)) + xlab("") + ylab("photoreceptors") + scale_colour_manual(values=cbbPalette)

M <- cbind(X1F1,X2F1)
fit = manova(M~genotype)
summary(fit)
summary.aov(fit)

          Df Pillai approx F num Df den Df    Pr(>F)    
genotype   3 1.1181   14.793      6     70 7.766e-11 ***
Residuals 35                                            
---
Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1


 Response X1F1 :
            Df Sum Sq Mean Sq F value    Pr(>F)    
genotype     6 374224   62371  8.8956 1.331e-07 ***
Residuals   89 624015    7011                      
---
Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

 Response X2F1 :
            Df Sum Sq Mean Sq F value    Pr(>F)    
genotype     6  93955 15659.2  9.7106 3.279e-08 ***
Residuals   89 143521  1612.6                      
---
Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1


> n_fun <- function(x){
+   return(data.frame(y = median(x) * 0.92, label = paste0("N = ",length(x))))
+ }
> ggplot(sc, aes(x=genotype,y=myVar,color= R, na.rm=TRUE)) + geom_boxplot(fill='light grey') + geom_point(position=position_jitterdodge(dodge.width=0.1)) +  coord_cartesian(ylim = c(0, 1.05 * max(myVar, na.rm=TRUE))) + theme_classic() + ylab('period (h)') + stat_summary(fun.data = n_fun, geom = "text")
> 

library(ggpubr)

> n_fun <- function(x){
    return(data.frame(y = median(x) * 0.92, label = paste0("N = ",length(x))))
  }
> 
> 
> ggboxplot(sc, x = "genotype", y = "myVar",
           color = "R", palette = "jco",
           add = "jitter") + stat_compare_means(comparisons=my_comparisons) + ylab('period (h)') + coord_cartesian(ylim = c(0, 1.05 * max(myVar, na.rm=TRUE))) +  stat_summary(fun.data = n_fun, geom = "text")
           
ggboxplot(sc, x = "genotype", y = "myVar",
+           color = "genotype", palette= c("darkorange", "magenta","firebrick","green"),
+           add = "jitter") +  ylab('power') + coord_cartesian(ylim = c(0, 1.05 * max(myVar, na.rm=TRUE))) +  stat_summary(fun.data = n_fun, geom = "text") + theme(legend.position="none")
> 

install.packages("multcomp")
library('multcomp')
Rab3$g2 <- relevel(Rab3$g2,"THG w")
model = lm(X1F1 ~ g2, data=Rab3)
mc = glht(model, mcp(g2 = "Dunnett"))
summary(mc)

model = lm(X2F1 ~ g2, data=Rab3)
mc = glht(model, mcp(g2 = "Dunnett"))
summary(mc)
confint(mc, level = 0.95)

bUpper <- function(N_pass, N_total) {
	# calculate % error at 95% CI
	b <- binom.test(N_pass, N_total)
	bUpper <- 100 * (b$conf.int[2]-b$estimate[1])
	bUpper[[1]]
	}
