#' A function to estimate the overdispersion of the negative binomial distribution. Hereby information between taxa is shared with empirical Bayes using the edgeR pacakage, where the time-limiting steps are programmed in C.
#'
#' @param X: the data matrix of dimensions nxp
#' @param cMat a 1xp colum scores matrix
#' @param rMat a nx1 rowscores matrix, if unconstrained
#' @param muMarg an nxp offset matrix
#' @param psis a scalar, the current psi estimate
#' @param trended.dispersion a vector of length p with pre-calculated trended.dispersion estimates. They do not vary in function of the offset anyway
#' @param prior.df an integer, number of degrees of freedom of the prior for the Bayesian shrinkage
#' @param dispWeights Weights for estimating the dispersion in a zero-inflated model
#' @param rowMat matrix of row scores in case of constrained ordination
#'
#' @return A vector of length p with dispersion estimates
estDisp = function (X, cMat = NULL, rMat = NULL, muMarg, psis, trended.dispersion, prior.df = 10, dispWeights = NULL, rowMat = NULL)
{

  require(edgeR)
  logMeansMat =
    if(!is.null(rMat)){ #Unconstrained
      t(rMat %*% (cMat * psis) + log(muMarg))
    } else { #Constrained
      t(log(muMarg) + psis* rowMat)
    }
  thetaEsts <- 1/estimateGLMTagwiseDisp(y = t(X), design = NULL,
                                        prior.df = prior.df, offset = logMeansMat, dispersion = trended.dispersion, weights = dispWeights)
  if (anyNA(thetaEsts)) {
    idNA = is.na(thetaEsts)
    thetaEsts[idNA] = mean(thetaEsts[!idNA])
    warning(paste(sum(idNA), "dispersion estimations did not converge!"))
  }
  return(thetas = thetaEsts)
}