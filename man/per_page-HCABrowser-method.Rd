% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/AllClasses.R
\docType{methods}
\name{per_page,HCABrowser-method}
\alias{per_page,HCABrowser-method}
\title{Set per_page argument of HCABrowser object}
\usage{
\S4method{per_page}{HCABrowser}(hca, n)
}
\arguments{
\item{hca}{a HCABrowser object}

\item{n}{the new per_page value}
}
\value{
a HCABrowser with updated per_page value
}
\description{
note that no more than 10 pages can be displayed at once
}
\examples{

hca <- HCABrowser()
hca <- per_page(hca, 5)
hca

}
