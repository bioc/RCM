#' A function that returns the Jacobian of the likelihood ratio
#'
#' @param Alpha: a vector of length d + k*(2+(k-1)/2), the environmental gradient plus the lagrangian multipliers
#' @param X the n-by-p count matrix
#' @param CC a n-by-d covariate vector
#' @param responseFun a character string indicating the type of response function
#' @param psi a scalar, an importance parameter
#' @param NB_params Starting values for the NB_params
#' @param NB_params_noLab Starting values for the NB_params without label
#' @param d an integer, the number of covariate parameters
#' @param alphaK a matrix of environmental gradients of lower dimensions
#' @param k an integer, the current dimension
#' @param centMat a nLambda1s-by-d centering matrix
#' @param nLambdas an integer, number of lagrangian multipliers
#' @param nLambda1s an integer, number of centering restrictions
#' @param thetaMat a matrix of size n-by-p with estimated dispersion parameters
#' @param muMarg an n-by-p offset matrix
#' @param n an integer, the number of rows of X
#' @param ncols a scalar, the number of columns of X
#'
#' @return A symmetric matrix, the evaluated Jacobian
LR_nb_Jac = function(Alpha, X, CC, responseFun = c("linear", "quadratic", "nonparametric","dynamic"), psi, NB_params, NB_params_noLab, d, alphaK, k, centMat, nLambda, nLambda1s, thetaMat, muMarg, n, ncols, ...){
  did = seq_len(d)
  #Extract the parameters
  alpha = Alpha[did]
  lambda1s = Alpha[d+seq_len(nLambda1s)] #Multiple centering requirements now!
  lambda2 = Alpha[d+nLambda1s+1]
  lambda3 = if(k==1) {0} else {Alpha[(d+nLambda1s+2):(d+nLambda)]}

  sampleScore = CC %*% alpha #A linear combination of the environmental variables yields the sampleScore
  design = switch(responseFun,
                  linear = model.matrix(~ sampleScore),#With intercept
                  quadratic = model.matrix(~ sampleScore + I(sampleScore^2)),
                  dynamic = model.matrix(~ sampleScore + I(sampleScore^2)),
                  stop("Non-parametric model not yet implemented")
  )

  mu = muMarg * exp(design %*% NB_params *psi)
  mu0 = muMarg * c(exp(design %*% NB_params_noLab*psi))

  Jac = matrix(0, nrow= d + nLambda, ncol = d + nLambda)
  #dLag²/dalpha_{yk}dlambda_{1k}
  Jac[(d+seq_len(nLambda1s)), did] = centMat

  Jac[did,d+nLambda1s+1] = 2 * alpha

  if(responseFun=="linear"){
    tmp = rowMultiply((1+X/thetaMat)*mu/(1+mu/thetaMat)^2,NB_params[2,]^2)
    tmp0 = (1+X/thetaMat)*mu0/(1+mu0/thetaMat)^2 * NB_params_noLab[2]^2
  } else if (responseFun=="quadratic"){
    tmp = (1+X/thetaMat)*mu/(1+mu/thetaMat)^2
    tmp0 = (1+X/thetaMat)*mu0/(1+mu0/thetaMat)^2
  }
  #dLag²/ds_{ik}dlambda_{3kk'}
  if(k>1){
    Jac[(d+nLambda1s+2):(d+nLambda), did] = alphaK
  }

  #Symmetrize
  Jac = Jac + t(Jac)
  cSam = c(sampleScore)
  cSam2 = cSam^2

  Jac[did,did] = switch(responseFun,
                        "linear" = - psi^2 *(colSums(tensor(vapply(did, FUN.VALUE = tmp, function(x){CC[,x]*(tmp-tmp0)}), CC,1,1))),
                        "quadratic" = colSums((tensor(vapply(did, FUN.VALUE = tmp, function(x){CC[,x]*(-psi^2*(tmp*(matrix(NB_params[2,]^2,n,ncols, byrow =TRUE)+4*outer(cSam,NB_params[2,]*NB_params[3,])+4*outer(cSam2,NB_params[3,]^2))-
                                                                                                                 tmp0*(NB_params_noLab[2]+NB_params_noLab[3]*2*cSam)^2) + 2*psi*(rowMultiply((X-mu)/(1+mu/thetaMat),NB_params[3,])-(X-mu0)/(1+mu0/thetaMat)*NB_params_noLab[3]))}),CC,1,1))
                        ))

  diag(Jac)[did] = diag(Jac)[did] + 2*lambda2 #Correct the diagonal

  Jac
}