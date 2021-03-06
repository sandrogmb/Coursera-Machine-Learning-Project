---
title: "course project machine learning"
author: "sandro"
date: "15/9/2017"
output: html_document
---

#Executive Summary

Using devices such as Jawbone Up, Nike FuelBand, and Fitbit it is now possible to collect a large amount of data about personal activity relatively inexpensively. These type of devices are part of the quantified self movement - a group of enthusiasts who take measurements about themselves regularly to improve their health, to find patterns in their behavior, or because they are tech geeks. One thing that people regularly do is quantify how much of a particular activity they do, but they rarely quantify how well they do it.

The goal of this project is to use data from accelerometers on the belt, forearm, arm, and dumbell of 6 participants and to predict the manner in which they did the exercise.

The participants were asked to perform barbell lifts correctly and incorrectly in 5 different ways. More information is available from the website here: http://groupware.les.inf.puc-rio.br/har (see the section on the Weight Lifting Exercise Dataset).  

#Data

###Download data
The data for this project come from this source: http://web.archive.org/web/20170809020213/http://groupware.les.inf.puc-rio.br/public/papers/2013.Velloso.QAR-WLE.pdf
```{r download data, include=TRUE, echo=TRUE, eval=TRUE}
download.file(url = "https://d396qusza40orc.cloudfront.net/predmachlearn/pml-training.csv", destfile = "pml.training.csv", method = "curl")

download.file(url = "https://d396qusza40orc.cloudfront.net/predmachlearn/pml-testing.csv", destfile = "pml.testing.csv", method = "curl")

```

```{r load data, include=TRUE, echo=TRUE, eval=TRUE}

pml.training<-read.csv("pml.training.csv", na.strings=c("NA","#DIV/0!",""))
pml.testing<-read.csv("pml.testing.csv", na.strings=c("NA","#DIV/0!",""))
```  

###Exploring data
This is a dataset of 160 varibales and the last variable is the actual class.  
Six young health participants were asked to perform one set of 10 repetitions of the Unilateral Dumbbell Biceps Curl in five different fashions: exactly according to the specification (Class A), throwing the elbows to the front (Class B), lifting the dumbbell only halfway (Class C), lowering the dumbbell only halfway (Class D) and throwing the hips to the front (Class E).

Class A corresponds to the specified execution of the exercise, while the other 4 classes correspond to common mistakes. Participants were supervised by an experienced weight lifter to make sure the execution complied to the manner they were supposed to simulate. The exercises were performed by six male participants aged between 20-28 years, with little weight lifting experience. We made sure that all participants could easily simulate the mistakes in a safe and controlled manner by using a relatively light dumbbell (1.25kg).  

```{r exploring data, echo=TRUE}
#exploring dimensons of the two dataset
dim(pml.training)
dim(pml.testing)

#four sensor sources of measures:
belt = grep(pattern = "_belt", names(pml.training))
length(belt)
range(belt)

arm=grep(pattern = "_arm", names(pml.training))
length(arm)
range(arm)

dumbbell=grep(pattern = "_dumbbell", names(pml.training))
length(dumbbell)
range(dumbbell)

forearm=grep(pattern = "_forearm", names(pml.training))
length(forearm)
range(forearm)

```

###Cleaning data  
Training data  
```{r cleaning training data, echo=TRUE}

#selecting the columns containing sensor measures or classe variables
var<-grep(pattern = "_belt|_arm|_dumbbell|_forearm|classe", names(pml.training))

#variables not containing sensor measures
names(pml.training[,-var])

#eliminating columns that not contains sensor measures or the variable response "classe"
new.pml.training<-pml.training[, var]
dim(new.pml.training)

#there are some variables with 100% NA values and only 53 variables have no NA
NAvector<-colSums(is.na(new.pml.training))/19622
range(NAvector)

v<-which(NAvector==0)
length(v)
data.training<-new.pml.training[,v]
table(complete.cases(data.training))

```  
Testing data  
```{r exploring and cleaning testing data, echo=TRUE}

#selecting the columns containing sensor measures or problem_id variables
var.test<-grep(pattern = "_belt|_arm|_dumbbell|_forearm|problem_id", names(pml.testing))


#eliminating columns that not contains sensor measures or the variable response "proble_id"
new.pml.testing<-pml.testing[, var.test]

#select the same variables of training data
data.testing<-new.pml.testing[,v]

#data.testing has 20 predictors that are the same of the set data.training
dim(data.testing)

#column names are the same in both sets (except the last column)
trainingNames <- colnames(data.training)
testingNames <- colnames(data.testing)
all.equal(trainingNames[1:length(trainingNames)-1], testingNames[1:length(testingNames)-1])
```

###Splitting data.training

```{r splitting, echo=TRUE}
set.seed(1)
library(caret)
attach(data.training)
inTrain<-createDataPartition(y=classe, p=0.70, list = FALSE)

training<-data.training[inTrain,]
testing<-data.training[-inTrain,]

```  

#Elaborating data and prediction 

###Training three models  
```{r training model, echo=TRUE}

library(randomForest)
library(gbm)

#bagging: we use 52 predictors, 500 n.trees
bag.model<-randomForest(classe~., data=training, mtry=52, importance=TRUE)
bag.model

#randomForest: we use m=7 about sqrt(52) predictors, 500 n.trees
rf.model<-randomForest(classe~., data=training, importance=TRUE)
rf.model

#boosting: we use cross validation with k=10 folds, 150 n.trees, interaction.depth=3, shrinkage=0.1
boost.model<-train(classe~., method="gbm", data=training, verbose=F, trControl = trainControl(method = "cv", number = 10))
boost.model
plot(boost.model)
```

###Prediction of the three models
```{r predictions, echo=TRUE}

#bagging
yhat.bag<-predict(bag.model, newdata=testing)
confusionMatrix(yhat.bag, testing$classe)

#randomForest
yhat.rf<-predict(rf.model, newdata=testing)
confusionMatrix(yhat.rf, testing$classe)

#boosting
yhat.boost<-predict(boost.model, testing)
confusionMatrix(yhat.boost, testing$classe)
```

#Conclusions
###Analysis of the three models
All the three models performe well, in fact all of them have high prediction accuracy on validation set. The best one, however, is the random forest model with a OOB estimate of  error rate equal to 0.53%, while, when the model is applied to the validation dataset, both the accuracy and k-value overcome the value of 99%.
Consequently we decided to apply the random forest model to the analysis of the 20 observations testing set.

###Prediction on 20 testing samples
```{r prediction on pml.testing, echo=TRUE}

#randomForest
yhat.rf2<-predict(rf.model, newdata=data.testing)
yhat.rf2
```

#References
Velloso, E.; Bulling, A.; Gellersen, H.; Ugulino, W.; Fuks, H. Qualitative Activity Recognition of Weight Lifting Exercises. Proceedings of 4th International Conference in Cooperation with SIGCHI (Augmented Human ’13) . Stuttgart, Germany: ACM SIGCHI, 2013.

Website for the Groupware@LES Human Activity Recognition project.

An Introduction to Statistical Learning, G. James, D. Witten, T. Hastie, R. Tibshirani. Ed. Springer Verlag (2013). ISBN: 978-1-4614-7138-7.

The Elements of Statistical Learning (2nd. Edition, 10th printing), T. Hastie, R. Tibshirani, J. Friedman. Ed. Springer Verlag (2009). ISBN: 978-0-3878-4857-0.
