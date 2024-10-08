% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Functions.R
\name{SurvMA.Fit}
\alias{SurvMA.Fit}
\title{Model averaging prediction of personalized survival probabilities (model fitting)}
\usage{
SurvMA.Fit(
  formula,
  sdata,
  submodel = c("PL", "TVC"),
  continuous = NULL,
  control = list(K.set = c(5:10), criterion = "AIC", method = "KM")
)
}
\arguments{
\item{formula}{a formula expression, of the form \code{response ~ predictors}.
The \code{response} is a \code{Surv} object (from R package "survival") with right censoring.
It is used to specify the included covariates (risk factors).
See the documentation for \code{survreg} and \code{Surv} in R package \code{survival} for details.
The expression to the right of the "~" specifies the covariates.}

\item{sdata}{a survival dataset (dataframe) in which to interpret the variables named in the \code{formula} and the \code{cureform}.}

\item{submodel}{a character string defining the groups of candidate models, as introduced.
It can be \code{"PL"} for partial linear Cox models or \code{"TVC"} for time varying coefficient Cox models.}

\item{continuous}{a vector of integers representing the positions of continuous covariates within \code{predictors} specified in \code{formula}.
If \code{submodel="TVC"} is set, this argument is redundant and the default value \code{NULL} is sufficient.}

\item{control}{indicates more detailed control of the underlying model averaging fitting procedures.
It is a list of the following three arguments:
\code{K.set} specifies the range of the number of spline basis functions, with the default being \code{K.set=c(5:10)};
\code{criterion} is a character string that specifies the information criterion for choosing the optimal number of B-spline basis functions and
it can be either the default Akaike Information Criterion (\code{criterion="AIC"}) or the Bayesian Information Criterion (\code{criterion = "BIC"});
\code{method} determines the approach to estimate the survival function of censoring time, which can be \code{method="KM"} to
estimate it via the Kaplan-Meier estimator or \code{method = "Cox"} to estimate it via the Cox proportional hazards model.}
}
\value{
A list of fitted results that contain not only parameter estimates for all candidate models, but also optimal averaging weights (\code{weights}).
}
\description{
Model averaging prediction of personalized survival probabilities (model fitting)
}
\details{
This is a function used to conduct model averaging prediction (model fitting) of personalized survival probabilities.
For obtaining specific predictions of personalized survival probabilities, see another function \code{SurvMA.Predict()}.
The underlying methods are based on the paper titled "Semiparametric model averaging method for survival probability predictions of patients", which has been published in Mengyu Li and Xiaoguang Wang (2023) \url{doi:10.1016/j.csda.2023.107759}.
}
\examples{

#----------------------------------------------------------#
# Basic preparations before running subsequent examples ####
#----------------------------------------------------------#

rm(list=ls(all=TRUE))

## library necessary packages
library(SurvMA)
library(survival)
#'
#--------------------------------------------------------------#
# Simulated dataset: from partial linear additive Cox model ####
#--------------------------------------------------------------#

## Pre-process the dataset

# - load the dataset
data(SimData.APL)
head(SimData.APL,2)

# - split the data into training and test datasets
set.seed(1)
train.index <- sort(sample(1:200,0.75*200))
sdata.train <- SimData.APL[train.index,]
sdata.test  <- SimData.APL[-train.index,]

## Fit the dataset via our model averaging method

# - fit the data using provided R function SurvMA.Fit
set.seed(1)
sol.SurvMA.PL <- SurvMA.Fit(
  formula = Surv(time,delta) ~ X + U1 + U2 + U3 + U4 + U5 + U6,
  sdata = SimData.APL, submodel = "PL", continuous = 2:4
)
print(sol.SurvMA.PL$weights)

\donttest{
# - do prediction using provided R function SurvMA.Predict
predict.SurvMA.PL <- SurvMA.Predict(
  object = sol.SurvMA.PL,
  covariates = sdata.test[,-c(1,2)],
  times = round(quantile(sdata.test$time,c(0.25,0.50,0.75)),2)
)
head(predict.SurvMA.PL$sprobs,2)


#-----------------------------------------------------------#
# Real dataset: using time-varying coefficient Cox model ####
#   - the breast cancer data originally from survival package
#-----------------------------------------------------------#

## Pre-process the dataset

# - load the dataset
data(RealData.ROT)
summary(RealData.ROT$time)
table(RealData.ROT$delta)

# - plot the Kaplan-Meier curve
plot(
  survfit(Surv(time,delta) ~ 1, data = RealData.ROT),
  mark.time = TRUE, conf.int = TRUE, lwd=2,
  xlim = c(0,3200), ylim=c(0.4,1),
  xlab="Time (in Days)", ylab="Estimated Survival Probability"
)

# - test time-varying effects
TVC.Test <- cox.zph(coxph(Surv(time, delta)~., data = RealData.ROT))
print(TVC.Test)
oldpar <- par(mfrow=c(2,3))
plot(
  TVC.Test, resid = FALSE, lwd = 2,
  xlab = "Time (in Days)",
  ylab = paste("Coefficient for",colnames(RealData.ROT)[1:6])
)
par(oldpar)

# - split the data into training and test datasets
set.seed(1)
n <- nrow(RealData.ROT)
train.index <- sort(sample(1:n,0.75*n))
sdata.train <- RealData.ROT[train.index,]
sdata.test  <- RealData.ROT[-train.index,]

## Fit the dataset via our model averaging method

# - fit the data using provided R function SurvMA.Fit
set.seed(1)
sol.SurvMA.ROT <- SurvMA.Fit(
  formula = Surv(time, delta) ~ age + meno + pgr + er + hormon + chemo,
  sdata = sdata.train, submodel = "TVC", continuous = NULL
)
print(sol.SurvMA.ROT$weights)

# - do prediction using provided R function SurvMA.Predict
predict.SurvMA.ROT <- SurvMA.Predict(
  object = sol.SurvMA.ROT, covariates =
    sdata.test[,!(colnames(sdata.test) \%in\% c("time","delta"))],
  times = round(quantile(sdata.test$time,c(0.25,0.50,0.75)))
)
head(predict.SurvMA.ROT$sprobs,2)


#----------------------------------------------------------------#
# Simulated dataset: from time-varying coefficients Cox model ####
#----------------------------------------------------------------#

## Pre-process the dataset

# - load the dataset
data(SimData.TVC)
head(SimData.TVC,2)

# - split the data into training and test datasets
set.seed(1)
train.index <- sort(sample(1:150,0.75*150))
sdata.train <- SimData.TVC[train.index,]
sdata.test  <- SimData.TVC[-train.index,]

## Fit the dataset via our model averaging method

# - fit the data using provided R function SurvMA.Fit
set.seed(1)
sol.SurvMA.TVC <- SurvMA.Fit(
  formula = Surv(time,delta) ~ Z1 + Z2 + Z3 + Z4 + Z5 + Z6,
  sdata = sdata.train, submodel = "TVC", continuous = NULL
)
print(sol.SurvMA.TVC$weights)

# - do prediction using provided R function SurvMA.Predict
predict.SurvMA.TVC <- SurvMA.Predict(
  object = sol.SurvMA.TVC,
  covariates = sdata.test[,-c(1,2)],
  times = round(quantile(sdata.test$time,c(0.25,0.50,0.75)),2)
)
head(predict.SurvMA.TVC$sprobs,2)

}
}
