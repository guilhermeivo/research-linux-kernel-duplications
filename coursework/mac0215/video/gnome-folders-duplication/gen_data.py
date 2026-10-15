from pathlib import Path
import json
import subprocess
import sys
from collections import defaultdict
import networkx as nx

folder = Path(sys.argv[1])

nodes = {}

for file in sorted(folder.iterdir()):
    if file.is_file():
        nodes[file.name] = {
            "id": file.name,
            "duplicated_lines": 0,
            "x": 0,
            "y": 0
        }

f = subprocess.run(
    ["arkanjo", "explorer", "--json"],
    capture_output=True,
    encoding="utf-8"

)
output = f.stdout
duplicates = json.loads(output)


edges = defaultdict(int)

for item in duplicates:
    a = item["filename_a"]
    b = item["filename_b"]

    lines = item["duplicated_lines"]

    if a in nodes:
        nodes[a]["duplicated_lines"] += lines

    if b in nodes:
        nodes[b]["duplicated_lines"] += lines

    key = tuple(sorted([a,b]))

    edges[key] += lines

graph = {
    "nodes": sorted(
        nodes.values(),
        key=lambda node: node["id"]
    ),
    "edges": []
}

for (a,b), weight in edges.items():
    graph["edges"].append({
        "source": a,
        "target": b,
        "duplicated_lines": weight
    })

G = nx.Graph()

for node in graph["nodes"]:
    G.add_node(
        node["id"],
        weight=node["duplicated_lines"]
    )

for link in graph["edges"]:
    G.add_edge(
        link["source"],
        link["target"],
        weight=link["duplicated_lines"]
    )

similarity_graph = G.subgraph(
    [
        n for n in G.nodes
        if G.nodes[n]["weight"] > 0
    ]
)

import math


def apply_min_distance(pos, min_distance=1.0, iterations=100):
    nodes = list(pos.keys())

    for _ in range(iterations):
        moved = False
        for i in range(len(nodes)):
            for j in range(i + 1, len(nodes)):
                a = nodes[i]
                b = nodes[j]

                ax, ay = pos[a]
                bx, by = pos[b]

                dx = bx - ax
                dy = by - ay

                distance = math.sqrt(
                    dx * dx +
                    dy * dy
                )

                if distance == 0:
                    dx = 0.01
                    dy = 0.01
                    distance = math.sqrt(
                        dx * dx +
                        dy * dy
                    )

                if distance < min_distance:
                    force = (
                        min_distance - distance
                    ) / 2

                    nx = dx / distance
                    ny = dy / distance

                    pos[a] = (
                        ax - nx * force,
                        ay - ny * force
                    )

                    pos[b] = (
                        bx + nx * force,
                        by + ny * force
                    )

                    moved = True

        if not moved:
            break

    return pos

local_pos = nx.spring_layout(G, k=2.0, iterations=100, weight="weight")

local_pos = apply_min_distance(
    local_pos,
    min_distance=2.0,
    iterations=200
)

factor = 25.0
pos_factor = {no: (coords[0] * factor, coords[1] * factor) for no, coords in local_pos.items()}

for node in graph["nodes"]:
    degree = G.degree(node["id"])

    if (
        node["duplicated_lines"] == 0
        or degree < 10
    ):
        node["x"] = -1
        node["y"] = -1
    else:
        x, y = pos_factor[node["id"]]

        node["x"] = float(x)
        node["y"] = float(y)

graph["nodes"] = sorted(
    graph["nodes"],
    key=lambda node: node["id"]
)

with open("data.json", "w", encoding="utf-8") as f:
    json.dump(
        graph,
        f,
        indent=4,
        ensure_ascii=False
    )
