#' The influence function for the column scores
#' @param rcm an rcm object
#' @param Dim the required dimension
#'
#' @return A list with components
#' \item{score}{a matrix with components of the score function}
#' \item{InvJac}{A square matrix of dimension p with the components of the Jacobian related to the column scores}
NBcolInfl = function(rcm, Dim = 1){
  reg = rcm$psis[Dim] * rcm$rMat[,Dim]
  mu = extractE(rcm, seq_len(Dim)) #Take also lower dimensions into account here
  thetaMat = extractDisp(rcm, mu, Dim)
  lambdaCol = rcm$lambdaCol[seq_k(Dim)]
  cMatK = rcm$cMat[seq_len(Dim-1),,drop=FALSE]
  tmp = if(k>1) lambdaCol[-(1:2)] %*% cMatK else 0

  score = (reg *(rcm$X-mu)/(1+mu/thetas)) + rcm$colWeights*(lambdaCol[1] + lambdaCol[2]*2*cMat + tmp)

  JacobianInv = solve(NBjacobianCol(beta = c(cMat[Dim,], lambdaCol), X = rcm$X, reg = reg, thetas = thetaMat, muMarg = muMarg, k = Dim, p = nrow(rcm$X), n=ncol(rcm$X) ,colWeights = rcm$colWeights , nLambda = length(lambdaCol), cMatK = cMatK)) #Inverse Jacobian

  #After a long thought: The X's do not affect the estimation of the lambda parameters!
  #Matrix becomes too large: return score and inverse jacobian
  return(list(score=score, InvJac = JacobianInv[1:ncol(rcm$X),1:ncol(rcm$X)]))
}