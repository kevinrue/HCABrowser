.manifest_fields <- c(
    'content_type',
    'crc32c',
    'indexed',
    'name',
    's3-etag',
    'sha1',
    'sha256',
    'size',
    'uuid',
    'version'
)

.manifest_fields <- paste0('manifest.files.', .manifest_fields)

.initial_source <- c(
    "project_title", "project_short_name", "organ.text",
    "library_construction_approach.text",
    "specimen_from_organism_json.genus_species.text",
    "disease.text", .manifest_fields
)

.range_ops = list(
    '<' = "lt",
    '<=' = "lte",
    '>' = 'gt',
    '>=' = 'gte'
)

.regexp_ops = c('contains', 'startsWith', 'endsWith')

.range <- c('<', '<=', '>', '>=')

.match_ops = list(
    '==' = '='
)

.fields <- function(hca)
{
    hca@supported_fields
}

#' List supported fields of an HCABrowser object
#'
#' @export
setMethod("fields", "HCABrowser", .fields)

.values <- function(x, fields=c(), ...)
{
    hca <- x
    fields_json <- jsonlite::fromJSON(hca@fields_path)
    fields <- .convert_names_to_filters(hca, fields)
    if (length(fields) > 0)
        fields_json <- fields_json[fields]
    value <- unlist(fields_json, use.names=FALSE)
    field_names <- rep(names(fields_json), lengths(fields_json))
    fields <- data.frame(field_names, value)
    as_tibble(fields)
}

#' List all values for certain fields
#'
#' @importFrom S4Vectors values
#' @export
setMethod("values", "HCABrowser", .values)

.is_bool_connector <- function(x)
{
    if (length(x) == 0)
        return(FALSE)
    names <- names(x)
    names %in% c("filter", "should", "must_not") 
}

.binary_op <- function(sep)
{
    force(sep)
    function(e1, e2) {
        field <- as.character(substitute(e1))

        value <- try({
            e2
        }, silent = TRUE)
        if (inherits(value, "try-error")) {
            value <- as.character(substitute(e2))
            if(value[1] == 'c')
                value <- value[-1]
            value
        }

        fun <- "term"

        if(length(value) > 1)
            fun <- "terms"

        if(sep %in% .range)
            fun <- "range"

        if(sep %in% .regexp_ops) {
            fun <- 'regexp'
            ## TODO parse regex string to catch protected characters
            if(sep == 'contains')
                value <- paste0('.*', value, '.*')
            if(sep == 'startsWith')
                value <- paste0(value, '.*')
            if(sep == 'endsWith')
                value <- paste0('.*', value)
        }

        field <- .convert_names_to_filters(NULL, field)

        leaf <- list(value)
        if(fun == 'range') {
            names(leaf) <- .range[sep]
            leaf <- list(leaf)
        }
        names(leaf) <- field
        leaf <- list(leaf)
        names(leaf) <- fun

        if(sep == "!=")
            leaf <- list(must_not = leaf)

        leaf
    }
}

.not_op <- function(sep)
{
    force(sep)
    function(e1) {
        list(must_not = list(e1))
    }
}

.parenthesis_op <- function(sep)
{
    force(sep)
    function(e1) {
        if(.is_bool_connector(e1))
            list(bool = list(filter = list(list(bool = e1))))
        else
            list(bool = list(filter = list(e1)))
    }
}

.combine_op <- function(sep)
{
    force(sep)
    function(e1, e2) {
        fun <- "should"
        if (sep == '&')
            fun <- "filter"

        if(.is_bool_connector(e1))
            e1 <- list(bool = e1)
        if(.is_bool_connector(e2))
            e2 <- list(bool = e2)

        con <- list(list(e1, e2))
        names(con) <- fun
        con
    }
}

.get_selections <- function(x, ret_next = FALSE)
{
    if (ret_next)
        return(names(x))
    if(!is.null(names(x)) && names(x) %in% c("term", "terms", "range", "regexp"))
        lapply(x, .get_selections, TRUE)
    else
        lapply(x, .get_selections, FALSE)
}

#' @importFrom rlang eval_tidy f_rhs f_env
.hca_filter_loop <- function(li, expr)
{
    res <- rlang::eval_tidy(expr, data= .LOG_OP_REG)
    if(length(li) == 0) {
        if(.is_bool_connector(res))
            list(filter=list(list(bool = res)))
        else
            list(filter=list(res))
    }
    else {
        if (.is_bool_connector(li) & .is_bool_connector(res))
            list(filter = list(c(list(bool = li)), list(bool = res)))
        else if(.is_bool_connector(li))
            list(filter = list(c(list(bool = li)), res))
        else if(.is_bool_connector(res))
            list(filter = list(c(li, list(bool = res))))
        else
            list(filter = list(c(li, res)))
    }
}

.temp <- function(dots)
{
    res <- Reduce(.hca_filter_loop, dots, init =  list())
    list(es_query = list(query = list(bool = res)))
}

