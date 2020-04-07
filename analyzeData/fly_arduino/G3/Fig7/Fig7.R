dan <- read.table(pipe("pbpaste"), sep="\t", header=T, na.strings=c(""))
head(dan)


cbbPalette <- c("#AAAAAA", "#E69F00", "#56B4E9", "#009E73", "#F0E442")
#remove TH data, just use DDC
ddc <- dan[ !(dan$Gal4 %in% "TH"), ]
attach(ddc)


ggplot(ddc, aes(x=cell.group,y=percent_left,fill= Gal4)) + 
  geom_boxplot(fill='grey', colour='black', outlier.shape = NA) + 
  geom_jitter(colour="blue", alpha=0.5, width=0.1) + 
  coord_cartesian(ylim = c(0, 105)) + 
  theme_classic() + theme(legend.position = "none") +
  ylab("Percentage of neurons left in old flies, mean ± SE") + xlab('Cell group')

# ggplot(ddc, aes(x= cell.group, y=percent_left, fill= cell.group)) + 
  # geom_jitter(colour="blue", alpha=0.5, width=0.1) +
  # geom_point(stat="summary", fun.y="mean", colour='UAS') + 
  # geom_errorbar(stat="summary", fun.data="mean_se",  width=0.25) +
  # theme(axis.text.x = element_text(angle = 45, hjust = 1)) + 
  # coord_cartesian(ylim = c(0, 105)) +
  # theme(legend.position = "none") +
  # ylab("Percentage of neurons left in old flies, mean ± SE") + xlab('')



myANOVA = (aov(data=ddc,formula = percent_left ~ cell.group))
summary(myANOVA)

            # Df Sum Sq Mean Sq F value  Pr(>F)   
# cell.group   4   5069  1267.1   5.233 0.00151 **
# Residuals   45  10897   242.1                   
# ----
# # Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1


TukeyHSD(myANOVA)
  # Tukey multiple comparisons of means
    # 95% family-wise confidence level

# Fit: aov(formula = percent_left ~ cell.group, data = ddc)

# $cell.group
                  # diff       lwr        upr     p adj
# PPL1-PAL    -15.922917 -37.08965  5.243820 0.2225188
# PPL2-PAL    -26.383333 -51.91138 -0.855288 0.0396467
# PPM1/2-PAL  -27.458333 -49.56627 -5.350398 0.0082324
# PPM3-PAL    -32.586667 -55.41964 -9.753689 0.0017566
# PPL2-PPL1   -10.460417 -31.62715 10.706320 0.6281977
# PPM1/2-PPL1 -11.535417 -28.42063  5.349798 0.3111716
# PPM3-PPL1   -16.663750 -34.48774  1.160238 0.0770117
# PPM1/2-PPL2  -1.075000 -23.18294 21.032936 0.9999146
# PPM3-PPL2    -6.203333 -29.03631 16.629645 0.9373457
# PPM3-PPM1/2  -5.128333 -24.06044 13.803772 0.9379789

