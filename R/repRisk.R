#' @title Decompose portfolio risk into individual factor contributions and provide tabular report
#' 
#' @description Compute the factor contributions to standard deviation (SD), Value-at-Risk (VaR), 
#' Expected Tail Loss or Expected Shortfall (ES) of the return of individual asset within a portfolio 
#' return of a portfolio based on Euler's theorem, given the fitted factor model.
#' 
#' @importFrom lattice barchart
#' 
#' @param object fit object of class \code{tsfm}, or \code{ffm}.
#' @param p tail probability for calculation. Default is 0.05.
#' @param weights a vector of weights of the assets in the portfolio, names of 
#' the vector should match with asset names. Default is NULL, in which case an 
#' equal weights will be used.
#' @param risk one of 'Sd' (standard deviation), 'VaR' (Value-at-Risk) or 'ES' (Expected Tail 
#' Loss or Expected Shortfall for calculating risk decompositon. Default is 'Sd'
#' @param decomp one of 'FMCR' (factor marginal contribution to risk), 
#' 'FCR' 'factor contribution to risk' or 'FPCR' (factor percent contribution to risk).
#' @param digits digits of number in the resulting table. Default is NULL, in which case digtis = 3 will be
#' used for decomp = ( 'FMCR', 'FCR'), digits = 1 will be used for decomp = 'FPCR'. Used only when 
#' isPrint = 'TRUE'
#' @param nrowPrint a numerical value deciding number of assets/portfolio in result vector/table to print
#' or plot  
#' @param type one of "np" (non-parametric) or "normal" for calculating VaR & Es. 
#' Default is "np".
#' @param sliceby one of “factor” (slice/condition by factor) or “asset” (slice/condition by asset)
#' Used only when isPlot = 'TRUE'  
#' @param invert a logical variable to change VaR/ES to positive number, default
#' is False and will return positive values.
#' @param layout layout is a numeric vector of length 2 or 3 giving the number of columns, rows, and pages (optional) in a multipanel display.
#' @param portfolio.only logical variable to choose if to calculate portfolio only decomposition, in which case multiple risk measures are 
#' allowed.
#' @param isPlot logical variable to generate plot or not.
#' @param isPrint logical variable to print numeric output or not.
#' @param use an optional character string giving a method for computing factor
#' covariances in the presence of missing values. This must be (an 
#' abbreviation of) one of the strings "everything", "all.obs", 
#' "complete.obs", "na.or.complete", or "pairwise.complete.obs". Default is 
#' "pairwise.complete.obs".
#' @param ... other optional arguments passed to \code{\link[stats]{quantile}} and 
#' optional arguments passed to \code{\link[stats]{cov}}
#'
#' @return A table containing 
#' \item{decomp = 'FMCR'}{(N + 1) * (K + 1) matrix of marginal contributions to risk of portfolio 
#' return as well assets return, with first row of values for the portfolio and the remaining rows for 
#' the assets in the portfolio, with  (K + 1) columns containing values for the K risk factors and the
#' residual respectively}
#' \item{decomp = 'FCR'}{(N + 1) * (K + 2) matrix of component contributions to risk of portfolio 
#' return as well assets return, with first row of values for the portfolio and the remaining rows for 
#' the assets in the portfolio, with  first column containing portfolio and asset risk values and remaining
#' (K + 1) columns containing values for the K risk factors and the residual respectively}
#' \item{decomp = 'FPCR'}{(N + 1) * (K + 1) matrix of percentage component contributions to risk 
#' of portfolio return as well assets return, with first row of values for the portfolio and the remaining rows for 
#' the assets in the portfolio, with  (K + 1) columns containing values for the K risk factors and the
#' residual respectively}
#' Where, K is the number of factors, N is the number of assets.
#' 
#' @author Douglas Martin, Lingjie Yi
#' 
#' 
#' @seealso \code{\link{fitTsfm}}, \code{\link{fitFfm}}
#' for the different factor model fitting functions.
#' 
#' 
#' @examples
#' # Time Series Factor Model
#' data(managers)
#' fit.macro <- factorAnalytics::fitTsfm(asset.names=colnames(managers[,(1:6)]),
#'                      factor.names=colnames(managers[,(7:9)]),
#'                      rf.name=colnames(managers[,10]), data=managers)
#' report <- repRisk(fit.macro, risk = "ES", decomp = 'FPCR', 
#'                   nrowPrint = 10)
#' report 
#' 
#' # plot
#' repRisk(fit.macro, risk = "ES", decomp = 'FPCR', isPrint = FALSE, 
#'         isPlot = TRUE)
#' 
#' # Fundamental Factor Model
#' data("stocks145scores6")
#' dat = stocks145scores6
#' dat$DATE = as.yearmon(dat$DATE)
#' dat = dat[dat$DATE >=as.yearmon("2008-01-01") & 
#'           dat$DATE <= as.yearmon("2012-12-31"),]
#'
#' # Load long-only GMV weights for the return data
#' data("wtsStocks145GmvLo")
#' wtsStocks145GmvLo = round(wtsStocks145GmvLo,5)  
#'                                                      
#' # fit a fundamental factor model
#' fit.cross <- fitFfm(data = dat, 
#'               exposure.vars = c("SECTOR","ROE","BP","MOM121","SIZE","VOL121",
#'               "EP"),date.var = "DATE", ret.var = "RETURN", asset.var = "TICKER", 
#'               fit.method="WLS", z.score = TRUE)
#' repRisk(fit.cross, risk = "Sd", decomp = 'FCR', nrowPrint = 10,
#'         digits = 4) 
#' # get the factor contributions of risk 
#' repRisk(fit.cross, wtsStocks145GmvLo, risk = "Sd", decomp = 'FPCR', 
#'         nrowPrint = 10)          
#' # portfolio only decomposition
#' repRisk(fit.cross, wtsStocks145GmvLo, risk = c("VaR", "ES"), decomp = 'FPCR', 
#'         portfolio.only = TRUE)       
#' # plot
#' repRisk(fit.cross, wtsStocks145GmvLo, risk = "Sd", decomp = 'FPCR', 
#'         isPrint = FALSE, nrowPrint = 15, isPlot = TRUE, layout = c(4,2))  
#' @export    


