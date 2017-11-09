hh<-read.table("1F1rawdata.csv",sep=",",header=T)
hh

#x<-hh[,1] # time
#y<-hh[,3] # 1F1 of scarlet
#y<-hh[,4] # 1F1 of clkjrk

x<-hh[7:18,1] # just do the DD section...
y<-hh[7:18,4] 
# y<-hh[7:18,3] # for scarlet


#Part one : measure the residual in a 'lm' fit and find its approximate minimum
f <- function( omega ) { #
   x1 <- sin( omega * x )#
   x2 <- cos( omega * x )#
   r <- lm( y ~ x1 + x2 )#
   res <- mean( residuals(r)^2 )#
   attr( res, "coef" ) <- coef(r)#
   res#
 }#

omegas <- seq( .001, 0.5, length=1000 )
res <- sapply(omegas, f)#
plot( #
   omegas*24/(2*3.14), res,#
   las=1, type="n", ylim=c(0,3.5),xlim=c(0.5,1.7),#
   ylab = "cj Residuals", xlab = "period (days)" )
   
lines( #
   omegas*24/(2*3.14), res )   
   
   
#find the minimum 
which(res == min(res), arr.ind = TRUE)
omega_start <- res[which(res == min(res), arr.ind = TRUE)]
omega_start

#Part two : do the nls fit

fit<-nls(y~C+alpha*sin(W*x)+beta*cos(W*x), start=list(C=9.6, alpha=4.8, beta=4.8, W= omega_start))
summary(fit)





   