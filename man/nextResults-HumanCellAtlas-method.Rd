% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/hca-api.R
\docType{methods}
\name{nextResults,HumanCellAtlas-method}
\alias{nextResults,HumanCellAtlas-method}
\title{Next Results}
\usage{
\S4method{nextResults}{HumanCellAtlas}(result)
}
\arguments{
\item{hca}{A Human Cell Atlas object the has further bundles to display}
}
\value{
A Human Cell Atlas object that displays the next results
}
\description{
Fetch the next set of bundles from a Human Cell Atlas Object
}
\examples{

hca <- HumanCellAtlas()
hca <- nextResults(hca)
hca

}
