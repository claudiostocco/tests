"""Utilitários de formatação, normalização e extração de trechos (snippets)."""

from __future__ import annotations

import re
from typing import Optional

# Janela de contexto (caracteres) antes e depois do termo localizado, conforme
# a especificação técnica (seção 5 - Algoritmo de Extração do Trecho).
SNIPPET_WINDOW = 120


def normalize_process_number(texto: str) -> str:
    """Sanitiza a entrada do usuário, mantendo apenas os dígitos.

    Permite buscas tanto pelo número cru (somente dígitos) quanto formatado
    com pontos, hífens, barras ou espaços (ex.: ``912345678`` ou
    ``BR 10 2023/001234``).
    """
    return re.sub(r"\D", "", texto or "")


def build_process_pattern(digits: str) -> Optional[re.Pattern]:
    """Constrói uma regex flexível que localiza os dígitos em ordem.

    Entre cada dígito são permitidos separadores opcionais (espaço, ponto,
    hífen ou barra), de modo que tanto ``942431626`` quanto
    ``942.431.626`` ou ``942 431 626`` sejam encontrados.
    """
    if not digits:
        return None
    # Espelha os dígitos com separadores opcionais entre eles.
    corpo = r"[.\s/\-]?".join(re.escape(d) for d in digits)
    return re.compile(corpo)


def clean_snippet(texto: str) -> str:
    """Limpa quebras de linha repetidas e espaços para exibição no terminal."""
    texto = re.sub(r"\n{2,}", "\n", texto)
    texto = re.sub(r"[ \t]+", " ", texto)
    return texto.strip()


def extract_snippet(texto: str, match: re.Match, window: int = SNIPPET_WINDOW) -> str:
    """Recorta a janela de contexto ao redor da correspondência.

    Regras (spec seção 5):
      - início:  max(0, idx - 120)
      - fim:     min(len(texto), idx + len(termo) + 120)
      - trata quebras de linha repetidas para exibição limpa.
    """
    idx = match.start()
    termo = match.group(0)
    inicio = max(0, idx - window)
    fim = min(len(texto), idx + len(termo) + window)
    trecho = texto[inicio:fim]
    return clean_snippet(trecho)


def highlight(texto: str, termo: str) -> str:
    """Envolve o termo encontrado em markup do Rich para destaque no terminal."""
    if not termo:
        return texto
    # Escapa colchetes do Rich para evitar quebra de markup no restante do texto.
    seguro = texto.replace("[", "\\[").replace("]", "\\]")
    marca = f"[bold black on yellow]{termo}[/bold black on yellow]"
    return seguro.replace(termo, marca)
