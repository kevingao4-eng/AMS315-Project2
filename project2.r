# AMS 315 – Project 2
# Multiple Regression Computing Project
# Student ID suffix: 785838
#
# This script performs:
# - Correlation screening
# - Box-Cox transformation
# - Interaction modeling
# - Nonlinear terms
# - Model selection using regsubsets
# - Final model inference and ANOVA
# ============================================================

# --------------------
# Load required libraries
# --------------------
library(leaps)
library(knitr)
library(MASS)

# --------------------
# Read data
# --------------------
Dat <- read.csv("P2_785838.csv", header = TRUE)
str(Dat)

# --------------------
# Correlation screening
# --------------------
cor_all <- cor(
  Dat$Y,
  Dat[, c("E1", "E2", "E3", "E4", paste0("G", 1:20))]
)
print(round(cor_all, 3))

# --------------------
# Environmental-only model
# --------------------
M_E <- lm(Y ~ E1 + E2 + E3 + E4, data = Dat)
summary(M_E)
summary(M_E)$adj.r.squared

# --------------------
# Full interaction model (raw scale)
# --------------------
M_raw <- lm(
  Y ~ (E1 + E2 + E3 + E4 +
         G1 + G2 + G3 + G4 + G5 + G6 + G7 + G8 + G9 + G10 +
         G11 + G12 + G13 + G14 + G15 + G16 + G17 + G18 + G19 + G20)^2,
  data = Dat
)

plot(resid(M_raw) ~ fitted(M_raw), main = "Residual Plot (Raw Model)")
boxcox(M_raw)

# --------------------
# Box-Cox transformed model
# --------------------
M_trans <- lm(
  I(Y^.5) ~ (E1 + E2 + E3 + E4 +
               G1 + G2 + G3 + G4 + G5 + G6 + G7 + G8 + G9 + G10 +
               G11 + G12 + G13 + G14 + G15 + G16 + G17 + G18 + G19 + G20)^2,
  data = Dat
)

summary(M_raw)$adj.r.squared
summary(M_trans)$adj.r.squared

plot(resid(M_trans) ~ fitted(M_trans),
     main = "Residual Plot (Transformed Model)")

# --------------------
# Add nonlinear terms
# --------------------
Dat$E2_sq <- Dat$E2^2
Dat$E4_sqrt <- Dat$E4^0.5

M_trans_nonlin <- lm(
  I(Y^.5) ~ (E1 + E2 + E2_sq + E3 + E4 + E4_sqrt +
               G1 + G2 + G3 + G4 + G5 + G6 + G7 + G8 + G9 + G10 +
               G11 + G12 + G13 + G14 + G15 + G16 + G17 + G18 +
               G19 + G20)^2,
  data = Dat
)

cat("Transformed model adj.R²:",
    summary(M_trans)$adj.r.squared, "\n")
cat("With nonlinear terms adj.R²:",
    summary(M_trans_nonlin)$adj.r.squared, "\n")

# --------------------
# Variable selection using regsubsets
# --------------------
M <- regsubsets(
  model.matrix(M_trans)[, -1],
  I((Dat$Y)^.5),
  nbest = 1,
  nvmax = 5,
  method = "forward",
  intercept = TRUE
)

temp <- summary(M)
Var <- colnames(model.matrix(M_trans))

M_select <- apply(
  temp$which,
  1,
  function(x) paste0(Var[x], collapse = "+")
)

kable(
  data.frame(
    model = M_select,
    adjR2 = temp$adjr2,
    BIC = temp$bic
  ),
  caption = "Model Selection Summary"
)

# --------------------
# Main-effects model
# --------------------
M_main <- lm(
  I(Y^.5) ~ E1 + E2 + E3 + E4 +
    G1 + G2 + G3 + G4 + G5 + G6 + G7 + G8 + G9 + G10 +
    G11 + G12 + G13 + G14 + G15 + G16 + G17 + G18 + G19 + G20,
  data = Dat
)

temp <- summary(M_main)

kable(
  temp$coefficients[abs(temp$coefficients[, 4]) <= 0.001, ],
  caption = "Significant Coefficients (Bonferroni-Style Filter)"
)

# --------------------
# Two-stage interaction model
# --------------------
M_2stage <- lm(I(Y^.5) ~ (E1 + E2 + G2 + G13)^2, data = Dat)
temp <- summary(M_2stage)

kable(
  temp$coefficients[abs(temp$coefficients[, 3]) >= 4, ],
  caption = "Strong Interaction Effects"
)

# --------------------
# Final model
# --------------------
M_final <- lm(I(Y^.5) ~ E1 + E2 + G2:G13, data = Dat)
summary(M_final)

anova_final <- anova(M_final)
kable(anova_final, caption = "ANOVA for Final Model")

# --------------------
# Test gene interaction contribution
# --------------------
M_env <- lm(I(Y^.5) ~ E1 + E2, data = Dat)

anova_env_vs_final <- anova(M_env, M_final)
kable(
  anova_env_vs_final,
  caption = "Test That G2 × G13 Adds Beyond E1 and E2"
)

# --------------------
# Final coefficients
# --------------------
coef_final <- summary(M_final)$coefficients
kable(
  coef_final,
  caption = "Estimated Coefficients for Final Model"
)
