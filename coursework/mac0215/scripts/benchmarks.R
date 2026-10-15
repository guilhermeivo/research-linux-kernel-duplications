library(arrow)
library(dplyr)
library(tidyr)
library(fmsb)
library(stringr)
library(ggplot2)

ROOT_FOLDER <- "scripts/benchmarks"

methods <- list(
    "1" = "NLP Similarity (Gensim)",
    "2" = "Line Overlap (Diff)",
    "3" = "AST Linearizada (Tree-sitter)",
    "4" = "Embeddings (Code LM)"
)

linetype_mapping <- c(
    "NLP Similarity (Gensim)" = "dotted",
    "Line Overlap (Diff)" = "dotdash",
    "AST Linearizada (Tree-sitter)" = "dashed",
    "Embeddings (Code LM)" = "solid"
)

results_dir <- paste0(ROOT_FOLDER, "/", "results")

type_filter <- "fixed" # "fixed" ou "best"
threshold_chose <- 90

syntactic_type_line_chart <- "Aggregate"

syntactic_type_order <- c(
    "Aggregate",
    "Type-1",
    "Type-2",
    "Very Strong Type-3",
    "Strong Type-3",
    "Moderate Type-3",
    "Type-4"
)

colors_border <- c("#D55E00", "#4D4D4D", "#009E73", "#0072B2")

color_mapping <- setNames(colors_border, unname(unlist(methods)))
linetype <- c("dotted", "dotdash", "dashed", "solid")
linetype_radar <- c(
    3, # dotted
    4, # dotdash
    2, # dashed
    1 # solid
)
linetype_mapping <- setNames(linetype, unname(unlist(methods)))
linetype_mapping_radar <- setNames(linetype_radar, unname(unlist(methods)))

width_figure <- 6
height_figure <- 4.5

my_theme <- theme_minimal(base_size = 11, base_family = "serif") +
    theme(
        plot.title = element_text(size = 13, face = "bold", hjust = 0.5),
        axis.title = element_text(size = 12),
        axis.text = element_text(size = 11),
        legend.text = element_text(size = 11),
        legend.title = element_text(size = 12, face = "bold"),
        legend.position = "bottom"
    )

read_and_aggregate <- function(path_file) {
    base_name <- basename(path_file)
    method_id <- str_replace(base_name, "\\.parquet", "") %>%
                 str_replace(paste0("^", dataset, "_"), "")

    ds <- open_dataset(path_file, format = "parquet")

    meta <- ds$schema$metadata
    exec_time <- NA_real_

    if (!is.null(meta) && "timestamp" %in% names(meta)) {
        exec_time <- as.numeric(meta[["timestamp"]])
    }

    agg <- ds %>%
        mutate(
            is_TP = as.integer(y_true == 1 & y_pred == 1),
            is_FP = as.integer(y_true == 0 & y_pred == 1),
            is_FN = as.integer(y_true == 1 & y_pred == 0)
        ) %>%
        group_by(syntactic_type, threshold) %>%
        summarise(
            TP = sum(is_TP, na.rm = TRUE),
            FP = sum(is_FP, na.rm = TRUE),
            FN = sum(is_FN, na.rm = TRUE),
            .groups = "drop"
        ) %>%
        collect()

    method_name <- methods[[method_id]]
    agg$method <- ifelse(is.null(method_name), method_id, method_name)
    agg$exec_time <- exec_time

    return(agg)
}

