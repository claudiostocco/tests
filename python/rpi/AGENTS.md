# AGENTS.md — `python/rpi/`

Este arquivo vale **apenas** para a pasta `python/rpi/` e subpastas. Os outros projetos do repositório (`dart/`, `flutter-new/`, `ia/`, `python/web_scraping`) são independentes.

## Projeto

`rpi-finder/` é um CLI em Python que busca um número de processo dentro de PDFs da Revista da Propriedade Industrial (RPI/INPI), lendo de uma pasta local ou baixando de uma URL. Exibe, por ocorrência: arquivo, página (base 1) e trecho de contexto.

## Como executar

```bash
cd python/rpi/rpi-finder
pip3 install -r requirements.txt   # PyMuPDF (fitz), requests, rich
python3 main.py                    # não existe binário `python`, somente `python3`
```

O programa é **interativo, sem argumentos de CLI**: pede o número do processo, a fonte `[1] pasta local | [2] URL` e, em seguida, o caminho da pasta ou as URLs do PDF.

Na opção `[2] URL`, o programa pede URLs uma a uma (`Digite a URL completa do PDF (N) (Enter para iniciar):`) até você pressionar Enter sem informar nova URL; então inicia a varredura de cada URL em sequência. Se nenhuma URL for informada, a busca é cancelada.

## Coisas que um agente provavelmente vai esquecer

- Os imports `from core.xxx` funcionam **só executando `main.py` dentro de `rpi-finder/`** (o diretório do script entra no `sys.path`). Executar de outro diretório ou como módulo quebra a importação do pacote `core`.
- Baixas via URL são gravadas em `./temp` e **removidas após a varredura** por padrão (`KEEP_TEMP = False` em `core/downloader.py`). Defina `True` para reter o arquivo.
- Na opção `[2] URL`, cada URL é processada de forma independente: se uma falhar (rede/timeout/arquivo vazio → `DownloadError`), as demais URLs da lista ainda são varridas; a falha de uma não interrompe as outras.
- PDFs de exemplo para teste manual: `revista/` (várias edições "Marcas").
- Não há testes, CI, linter, typecheck nem `pyproject.toml`. Não invente comandos de verificação.
- O scanner já usa `import pymupdf as fitz` (sem `DeprecationWarning`). Mantenha esse padrão; não use `import fitz`.

## Especificações e docs

- `spec.md` — especificação técnica (fluxo, dependências, algoritmo de snippet, tratamento de exceções).
- `prd.md` — requisitos de produto.
- `rpi-finder/README.md` — instruções de instalação e uso com exemplo de interação.

## Detalhes de implementação

- Entrada: `rpi-finder/main.py` (`main()` → `sys.exit(main())`).
- Orquestração: `core/scanner.py` (`varrer_pasta`, `varrer_url` geram `ScanResult` um a um); `core/downloader.py` (download streaming com barra de progresso); `core/utils.py` (normalização do número, snippet com janela de 120 chars de cada lado, destaque com Rich).
- Número do processo: normalizado para dígitos apenas (`normalize_process_number`); a regex aceita separadores opcionais entre dígitos (`.` `/` `-` espaço).
- Erros tratados: PDF corrompido/protegido por senha → `[Aviso] Arquivo corrompido...`; PDF sem texto em nenhuma página (imagem/escaneado, sem OCR) → aviso; falha de rede/timeout ou arquivo baixado vazio → `DownloadError` (erro de download, **não** "processo não encontrado") sem travar o app.
