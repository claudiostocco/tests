"""Lógica de download de PDF via URL com barra de progresso (streaming)."""

from __future__ import annotations

from pathlib import Path
from typing import Optional

import requests
from rich.console import Console
from rich.progress import (
    BarColumn,
    DownloadColumn,
    Progress,
    TimeRemainingColumn,
    TransferSpeedColumn,
)

console = Console()

# Pasta temporária usada para armazenar PDFs baixados via URL.
TEMP_DIR = Path("./temp")
# Quando False, o arquivo baixado é removido após a varredura. Quando True,
# é retido em TEMP_DIR. Configurável conforme a spec (seção 3.3, Cenário B).
KEEP_TEMP = False


class DownloadError(Exception):
    """Erro ao baixar o PDF de uma URL."""


def download_pdf(url: str, dest_dir: Path = TEMP_DIR) -> Path:
    """Baixa o PDF de ``url`` via streaming com barra de progresso.

    Retorna o caminho do arquivo armazenado em ``dest_dir``.
    Lança :class:`DownloadError` em caso de falha de rede/timeout/URL inválida.
    """
    dest_dir.mkdir(parents=True, exist_ok=True)
    nome_arquivo = Path(url).name or "rpi.pdf"
    if not nome_arquivo.lower().endswith(".pdf"):
        nome_arquivo = "rpi.pdf"
    destino = dest_dir / nome_arquivo

    try:
        with requests.get(url, stream=True, timeout=30) as resposta:
            resposta.raise_for_status()
            total = int(resposta.headers.get("content-length", 0) or 0)

            with Progress(
                "[progress.description]{task.description}",
                BarColumn(),
                DownloadColumn(),
                TransferSpeedColumn(),
                TimeRemainingColumn(),
                console=console,
                transient=True,
            ) as progress:
                tarefa = progress.add_task(f"Baixando {nome_arquivo}", total=total)
                with open(destino, "wb") as arquivo:
                    for bloco in resposta.iter_content(chunk_size=1024 * 64):
                        if not bloco:
                            continue
                        arquivo.write(bloco)
                        progress.update(tarefa, advance=len(bloco))
    except requests.exceptions.RequestException as exc:  # timeout, URL inválida, etc.
        # Remove arquivo parcial, se existir.
        try:
            if destino.exists():
                destino.unlink()
        except OSError:
            pass
        raise DownloadError(f"Falha ao baixar a URL: {exc}") from exc

    # Um arquivo baixado vazio (0 bytes) nunca deve ser confundido com
    # "processo não encontrado"; trata como falha de download.
    if destino.stat().st_size == 0:
        try:
            destino.unlink()
        except OSError:
            pass
        raise DownloadError(f"Arquivo baixado está vazio: {url}")

    console.print(f"[green]✔ Download concluído:[/green] {destino}")
    return destino
