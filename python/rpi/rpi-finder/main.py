"""Ponto de entrada CLI do rpi-finder.

Fluxo de execução (conforme PRD e spec):
  1. Solicita o número do processo a ser buscado.
  2. Pergunta se a busca será em pasta local ou por URL.
  3. Varre os PDFs e exibe página + trecho de contexto de cada ocorrência.
"""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Optional

from rich.console import Console
from rich.panel import Panel
from rich.table import Table

from core.downloader import DownloadError
from core.scanner import ScanResult, varrer_pasta, varrer_url
from core.utils import build_process_pattern, extract_snippet, highlight, normalize_process_number

console = Console()

MSG_PROCESSO = "Digite o número do processo a ser buscado: "

MENU = """\
[bold cyan]Escolha a fonte de busca:[/bold cyan]
  [1] Pesquisar em pasta local com PDFs
  [2] Pesquisar a partir de uma URL
"""


def ler_processos() -> str:
    """Solicita e valida o número do processo (funcionalidade 1 do PRD)."""
    while True:
        processo = console.input(f"[bold yellow]{MSG_PROCESSO}[/bold yellow] ").strip()
        if processo:
            return processo
        console.print("[red]Informe um número de processo válido.[/red]")


def ler_opcao_fonte() -> str:
    """Exibe o menu e repete enquanto a opção for inválida (spec 3.2)."""
    while True:
        console.print(MENU)
        opcao = console.input("[bold yellow]Opção:[/bold yellow] ").strip()
        if opcao in {"1", "2"}:
            return opcao
        console.print("[red]Opção inválida. Digite 1 ou 2.[/red]")


def ler_pasta() -> Optional[Path]:
    """Solicita o caminho da pasta local e valida sua existência (spec 3.3, Cenário A)."""
    while True:
        caminho = console.input(
            "[bold yellow]Digite o caminho da pasta com os PDFs:[/bold yellow] "
        ).strip()
        if not caminho:
            console.print("[red]Informe um caminho válido.[/red]")
            continue
        pasta = Path(caminho).expanduser().resolve()
        if pasta.is_dir():
            return pasta
        console.print(f"[red]O diretório não existe: {pasta}[/red]")


def ler_urls() -> list[str]:
    """Solicita múltiplas URLs de PDF até o usuário pressionar Enter sem digitar."""
    urls: list[str] = []
    indice = 1
    while True:
        url = console.input(
            f"[bold yellow]Digite a URL completa do PDF ({indice}) (Enter para iniciar):[/bold yellow] "
        ).strip()
        if not url:
            break
        urls.append(url)
        indice += 1
    return urls


def exibir_resultado(resultado: ScanResult, processo_digits: str) -> None:
    """Exibe o resultado da varredura de um PDF no terminal (funcionalidade 4)."""
    nome = resultado.arquivo

    if resultado.erro:
        console.print(f"\n{resultado.erro}")
        return

    # PDF não pesquisável (imagem/escaneado) - spec seção 6.
    if resultado.pesquisa_velha:
        console.print(
            f"\n[bold magenta]⚠ Aviso:[/bold magenta] '{nome}' não retornou texto em "
            f"nenhuma das {resultado.paginas} páginas. Pode ser uma imagem (sem OCR aplicado)."
        )
        return

    if not resultado.ocorrencias:
        console.print(f"\n[dim]Processo não encontrado em '{nome}' ({resultado.paginas} páginas).[/dim]")
        return

    console.print(
        f"\n[bold green]✔ Processo encontrado em '{nome}'"
        f" ({resultado.paginas} páginas, {len(resultado.ocorrencias)} ocorrência(s)):[/bold green]"
    )

    tabela = Table(show_header=True, header_style="bold magenta")
    tabela.add_column("Página", style="cyan", justify="right", width=8)
    tabela.add_column("Trecho de contexto", style="white")

    for ocorr in resultado.ocorrencias:
        snippet_destaque = highlight(ocorr.snippet, ocorr.termo)
        tabela.add_row(str(ocorr.pagina), snippet_destaque)

    console.print(tabela)


def executar_busca_pasta(processo: str, pasta: Path) -> None:
    """Orquestra a varredura de uma pasta local."""
    processo_digits = normalize_process_number(processo)
    if not build_process_pattern(processo_digits):
        console.print("[red]Não foi possível extrair dígitos do número informado.[/red]")
        return

    pdfs = list(pasta.rglob("*"))
    pdfs = [p for p in pdfs if p.is_file() and p.suffix.lower() == ".pdf"]
    if not pdfs:
        console.print(f"[yellow]Nenhum arquivo .pdf encontrado na pasta '{pasta}'.[/yellow]")
        return

    console.print(f"\n[blue]Varredura de {len(pdfs)} PDF(s) em '{pasta}'...[/blue]\n")
    for resultado in varrer_pasta(pasta, processo):
        exibir_resultado(resultado, processo_digits)


def executar_busca_url(processo: str, url: str) -> None:
    """Orquestra a busca via download de URL."""
    try:
        for resultado in varrer_url(url, processo):
            exibir_resultado(resultado, normalize_process_number(processo))
    except DownloadError as exc:
        console.print(f"\n[red]Falha no download:[/red] {exc}")


def main() -> int:
    console.print(
        Panel.fit(
            "[bold]rpi-finder[/bold] - Leitor e Rastreador de Processos em Revistas RPI (INPI)",
            border_style="blue",
        )
    )

    # 1. Número do processo (funcionalidade 1)
    processo = ler_processos()

    # 2. Escolha da fonte (funcionalidade 2)
    opcao = ler_opcao_fonte()

    if opcao == "1":
        # 3a. Cenário A - pasta local (funcionalidade 3)
        pasta = ler_pasta()
        if pasta is None:
            return 1
        executar_busca_pasta(processo, pasta)
    else:
        # 3b. Cenário B - URL (funcionalidade 3)
        urls = ler_urls()
        if not urls:
            console.print("[red]Nenhuma URL informada. Busca cancelada.[/red]")
            return 1
        for url in urls:
            executar_busca_url(processo, url)

    console.print("\n[bold blue]Busca finalizada.[/bold blue]")
    return 0


if __name__ == "__main__":
    sys.exit(main())
