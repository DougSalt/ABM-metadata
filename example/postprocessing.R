#!/usr/bin/Rscript

# A small R script that emaulates what Gary did with the outputs from
# the model in an R script. That is it reconsturcts what he did
# originally in what we presume was an interactive R
# session. Essentially this scrpt takes the combined results from the
# model and:

# 1. Adds two empty columns TSNE.1.X and TSNE.1.Y - this were going to
# be used for visulisation of the data, but were late abaondoned. The
# columns have been retained, so that they do not mess up any
# subsequent programs that use the output.
# 2, Adds an incentive column.
# 3. Removes the high bankruptcy rates.
# 4. Removes high expenditure.

# Author: Doug Salt

# Date: June 2016

# Version: 1.0

# Licence: GPLv3

args <- commandArgs(TRUE)
results <- read.csv(args[1])
results[,"TSNE.1.X"] <- rep.int(0, nrow(results))
results[,"TSNE.1.Y"] <- rep.int(0, nrow(results))
results$Incentive <- ifelse(substr(results$Government, 1, 7) == "Cluster",
                           results$Reward / results$Ratio, results$Reward)

scenarios <- read.csv(args[2])
merged <- merge(results,scenarios)

merged.without.high.bankruptcy <- subset(merged,
	as.numeric(as.character(Bankruptcies)) <= 0.1)
merged.without.high.expenditure <-
	subset(merged.without.high.bankruptcy, 
	as.numeric(as.character(Expenditure)) < 2500000)

write.csv(merged.without.high.expenditure,args[3],row.names=FALSE)
