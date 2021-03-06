% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/filter-utilities.R
\name{filter.HCABrowser}
\alias{filter.HCABrowser}
\title{Filter HCABrowser objects}
\usage{
\method{filter}{HCABrowser}(hca, ...)
}
\arguments{
\item{hca}{a HCABrowser object to perform a query on.}

\item{...}{further argument to be tranlated into a query to select from.
These arguments can be passed in two ways, either as a single expression or
as a series of expressions that are to be seperated by commas.}
}
\value{
a HCABrowser object containing the resulting query.
}
\description{
Filter HCABrowser objects
}
\examples{

hca <- HCABrowser()
hca2 <- hca \%>\% filter()
hca2

hca3 <- hca \%>\% filter()
hca3


}