radar_plot <- function(dataset, dataset_label, type_filter, pdf = TRUE) {
    if (type_filter == "fixed") {
        df_radar_metrics <- df_base_metrics %>%
            filter(threshold == threshold_chose)
    } else {
        df_radar_metrics <- df_base_metrics %>%
            group_by(method, syntactic_type) %>%
            slice_max(order_by = recall, n = 1, with_ties = FALSE) %>%
            ungroup()
    }

    df_large <- df_radar_metrics %>%
        select(method, syntactic_type, recall) %>%
        pivot_wider(names_from = syntactic_type, values_from = recall, values_fill = 0) %>%
        as.data.frame()

    rownames(df_large) <- df_large$method
    df_large <- df_large %>% select(-method)

    syntactic_type_list <- syntactic_type_order[syntactic_type_order != "Aggregate"]

    available_cols <- intersect(syntactic_type_list, colnames(df_large))
    df_large <- df_large[, c(available_cols), drop = FALSE]

    max_min <- data.frame(
        matrix(rep(c(1.0, 0.0), each = ncol(df_large)), nrow = 2, byrow = TRUE)
    )
    colnames(max_min) <- colnames(df_large)
    rownames(max_min) <- c("Max", "Min")

    df_radar <- rbind(max_min, df_large)

    plot_colors <- color_mapping[rownames(df_large)]
    plot_fills <- scales::alpha(plot_colors, 0.2)
    plot_lty <- linetype_mapping_radar[rownames(df_large)]

    title_radar <- "Recall por Tipo Sintático"
    if (type_filter == "fixed") {
        title_radar <- paste0("\\caption{Comparação do Recall por Tipo Sintático (T1 a T4) utilizando limiar de ", threshold_chose, "\\% na base ", dataset_label, "}")
    }

    if (pdf == TRUE) {
        pdf(paste0(ROOT_FOLDER, "/", dataset, "/spider_chart.pdf"), width = width_figure, height = 6, family = "serif")
    }
    par(mar = c(4, 1, 1, 1), family = "serif", cex = 1.1, xpd=TRUE)

    radarchart(
        df_radar,
        axistype = 1,
        pcol = plot_colors,
        pfcol = plot_fills,
        plwd = 2,
        plty = plot_lty,
        cglcol = "grey",
        cglty = 1,
        axislabcol = "black",
        caxislabels = seq(0, 1, 0.25),
        cglwd = 0.8,
        vlcex = 1.0,
        family = "serif"
    )
    legend(
        "bottom",
        legend = rownames(df_large),
        col = plot_colors,
        lty = plot_lty,
        lwd = 2,
        ncol = 2,
        bty = "n",
        inset = c(0, -0.18),
        xpd = NA
    )
    if (pdf == FALSE) {
        title(main = str_wrap(title_radar, width = 80), family="serif", cex.main = 1.3)
    }

    if (pdf == TRUE) {
        dev.off()
        writeLines(title_radar, paste0(ROOT_FOLDER, "/", dataset, "/spider_chart_title.tex"))
    }
}

pr_chart_plot <- function(dataset, syntactic_type_line, label = NULL) {
    df_pr <- df_base_metrics %>%
        filter(tolower(syntactic_type) == tolower(syntactic_type_line)) %>%
        arrange(method, threshold)

    formatted_type <- str_to_title(syntactic_type_line)

    if (!is.null(label)) {
        title_chart <- paste0("\\caption{", label, "}")
    } else {
        title_chart <- paste0("\\caption{}")
    }

    grafico_pr <- ggplot(df_pr, aes(x = recall, y = precision, color = method, group = method, linetype = method)) +
        geom_path(linewidth = 1) +
        geom_point(aes(size = threshold), alpha = 0.6) +
        scale_color_manual(values = color_mapping) +
        scale_linetype_manual(values = linetype_mapping) +
        labs(
            # title = paste("Precision-Recall Curve (", formatted_type, ") - ", dataset),
            x = "Recall",
            y = "Precision",
            color = "Método",
            size = "Limiar",
            linetype = "Método"
        ) +
        my_theme +
        theme(
            legend.position = "bottom",
            legend.box = "vertical"
        ) +
        coord_fixed(ratio = 1) +
        scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
        scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
        guides(
            color = guide_legend(
                order = 1,
                ncol = 2
            ),
            linetype = "none",
            size = guide_legend(
                order = 2,
                ncol = 2
            )
        )

    if (pdf == TRUE) {
        pdf(paste0(ROOT_FOLDER, "/", dataset, "/pr_chart.pdf"), width = width_figure, height = 6, family = "serif")
    }
    print(grafico_pr)
    if (pdf == TRUE) {
        dev.off()

        writeLines(title_chart, paste0(ROOT_FOLDER, "/", dataset, "/pr_chart_title.tex"))
    }
}

