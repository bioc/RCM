% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/F_buildCovMat.R
\name{buildCovMat}
\alias{buildCovMat}
\title{A function to build the covariate matrix of the constraints}
\usage{
buildCovMat(covariates, dat)
}
\arguments{
\item{covariates}{the covariates, either as dataframe or as character string}

\item{dat}{the phyloseq object

In this case we will 1) Include dummy's for every level of the
 categorical variable, and force them to sum to zero.
 This is needed for plotting and required for
  reference level independent normalization.
  2) Exclude an intercept. The density function f()
  will provide this already.}
}
\value{
a list with components
\item{covModelMat}{The model matrix}
\item{datFrame}{The dataframe used to construct the model matrix}
}
\description{
A function to build the covariate matrix of the constraints
}
