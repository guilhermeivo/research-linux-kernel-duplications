import json
import re
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd

RAW_DIR = Path("raw")
OUTPUT_DIR = Path("dataset")

RESULT_PATTERN = re.compile(
    r"^(SUCCESS|FAILED)\s+(.+?)\s+"
    r"((?:\d+\s+days?,\s+)?\d+:\d{2}:\d{2}(?:\.\d+)?)$"
)
DAYS_PATTERN = re.compile(r"(\d+)\s+days?,\s+")
SIMILARITY_PATTERN = re.compile(r"-sim([\d.]+)")

NAN = float("nan")


def parse_duration(value: str) -> float:
    days = 0
    match = DAYS_PATTERN.match(value)
    if match:
        days = int(match.group(1))
        value = value[match.end():]

    hours, minutes, seconds = value.split(":")
    return days * 86400 + int(hours) * 3600 + int(minutes) * 60 + float(seconds)


def parse_command_file(path: Path) -> list[dict]:
    """Lê o arquivo `command` e devolve uma linha por repositório.

    - `duration_seconds`: só preenchido quando o repositório teve SUCESSO.
      Em falhas fica NaN, para que gráficos e médias ignorem esses casos.
    - `time_to_failure_seconds`: tempo até a falha (NaN em sucessos).
      Mantido à parte caso você queira analisar *quando* as falhas ocorrem.
    """
    rows = []

    for line in path.read_text(encoding="utf-8").splitlines():
        match = RESULT_PATTERN.match(line.strip())
        if not match:
            continue

        status, repository, duration = match.groups()
        seconds = parse_duration(duration)
        succeeded = status == "SUCCESS"

        rows.append({
            "repository": repository.strip(),
            "status": status.lower(),
            "duration_seconds": seconds if succeeded else NAN,
            "time_to_failure_seconds": NAN if succeeded else seconds,
        })

    return rows


def load_metadata(execution_dir: Path) -> dict:
    """Metadados opcionais (metadata.json) na pasta da execução."""
    path = execution_dir / "metadata.json"
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def infer_similarity(execution_dir: Path):
    match = SIMILARITY_PATTERN.search(execution_dir.name)
    return float(match.group(1)) if match else None


def main():
    if not RAW_DIR.is_dir():
        raise SystemExit(f"Diretório não encontrado: {RAW_DIR.resolve()}")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    processed_at = datetime.now(timezone.utc).isoformat()

    execution_rows = []
    repository_rows = []

    for execution_dir in sorted(p for p in RAW_DIR.iterdir() if p.is_dir()):
        command_file = execution_dir / "command"
        if not command_file.exists():
            continue

        repositories = parse_command_file(command_file)
        if not repositories:
            print(f"No results: {execution_dir}")
            continue

        metadata = load_metadata(execution_dir)

        # Soma todos os arquivos cache.zip pertencentes a esta execução.
        cache_archives = list(execution_dir.rglob("cache.zip"))
        cache_zip_bytes = sum(p.stat().st_size for p in cache_archives if p.is_file())

        run_id = metadata.get("run_id", execution_dir.name)
        version = metadata.get("tool_version", execution_dir.name.split("-sim")[0])
        similarity = metadata.get("similarity", infer_similarity(execution_dir))

        for repo in repositories:
            repository_rows.append({
                "run_id": run_id,
                "tool_version": version,
                "similarity": similarity,
                **repo,
            })

        df = pd.DataFrame(repositories)
        total = len(df)
        success = int((df["status"] == "success").sum())

        execution_rows.append({
            "run_id": run_id,
            "tool_version": version,
            "similarity": similarity,
            "total": total,
            "success": success,
            "failed": total - success,
            "success_rate": success / total,
            "cache_zip_bytes": cache_zip_bytes,
            "cache_zip_count": len(cache_archives),
            # Somente repositórios bem-sucedidos (NaN é ignorado pelo sum/mean)
            "total_duration_seconds": df["duration_seconds"].sum(),
            "mean_duration_seconds": df["duration_seconds"].mean(),
            "processed_at": processed_at,
        })

    pd.DataFrame(execution_rows).to_parquet(
        OUTPUT_DIR / "executions.parquet", index=False
    )
    pd.DataFrame(repository_rows).to_parquet(
        OUTPUT_DIR / "repositories.parquet", index=False
    )

    print("Parquet files generated successfully!")


if __name__ == "__main__":
    main()