#' Filter HCABrowser objects
#'
#' @param hca a HCABrowser object to perform a query on.
#' @param ... further argument to be tranlated into a query to select from.
#'  These arguments can be passed in two ways, either as a single expression or
#'  as a series of expressions that are to be seperated by commas.
#'
#' @return a HCABrowser object containing the resulting query.
#'
#' @examples
#'
#' hca <- HCABrowser()
#' hca2 <- hca %>% filter()
#' hca2
#'
#' hca3 <- hca %>% filter()
#' hca3
#'
#'
#' @export
#' @importFrom dplyr filter
#' @importFrom rlang quo_get_expr quos
filter.HCABrowser <- function(hca, ...)
{
    dots <- quos(...)
    es_query <- c(hca@es_query, dots)
    search_term <- .temp(es_query)
    hca@search_term <- search_term
    hca@es_query <- es_query
    
    selected <- unlist(.get_selections(search_term))
    select(hca, selected)
}

#' Select fields from a HCABrowser object
#'
#' @param hca a HCABrowser object to perform a selection on
#' @param ... further argument to be tranlated into an expression to select from.
#'  These arguments can be passed in two ways, either as a character vector or
#'  as a series of expressions that are the fields that are to be selected
#'  seperated by commas.
#'
#' @return a HCABrowser object containing the results of the selection.
#'
#' @examples
#'
#' hca <- HCABrowser()
#' hca2 <- hca %>% select(paired_end)
#' hca2
#'
#' hca3 <- hca %>% select(c('organ.text', 'paired_end'))
#' hca3
#'
#' @export
#' @importFrom dplyr select
#' @importFrom rlang quo_get_expr
select.HCABrowser <- function(hca, ..., .search = TRUE)
{
    sources <- quos(...)
    sources <- c(hca@es_source, sources)
    hca@es_source <- sources
    sources <- lapply(sources, function(x) {
        val <- try ({
            rlang::eval_tidy(x)
        }, silent = TRUE)
        if (inherits(val, "try-error")) {
            val <- as.character(rlang::quo_get_expr(x))
        }
        val
    })
    #sources <- lapply(sources, as.character)
    sources <- unlist(sources)
    if (length(sources) && sources[1] == 'c')
        sources <- sources[-1]
    sources <- unique(sources)

    sources <- .convert_names_to_filters(hca, sources)

    search_term <- hca@search_term
    if(length(search_term) == 0)
        search_term <- list(es_query = list(query = NULL))
    search_term$es_query$"_source" <- sources
    hca@search_term <- search_term

    if (.search)
        postSearch(hca, 'aws', 'raw', per_page = hca@per_page)
    else
        hca
}

.convert_names_to_filters <- function(hca, sources)
{
    if(is.null(hca))
        fields <- .get_supportedFields(NULL)
    else
        fields <- fields(hca)
    fields <- data.frame(fields)[,2]

    sources <- vapply(sources, function(x) {
        if (x == 'uuid')
            return(x)
        name <- fields[grepl(paste0('[.]', x, '$'), fields)]
        if (length(name) > 1) {
            txt <- vapply(name, function(y) {
                paste0(y, '\n')
            }, character(1))
            mes <- paste0('Field "', x, '" matched more than one field. Please select one:\n')  
            txt <- c(mes, txt)
            stop(txt)
        }
        if (length(name) == 0) {
            if (x %in% fields)
                name <- x
            else {
                message(paste0('Field "', x, '" may not be supported.'))
                name <- x
            }
        }
        name
            
    }, character(1))    
    names(sources) <- NULL
    sources
}

.LOG_OP_REG <- list()
## Assign conditions.
.LOG_OP_REG$`==` <- .binary_op("==")
.LOG_OP_REG$`%in%` <- .binary_op("==")
.LOG_OP_REG$`!=` <- .binary_op("!=")
.LOG_OP_REG$`>` <- .binary_op(">")
.LOG_OP_REG$`<` <- .binary_op("<")
.LOG_OP_REG$`>=` <- .binary_op(">=")
.LOG_OP_REG$`<=` <- .binary_op("<=")
## Custom binary operators 
.LOG_OP_REG$`%startsWith%` <- .binary_op("startsWith")
.LOG_OP_REG$`%endsWith%` <- .binary_op("endsWith")
.LOG_OP_REG$`%contains%` <- .binary_op("contains")
## not conditional.
.LOG_OP_REG$`!` <- .not_op("!")
## parenthesis
.LOG_OP_REG$`(` <- .parenthesis_op("(")
## combine filters
.LOG_OP_REG$`&` <- .combine_op("&")
.LOG_OP_REG$`|` <- .combine_op("|")

`%startsWith%` <- function(e1, e2){}
`%endsWith%` <- function(e1, e2){}
`%contains%` <- function(e1, e2){}

