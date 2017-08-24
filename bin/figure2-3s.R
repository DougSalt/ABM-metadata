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

if(length(args) < 8) {
  print(paste("Usage: figure2-3s.R [-showdata] [-plotlm] [-plotgam4] [-bs] <data>",
              "<y-axis> <main scenario> <small scenario 1> <small scenario 2>",
              "<small scenario 3> <small scenario 4> <PDF>"),
        quote = FALSE)
  q(status = 1)
}

showdata <- TRUE
plotlm <- TRUE
plotgam4 <- TRUE
bs <- FALSE
splits <- FALSE

while(substr(args[1], 1, 1) == "-") {
  opt <- args[1]
  args <- args[2:length(args)]
  if(opt == "-showdata") {
    showdata <- FALSE
  }
  if(opt == "-plotlm") {
    plotlm <- FALSE
  }
  if(opt == "-plotgam4") {
    plotgam4 <- FALSE
  }
  if(opt == "-bs") {
    bs <- TRUE
  }
  if(opt == "-splits") {
    splits <- TRUE
  }
}

input.file <- args[1]
y.axis <- args[2]
do.scenarios <- args[3:7]
pdf.file <- args[8]

pdf(pdf.file)
#par(mai = c(1, 1, 1, 0), oma = c(2, 2, 2, 2))

# Read the data

print(c("Reading data from", input.file), quote = FALSE)
data <- read.table(input.file, sep = ",", header = TRUE)

attach(data)
maxy <- max(get(y.axis))
miny <- min(get(y.axis))
detach(data)

scenarios <- sort(as.vector(unique(data$Scenario)))

# loop through the subsets

for(j in 1:length(do.scenarios)) {
  if(j == 2) {
    par(mfrow = c(2, 2))
  }
  subdata <- subset(data, Scenario == do.scenarios[j])
  
  # build the PDF file
  
  attach(subdata)
  
  if(bs) {
    cat(do.scenarios[j], "bs\n")
    gamwell <- gam(get(y.axis) ~ s(Incentive, bs = "ts"), data = subdata,
                   family = poisson(link = "log"))
  } else {
    cat(do.scenarios[j], "\n")
    gamwell <- gam(get(y.axis) ~ s(Incentive), data = subdata,
                   family = poisson(link = "log"))
  }
  
  if(bs) {
    gam4well <- gam(get(y.axis) ~ s(Incentive, k = 4, bs = "ts"), data = subdata,
                    family = poisson(link = "log"))
  } else {
    gam4well <- gam(get(y.axis) ~ s(Incentive, k = 4), data = subdata,
                    family = poisson(link = "log"))
  }
  
  lmwell <- lm(get(y.axis) ~ Incentive)
  
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

  plot(0, type = "n", bty = "n", xlim = c(0, max(Incentive)),
       ylim = c(miny, maxy), xlab = "Incentive", ylab = y.axis,
       main = paste(do.scenarios[j], " (", dev.expl, ")", sep = ""))

  i.for = order(pred.points$Incentive)
  i.back = order(pred.points$Incentive, decreasing = TRUE)

  if(showdata) {
    sunflowerplot(Incentive, get(y.axis), col = "darkgrey", seg.col = "grey",
                  add = TRUE, size = 0.0625)
  }

  lines(pred.points$Incentive[i.for], ucl[i.for], lty = "dotted")
  lines(pred.points$Incentive[i.for], lcl[i.for], lty = "dotted")
    
  lines(pred.points$Incentive[i.for], predictions$fit[i.for], lwd = 3)
  
  if(plotlm) {
    lines(pred.points$Incentive[i.for], pred.lm$fit[i.for], lty = "longdash", lwd = 2)
  }
  if(plotgam4) {
    lines(pred.points$Incentive[i.for], pred.4$fit[i.for], lty = "dashed", lwd = 2)
  }

  if(splits) {
    rp <- rpart(get(y.axis) ~ Incentive, method = "class")
    for(i in rp$splits[,"index"]) lines(c(i, i), c(miny, maxy))
  }

  detach(subdata)
}

print(c("Writing data to", pdf.file), quote = FALSE)

q(status = 0)
