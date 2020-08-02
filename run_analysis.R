
packages <- c("data.table", "reshape2", "dplyr")
sapply(packages, require, character.only=TRUE, quietly=TRUE)
path <- getwd()

projectDataPath <- file.path(path, "project_data")
fileCount <- length(list.files(projectDataPath, recursive=TRUE))
if (fileCount != 28) {
  stop("Please use setwd() to the root of the cloned repository.")
}

dtTrainingSubjects <- fread(file.path(projectDataPath, "train", "subject_train.txt"))
dtTestSubjects  <- fread(file.path(projectDataPath, "test" , "subject_test.txt" ))

dtTrainingActivity <- fread(file.path(projectDataPath, "train", "Y_train.txt"))
dtTestActivity  <- fread(file.path(projectDataPath, "test" , "Y_test.txt" ))

dtTrainingMeasures <- data.table(read.table(file.path(projectDataPath, "train", "X_train.txt")))
dtTestMeasures  <- data.table(read.table(file.path(projectDataPath, "test" , "X_test.txt")))


dtSubjects <- rbind(dtTrainingSubjects, dtTestSubjects)
setnames(dtSubjects, "V1", "subject")

dtActivities <- rbind(dtTrainingActivity, dtTestActivity)
setnames(dtActivities, "V1", "activityNumber")

dtMeasures <- rbind(dtTrainingMeasures, dtTestMeasures)

dtSubjectActivities <- cbind(dtSubjects, dtActivities)
dtSubjectAtvitiesWithMeasures <- cbind(dtSubjectActivities, dtMeasures)

setkey(dtSubjectAtvitiesWithMeasures, subject, activityNumber)

dtAllFeatures <- fread(file.path(projectDataPath, "features.txt"))
setnames(dtAllFeatures, c("V1", "V2"), c("measureNumber", "measureName"))

dtMeanStdMeasures$measureCode <- dtMeanStdMeasures[, paste0("V", measureNumber)]

dtSubjectActivitesWithMeasuresMeanStd <- subset(dtSubjectAtvitiesWithMeasures, 
                                                select = columnsToSelect)

dtActivityNames <- fread(file.path(projectDataPath, "activity_labels.txt"))
setnames(dtActivityNames, c("V1", "V2"), c("activityNumber", "activityName"))

dtSubjectActivitesWithMeasuresMeanStd <- merge(dtSubjectActivitesWithMeasuresMeanStd, 
                                               dtActivityNames, by = "activityNumber", 
                                               all.x = TRUE)
                                               
setkey(dtSubjectActivitesWithMeasuresMeanStd, subject, activityNumber, activityName)

dtSubjectActivitesWithMeasuresMeanStd <- data.table(melt(dtSubjectActivitesWithMeasuresMeanStd, 
                                                         id=c("subject", "activityName"), 
                                                         measure.vars = c(3:68), 
                                                         variable.name = "measureCode", 
                                                         value.name="measureValue"))

dtSubjectActivitesWithMeasuresMeanStd <- merge(dtSubjectActivitesWithMeasuresMeanStd, 
                                               dtMeanStdMeasures[, list(measureNumber, measureCode, measureName)], 
                                               by="measureCode", all.x=TRUE)

dtSubjectActivitesWithMeasuresMeanStd$activityName <- 
  factor(dtSubjectActivitesWithMeasuresMeanStd$activityName)
dtSubjectActivitesWithMeasuresMeanStd$measureName <- 
  factor(dtSubjectActivitesWithMeasuresMeanStd$measureName)

# Reshape the data to get the averages 
measureAvgerages <- dcast(dtSubjectActivitesWithMeasuresMeanStd, 
                          subject + activityName ~ measureName, 
                          mean, 
                          value.var="measureValue")

# Write the tab delimited file
write.table(measureAvgerages, file="tidyData.txt", row.name=FALSE, sep = "\t")
