#' Defines linear equality constraints function for the estimation of the environmental gradient
#'
#' @param Alpha the current estimate of the environmental gradient
#' @param alphaK a matrix with the environmental gradients of the lower dimensions
#' @param d an integer, the number of environmental variables, including dummies
#' @param k an integer, the current dimension
#' @param centMat a centering matrix
#'
#' The centering matrix centMat ensures that the parameters of the dummies of the same categorical variable sum to zero
#'
#' @return a vector of with current values of the constraints, should evolve to zeroes only
heq_nb = function(Alpha, alphaK, d, k,  centMat, ...){
  centerFactors = centMat %*% Alpha #Includes overal centering
  size = sum(Alpha^2)-1
  if(k==1) { return(c( centerFactors, size))}
  ortho = crossprod(alphaK,  Alpha)
  c(centerFactors, size, ortho)
}