line_chart_plot <- function(
    dataset, dataset_label,
    syntactic_type_line,
    metric = "f1_score",
    metric_label = "F1-Score",
    pdf = TRUE,
    label = NULL
) {
    df_line_chart <- df_base_metrics %>%
        filter(tolower(syntactic_type) == tolower(syntactic_type_line))

    df_max_points <- df_line_chart %>%
        group_by(method) %>%
        slice_max(order_by = .data[[metric]], n = 1, with_ties = FALSE) %>%
        ungroup()

    formatted_type <- str_to_title(syntactic_type_line)

    if (!is.null(label)) {
        title_line_chart <- paste0("\\caption{", label, "}")
    } else {
        title_line_chart <- paste0("\\caption{", metric_label, " ", formatted_type, " dos métodos em relação ao limiar de similaridade no ", dataset_label, "}")
    }
    y_label_line_chart <- paste(metric_label)

    grafico_linhas <- ggplot(df_line_chart, aes(x = threshold, y = .data[[metric]], color = method, linetype = method)) +
        geom_line(linewidth = 1) +
        geom_point(data = df_max_points,
            aes(x = threshold, y = .data[[metric]]),
            size = 4,
            shape = 21,
            stroke = 1.5,
            fill = "white",
            show.legend = FALSE) +
        scale_color_manual(values = color_mapping) +
        scale_linetype_manual(values = linetype_mapping) +
        labs(
            # title = title_line_chart,
            x = "Limiar",
            y = y_label_line_chart,
            color = "Método",
            linetype = "Método"
        ) +
        my_theme +
        theme(
            legend.position = "bottom",
            panel.grid.minor = element_blank()
        ) +
        scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
        guides(
            color = guide_legend(ncol = 2),
            linetype = guide_legend(ncol = 2)
        )

    if (pdf == TRUE) {
        pdf(paste0(ROOT_FOLDER, "/", dataset, "/", metric, "_", syntactic_type_line, "_line_chart.pdf"), width = width_figure, height = height_figure, family = "serif")
    }
        print(grafico_linhas)
    if (pdf == TRUE) {
        dev.off()

        writeLines(title_line_chart, paste0(ROOT_FOLDER, "/", dataset, "/", metric, "_", syntactic_type_line, "_line_chart_title.tex"))
    }
}

time_chart_plot <- function(dataset, dataset_label, pdf = TRUE) {
    df_time <- df_aggregated %>%
        select(method, exec_time) %>%
        distinct() %>%
        filter(!is.na(exec_time))

    if(nrow(df_time) == 0) {
        warning("Nenhum timestamp encontrado nos metadados. O gráfico não será gerado.")
        return(invisible(NULL))
    }

    title_time_chart <- paste("Tempo de Execução (s) -", dataset_label)

    grafico_tempo <- ggplot(df_time, aes(x = reorder(method, exec_time), y = exec_time, fill = method)) +
        geom_col(alpha = 0.85, width = 0.6) +
        geom_text(aes(label = sprintf("%.2fs", exec_time)), hjust = -0.15, family = "serif", size = 4) +
        scale_fill_manual(values = color_mapping) +
        coord_flip() +
        labs(
            title = title_time_chart,
            x = "Método",
            y = "Tempo (segundos)",
            fill = "Método"
        ) +
        my_theme +
        theme(
            legend.position = "none",
            panel.grid.minor = element_blank(),
            panel.grid.major.y = element_blank()
        ) +
        scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
        guides(
            color = guide_legend(ncol = 2),
            linetype = guide_legend(ncol = 2)
        )

    if (pdf == TRUE) {
        pdf(paste0(ROOT_FOLDER, "/", dataset, "/time_chart.pdf"), width = width_figure, height = height_figure, family = "serif")
    }
    print(grafico_tempo)
    if (pdf == TRUE) {
        dev.off()

        writeLines(title_time_chart, paste0(ROOT_FOLDER, "/", dataset, "/time_chart_title.tex"))
    }
}

