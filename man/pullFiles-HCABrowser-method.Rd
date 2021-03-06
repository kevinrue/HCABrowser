% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/AllClasses.R
\docType{methods}
\name{pullFiles,HCABrowser-method}
\alias{pullFiles,HCABrowser-method}
\title{Obtain file uuids from a HCABrowser object}
\usage{
\S4method{pullFiles}{HCABrowser}(hca, n = 10)
}
\arguments{
\item{hca}{A HCABrowser object}

\item{n}{integer(1) number of files to pull}
}
\value{
character(1) of
}
\description{
Obtain file uuids from a HCABrowser object
}
\examples{

hca <- HCABrowser()
hca <- hca \%>\% pullFiles

}
