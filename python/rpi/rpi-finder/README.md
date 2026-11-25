# rpi-finder

Leitor e Rastreador de Processos em Revistas RPI (INPI) — aplicativo de linha de comando (CLI)
desenvolvido em Python conforme o Documento de Especificação Técnica (`spec.md`) e os
Requisitos de Produto (`prd.md`).

## Funcionalidades

1. Solicita o número do processo a ser buscado.
2. Escolhe a fonte de busca:
   - `[1] Pesquisar em pasta local com PDFs`
   - `[2] Pesquisar a partir de uma URL`
3. Busca:
   - Em pasta local: valida o diretório, varre recursivamente todos os `.pdf` e alerta se nenhum for encontrado.
   - Por URL: baixa o PDF via streaming com barra de progresso, armazena em pasta temporária e (por padrão) remove ao final.
4. Exibe, para cada ocorrência, o nome do arquivo, a página (base 1) e um trecho de contexto com o processo destacado.

## Pré-requisitos

- Python 3.10+

## Instalação

```bash
# Crie o ambiente e instale as dependências
cd rpi-finder
pip install -r requirements.txt
```

## Uso

```bash
python main.py
```

Exemplo de interação:

```
┌─────────────────────────────────────────────────────────────┐
│ rpi-finder - Leitor e Rastreador de Processos em Revistas   │
│ (INPI)                                                      │
└─────────────────────────────────────────────────────────────┘

Digite o número do processo a ser buscado: 942431626

Escolha a fonte de busca:
  [1] Pesquisar em pasta local com PDFs
  [2] Pesquisar a partir de uma URL
Opção: 1
Digite o caminho da pasta com os PDFs: ./revista

Varredura de 1 PDF(s) em '/home/.../rpi/revista'...

✔ Processo encontrado em 'Marcas2899.pdf' (9475 páginas, 1 ocorrência(s))
┌─────────┬──────────────────────────────────────────────────┐
│ Página  │ Trecho de contexto                               │
├─────────┼──────────────────────────────────────────────────┤
│ 7       │ ... 942431626 ...                                │
└─────────┴──────────────────────────────────────────────────┘

Busca finalizada.
```

## Estrutura do projeto

```
rpi-finder/
├── main.py              # Ponto de entrada (CLI e orquestração)
├── core/
│   ├── __init__.py
│   ├── downloader.py    # Download do PDF por URL (streaming + progresso)
│   ├── scanner.py       # Varredura e extração com PyMuPDF (fitz)
│   └── utils.py         # Normalização, snippets e destaque no terminal
├── requirements.txt     # Dependências (PyMuPDF, requests, rich)
└── README.md            # Este arquivo
```

## Dependências principais

| Biblioteca | Finalidade |
|------------|------------|
| PyMuPDF (`fitz`) | Extração de texto de PDFs com alta performance |
| requests | Download de PDF via URL com suporte a streaming |
| rich | Terminal colorido, tabelas, barras de progresso |

## Tratamento de exceções

- URL inválida / timeout: exibe falha no download sem travar a aplicação.
- PDF corrompido ou protegido por senha: `[Aviso] Arquivo corrompido ou inacessível: <nome>`.
- PDF não pesquisável (imagem/escaneado): alerta que o PDF pode conter apenas imagens (sem OCR).