repRisk <- function(object, ...){
  # check input object validity
  if (!inherits(object, c("tsfm", "ffm"))) {
    stop("Invalid argument: Object should be of class 'tsfm',  or 'ffm'.")
  }
  UseMethod("repRisk")
}

#' @rdname repRisk
#' @method repRisk tsfm
#' @importFrom utils head
#' @export

repRisk.tsfm <- function(object, weights = NULL, risk = c("Sd", "VaR", "ES"), 
                         decomp = c('FPCR','FCR','FMCR' ), digits = NULL, invert = FALSE,
                         nrowPrint = 20, p=0.05, type=c("np","normal"), use="pairwise.complete.obs", 
                         sliceby = c('factor', 'asset'), isPrint = TRUE, isPlot = FALSE, layout =NULL,
                         portfolio.only = FALSE, ...) {
  
  # set default for type
  type = type[1]
  sliceby = sliceby[1]
  
  if(!portfolio.only){
    risk = risk[1]
  }
  decomp = decomp[1]
  
  if (!(type %in% c("np","normal"))) {
    stop("Invalid args: type must be 'np' or 'normal' ")
  }
  
  if (!prod(risk %in% c("Sd", "VaR", "ES"))) {
    stop("Invalid args: risk must be 'Sd', 'VaR' or 'ES' ")
  }
  
  if (!prod(decomp %in% c('FPCR','FCR','FMCR' ))) {
    stop("Invalid args: decomp must be  'FMCR', 'FCR' or 'FPCR' ")
  }
  
  if(!portfolio.only){
    if(length(which(risk == "Sd"))){
      port.Sd = riskDecomp(object, weights = weights,risk = "Sd", ... )
      asset.Sd = riskDecomp(object,risk = "Sd", portDecomp =FALSE, ... )
      
#       if(decomp == "RM"){
#         isPlot = FALSE
#         port = port.Sd$portSd
#         asset = asset.Sd$Sd.fm
#         result = c(port, asset)
#         names(result)[1] = 'Portfolio'
#       } else if(decomp == "FMCR"){
      if(decomp == "FMCR"){
        port = port.Sd$mSd
        asset = asset.Sd$mSd
        result = rbind(port, asset)
        rownames(result)[1] = 'Portfolio'
      } else if(decomp == "FCR"){
        portRM = port.Sd$portSd
        assetRM = asset.Sd$Sd.fm
        resultRM = c(portRM, assetRM)
        
        port = port.Sd$cSd
        asset = asset.Sd$cSd
        result = cbind(resultRM,rbind(port, asset))
        rownames(result)[1] = 'Portfolio'
        colnames(result)[1] = 'RM'
      } else if(decomp == "FPCR"){
        port = port.Sd$pcSd
        asset = asset.Sd$pcSd
        result = rbind(port, asset)
        rownames(result)[1] = 'Portfolio'
        result = cbind(rowSums(result), result)
        colnames(result)[1] = 'Total'
      }
      
    } else if(length(which(risk == "VaR"))){
      port.VaR = riskDecomp(object, risk = "VaR", weights = weights, p = p, type = type, invert = invert, ... )
      asset.VaR = riskDecomp(object, p = p, type = type, invert = invert, risk = "VaR", portDecomp =FALSE, ... )
      
#       if(decomp == "RM"){
#         isPlot = FALSE
#         port = port.VaR$portVaR
#         asset = asset.VaR$VaR.fm
#         result = c(port, asset)
#         names(result)[1] = 'Portfolio'
#       } else if(decomp == "FMCR"){
      if(decomp == "FMCR"){
        port = port.VaR$mVaR
        asset = asset.VaR$mVaR
        result = rbind(port, asset)
        rownames(result)[1] = 'Portfolio'
      } else if(decomp == "FCR"){
        portRM = port.VaR$portVaR
        assetRM = asset.VaR$VaR.fm
        resultRM = c(portRM, assetRM)
        
        port = port.VaR$cVaR
        asset = asset.VaR$cVaR
        result = cbind(resultRM,rbind(port, asset))
        rownames(result)[1] = 'Portfolio'
        colnames(result)[1] = 'RM'
      } else if(decomp == "FPCR"){
        port = port.VaR$pcVaR
        asset = asset.VaR$pcVaR
        result = rbind(port, asset)
        rownames(result)[1] = 'Portfolio'
        result = cbind(rowSums(result), result)
        colnames(result)[1] = 'Total'
      }
      
    } else if(length(which(risk == "ES"))){
      port.Es = riskDecomp(object, risk = "ES", weights = weights, p = p, type = type, invert = invert, ... )
      asset.Es = riskDecomp(object, p = p, type = type, invert = invert,risk = "ES", portDecomp =FALSE, ... )
      
#       if(decomp == "RM"){
#         isPlot = FALSE
#         port = port.Es$portES
#         asset = asset.Es$ES.fm
#         result = c(port, asset)
#         names(result)[1] = 'Portfolio'
#       } else if(decomp == "FMCR"){
      if(decomp == "FMCR"){
        port = port.Es$mES
        asset = asset.Es$mES
        result = rbind(port, asset)
        rownames(result)[1] = 'Portfolio'
      } else if(decomp == "FCR"){
        portRM = port.Es$portES
        assetRM = asset.Es$ES.fm
        resultRM = c(portRM, assetRM)
        
        port = port.Es$cES
        asset = asset.Es$cES
        result = cbind(resultRM,rbind(port, asset))
        rownames(result)[1] = 'Portfolio'
        colnames(result)[1] = 'RM'
      } else if(decomp == "FPCR"){
        port = port.Es$pcES
        asset = asset.Es$pcES
        result = rbind(port, asset)
        rownames(result)[1] = 'Portfolio'
        result = cbind(rowSums(result), result)
        colnames(result)[1] = 'Total'
      }
      
    }
    
    if(isPlot){
      if(decomp == "FCR"){
        result = result[,-1]
      }else if(decomp == "FPCR"){
        result = result[,-1]
      }
      
      if(sliceby == 'factor'){
        result = head(result, nrowPrint)
        
        if(is.null(layout)){
          n = ncol(result)
          l = 3
          while(n %% l == 1){
            l = l+1
          }
          layout = c(l,1)
        }
        
        print(barchart(result[rev(rownames(result)),], groups = FALSE, main = paste(decomp,"of", risk),layout = layout,
                       ylab = '', xlab = '', as.table = TRUE))
        
      }else if(sliceby == 'asset'){
        result = head(result, nrowPrint)
        result = t(result)
        
        if(is.null(layout)){
          n = ncol(result)
          l = 3
          while(n %% l == 1){
            l = l+1
          }
          layout = c(l,1)
        }
        
        print(barchart(result[rev(rownames(result)),], groups = FALSE, main = paste(decomp,"of", risk),layout = layout, 
                       ylab = '', xlab = '', as.table = TRUE))
      }
    }
    
    if(isPrint){
      if(is.null(digits)){
        if(decomp == 'FPCR'){
          digits = 1
        }else{
          digits = 3
        }
      }
      result = head(result, nrowPrint)
      result = round(result, digits)
      
      output = list(decomp = result)
      names(output) = paste(risk,decomp,sep = '')
      
      return(output)
    }
  } else{
    port.Sd = riskDecomp(object, risk = "Sd", weights = weights, ... )
    port.VaR = riskDecomp(object, risk = "VaR", weights = weights, p = p, type = type, invert = invert, ... )
    port.Es = riskDecomp(object, risk = "ES", weights = weights, p = p, type = type, invert = invert, ... )
    
#     if(decomp == "RM"){
#       isPlot = FALSE
#       Sd = port.Sd$portSd
#       VaR = port.VaR$portVaR
#       Es = port.Es$portES
#       
#       result = c(Sd, VaR, Es)
#       names(result) = c('Sd','VaR','ES')
#       result = result[risk]
#     } else if(decomp == "FMCR"){
    if(decomp == "FMCR"){
      Sd = port.Sd$mSd
      VaR = port.VaR$mVaR
      Es = port.Es$mES
      result = rbind(Sd, VaR, Es)
      rownames(result) = c('Sd','VaR','ES')
      result = result[risk,]
    } else if(decomp == "FCR"){
      SdRM = port.Sd$portSd
      VaRRM = port.VaR$portVaR
      EsRM = port.Es$portES
      resultRM = c(SdRM, VaRRM, EsRM)
      names(resultRM) = c('Sd','VaR','ES')
      
      Sd = port.Sd$cSd
      VaR = port.VaR$cVaR
      Es = port.Es$cES
      result = rbind(Sd, VaR, Es)
      rownames(result) = c('Sd','VaR','ES')
      result = cbind(resultRM,result)
      colnames(result)[1] = 'RM'
      result = result[risk,]
    } else if(decomp == "FPCR"){
      Sd = port.Sd$pcSd
      VaR = port.VaR$pcVaR
      Es = port.Es$pcES
      result = rbind(Sd, VaR, Es)
      rownames(result) = c('Sd','VaR','ES')
      result = cbind(rowSums(result), result)
      colnames(result)[1] = 'Total'
      result = result[risk,]
    }
    
    if(isPrint){
      if(is.null(digits)){
        if(decomp == 'FPCR'){
          digits = 1
        }else{
          digits = 3
        }
      }
      result = round(result, digits)
      
      if(type=="normal"){
        Type = 'Parametric Normal'
      }else{
        Type = 'Non-Parametric'
      }
      output = list(decomp = result)
      names(output) = paste('Portfolio',decomp, Type, sep = ' ')

            return(output)
    }
    
  }
}

