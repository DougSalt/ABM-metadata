#!/usr/bin/env Rscript

# Author: Doug Salt

# Date: June 2016

# Version 1.0

# Licence GPLv3

# A small script to prodce a text version of the table found in 

# Polhil et al (2013) - Nonlinearities in biodiversity incentive schemes: A study using an integrated agent-based and metacommunity model
# The original diagram was done with a mixture of R and Excel. I have automated
# this part.

args <- commandArgs(TRUE)

table <- read.csv(args[1])

results <- data.frame(as.character(table$scenario))

results$Deviance <- round(as.numeric(table$dev.expl.gam) * 100)
results$Test1 <- ifelse(table$edf.gam  > 3.0 & 
	                table$smooth.gam.P <= 0.0001, c('*'), c('-'))
results$Test2 <- ifelse(table$anova.gam.klm.P < 0.0001 & 
	                table$diff.gam.klm > 10000 & 
	                table$ssq.gam < table$ssq.gam.klm,c("*"),c("-"))
results$Test3 <- ifelse(table$aic.gam <= table$aic.gam.klm - 2, c("*"),c("-"))
results$Test4 <- ifelse(table$anova.lm.P < 0.0001 &
		        table$diff.lm > 10000.0 &
		        table$ssq.gam < table$ssq.lm, c("*"),c("-"))
results$Test5 <- ifelse(table$aic.gam <= table$aic.lm - 2, c("*"),c("-"))
write.csv(results,args[2],row.names = FALSE)
