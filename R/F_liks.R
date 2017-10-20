#' Calculate the log-likelihoods of the indepence and saturated models and all fitted submodels
#'
#'@param rcm an object of the RCM class
#'@param Sum a boolean, should likelihoods be summed?
#'
#'Dispersions are re-estimated for every dimension of the model.
#'
#'@return a named array log-likelihoods of the independence model and all models with dimension 1 to k, or a vector with summed log-likelihoods
liks = function(rcm, Sum = FALSE){
  outnames = c("independence", paste0("Dim ", 1:rcm$k),"saturated")
  if(Sum) {
    tmp = sapply(c(0:rcm$k, Inf), FUN = function(i){
      sum(getLogLik(rcm, i))
    })
    names(tmp) = outnames
  } else {
  tmp = vapply(c(0:rcm$k, Inf), FUN.VALUE = matrix(0, nrow(rcm$X), ncol(rcm$X)), FUN = function(i){
getLogLik(rcm, i)
  })
  dimnames(tmp)[[3]] = outnames
  tmp
  }
}