#Fig 1F Plot and ANOVA
 library('tidyverse')
 stav <- read.table(pipe("pbpaste"), sep="\t", header=T, na.strings=c(""), check.names=FALSE)
 stavs <- stack (stav)
 stavs <- na.omit(stavs)
 stavs$values <- stavs$values/1000
 ggplot(stavs, aes(x=ind, y=values, fill=ind)) + geom_boxplot(width=0.6, position = position_dodge(0.6), outlier.shape = NA) +
        geom_dotplot(binaxis='y', stackdir='center', stackratio=2, dotsize=4, binwidth= 1, position = position_dodge(0.6)) + 
        theme(axis.text.x = element_text(angle = 45, hjust = 1)) + xlab("") + ylab("lamina neuron response (a.u.)") +
        coord_cartesian(ylim = c(0, 1.05 * max(stavs$values))) + scale_fill_manual(values=c("light green","cyan", "grey","magenta"))


 myANOVA= aov(values ~ ind, data=stavs)
  summary(myANOVA)
  TukeyHSD(myANOVA)
  
  
# #1F1
            # Df    Sum Sq   Mean Sq F value   Pr(>F)    
# ind          3 2.110e+10 7.035e+09      24 8.49e-09 ***
# Residuals   37 1.084e+10 2.931e+08                     
# ---
# Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

  # Tukey multiple comparisons of means
    # 95% family-wise confidence level

# Fit: aov(formula = values ~ ind, data = stavs)

# $ind
                                                           # diff       lwr      upr     p adj
# TH_G2019S w 1 female fly blue-TH+ w 1 female fly blue  9596.923 -12666.67 31860.52 0.6556651
# TH Rab7_23641 1-TH+ w 1 female fly blue                2895.492 -19368.10 25159.08 0.9850695
# TH_G2019S Rab7_23641 1-TH+ w 1 female fly blue        54063.769  32163.90 75963.64 0.0000005
# TH Rab7_23641 1-TH_G2019S w 1 female fly blue         -6701.431 -26336.07 12933.21 0.7953905
# TH_G2019S Rab7_23641 1-TH_G2019S w 1 female fly blue  44466.845  25245.61 63688.08 0.0000018
# TH_G2019S Rab7_23641 1-TH Rab7_23641 1                51168.277  31947.04 70389.51 0.0000001

#same for 2F1
            # Df Sum Sq Mean Sq F value  Pr(>F)    
# ind          3  13392    4464   13.12 5.5e-06 ***
# Residuals   37  12590     340                    
# ---
# Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1
# >   TukeyHSD(myANOVA)
  # Tukey multiple comparisons of means
    # 95% family-wise confidence level

# Fit: aov(formula = values ~ ind, data = stavs)

# $ind
                                                          # diff        lwr      upr     p adj
# TH_G2019S w 1 female fly blue-TH w 1 female fly blue  9.332122 -14.657149 33.32139 0.7235807
# TH Rab7_23641 1-TH w 1 female fly blue               20.945814  -3.043457 44.93509 0.1054444
# TH_G2019S Rab7_23641 1-TH w 1 female fly blue        48.186092  24.588737 71.78345 0.0000177
# TH Rab7_23641 1-TH_G2019S w 1 female fly blue        11.613692  -9.542857 32.77024 0.4615235
# TH_G2019S Rab7_23641 1-TH_G2019S w 1 female fly blue 38.853970  18.142872 59.56507 0.0000700
# TH_G2019S Rab7_23641 1-TH Rab7_23641 1               27.240278   6.529180 47.95138 0.0058408

summary.df <- stavs %>%
+  group_by(ind) %>%
+  summarise(Observations = n())
print (summary.df)
# A tibble: 4 x 2
  # ind                           Observations
  # <fct>                                <int>
# 1 TH w 1 female fly blue                   7
# 2 TH_G2019S w 1 female fly blue           11
# 3 TH Rab7_23641 1                         11
# 4 TH_G2019S Rab7_23641 1                  12
