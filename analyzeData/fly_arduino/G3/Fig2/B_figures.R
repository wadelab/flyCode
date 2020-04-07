xx <- read.table(pipe("pbpaste"), sep="\t", header=T, na.strings=c(""), check.names=FALSE)
  
head(xx)

library('ggplot2')
library('cowplot')
library(viridis)

resize.win <- function(Width=6, Height=6)
 {
     while (!is.null(dev.list()))  dev.off()
     quartz(width=Width, height=Height)
 }
 resize.win(8,13)


p1 <- ggplot(xx, aes(x= two_one,y= two_G1, colour= `group per Zhang`)) + geom_smooth(aes(x= two_one,y= two_G1),method=lm, inherit.aes=FALSE, fill = 'light grey') + geom_point(size=2) + scale_x_log10() + scale_y_log10() + expand_limits(x=c(30,2000), y=c(30,4000)) + theme_classic()  +theme(legend.justification=c(0,0), legend.position=c(0.8,0.8)) + scale_fill_manual(values=c('dark green','magenta', 'cyan', 'orange', 'navy', 'lawn green', 'dark red')) + xlab("Effect of Rab (as % of wildtype)") + ylab("Synergistic effect of G2019S (as % of TH > Rab)") + annotation_logticks() + ggtitle("Phylogenetic group") + theme(legend.title=element_blank())

p2 <- ggplot(xx, aes(x= two_one,y= two_G1, colour= `amino acid at active site`)) + geom_smooth(aes(x= two_one,y= two_G1),method=lm, inherit.aes=FALSE, fill = 'light grey') + geom_point(size=2) + scale_x_log10() + scale_y_log10() + expand_limits(x=c(30,2000), y=c(30,4000)) + theme_classic()  +theme(legend.justification=c(0,0), legend.position=c(0.8,0.8)) + scale_fill_manual(values=c('dark green','magenta', 'cyan', 'orange', 'navy', 'lawn green', 'dark red')) + xlab("Effect of Rab (as % of wildtype)") + ylab("Synergistic effect of G2019S (as % of TH > Rab)") + annotation_logticks() + ggtitle("Amino acid at active site") + theme(legend.title=element_blank())

p3 <- ggplot(xx, aes(x= two_one,y= two_G1, colour= `Link to PD (Shi et al)`)) + geom_smooth(aes(x= two_one,y= two_G1),method=lm, inherit.aes=FALSE, fill = 'light grey') + geom_point(size=2) + scale_x_log10() + scale_y_log10() + expand_limits(x=c(30,2000), y=c(30,4000)) + theme_classic()  +theme(legend.justification=c(0,0), legend.position=c(0.8,0.8)) + scale_fill_manual(values=c('dark green','magenta', 'cyan', 'orange', 'navy', 'lawn green', 'dark red')) + xlab("Effect of Rab (as % of wildtype)") + ylab("Synergistic effect of G2019S (as % of TH > Rab)") + annotation_logticks() + ggtitle("Link to PD (Shi et al)") + theme(legend.title=element_blank())

p4 <- ggplot(xx, aes(x= two_one,y= two_G1, colour= Steger)) + geom_smooth(aes(x= two_one,y= two_G1),method=lm, inherit.aes=FALSE, fill = 'light grey') + geom_point(size=2) + scale_x_log10() + scale_y_log10() + expand_limits(x=c(30,2000), y=c(30,4000)) + theme_classic()  +theme(legend.justification=c(0,0), legend.position=c(0.8,0.8)) + scale_fill_manual(values=c('dark green','magenta', 'cyan', 'orange', 'navy', 'lawn green', 'dark red')) + xlab("Effect of Rab (as % of wildtype)") + ylab("Synergistic effect of G2019S (as % of TH > Rab)") + annotation_logticks() + ggtitle("Phosphorylated in vitro") + theme(legend.title=element_blank())

p5 <- ggplot(xx, aes(x= two_one,y= two_G1, colour= `Role (Banworth & Lee)`)) + geom_smooth(aes(x= two_one,y= two_G1),method=lm, inherit.aes=FALSE, fill = 'light grey') + geom_point(size=2) + scale_x_log10() + scale_y_log10() + expand_limits(x=c(30,2000), y=c(30,4000)) + theme_classic()  +theme(legend.justification=c(0,0), legend.position=c(1.3,0.3)) + scale_fill_manual(values=c('dark green','magenta', 'cyan', 'orange', 'navy', 'lawn green', 'dark red')) + xlab("Effect of Rab (as % of wildtype)") + ylab("Synergistic effect of G2019S (as % of TH > Rab)") + annotation_logticks() + ggtitle("Role (Banworth & Lee)") + theme(legend.title=element_blank())



p <- plot_grid(p3,p1,p2,p4,p5, nrow=3)
show(p)

#save here or elsewhere: 
#ggsave('/Users/chris/git/flyCode/analyzeData/fly_arduino/G3/Fig2/Rplot.pdf')