#' @rdname repRisk
#' @method repRisk ffm
#' @importFrom utils head
#' @export

repRisk.ffm <- function(object, weights = NULL, risk = c("Sd", "VaR", "ES"),
                        decomp = c('FMCR', 'FCR', 'FPCR'), digits = NULL, invert = FALSE,
                        nrowPrint = 20, p=0.05, type=c("np","normal"), 
                        sliceby = c('factor', 'asset'), isPrint = TRUE, isPlot = FALSE, layout =NULL,
                        portfolio.only = FALSE, ...) {
  
  # set default for type
  type = type[1]
  sliceby = sliceby[1]
  
  if(!portfolio.only){
    risk = risk[1]
  }
  decomp = decomp[1]
  
  if (!(type %in% c("np","normal"))) {
    stop("Invalid args: type must be 'np' or 'normal' ")
  }
  
  if (!prod(risk %in% c("Sd", "VaR", "ES"))) {
    stop("Invalid args: risk must be 'Sd', 'VaR' or 'ES' ")
  }
  
  if (!prod(decomp %in% c( 'FMCR', 'FCR', 'FPCR'))) {
    stop("Invalid args: decomp must be 'FMCR', 'FCR' or 'FPCR' ")
  }
  
  if(!portfolio.only){
    if(length(which(risk == "Sd"))){
      port.Sd = riskDecomp(object,risk = "Sd",weights = weights, ... )
      asset.Sd = riskDecomp(object,risk = "Sd", portDecomp =FALSE, ... )
      
#       if(decomp == "RM"){
#         isPlot = FALSE
#         port = port.Sd$portSd
#         asset = asset.Sd$Sd.fm
#         result = c(port, asset)
#         names(result)[1] = 'Portfolio'
#       } else if(decomp == "FMCR"){
      if(decomp == "FMCR"){
        port = port.Sd$mSd
        asset = asset.Sd$mSd
        result = rbind(port, asset)
        rownames(result)[1] = 'Portfolio'
      } else if(decomp == "FCR"){
        portRM = port.Sd$portSd
        assetRM = asset.Sd$Sd.fm
        resultRM = c(portRM, assetRM)
        
        port = port.Sd$cSd
        asset = asset.Sd$cSd
        result = cbind(resultRM,rbind(port, asset))
        rownames(result)[1] = 'Portfolio'
        colnames(result)[1] = 'RM'
      } else if(decomp == "FPCR"){
        port = port.Sd$pcSd
        asset = asset.Sd$pcSd
        result = rbind(port, asset)
        rownames(result)[1] = 'Portfolio'
        result = cbind(rowSums(result), result)
        colnames(result)[1] = 'Total'
      }
      
    } else if(length(which(risk == "VaR"))){
      port.VaR = riskDecomp(object, risk = "VaR", weights = weights, p = p, type = type, invert = invert, ... )
      asset.VaR = riskDecomp(object,risk = "VaR", portDecomp =FALSE,  p = p, type = type, invert = invert, ... )
      
#       if(decomp == "RM"){
#         isPlot = FALSE
#         port = port.VaR$portVaR
#         asset = asset.VaR$VaR.fm
#         result = c(port, asset)
#         names(result)[1] = 'Portfolio'
#       } else if(decomp == "FMCR"){
      if(decomp == "FMCR"){
        port = port.VaR$mVaR
        asset = asset.VaR$mVaR
        result = rbind(port, asset)
        rownames(result)[1] = 'Portfolio'
      } else if(decomp == "FCR"){
        portRM = port.VaR$portVaR
        assetRM = asset.VaR$VaR.fm
        resultRM = c(portRM, assetRM)
        
        port = port.VaR$cVaR
        asset = asset.VaR$cVaR
        result = cbind(resultRM,rbind(port, asset))
        rownames(result)[1] = 'Portfolio'
        colnames(result)[1] = 'RM'
      } else if(decomp == "FPCR"){
        port = port.VaR$pcVaR
        asset = asset.VaR$pcVaR
        result = rbind(port, asset)
        rownames(result)[1] = 'Portfolio'
        result = cbind(rowSums(result), result)
        colnames(result)[1] = 'Total'
      }
      
    } else if(length(which(risk == "ES"))){
      port.Es = riskDecomp(object, risk = "ES", weights = weights, p = p, type = type, invert = invert, ... )
      asset.Es = riskDecomp(object,risk = "ES", portDecomp =FALSE, p = p, type = type, invert = invert, ... )
      
#       if(decomp == "RM"){
#         isPlot = FALSE
#         port = port.Es$portES
#         asset = asset.Es$ES.fm
#         result = c(port, asset)
#         names(result)[1] = 'Portfolio'
#       } else if(decomp == "FMCR"){
      if(decomp == "FMCR"){
        port = port.Es$mES
        asset = asset.Es$mES
        result = rbind(port, asset)
        rownames(result)[1] = 'Portfolio'
      } else if(decomp == "FCR"){
        portRM = port.Es$portES
        assetRM = asset.Es$ES.fm
        resultRM = c(portRM, assetRM)
        
        port = port.Es$cES
        asset = asset.Es$cES
        result = cbind(resultRM,rbind(port, asset))
        rownames(result)[1] = 'Portfolio'
        colnames(result)[1] = 'RM'
      } else if(decomp == "FPCR"){
        port = port.Es$pcES
        asset = asset.Es$pcES
        result = rbind(port, asset)
        rownames(result)[1] = 'Portfolio'
        result = cbind(rowSums(result), result)
        colnames(result)[1] = 'Total'
      }
      
    }
    
    if(isPlot){
      if(decomp == "FCR"){
        result = result[,-1]
      }else if(decomp == "FPCR"){
        result = result[,-1]
      }
      
      if(sliceby == 'factor'){
        result = head(result, nrowPrint)
        
        if(is.null(layout)){
          n = ncol(result)
          l = 3
          while(n %% l == 1){
            l = l+1
          }
          layout = c(l,1)
        }
        
        print(barchart(result[rev(rownames(result)),], groups = FALSE, main = paste(decomp,"of", risk),layout = layout,
                       ylab = '', xlab = '', as.table = TRUE))
        
      }else if(sliceby == 'asset'){
        result = head(result, nrowPrint)
        result = t(result)
        
        if(is.null(layout)){
          n = ncol(result)
          l = 3
          while(n %% l == 1){
            l = l+1
          }
          layout = c(l,1)
        }
        
        print(barchart(result[rev(rownames(result)),], groups = FALSE, main = paste(decomp,"of", risk),layout = layout, 
                       ylab = '', xlab = '', as.table = TRUE))
      }
    }
    
    if(isPrint){
      if(is.null(digits)){
        if(decomp == 'FPCR'){
          digits = 1
        }else{
          digits = 3
        }
      }
      result = head(result, nrowPrint)
      result = round(result, digits)
      
      output = list(decomp = result)
      names(output) = paste(risk,decomp,sep = '')
      
      return(output)
    }
  } else{
    port.Sd = riskDecomp(object, risk = "Sd", weights = weights, ... )
    port.VaR = riskDecomp(object, risk ="VaR", weights = weights, p = p, type = type, invert = invert, ... )
    port.Es = riskDecomp(object,risk ="ES", weights = weights, p = p, type = type, invert = invert, ... )
    
#     if(decomp == "RM"){
#       isPlot = FALSE
#       Sd = port.Sd$portSd
#       VaR = port.VaR$portVaR
#       Es = port.Es$portES
#       
#       result = c(Sd, VaR, Es)
#       names(result) = c('Sd','VaR','ES')
#       result = result[risk]
#     } else if(decomp == "FMCR"){
    if(decomp == "FMCR"){
      Sd = port.Sd$mSd
      VaR = port.VaR$mVaR
      Es = port.Es$mES
      result = rbind(Sd, VaR, Es)
      rownames(result) = c('Sd','VaR','ES')
      result = result[risk,]
    } else if(decomp == "FCR"){
      SdRM = port.Sd$portSd
      VaRRM = port.VaR$portVaR
      EsRM = port.Es$portES
      resultRM = c(SdRM, VaRRM, EsRM)
      names(resultRM) = c('Sd','VaR','ES')
      
      Sd = port.Sd$cSd
      VaR = port.VaR$cVaR
      Es = port.Es$cES
      result = rbind(Sd, VaR, Es)
      rownames(result) = c('Sd','VaR','ES')
      result = cbind(resultRM,result)
      colnames(result)[1] = 'RM'
      result = result[risk,]
    } else if(decomp == "FPCR"){
      Sd = port.Sd$pcSd
      VaR = port.VaR$pcVaR
      Es = port.Es$pcES
      result = rbind(Sd, VaR, Es)
      rownames(result) = c('Sd','VaR','ES')
      result = cbind(rowSums(result), result)
      colnames(result)[1] = 'Total'
      result = result[risk,]
    }
    
    if(isPrint){
      if(is.null(digits)){
        if(decomp == 'FPCR'){
          digits = 1
        }else{
          digits = 3
        }
      }
      result = round(result, digits)
      
      if(type=="normal"){
        Type = 'Parametric Normal'
      }else{
        Type = 'Non-Parametric'
      }
      output = list(decomp = result)
      names(output) = paste('Portfolio',decomp, Type, sep = ' ')
      
      return(output)
    }
    
  }

}
