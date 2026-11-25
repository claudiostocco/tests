A melhor linguagem para este tipo de sistema é o Python.

Por que o Python é a escolha ideal?

1.  Desempenho com PDFs gigantes (RPI): As revistas do INPI costumam ter
    entre 500 e mais de 4.000 páginas. Com a biblioteca PyMuPDF (fitz), o Python
    processa milhares de páginas em poucos segundos, consumindo pouca memória
    RAM (diferente de outras linguagens que sofrem com out of memory ao abrir
    arquivos desse porte).
2.  Facilidade de rede e download: Baixar arquivos de URLs de forma segura e com
    suporte a streaming (para não travar a máquina com downloads grandes) é
    trivial com a biblioteca requests.
3.  Manipulação de texto e Regex: A busca pelo número de processo e o recorte de
    trechos (snippets de contexto) são nativamente simples e rápidos.
4.  Rapidez de entrega: Em poucas dezenas de linhas de código, o sistema fica
    pronto, funcional e empacotável em um executável .exe (via PyInstaller), se
    necessário.

Abaixo está o Documento de Especificação Técnica de Desenvolvimento detalhado
para a implementação em Python.

ESPECIFICAÇÃO TÉCNICA DE DESENVOLVIMENTO

Projeto: Leitor e Rastreador de Processos em Revistas RPI (INPI)
Linguagem: Python 3.10+
Versão da Spec: 1.0

1. Visão Geral

O objetivo deste sistema de linha de comando (CLI) é automatizar a localização
de números de processos (marcas, patentes, etc.) dentro das publicações em
formato PDF da Revista da Propriedade Industrial (RPI). O sistema deve permitir
a leitura a partir de um diretório local ou via download direto de uma URL,
exibindo a página e o contexto onde o processo foi citado.

2. Tecnologias e Dependências

| Biblioteca                | Versão recomendada | Finalidade                                          |
| :------------------------ | :----------------- | :-------------------------------------------------- |
| **Python**                | 3.10 ou superior   | Ambiente de execução                                |
| **PyMuPDF (`fitz`)**      | `>= 1.23.0`        | Extração de texto de PDFs com altíssima performance |
| **requests**              | `>= 2.31.0`        | Download do arquivo PDF via URL                     |
| **re** (nativo)           | \-                 | Expressões regulares para busca flexível do número  |
| **pathlib / os** (nativo) | \-                 | Manipulação de diretórios e arquivos                |
| **input() nativo + rich** | \-                 | Para deixar o terminal colorido e formatado         |

3. Fluxo de Execução e Regras de Negócio

3.1. Entrada de Dados: Número do Processo (Funcionalidade 1)

1.  O sistema solicita: "Digite o número do processo a ser buscado:".
2.  Normalização: O sistema deve sanitizar a entrada, permitindo buscas tanto
    pelo número cru (somente dígitos) quanto formatado com pontos/hífens (ex:
    912345678 ou BR 10 2023...).

3.2. Escolha da Fonte de Busca (Funcionalidade 2)

1.  O sistema exibe o menu:
      - [1] Pesquisar em pasta local com PDFs
      - [2] Pesquisar a partir de uma URL
2.  Validação: Repetir a pergunta caso o usuário digite uma opção inválida.

3.3. Origem: Pasta Local ou URL (Funcionalidade 3)

Cenário A: Pasta Local

  - Solicitar o caminho da pasta (Ex: C:\Users\user\Downloads\RPI).
  - Validar se o diretório existe.
  - Filtrar recursivamente ou diretamente todos os arquivos que terminem com
    .pdf ou .PDF.
  - Se não houver PDFs na pasta, abortar com aviso amigável.

Cenário B: Download via URL

  - Solicitar a URL completa do arquivo PDF.
  - Realizar download via streaming com barra de progresso ou indicação visual.
  - Armazenar o arquivo em pasta temporária (/tmp ou pasta local ./temp).
  - Garantir a exclusão ou retenção configurável do arquivo após a conclusão.

3.4. Mecanismo de Varredura e Busca (Funcionalidades 3 e 4)

Para cada PDF encontrado/baixado:

1.  Abrir o arquivo utilizando fitz.open(caminho_arquivo).
2.  Iterar página a página.
3.  Extrair o texto da página via page.get_text("text").
4.  Buscar ocorrências do número do processo:
      - Critério de Exibição: Se encontrar, extrair o número da página (base 1)
        e uma janela de contexto em torno do termo (ex.: 150 caracteres antes
        e 150 caracteres depois do termo localizado, ou o parágrafo completo).
      - Destaque: Apresentar a saída formatada no terminal com o nome do
        arquivo, página e o trecho com a palavra destacada.

4. Estrutura do Projeto

rpi-finder/
├── main.py              # Ponto de entrada (CLI e orquestração)
├── core/
│   ├── __init__.py
│   ├── downloader.py    # Lógica de download do PDF por URL
│   ├── scanner.py       # Lógica de varredura e extração com PyMuPDF
│   └── utils.py         # Formatação de texto e extração de trecho/snippet
├── requirements.txt     # Dependências (PyMuPDF, requests)
└── README.md            # Instruções de instalação e uso

5. Algoritmo de Extração do Trecho (Snippet)

A função responsável por recortar o contexto deve obedecer à seguinte regra:

  - Localizar o índice inicial da correspondência idx.
  - Definir início: max(0, idx - 120).
  - Definir fim: min(len(texto), idx + len(termo) + 120).
  - Tratar quebras de linha repetidas (\n) para exibição limpa no terminal.

6. Tratamento de Exceções Obrigatório

  - URL inválida / Timeout: Capturar requests.exceptions.RequestException e
    informar falha no download sem travar a aplicação.
  - PDF corrompido ou protegido por senha: Tratar fitz.FileDataError com aviso:
    "[Aviso] Arquivo corrompido ou inacessível: <nome_arquivo>".
  - PDF não pesquisável (Imagem/Escaneado): Se a extração de texto retornar
    vazio em todas as páginas, alertar que o PDF pode ser uma imagem (sem OCR
    aplicado).

7. Exemplo e validação

  - Revista exemplo na pasta revista/
  