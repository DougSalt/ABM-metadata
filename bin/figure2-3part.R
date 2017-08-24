#!/usr/bin/env Rscript

# cmpgam3-5.R
#
# This is a script to analyse the CSV file created by analysege_gp.pl
# from the output created by the runs themselves.
#
# Gary Polhill, 18 March 2011


# Copyright (C) 2011  Macaulay Institute
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
require(mgcv)
require(rpart)

args <- commandArgs(TRUE)
args <- commandArgs(TRUE)

if(length(args) < 3) {
  print(paste("Usage: figure2-3s.R [-showdata] [-plotlm] [-plotgam4] [-bs] <data>",
              "<config file (scenario,x.start,x.finish)> <PDF>"),
        quote = FALSE)
  q(status = 1)
}

showdata <- TRUE
plotlm <- FALSE
plotgam4 <- FALSE
bs <- FALSE
splits <- TRUE
dogam <- FALSE

while(substr(args[1], 1, 1) == "-") {
  opt <- args[1]
  args <- args[2:length(args)]
  if(opt == "-showdata") {
    showdata <- FALSE
  }
  if(opt == "-plotlm") {
    plotlm <- TRUE
  }
  if(opt == "-plotgam4") {
    plotgam4 <- TRUE
  }
  if(opt == "-bs") {
    bs <- TRUE
  }
  if(opt == "-splits") {
    splits <- FALSE
  }
  if(opt == "-dogam") {
    dogam <- TRUE
  }
}

input.file <- args[1]
cfg.file <- args[2]
pdf.file <- args[3]

pdf(pdf.file, width = 2.5, height = 2.5)
#par(mai = c(1, 1, 1, 0), oma = c(2, 2, 2, 2))
par(mar = c(2, 2, 2, 0.3) + 0.1)

# Read the data

print(c("Reading data from", input.file), quote = FALSE)
data <- read.table(input.file, sep = ",", header = TRUE)

print(c("Reading data from", cfg.file), quote = FALSE)
cfg <- read.table(cfg.file, sep = ",", header = TRUE)

names(cfg)

# loop through the subsets

for(j in 1:nrow(cfg)) {

  do.scenario <- as.character(cfg$scenario[j])
  x.start <- cfg$x.start[j]
  x.finish <- cfg$x.finish[j]

  cat("Running scenario", do.scenario, "from", x.start, "to", x.finish, "\n")
  
  subdata <- subset(data, Scenario == do.scenario)
  
  # build the PDF file
  
  attach(subdata)

  if(dogam) {
    if(bs) {
      cat(do.scenario, "bs\n")
      gamwell <- gam(Richness ~ s(Incentive, bs = "ts"), data = subdata,
                     family = poisson(link = "log"))
    } else {
      cat(do.scenario, "\n")
      gamwell <- gam(Richness ~ s(Incentive), data = subdata,
                     family = poisson(link = "log"))
    }
  
    if(bs) {
      gam4well <- gam(Richness ~ s(Incentive, k = 4, bs = "ts"), data = subdata,
                      family = poisson(link = "log"))
    } else {
      gam4well <- gam(Richness ~ s(Incentive, k = 4), data = subdata,
                      family = poisson(link = "log"))
    }
  
    lmwell <- lm(Richness ~ Incentive)
    
    sumwell <- summary(gamwell)
       
    dev.expl <- paste(round(100 * sumwell$dev.expl), "%", sep = "")
    
    pred.points <- data.frame((0:100
                               / (100 / (max(Incentive) - min(Incentive))))
                              + min(Incentive))
    names(pred.points) <- c("Incentive")

  
    predictions <- predict(gamwell, pred.points, type = "response", se = TRUE)
    ucl <- predictions$fit + 1.96 * predictions$se.fit
    lcl <- predictions$fit - 1.96 * predictions$se.fit

    pred.4 <- predict(gam4well, pred.points, type = "response", se = TRUE)
    pred.lm <- predict(lmwell, pred.points, type = "response", se.fit =  T)
  }
  
  sunflowerplot(Incentive, Richness, col = "black", seg.col = "grey40",
                bty = "n", size = 0.04, xlim = c(x.start, x.finish),
                xlab = "Incentive", ylab = "Richness",
                main = do.scenario)

  if(dogam) {
    i.for = order(pred.points$Incentive)
    i.back = order(pred.points$Incentive, decreasing = TRUE)
  }
  
  if(dogam) {
    lines(pred.points$Incentive[i.for], ucl[i.for], lty = "dotted")
    lines(pred.points$Incentive[i.for], lcl[i.for], lty = "dotted")
    
    lines(pred.points$Incentive[i.for], predictions$fit[i.for], lwd = 3)
  }
  
  if(plotlm) {
    lines(pred.points$Incentive[i.for], pred.lm$fit[i.for], lty = "longdash", lwd = 2)
  }
  if(plotgam4) {
    lines(pred.points$Incentive[i.for], pred.4$fit[i.for], lty = "dashed", lwd = 2)
  }

  if(splits) {
    rp <- rpart(Richness ~ Incentive, method = "class")
    p <- predict(rp, newdata = list(Incentive = x.start + (0:((x.finish - x.start) * 10000) / 10000)))
    pp <- vector(length = nrow(p))
    for(i in 1:length(pp)) for(k in 1:length(p[i,])) if(p[i, k] == max(p[i,])) pp[i] = as.numeric(colnames(p)[k])
    lines(x.start + (0:((x.finish - x.start) * 10000) / 10000), pp)
  }

  detach(subdata)
}

print(c("Writing data to", pdf.file), quote = FALSE)

q(status = 0)
