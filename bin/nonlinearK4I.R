#!/usr/bin/env Rscript

# nonlinear.R
#
# Script to create a table of nonlinear tests for each scenario
#
# Gary Polhill, 20 June 2012

# Copyright (C) 2012  The James Hutton Institute
#
# This script is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the Licence, or
# (at your option) any later version
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

args <- commandArgs(TRUE)
require(mgcv)

if(length(args) < 2) {
  print("Usage: nonlinear.R <results CSV file> <table CSV file to create>",
        quote = FALSE)
  q(status = 1)
}

scenario.gam.list <- function(scenario, data = NA, explanatory.var = NA, response.var = NA, big.k = 40) {
  subdata <- subset(data, Scenario == scenario, select = c(explanatory.var, response.var))
  names(subdata) <- c("explanatory", "response")
  a.lm <- with(subdata, lm(response ~ explanatory))
  a.gam <- with(subdata, gam(response ~ s(explanatory),
                             family = poisson(link = "log")))
  a.gam.k <- with(subdata, gam(response ~ s(explanatory, k = big.k),
                               family = poisson(link = "log")))
  a.gam.ml <- with(subdata, gam(response ~ s(explanatory), method = "ML",
                                family = poisson(link = "log")))
  a.gam.klm <- with(subdata, gam(response ~ s(explanatory, k = 4),
                               family = poisson(link = "log")))

  # Shouldn't this predict over a uniform sample in the explanatory variable?
  # A: not for computing SSQ, but yes for computing model difference
  pred.lm <- with(subdata, predict(a.lm))
  pred.gam <- with(subdata, predict(a.gam, type = "response"))
  pred.gam.k <- with(subdata, predict(a.gam.k, type = "response"))
  pred.gam.ml <- with(subdata, predict(a.gam.ml, type = "response"))
  pred.gam.klm <- with(subdata, predict(a.gam.klm, type = "response"))

  min.exp <- min(subdata$explanatory)
  max.exp <- max(subdata$explanatory)
  
  pred2.points <- data.frame(explanatory = ((0:10000) / 10000) * (max.exp - min.exp))
  pred2.lm <- predict(a.lm, pred2.points, type = "response", se.fit = T)
  pred2.gam <- predict(a.gam, pred2.points, type = "response", se = T)
  pred2.gam.k <- predict(a.gam.k, pred2.points, type = "response", se = T)
  pred2.gam.ml <- predict(a.gam.ml, pred2.points, type = "response", se = T)
  pred2.gam.klm <- predict(a.gam.klm, pred2.points, type = "response", se = T)

  ssq.lm <- sum((pred.lm - subdata$response)^2)
  ssq.gam <- sum((pred.gam - subdata$response)^2)
  ssq.gam.k <- sum((pred.gam.k - subdata$response)^2)
  ssq.gam.ml <- sum((pred.gam.ml - subdata$response)^2)
  ssq.gam.klm <- sum((pred.gam.klm - subdata$response)^2)

  aic.lm <- AIC(a.lm)
  aic.gam <- AIC(a.gam)
  aic.gam.k <- AIC(a.gam.k)
  aic.gam.ml <- AIC(a.gam.ml)
  aic.gam.klm <- AIC(a.gam.klm)

  bic.lm <- AIC(a.lm, k = log(nrow(subdata)))
  bic.gam <- AIC(a.gam, k = log(nrow(subdata)))
  bic.gam.k <- AIC(a.gam.k, k = log(nrow(subdata)))
  bic.gam.ml <- AIC(a.gam.ml, k = log(nrow(subdata)))
  bic.gam.klm <- AIC(a.gam.klm, k = log(nrow(subdata)))

  s.gam <- summary(a.gam)
  s.gam.k <- summary(a.gam.k)
  s.gam.ml <- summary(a.gam.ml)
  s.gam.klm <- summary(a.gam.klm)

  anova.lm <- anova(a.lm, a.gam, test = "Chisq")
  anova.gam.k <- anova(a.gam.k, a.gam, test = "Chisq")
  anova.gam.ml <- anova(a.gam.ml, a.gam, test = "Chisq")
  anova.gam.klm <- anova(a.gam.klm, a.gam, test = "Chisq")

#  print(anova.gam.k)

  diff.lm <- sum((pred2.lm$fit - pred2.gam$fit)^2)
  diff.gam.k <- sum((pred2.gam.k$fit - pred2.gam$fit)^2)
  diff.gam.ml <- sum((pred2.gam.ml$fit - pred2.gam$fit)^2)
  diff.gam.klm <- sum((pred2.gam.klm$fit - pred2.gam$fit)^2)

  print(paste("Done scenario", scenario, sep = " "), quote = F)
  
  list(scenario = scenario, aic.gam = aic.gam, bic.gam = bic.gam, ssq.gam = ssq.gam,
       edf.gam = sum(a.gam$edf), smooth.gam.P = s.gam$s.pv,
       score.gam = a.gam$gcv.ubre, dev.expl.gam = s.gam$dev.expl,
       aic.gam.k = aic.gam.k, bic.gam.k = bic.gam.k, ssq.gam.k = ssq.gam.k,
       edf.gam.k = sum(a.gam.k$edf), smooth.gam.k.P = s.gam.k$s.pv,
       score.gam.k = a.gam.k$gcv.ubre, dev.expl.gam.k = s.gam.k$dev.expl,
       aic.gam.ml = aic.gam.ml, bic.gam.ml = bic.gam.ml, ssq.gam.ml = ssq.gam.ml,
       edf.gam.ml = sum(a.gam.ml$edf), smooth.gam.ml.P = s.gam.ml$s.pv,
       score.gam.ml = a.gam.ml$gcv.ubre, dev.expl.gam.ml = s.gam.ml$dev.expl,
       aic.gam.klm = aic.gam.klm, bic.gam.klm = bic.gam.klm, ssq.gam.klm = ssq.gam.klm,
       edf.gam.klm = sum(a.gam.klm$edf), smooth.gam.klm.P = s.gam.klm$s.pv,
       score.gam.klm = a.gam.klm$gcv.ubre, dev.expl.gam.klm = s.gam.klm$dev.expl,
       aic.lm = aic.lm, bic.lm = bic.lm, ssq.lm = ssq.lm,
       diff.gam.k = diff.gam.k, diff.gam.ml = diff.gam.ml, diff.gam.klm = diff.gam.klm,
       diff.lm = diff.lm,
       anova.gam.k.P = anova.gam.k$P[2], anova.gam.ml.P = anova.gam.ml$P[2],
       anova.gam.klm.P = anova.gam.klm$P[2], anova.lm.P = anova.lm$P[2])
}

data <- read.table(args[1], header = T, sep = ",")
scenarios <- sort(as.vector(unique(data$Scenario)))
list.of.lists <- lapply(scenarios, scenario.gam.list, data = data, explanatory.var = "Incentive", response.var = "Richness")
rtable <- do.call(rbind, lapply(list.of.lists, data.frame))
write.table(rtable, args[2], quote = F, sep = ",", row.names = F)
q(status = 0)
