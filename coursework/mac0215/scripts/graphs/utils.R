pdf(NULL)
par(family = "serif")

library(jsonlite)
library(dplyr)
library(purrr)
library(tidyr)
library(stringr)
library(ggplot2)
library(igraph)
library(ggraph)
library(viridis)
library(latex2exp)

base_dir <- "~/.cache/arkanjo"
number_of_duplicates <- 5000
separator <- "::"

all_files <- Sys.glob(file.path(base_dir, "*", "*.json"))
files <- all_files[grepl(".*/([^/]+)/\\1\\.json$", all_files)]

blacklist_subsystems <- c()
blacklist_files <- c("pinctrl::ARRAY_SIZE")

read_json_with_name <- function(file) {
  subsystem <- str_extract(file, "(?<=arkanjo/)[^/]+")

  tryCatch({
    raw <- fromJSON(file, simplifyVector = TRUE)
    df <- if (is.data.frame(raw)) raw else as_tibble(raw)
    df %>% mutate(subsystem = subsystem)
  }, error = function(e) {
    message("Error read file: ", file)
    return(NULL)
  })
}

df <- map_dfr(files, read_json_with_name)

split_cols <- function(df, col, sufix) {
  parts <- do.call(rbind, strsplit(df[[col]], separator))

  df[[paste0("file_", sufix)]] <- parts[, 1]
  df[[paste0("func_", sufix)]] <- parts[, 2]

  df[[col]] <- NULL

  df
}

df <- split_cols(df, "path_a", "a")
df <- split_cols(df, "path_b", "b")

df$file_a_full <- paste(df$subsystem, df$file_a, sep = "::")
df$file_b_full <- paste(df$subsystem, df$file_b, sep = "::")
df$func_a_full <- paste(
  df$file_a,
  df$func_a,
  sep = "::"
)
df$func_b_full <- paste(
  df$file_b,
  df$func_b,
  sep = "::"
)

df$pair_full <- paste(df$func_a_full, "vs", df$func_b_full)

df$duplicated_lines <- as.numeric(df$duplicated_lines)
df_no_all_na <- df[, colSums(is.na(df)) < nrow(df)]

df_small <- df[
  !is.na(df$duplicated_lines) & df$duplicated_lines >= 5,
]
# df_small <- df_small[
#   order(-df_small$duplicated_lines),
# ][1:min(number_of_duplicates, nrow(df_small)), ]

df_filtered <- df_small[
  (!df_small$subsystem %in% blacklist_subsystems) &
  (!df_small$func_a_full %in% blacklist_files) &
  (!df_small$func_b_full %in% blacklist_files),
]

dir.create("plots", showWarnings = FALSE)

dev.off()
