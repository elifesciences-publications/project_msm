library(lme4)
library(lmerTest)
library(readr)
library(emmeans)

# read in data from 4-way ANOVA with between-subject and within-subject factors
df_full <- read_csv("/Users/neichert/scratch/MSMstuff/targets_L.csv")

# with crossed-random effects
my_model_fit <- lmer(value ~ species * tract + (1|p_h/p_s), df_full, contrasts = list(species = "contr.sum", tract = "contr.sum"))

# display results of linear regression
summary(my_model_fit)
# main and interaction effects
anova(my_model_fit)
# random effects
rand(my_model_fit)

# post-hoc t-test for tracts
emmeans(my_model_fit, list(pairwise ~ tract * species), adjust = "tukey")
# post-hoc t-test for all combinations
emmeans(my_model_fit, list(pairwise ~ tract), adjust = "tukey")

# access underlying model for fixed effects
my_glm_fe = model.matrix(my_model_fit)
# access underlying model for random effects
my_glm_re = as.matrix(getME(my_model_fit, "Zt"))

# inspect matrices
image(t(my_glm_fe))
image(t(my_glm_re))

write.table(my_glm_fe, file = "/rootdir/palm_GLM/my_glm_fe.csv", row.names=FALSE, quote=FALSE)
write.table(t(my_glm_re), file = "/rootdir/palm_GLM/my_glm_re.csv", row.names=FALSE, quote=FALSE)
