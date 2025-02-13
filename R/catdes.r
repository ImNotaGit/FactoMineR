catdes <- function(donnee,num.var,proba = 0.05,row.w=NULL){

#  if (!is.null(row.w)) {
#    row.w=as.vector(row.w)
#	if (!any(row.w>=1)) stop("Argument row.w must be a vector of integers")
#    else donnee = donnee[rep(1:nrow(donnee),row.w),]
#  }
    moy.p <- function(V, fac=NULL, poids, na.rm=TRUE) {
		poids[is.na(V)] <- 0
        if (is.null(fac)) {
		  res <- sum(V * poids,na.rm=na.rm)/sum(poids)
		} else {
		  res <- NULL
		  for (i in 1:nlevels(fac)) res <- c(res, sum(V[fac==levels(fac)[i]] * poids[fac==levels(fac)[i]],na.rm=na.rm)/sum(poids[fac==levels(fac)[i]]))
		}
		return(res)
    }
    ec <- function(V, fac=NULL, poids, na.rm=TRUE) {
		poids[is.na(V)] <- 0
        if (is.null(fac)){
  		  V <- V-moy.p(V,fac=NULL,poids,na.rm)
		  res <- sum(V^2 * poids,na.rm=na.rm)/sum(poids)
        } else {
		  moy.par.mod <- moy.p(V,fac=fac,poids,na.rm)
		  res <- NULL
		  for (i in 1:nlevels(fac)) {
		   res <- c(res, sum((V[fac==levels(fac)[i]]-moy.par.mod[i])^2 * poids[fac==levels(fac)[i]],na.rm=na.rm)/sum(poids[fac==levels(fac)[i]]))
		}}
		return(sqrt(res))
    }
  donnee <- as.data.frame(donnee)
  if (is.numeric(donnee[,num.var])) stop(paste("The variable",num.var,"must be qualitative"))
  is.quali <- which(!unlist(lapply(donnee,is.numeric)))
  donnee[,is.quali] <- lapply(donnee[,is.quali,drop=FALSE],as.factor)
  donnee <- droplevels(donnee)
  if (is.null(row.w)) row.w <- rep(1,nrow(donnee))
  lab.sauv <- lab <- colnames(donnee)
  quali <- NULL
  for (i in 1:length(lab)){
    lab[i] <- gsub(" ",".",lab[i])
    if (is.factor(donnee[,i])) {
         if(any(is.na(donnee[,i]))){
             levels(donnee[,i]) <- c(levels(donnee[,i]), "NA")
             donnee[,i][is.na(donnee[,i])] <- "NA"
         }
      if (levels(donnee[,i])[1]=="") levels(donnee[,i])[1] <- "NA"
      if (i!=num.var) quali <- c(quali,i)
    }
  }
  quanti <- (1:ncol(donnee))[-c(quali,num.var)]
  if (length(quanti)==0) quanti <- NULL
  colnames(donnee) <- lab
  res <- list()

  nb.modalite <- nlevels(donnee[,num.var])
  nb.quali <- length(quali)
  old.warn <- options("warn")
  if (nb.quali>0){
    options(warn = -1)
    Test.chi <- matrix(NA,nrow=nb.quali,ncol=2)
    ## marge.li = xtabs(~donnee[,num.var])
	marge.li <- apply(sweep(tab.disjonctif(donnee[,num.var]),1,row.w,FUN="*"),2,sum)
    nom <- tri <- structure(vector(mode = "list", length = nb.modalite), names = levels(donnee[,num.var]))
    indicateur.quali <- 0
    for (i in 1:nb.quali){
#      Table <- t(tab.disjonctif(donnee[,num.var]))%*%sweep(tab.disjonctif(donnee[,quali[i]]),1,row.w,FUN="*")
	  Table <- t(sweep(tab.disjonctif(donnee[,num.var]),1,row.w,FUN="*"))%*%tab.disjonctif(donnee[,quali[i]])
    marge.col <- apply(Table,2,sum)
	  Test <- chisq.test(Table,correct=FALSE)
      Test.chi[i,1] <- Test$p.value
      Test.chi[i,2] <- Test$parameter
      for (j in 1:nlevels(donnee[,num.var])) {
       for (k in 1:nlevels(donnee[,quali[i]])) {
        aux2 <- Table[j,k]/marge.li[j]
        aux3 <- marge.col[k]/sum(marge.col)
        aux4 <- min(phyper(round(Table[j,k],0)-1,round(marge.li[j],0),round(sum(marge.li),0)-round(marge.li[j],0),round(marge.col[k],0))*2+dhyper(round(Table[j,k],0),round(marge.li[j],0),round(sum(marge.li),0)-round(marge.li[j],0),round(marge.col[k],0)),phyper(round(Table[j,k],0),round(marge.li[j],0),round(sum(marge.li),0)-round(marge.li[j],0),round(marge.col[k],0),lower.tail=FALSE)*2+dhyper(round(Table[j,k],0),round(marge.li[j],0),round(sum(marge.li),0)-round(marge.li[j],0),round(marge.col[k],0)))
        if (aux4 <= proba) {
          aux5 <- (1-2*as.integer(aux2>aux3))*qnorm(aux4/2)
          aux1 <- Table[j,k]/marge.col[k]
          tri[[j]] <- rbind(tri[[j]],c(aux1*100,aux2*100,aux3*100,aux4,aux5))
          nom[[j]] <- rbind(nom[[j]],c(levels(donnee[,quali[i]])[k],colnames(donnee)[quali[i]]))
        }
       }
      }
    rownames(Test.chi) <- colnames(donnee)[quali]
   }
   if (nrow(matrix(Test.chi,ncol=2))>1){
     if (sum(Test.chi[,1] <= proba)==1){
       nomaux <- rownames(Test.chi[order(Test.chi[,1]),])[1]
       Test.chi <- matrix(Test.chi[Test.chi[,1] <= proba,],ncol=2)
       rownames(Test.chi) <- nomaux
     }
     else Test.chi <- Test.chi[Test.chi[,1] <= proba,]
   }
   else if (Test.chi[,1] > proba) Test.chi <- NULL
   if (!is.null(Test.chi)){
     if (nrow(matrix(Test.chi,ncol=2))>1){
       oo <- order(Test.chi[,1])
       Test.chi <- Test.chi[oo,]
     }  
     colnames(Test.chi) <- c("p.value","df")
     res$test.chi2 <- Test.chi
   }
   for (j in 1:nb.modalite){
     if (!is.null(tri[[j]])){
       indicateur.quali <- 1
       oo <- rev(order(tri[[j]][,5]))
       tri[[j]] <- tri[[j]][oo,]
       nom[[j]] <- nom[[j]][oo,]
       if (nrow(matrix(tri[[j]],ncol=5))>1) rownames(tri[[j]]) <- paste(nom[[j]][,2],nom[[j]][,1],sep="=")
       else {
         tri[[j]] <- matrix(tri[[j]],ncol=5)
         rownames(tri[[j]]) <- paste(nom[[j]][2],nom[[j]][1],sep="=")
       }
       colnames(tri[[j]]) <-  c("Cla/Mod","Mod/Cla","Global","p.value","v.test")
     }
   }
   if (indicateur.quali>0) res$category <- tri
  }

  if (!is.null(quanti)){
    nom <- result <- structure(vector(mode = "list", length = nb.modalite), names = levels(donnee[,num.var]))
	tabF <- matrix(0, length(quanti), 2)
    for (i in 1:length(quanti)){	
      res.aov <- summary(aov(donnee[,quanti[i]]~donnee[,num.var], na.action = na.exclude,weights=row.w))[[1]]
      tabF[i, 1] <- res.aov[1,2]/sum(res.aov[,2])
      tabF[i, 2] <- res.aov[1,5]
      moy.mod <- moy.p(donnee[,quanti[i]],fac=donnee[,num.var],poids=row.w)
	  n.mod <- apply(sweep(tab.disjonctif(donnee[,num.var]),1,row.w,FUN="*"),2,sum)
      sd.mod <- ec(donnee[,quanti[i]],fac=donnee[,num.var],poids=row.w)
      moy <- moy.p(donnee[,quanti[i]],poids=row.w)
      et <- ec(donnee[,quanti[i]],poids=row.w)
      for (j in 1:nb.modalite){
        v.test <- (moy.mod[j]-moy)/et*sqrt(n.mod[j])/sqrt((sum(n.mod)-n.mod[j])/(sum(n.mod)-1))
        p.value <- pnorm(abs(v.test),lower.tail = FALSE)*2
        if(!is.na(v.test)){
         if (p.value <= proba) {
          result[[j]] <- rbind(result[[j]],c(v.test,moy.mod[j],moy,sd.mod[j],et,p.value))
          nom[[j]] <- c(nom[[j]],colnames(donnee)[quanti[i]])
        }
       }
      }
	}
    dimnames(tabF) <- list(colnames(donnee)[quanti], c("Eta2", "P-value"))
    auxF <- tabF[order(tabF[, 2]),,drop=FALSE]
    select1 <- (1:nrow(auxF))[auxF[, 2,drop=FALSE] <= proba]
    if (length(select1) > 0) resF <- auxF[select1,,drop=FALSE]
    for (j in 1:nb.modalite){
      if (!is.null(result[[j]])){
        oo <- rev(order(result[[j]][,1]))
        result[[j]] <- result[[j]][oo,,drop=FALSE]
        nom[[j]] <- nom[[j]][oo]
        result[[j]] <- matrix(result[[j]],ncol=6)
        rownames(result[[j]]) <- nom[[j]]
        colnames(result[[j]]) <- c("v.test","Mean in category","Overall mean","sd in category","Overall sd","p.value")
      }
    }
    if (length(select1)>0) {
	  res$quanti.var <- resF
	  res$quanti <- result
	}
  }
  res$call <- list(num.var=num.var, proba=proba, row.w=row.w, X=donnee)
  options(old.warn)
class(res) <- c("catdes", "list")
  return(res)
}
