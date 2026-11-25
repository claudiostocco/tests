"""Lógica de varredura e extração de texto de PDFs com PyMuPDF (fitz)."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterator, List, Optional

import pymupdf as fitz  # PyMuPDF (substitui o import `fitz` depreciado)
from rich.console import Console

from .utils import build_process_pattern, extract_snippet, highlight, normalize_process_number

console = Console()

# Mensagem de aviso para PDFs corrompidos / protegidos por senha (spec seção 6).
MSG_CORROTED = "[Aviso] Arquivo corrompido ou inacessível: {}"


@dataclass
class Occurrence:
    """Uma ocorrência do número de processo em uma página de PDF."""

    arquivo: str
    pagina: int  # base 1
    termo: str
    snippet: str
    texto_pagina: str


@dataclass
class ScanResult:
    """Resultado da varredura de um único PDF."""

    arquivo: str
    paginas: int
    ocorrencias: List[Occurrence]
    pesquisa_velha: bool  # True quando nenhuma página retornou texto (imagem/escaneado)
    erro: Optional[str] = None


def _limpar_texto(texto: str) -> str:
    """Normaliza espaços em branco do texto extraído para facilitar a busca."""
    return texto.replace("\x00", "")


def varrer_pdf(caminho: Path, processo_digits: str) -> ScanResult:
    """Varre um único PDF página a página buscando o número do processo.

    Para cada página:
      - abre com ``fitz.open``;
      - itera página a página;
      - extrai texto via ``page.get_text("text")``;
      - busca ocorrências com regex flexível.
    """
    nome = caminho.name
    ocorrencias: List[Occurrence] = []
    total_paginas = 0
    texto_geral_vazio = True  # detecta PDF não pesquisável (imagem/escaneado)

    pattern = build_process_pattern(processo_digits)

    try:
        doc = fitz.open(str(caminho))
    except fitz.FileDataError as exc:  # corrompido ou protegido por senha
        return ScanResult(
            arquivo=nome,
            paginas=0,
            ocorrencias=[],
            pesquisa_velha=False,
            erro=MSG_CORROTED.format(nome),
        )
    except Exception as exc:  # qualquer outra falha na abertura
        return ScanResult(
            arquivo=nome,
            paginas=0,
            ocorrencias=[],
            pesquisa_velha=False,
            erro=f"[Aviso] Não foi possível abrir o arquivo {nome}: {exc}",
        )

    try:
        total_paginas = doc.page_count
        for indice in range(total_paginas):
            pagina = doc[indice]
            texto = _limpar_texto(pagina.get_text("text"))
            if texto.strip():
                texto_geral_vazio = False

            if pattern is None or not texto:
                continue

            for match in pattern.finditer(texto):
                snippet = extract_snippet(texto, match)
                ocorrencias.append(
                    Occurrence(
                        arquivo=nome,
                        pagina=indice + 1,  # base 1
                        termo=match.group(0),
                        snippet=snippet,
                        texto_pagina=texto,
                    )
                )
    finally:
        doc.close()

    return ScanResult(
        arquivo=nome,
        paginas=total_paginas,
        ocorrencias=ocorrencias,
        pesquisa_velha=texto_geral_vazio and total_paginas > 0,
    )


def listar_pdfs(pasta: Path) -> List[Path]:
    """Lista recursivamente todos os arquivos ``.pdf`` / ``.PDF`` da pasta."""
    if not pasta.exists():
        return []
    return sorted(p for p in pasta.rglob("*") if p.is_file() and p.suffix.lower() == ".pdf")


def varrer_pasta(pasta: Path, processo: str) -> Iterator[ScanResult]:
    """Varre todos os PDFs de uma pasta, gerando os resultados um a um."""
    processo_digits = normalize_process_number(processo)
    pdfs = listar_pdfs(pasta)
    if not pdfs:
        return
    for pdf in pdfs:
        yield varrer_pdf(pdf, processo_digits)


def varrer_url(url: str, processo: str) -> Iterator[ScanResult]:
    """Baixa um PDF via URL e o varre, removendo o temporário ao final (padrão)."""
    from .downloader import KEEP_TEMP, download_pdf

    processo_digits = normalize_process_number(processo)
    caminho: Optional[Path] = None
    try:
        caminho = download_pdf(url)
        yield varrer_pdf(caminho, processo_digits)
    finally:
        if caminho is not None and caminho.exists() and not KEEP_TEMP:
            try:
                caminho.unlink()
                console.print(f"[dim]Arquivo temporário removido: {caminho}[/dim]")
            except OSError:
                pass
