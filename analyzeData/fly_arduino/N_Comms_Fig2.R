#Fig 2A and FigS2
> xx <- read.table(pipe("pbpaste"), sep="\t", header=T, na.strings=c(""), check.names=FALSE)
>  
> head(xx)

library('ggplot2')
library('cowplot')
library(viridis)

p1 <- ggplot(xx, aes(x= two_one,y= two_G1, colour= `group per Zhang`, label=RabNo)) + geom_smooth(aes(x= two_one,y= two_G1),method=lm, inherit.aes=FALSE, fill = 'light grey') + geom_point(shape=21, size=6, stroke=2, fill = 'white') + geom_text(colour='black', size=3, hjust = 'center', vjust = 'middle') + scale_x_log10() + scale_y_log10() + expand_limits(x=c(30,2000), y=c(30,4000)) + theme_classic()  +theme(legend.justification=c(0,0), legend.position=c(0.8,0.8)) + scale_color_manual(values=c('dark green','magenta', 'cyan', 'orange', 'navy', 'lawn green', 'dark red')) + xlab("Effect of Rab (as % of wildtype)") + ylab("Synergistic effect of G2019S (as % of TH > Rab)") + annotation_logticks() + ggtitle("Phylogenetic group") + theme(legend.title=element_blank())

p2 <- ggplot(xx, aes(x= two_one,y= two_G1, colour= `amino acid at active site`, label=RabNo)) + geom_smooth(aes(x= two_one,y= two_G1),method=lm, inherit.aes=FALSE, fill = 'light grey') + geom_point(shape=21, size=6, stroke=2, fill = 'white') + geom_text(colour='black', size=3, hjust = 'center', vjust = 'middle') + scale_x_log10() + scale_y_log10() + expand_limits(x=c(30,2000), y=c(30,4000)) + theme_classic() + theme(legend.justification=c(0,0), legend.position=c(0.8,0.8)) + scale_color_manual(values=c('dark green','magenta', 'cyan')) + xlab("Effect of Rab (as % of wildtype)") + ylab("Synergistic effect of G2019S (as % of TH > Rab)") + annotation_logticks() + ggtitle("Amino acid at active site") + theme(legend.title=element_blank())

p3 <- ggplot(xx, aes(x= two_one,y= two_G1, colour= Shi, label=RabNo)) + geom_smooth(aes(x= two_one,y= two_G1),method=lm, inherit.aes=FALSE, fill = 'light grey') + geom_point(shape=21, size=6, stroke=2, fill = 'white') + geom_text(colour='black', size=3, hjust = 'center', vjust = 'middle') + scale_x_log10() + scale_y_log10() + expand_limits(x=c(30,2000), y=c(30,4000)) + theme_classic() + theme(legend.justification=c(0,0), legend.position=c(0.8,0.8)) + scale_color_manual(values=c('dark green','magenta')) + xlab("Effect of Rab (as % of wildtype)") + ylab("Synergistic effect of G2019S (as % of TH > Rab)") + annotation_logticks() + ggtitle("Link to PD (Shi et al)") + theme(legend.title=element_blank())

p4 <- ggplot(xx, aes(x= two_one,y= two_G1, colour= Steger, label=RabNo)) + geom_smooth(aes(x= two_one,y= two_G1),method=lm, inherit.aes=FALSE, fill = 'light grey') + geom_point(shape=21, size=6, stroke=2, fill = 'white') + geom_text(colour='black', size=3, hjust = 'center', vjust = 'middle') + scale_x_log10() + scale_y_log10() + expand_limits(x=c(30,2000), y=c(30,4000)) + theme_classic() +  theme(legend.justification=c(0,0), legend.position=c(0.8,0.8)) + scale_color_manual(values=c('dark green','magenta', 'cyan')) + xlab("Effect of Rab (as % of wildtype)") + ylab("Synergistic effect of G2019S (as % of TH > Rab)") + annotation_logticks() + ggtitle("Phosphorylated in vitro") + theme(legend.title=element_blank())

p5 <- ggplot(xx, aes(x= two_one,y= two_G1, colour= `Role (Banworth & Lee)`, label=RabNo)) + geom_smooth(aes(x= two_one,y= two_G1),method=lm, inherit.aes=FALSE, fill = 'light grey') + geom_point(shape=21, size=6, stroke=2, fill = 'white') + geom_text(colour='black', size=3, hjust = 'center', vjust = 'middle')  + scale_x_log10() + scale_y_log10() + expand_limits(x=c(30,2000), y=c(30,4000)) + theme_classic() + theme(legend.justification=c(0,0), legend.position=c(0.8,0.8)) + scale_color_manual(values=c('dark green','magenta', 'cyan', 'orange', 'navy', 'lawn green', 'dark red')) + xlab("Effect of Rab (as % of wildtype)") + ylab("Synergistic effect of G2019S (as % of TH > Rab)") + annotation_logticks() + ggtitle("Role (Banworth & Li)") + theme(legend.title=element_blank())



 p <- plot_grid(p3,p1,p2,p4,p5, nrow=3)
   show(p)
   
