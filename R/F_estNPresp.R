#' Estimate the taxon-wise response functions non-parametrically
#'
#' @param sampleScore a vector of length n with environmental scores
#' @param muMarg the offset matrix
#' @param X the n-by-p data matrix
#' @param ncols an integer, the number of columns of X
#' @param thetas a vector of length p with dispersion parameters
#' @param n an integer, the number of samples
#' @param coefInit a 2-by-p matrix with current taxon-wise parameter estimates
#' @param coefInitOverall a vector of length 2 with current overall parameters
#' @param dfSpline a scalar, the degrees of freedom for the smoothing spline.
#' @param vgamMaxit Maximal number of iterations in the fitting of the GAM model
#' @param degree The degree if the parametric fit if the VGAM fit fails
#' @param verbose a boolean, should number of failed fits be reported
#' @param allowMissingness A boolean, are missing values present
#' @param naId The numeric index of the missing values in X
#' @param ... further arguments, passed on to the VGAM:::vgam() function
#'
#' The negative binomial likelihood is still maximized,
#'  but now the response function is a non-parametric one.
#'  To avoid a perfect fit and overly flexible functions,
#'  we enforce smoothness restrictions. In practice we use a
#'  generalized additive model (GAM), i.e. with splines.
#'  The same fitting procedure is carried out ignoring species labels.
#'   We do not normalize the parameters related to the splines:
#'   the psis can be calculated afterwards.
#'
#' @return A list with components
#' \item{taxonCoef}{The fitted coefficients of the sample-wise response curves}
#' \item{splinesList}{A list of all the B-spline objects}
#' \item{rowMar}{The row matrix}
#' \item{overall}{The overall fit ignoring taxon labels,
#'  as a list of coefficients and a spline}
#' \item{rowVecOverall}{The overall row vector, ignoring taxon labels}
#'
#' @importFrom MASS negative.binomial
#' @importFrom stats na.omit
#' @importFrom VGAM s vgam coef negbinomial.size
estNPresp = function(sampleScore, muMarg,
    X, ncols, thetas, n, coefInit, coefInitOverall,
    dfSpline, vgamMaxit, degree, verbose, allowMissingness, naId,
    ...) {
    logMu = log(muMarg)
    MM = getModelMat(sampleScore, degree)
    # The model matrix for the parametric fit
    MM1 = getModelMat(sampleScore, degree = 1)
    # The model matrix of the first degree
    taxonWise = lapply(seq_len(ncols), function(i) {
        #Fit based on non-NAs
        df = data.frame(x = X[, i], sampleScore = sampleScore,
            logMu = log(muMarg[, i]))
        # Going through a dataframe slows things
        # down, so ideally we should appeal
        # directly to the vgam.fit function
        tmp = try(suppressWarnings(vgam(data = df,
            x ~ s(sampleScore, df = dfSpline),
            offset = logMu, family = negbinomial.size(lmu = "loglink",
                size = thetas[i]), coefstart = coefInit[[i]],
            maxit = vgamMaxit, na.option = na.omit,...)), silent = TRUE)
        if (inherits(tmp, "try-error")) {
            # If this fails turn to parametric fit
            warning("GAM would not fit, turned to parametric fit of degree ",
                degree, "!")
            nonNaId = !is.na(X[,i])
            tmp = try(nleqslv(fn = dNBllcolNP,
                x = if (length(coefInit[[i]])) {coefInit[[i]]
                } else rep(1e-04, degree + 1), X = X[nonNaId,i],
                reg = MM[nonNaId,], theta = thetas[i],
                muMarg = muMarg[nonNaId, i], jac = NBjacobianColNP,
                allowMissingness = FALSE)$x)
        } else {
            # if VGAM fit succeeds, retain only
            # necessary information
            tmp = list(coef = coef(tmp),
                spline = tmp@Bspline[[1]])
        }
        if (inherits(tmp, "try-error")) {
            warning("GLM would not fit either, returning independence model! ")
            tmp = numeric(degree + 1)
            #If nothing will fit, stick to an independence model
        }
        return(tmp)
    })
    names(taxonWise) = colnames(X)
    # Report failed fits
    sumFit = sum(!vapply(FUN.VALUE = TRUE,
        taxonWise, is.list))
    if (verbose && sumFit)
        warning("A total number of ", sumFit,
            " response functions did not converge! \n")
    # Overall fit
    samRep = rep(sampleScore, ncols)
    sizes = if(length(naId)) rep(thetas, each = n)[-naId] else rep(thetas, each = n)
    overall = vgam(c(X) ~ s(samRep, df = dfSpline),
        offset = c(logMu), family = negbinomial.size(lmu = "loglink",
            size = sizes),
        coefstart = coefInitOverall, maxit = vgamMaxit,
        na.option = na.omit, ...)
    overallList = list(coef = coef(overall),
        spline = overall@Bspline[[1]])
    # Return lists of splines and of
    # coefficients, and a row regression
    # matrix
    rowMat = vapply(FUN.VALUE = numeric(n),
        taxonWise, function(x) {
            if (is.list(x))
                cbind(MM1, predict(x$spline, x = sampleScore)$y) %*%
                c(x$coef, 1) else MM %*% x
        })
    rowVecOverall = cbind(MM1, predict(overallList$spline,
        x = sampleScore)$y) %*% c(overallList$coef,1)
    taxonCoef = lapply(taxonWise, function(x) {
        if (is.list(x))
            x$coef else x
    })
    splinesList = lapply(taxonWise, function(x) {
        if (is.list(x))
            x$spline else NULL
    })

    list(taxonCoef = taxonCoef, splinesList = splinesList,
        rowMat = rowMat, overall = overallList,
        rowVecOverall = rowVecOverall)
}
