#' Rich parse data
#'
#' Returns a tibble with one row per function/object in the string, file, or package.
#'
#' @param text The text to parse as string.
#' @param filename The file name to attach to the parsed text.
#'
#' @export
parse_text <- function(text, filename = NULL) {
  stopifnot(length(text) == 1)

  if (is.null(filename)) {
    filename <- "<text>"
  }

  expr <- parse(
    text = text,
    keep.source = TRUE,
    srcfile = srcfilecopy(filename, text, isFile = TRUE)
  )
  srcrefs <- attr(expr, "srcref")

  parsed <- as.list(expr)
  parse_data <- get_parse_data(expr)

  n_parsed <- length(parsed)
  n_parse_data <- length(parse_data)
  if (n_parsed < n_parse_data) {
    # Bind the last two parse data frames
    stopifnot(all(parse_data[[n_parse_data]]$token == "COMMENT"))
    extra <- rlang::seq2(n_parsed + 1L, n_parse_data)
    parsed[extra] <- list(rlang::zap())
    srcrefs[extra] <- list(rlang::zap())
  }

  stopifnot(length(parsed) == length(srcrefs))
  stopifnot(length(parsed) == length(parse_data))

  tibble(filename, code = parsed, srcref = srcrefs, parse_data)
}


#' @rdname parse_text
#' @param file The file to parse, must be UTF-8 encoded.
#' @export
parse_file <- function(file) {
  message(file)
  text <- brio::read_file(file)
  parse_text(text, file)
}

#' @rdname parse_text
#' @param path The package to parse, must be UTF-8 encoded.
#' @export
parse_package <- function(path = ".") {
  file <- dir(file.path(path, "R"), full.names = TRUE)
  map_dfr(file, parse_file)
}

# FIXME: Reimplement for speed
get_tree_root <- function(id, parent) {
  tree <- data.tree::FromDataFrameNetwork(data.frame(id, parent))
  list <- data.tree::ToListSimple(tree)
  trees <- map(list[-1], data.tree::FromListSimple)
  root_maps <- map(trees, data.tree::ToDataFrameNetwork)

  root_map <- imap_dfr(root_maps, ~ tibble(id = c(as.integer(.y), .x$to), root = as.integer(.y)))

  root_map$root[match(id, root_map$id)]
}

get_parse_data <- function(exprs) {
  pd <-
    utils::getParseData(exprs, includeText = TRUE) %>%
    arrange(line1, col1, desc(line2), desc(col2), parent) %>%
    as_tibble()

  root <- get_tree_root(pd$id, abs(pd$parent))
  code <- unname(split(pd, root))

  # Special case: semicolon
  length_one <- map_int(code, nrow) == 1
  has_semicolon <- map_lgl(code, ~ .x$token[[1]] == "';'")
  code <- code[!length_one | !has_semicolon]

  code
}

get_pd_space <- function(pd) {
  if (nrow(pd) == 0) {
    return(character())
  }

  line1 <- pd$line1
  col1 <- pd$col1
  line2 <- pd$line2
  col2 <- pd$col2

  delta_lines <- lead(line1, default = line2[[length(line2)]]) - line2
  same_line <- (delta_lines == 0)
  lead_col1 <- lead(col1, default = col2[[length(col2)]])
  delta_cols <- lead_col1 - col2

  out <- character(length(line1))
  out[same_line] <- strrep(" ", pmax(delta_cols[same_line] - 1, 0))
  out[!same_line] <- paste0(
    strrep("\n", delta_lines[!same_line]),
    strrep(" ", lead_col1[!same_line] - 1)
  )
  out
}
