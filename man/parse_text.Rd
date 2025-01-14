% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/parse.R
\name{parse_text}
\alias{parse_text}
\alias{parse_file}
\alias{parse_package}
\title{Rich parse data}
\usage{
parse_text(text, filename = NULL)

parse_file(file)

parse_package(path = ".")
}
\arguments{
\item{text}{The text to parse as string.}

\item{filename}{The file name to attach to the parsed text.}

\item{file}{The file to parse, must be UTF-8 encoded.}

\item{path}{The package to parse, must be UTF-8 encoded.}
}
\description{
Returns a tibble with one row per function/object in the string, file, or package.
}
