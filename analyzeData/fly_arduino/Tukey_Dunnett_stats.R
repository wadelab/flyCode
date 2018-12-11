
TH <- read.table(pipe("pbpaste"), sep="\t", header=T, na.strings=c(""))
head (TH)
THS<- stack(TH)

THS_y <-THS[- grep("..N", THS$ind),]
THS_n <-THS[- grep("..Y", THS$ind),]


THS_NN <- na.omit(THS_n)
THS_YY <- na.omit(THS_y)


myANOVA= aov(data=THS_NN, values ~ ind)
summary(myANOVA)
TukeyHSD(myANOVA)

myANOVA= aov(data=THS_YY, values ~ ind)
summary(myANOVA)
TukeyHSD(myANOVA)

levels(THS_YY$ind)

THS_YY$ind <- relevel(THS_YY$ind,"THG.w..Y")
levels(THS_YY$ind)

library('multcomp')
model = lm(values ~ ind, data=THS_YY)
mc = glht(model, mcp(ind = "Dunnett"))
summary(mc)

THS_YY$ind <- relevel(THS_YY$ind,"TH.w..Y")
levels(THS_YY$ind)

model = lm(values ~ ind, data=THS_YY)
mc = glht(model, mcp(ind = "Dunnett"))
summary(mc)