tradeoff_plot <- function(dataset, dataset_label, threshold_val = 90, pdf = TRUE) {
    df_tradeoff <- df_base_metrics %>%
        filter(threshold == threshold_val, tolower(syntactic_type) == "aggregate") %>%
        filter(!is.na(exec_time))

    title_chart <- paste0("\\caption{Relação entre o tempo de execução e o F1-Score para cada método avaliado na base ", dataset_label, " com limiar de ", threshold_val, "\\%}")

    grafico_tradeoff <- ggplot(df_tradeoff, aes(x = exec_time, y = f1_score, color = method)) +
        geom_point(size = 5, alpha = 0.8) +
        # geom_text_repel(aes(label = method), family = "serif", vjust = -1.5) + # (Requer pacote ggrepel)
        scale_color_manual(values = color_mapping) +
        labs(

            x = "Tempo de Execução (s)",
            y = "F1-Score",
            color = "Método"
        ) +
        my_theme +
        theme(
            legend.position = "bottom",
            panel.grid.minor = element_blank()
        ) +
        guides(
            color = guide_legend(ncol = 2),
            linetype = guide_legend(ncol = 2)
        )

    if (pdf == TRUE) {
        pdf(paste0(ROOT_FOLDER, "/", dataset, "/trade_off.pdf"), width = width_figure, height = height_figure, family = "serif")
    }
    print(grafico_tradeoff)
    if (pdf == TRUE) {
        dev.off()

        writeLines(title_chart, paste0(ROOT_FOLDER, "/", dataset, "/trade_off.tex"))
    }
}

df_by_dataset <- function(dataset) {
    files_parquet <- list.files(
        results_dir,
        pattern = paste0("^", dataset, "(.*)\\.parquet$"),
        full.names = TRUE
    )

    df_aggregated <- bind_rows(lapply(files_parquet, read_and_aggregate))

    df_base_metrics <- df_aggregated %>%
        mutate(syntactic_type = str_to_title(syntactic_type)) %>%
        mutate(
            precision = ifelse((TP + FP) == 0, 0, TP / (TP + FP)),
            recall = ifelse((TP + FN) == 0, 0, TP / (TP + FN)),
            f1_score = ifelse((precision + recall) == 0, 0, 2 * (precision * recall) / (precision + recall))
        )

    return (list(aggregated = df_aggregated, base_metrics = df_base_metrics))
}

pdf = TRUE

# -------------
# bigclonebench
# -------------

dataset <- "bigclonebench"
dataset_label <- "BigCloneBench"

dfs <- df_by_dataset(dataset)
df_aggregated <- dfs$aggregated
df_base_metrics <- dfs$base_metrics

if (pdf == FALSE) {
    pdf(paste0(ROOT_FOLDER, "/", dataset, "/Rplots.pdf"), width = width_figure, height = height_figure, family = "serif")
}

radar_plot(dataset, dataset_label, type_filter, pdf = pdf)
line_chart_plot(dataset, dataset_label, "Aggregate", pdf = pdf)
for (type in syntactic_type_order) {
    line_chart_plot(dataset, dataset_label, type, pdf = pdf, metric = "recall", metric_label = "Recall")
}

time_chart_plot(dataset, dataset_label, pdf = pdf)
tradeoff_plot(dataset, dataset_label, threshold_val = threshold_chose, pdf = pdf)
pr_chart_plot(dataset, syntactic_type_line_chart, label = "Curva Precision-Recall agregada na base BigCloneBench.")

if (pdf == FALSE) {
    dev.off()
}

# ------
# poj104
# ------

dataset <- "poj104"
dataset_label <- "Poj-104"

dfs <- df_by_dataset(dataset)
df_aggregated <- dfs$aggregated
df_base_metrics <- dfs$base_metrics

if (pdf == FALSE) {
    pdf(paste0(ROOT_FOLDER, "/", dataset, "/Rplots.pdf"), width = width_figure, height = height_figure, family = "serif")
}

line_chart_plot(dataset, dataset_label, "Aggregate", pdf = pdf, label = "Eficácia dos modelos na detecção de clones semânticos na base POJ-104")
time_chart_plot(dataset, dataset_label, pdf = pdf)
tradeoff_plot(dataset, dataset_label, threshold_val = threshold_chose, pdf = pdf)
pr_chart_plot(dataset, "Aggregate")

if (pdf == FALSE) {
    dev.off()
}
