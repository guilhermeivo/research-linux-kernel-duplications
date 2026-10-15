source("utils.R")

scale_color_brewer(palette = "Set3")

check_func <- function(df, name, func) {
  cat("\n---", name, "---\n")
  print(df[
    grepl(func, df$func_a_full) |
    grepl(func, df$func_b_full),
  ])
}

gen_graph <- function(subsystem, min_weight, top) {
  df <- df_filtered[df_filtered$subsystem == subsystem, ]

  edges <- data.frame(
    from = df$func_a_full,
    to = df$func_b_full,
    weight = df$duplicated_lines
  )

  edges <- aggregate(weight ~ from + to, data = edges, sum)
  edges <- edges[order(-edges$weight), ]
  edges <- edges[edges$weight >= min_weight, ]
  edges <- edges[1:min(top, nrow(edges)), ]

  top <- nrow(edges)

  g <- graph_from_data_frame(edges, directed = FALSE)

  V(g)$degree <- degree(g)

  g <- delete_vertices(g, V(g)$degree < 2)

  comp <- components(g)

  keep <- which(comp$csize[comp$membership] >= 3)

  g <- induced_subgraph(
    g,
    vids = keep
  )

  clean_labels <- function(g, prefix) {
    pattern <- paste0(prefix, "::")
    V(g)$label <- sub(pattern, "", V(g)$name)
    g
  }

  g <- clean_labels(g, subsystem)
  V(g)$label <- sub(".*::", "", V(g)$name)

  V(g)$size <- scales::rescale(
    log1p(V(g)$degree),
    to = c(3, 15)
    )

  comp <- components(g)
  V(g)$comp <- comp$membership

  E(g)$width <- log1p(E(g)$weight)

  layout <- layout_with_kk(g, weights = E(g)$weight, maxiter = 3000)
#   layout <- layout_with_fr(g, niter = 5000)
#   layout <- layout_with_graphopt(g, niter = 5000)

  V(g)$label_show <- ifelse(
    V(g)$degree >= quantile(V(g)$degree, 0.9),
    V(g)$label,
    ""
  )

  p <- ggraph(g, layout = layout) +
    geom_edge_link(
      aes(width = log1p(weight)),
      alpha = 0.35,
      colour = "grey40"
    ) +
    geom_node_point(
      aes(
        color = as.factor(comp),
        size = size
      ),
      alpha = 0.85
    ) +
    geom_node_text(
      aes(label = label),
    #   aes(label = label_show),
      repel = TRUE,
      size = 2.5,
      max.overlaps = 30,
      family = "mono"
    ) +
    scale_edge_width(range = c(0.2, 1.5)) +
    labs(
    #   title = paste("Grafo de duplicação - drivers/", gsub("\\.", "/", subsystem), sep = ""),
    #   subtitle = TeX(paste("Nós representam funções; arestas agregam linhas duplicadas ($\\geq ", min_weight, "$), exibindo as ", top, " conexões mais relevantes", sep = "")),
      size = "Conexões"
    ) +
    guides(color = "none", size = "none") +
    theme(
      text = element_text(family = "serif"),
    #   plot.title = element_text(size = 14, face = "bold"),
    #   plot.subtitle = element_text(size = 10, margin = margin(b = 10)),
      legend.position = "none",
      panel.grid = element_blank(),
      axis.text = element_blank(),
      axis.title = element_blank(),

      panel.background = element_rect(fill = "transparent"),
      plot.margin = margin(0, 0, 0, 0),
    #   panel.background = element_rect(fill = "#f7f7f7"),
    #   plot.margin = margin(50, 50, 50, 50),
    )

  ggsave(
    paste("plots/", gsub("\\.", "_", subsystem), "_dup_graph.pdf", sep = ""),
    p,
    width = 12,
    height = 10,
    dpi = 300,
    bg = "transparent"
  )
}

# gen_graph(
#   subsystem = "gpu.drm.amd.display",
#   min_weight = 50,
#   top = 200
# )
# gen_graph(
#   subsystem = "gpu.drm.amd.amdgpu",
#   min_weight = 15,
#   top = 200
# )
gen_graph(
  subsystem = "gpu",
  min_weight = 15,
  top = 250
)
gen_graph(
  subsystem = "iio",
  min_weight = 15,
  top = 250
)
