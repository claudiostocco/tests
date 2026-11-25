Para esse sistema, minha recomendação é Python, com uma aplicação desktop simples ou uma interface web local, dependendo de como você pretende utilizá-la.

Python é especialmente adequado porque possui bibliotecas maduras para leitura de PDFs, pesquisa de texto, identificação de páginas e download de arquivos pela internet. Além disso, permite desenvolver uma solução que funcione no Windows sem exigir conhecimentos avançados de programação de quem vai utilizá-la.

## 1. Tecnologias recomendadas

## Python 3

RecomendadoLinguagem principal do sistema, responsável pela pesquisa, leitura dos arquivos e processamento dos resultados.

Explore Text Searching With PyMuPDF | Artifex

PyMuPDF

Leitura do conteúdo dos PDFs, identificação das páginas e extração de trechos próximos ao número do processo.

Tkinter

Interface gráfica para solicitar o número do processo, selecionar a pasta ou informar uma URL e exibir os resultados.

Requests

Download do PDF da revista RPI a partir de uma URL HTTP ou HTTPS, com validação da resposta.

Ponto importante: alguns PDFs contêm apenas imagens digitalizadas, sem texto selecionável. Para que a pesquisa também funcione nesses casos, a especificação prevê uma etapa opcional de OCR, usando Tesseract. Assim, o sistema poderá pesquisar tanto PDFs com texto digital quanto revistas digitalizadas, embora o OCR possa exigir revisão dos resultados.

A seguir, preparei a especificação funcional e técnica do projeto, organizada para servir de documento de referência para o desenvolvimento.

Writing

# Especificação Técnica e Funcional

## Sistema de Pesquisa de Processos em PDFs da Revista da Propriedade Industrial (RPI)

**Versão:** 1.0\
**Linguagem:** Python 3\
**Plataforma inicial:** Windows 10/11\
**Tipo de aplicação:** Desktop\
**Nome provisório:** BuscaRPI

---

## 1\. Objetivo

Desenvolver uma aplicação para pesquisar um número de processo nos arquivos PDF da Revista da Propriedade Industrial (RPI), permitindo ao usuário escolher entre pesquisar arquivos armazenados em uma pasta local ou baixar um arquivo PDF a partir de uma URL.

Quando o processo for encontrado, a aplicação deverá apresentar o nome do arquivo, o número da página e um trecho do texto em que o número aparece.

O sistema deverá ser simples de operar, sem exigir conhecimentos técnicos do usuário.

## 2\. Tecnologias e dependências

- **Python 3:** linguagem principal.
- **Tkinter:** interface gráfica.
- **PyMuPDF (fitz):** leitura de PDFs, extração de texto e identificação de páginas.
- **Requests:** download de arquivos PDF via HTTP/HTTPS.
- **Pytesseract:** integração opcional com OCR.
- **Tesseract OCR:** reconhecimento de texto em PDFs digitalizados.
- **PyInstaller:** geração de executável para Windows.

As dependências deverão ser instaladas e configuradas conforme a versão do Python utilizada no projeto.

## 3\. Requisitos funcionais

### RF-01 — Solicitação do número do processo

Ao iniciar a aplicação, apresentar uma janela solicitando o número do processo que será pesquisado.

A interface deverá conter:

- Campo para digitação do número do processo.
- Botão "Pesquisar".
- Botão "Cancelar" ou "Sair".
- Validação para impedir pesquisa com campo vazio.

O número informado deverá ser preservado durante toda a execução da pesquisa.

### RF-02 — Seleção da origem dos arquivos

Após a confirmação do número do processo, perguntar ao usuário onde deseja realizar a pesquisa.

Disponibilizar duas opções:

1. Pesquisar PDFs em uma pasta do computador.
2. Pesquisar um PDF obtido por URL.

A interface deverá permitir selecionar a opção desejada de maneira clara.

### RF-03 — Pesquisa em pasta local

Quando o usuário selecionar a pesquisa em pasta:

1. Abrir uma janela para seleção do diretório.
2. Permitir selecionar uma pasta existente.
3. Localizar os arquivos com extensão `.pdf` no diretório selecionado.
4. Percorrer todos os PDFs encontrados.
5. Extrair o texto de cada página.
6. Pesquisar o número do processo.
7. Registrar todas as ocorrências encontradas.
8. Apresentar os resultados ao final da varredura.

Na primeira versão, a pesquisa deverá abranger os PDFs diretamente presentes na pasta selecionada. A inclusão de subpastas poderá ser disponibilizada como opção adicional.

Um arquivo que não puder ser aberto deverá ser registrado como erro, sem interromper a pesquisa nos demais arquivos.

### RF-04 — Pesquisa por URL

Quando o usuário selecionar a pesquisa por URL:

1. Solicitar o endereço do PDF.
2. Validar se a URL possui formato aceitável e utiliza HTTP ou HTTPS.
3. Efetuar o download do arquivo.
4. Verificar se a resposta foi bem-sucedida e se o conteúdo recebido corresponde a um PDF válido.
5. Salvar o arquivo temporariamente.
6. Processar as páginas do documento.
7. Pesquisar o número do processo.
8. Exibir os resultados.
9. Remover o arquivo temporário ao final, quando não houver necessidade de mantê-lo.

O sistema deverá informar erros de conexão, URL inválida, ausência de permissão ou arquivo indisponível.

O download deverá possuir limite configurável de tamanho e tempo de espera.

### RF-05 — Extração e pesquisa de texto

A aplicação deverá pesquisar o número informado no texto extraído de cada página.

A pesquisa deverá considerar:

- Correspondência exata do número do processo.
- Diferenças de espaços, pontos, barras e hífens, quando aplicável.
- Formatação do número em linhas diferentes, quando possível.
- Preservação do número original informado para exibição dos resultados.

A normalização deverá ser utilizada somente para comparação. O texto original deverá ser mantido para a apresentação do trecho encontrado.

**Regra de segurança da pesquisa:** evitar considerar um número como encontrado quando ele for apenas parte de outro identificador maior, salvo quando o formato oficial do processo justificar essa correspondência.

A implementação deverá permitir ajustar a regra de comparação conforme os formatos de números de processo efetivamente utilizados na RPI.

### RF-06 — Exibição dos resultados

Para cada ocorrência encontrada, apresentar:

- Número do processo pesquisado.
- Nome do arquivo PDF.
- Caminho completo do arquivo, quando disponível.
- Número da página.
- Trecho do texto ao redor da ocorrência.
- Indicação de quantas ocorrências foram localizadas.

Exemplo ilustrativo:

**Processo pesquisado:** 123456789

**Arquivo:** RPI\_arquivo.pdf

**Página:** 42

**Trecho encontrado:**

"... pedido referente ao processo 123456789, conforme publicação constante nesta edição da Revista da Propriedade Industrial ..."

O trecho deverá incluir uma quantidade configurável de caracteres antes e depois do número encontrado, preferencialmente entre 100 e 200 caracteres de cada lado.

Quando o processo aparecer mais de uma vez no mesmo arquivo ou em arquivos diferentes, todas as ocorrências deverão ser apresentadas.

### RF-07 — Ausência de resultados

Se nenhum processo for encontrado, apresentar uma mensagem informando que não houve correspondências.

A mensagem deverá distinguir, quando possível:

- Pesquisa concluída sem ocorrências.
- Um ou mais arquivos não puderam ser processados.
- Não foi possível extrair texto de determinados PDFs.
- A pesquisa por OCR não foi executada.

### RF-08 — Progresso da pesquisa

Durante a varredura, exibir:

- Arquivo que está sendo processado.
- Quantidade de arquivos processados.
- Quantidade total de arquivos identificados.
- Indicador de progresso.
- Opção de cancelar a operação.

O cancelamento deverá encerrar a pesquisa de maneira controlada, preservando os resultados já encontrados.

### RF-09 — Acesso ao documento

Quando possível, permitir que o usuário abra o PDF correspondente ao resultado.

O sistema deverá informar o número da página em que a ocorrência foi localizada.

A abertura do arquivo poderá utilizar o leitor de PDF padrão do sistema operacional.

Na primeira versão, a localização da página deverá ser apresentada numericamente. A abertura automática já posicionada na página encontrada poderá ser implementada posteriormente, conforme a compatibilidade do leitor de PDF.

## 4\. Requisitos de OCR

### RNF-01 — PDFs digitalizados

Quando uma página não possuir texto extraível ou apresentar indícios de digitalização, o sistema poderá aplicar OCR para reconhecer o conteúdo da imagem.

O OCR deverá:

- Utilizar o idioma português, com suporte adicional a outros idiomas quando necessário.
- Permitir processamento página a página.
- Apresentar aviso de que resultados de OCR podem conter erros.
- Registrar quais páginas foram processadas por reconhecimento de imagem.

A ativação do OCR deverá ser configurável, pois seu uso pode aumentar significativamente o tempo de processamento.

## 5\. Requisitos não funcionais

### RNF-02 — Desempenho

- Processar os arquivos sequencialmente ou com paralelismo controlado, conforme a implementação.
- Evitar carregar todos os documentos integralmente na memória.
- Liberar os recursos de cada PDF após seu processamento.
- Permitir a interrupção da operação.
- Informar o progresso ao usuário.

### RNF-03 — Usabilidade

- Interface em português do Brasil.
- Mensagens de erro claras.
- Campos e botões identificados.
- Seleção de pastas por janela gráfica.
- Exibição legível dos resultados.
- Possibilidade de pesquisar diferentes números sem reiniciar o programa.

### RNF-04 — Segurança

- Aceitar apenas URLs HTTP ou HTTPS.
- Validar os arquivos baixados antes de processá-los.
- Definir limites para tamanho e tempo de download.
- Evitar execução de conteúdo baixado.
- Tratar arquivos corrompidos e entradas inválidas.
- Restringir a pesquisa aos arquivos e diretórios autorizados pelo usuário.

### RNF-05 — Manutenibilidade

- Código organizado em módulos.
- Funções documentadas.
- Tratamento centralizado de erros.
- Registro técnico de falhas sem expor informações desnecessárias ao usuário.
- Separação entre interface gráfica, processamento de PDFs e pesquisa textual.

## 6\. Arquitetura proposta

Organizar o projeto nos seguintes módulos:

**main.py**

- Inicialização da aplicação.
- Controle do fluxo de execução.

**interface.py**

- Janelas e campos de entrada.
- Seleção da origem dos documentos.
- Barra de progresso.
- Apresentação dos resultados.

**pesquisa.py**

- Coordenação da pesquisa.
- Comparação dos números de processo.
- Agregação das ocorrências.

**leitor\_pdf.py**

- Abertura dos PDFs.
- Extração de texto por página.
- Identificação das páginas.
- Geração dos trechos de contexto.

**download.py**

- Validação de URLs.
- Download dos arquivos.
- Controle de tamanho, tempo limite e erros de conexão.

**ocr.py**

- Reconhecimento de texto em páginas digitalizadas.
- Integração com o Tesseract OCR.

**configuracao.py**

- Parâmetros da aplicação.
- Limites de download.
- Configurações de pesquisa e OCR.

**tests/**

- Testes automatizados.
- Arquivos PDF de teste.
- Casos de números encontrados e não encontrados.

## 7\. Fluxo operacional

1. Iniciar a aplicação.
2. Solicitar o número do processo.
3. Validar o número informado.
4. Perguntar se a pesquisa será realizada em uma pasta local ou por URL.
5. Obter a pasta ou baixar o PDF.
6. Identificar os documentos a processar.
7. Abrir cada PDF e extrair o texto página por página.
8. Procurar correspondências do número do processo.
9. Registrar o arquivo, a página e o trecho correspondente.
10. Apresentar o resumo da pesquisa e todas as ocorrências.
11. Permitir nova pesquisa ou encerramento da aplicação.

## 8\. Critérios de aceitação

O desenvolvimento será considerado funcional quando os seguintes testes forem aprovados:

**CT-01:** informar um número de processo válido e iniciar a pesquisa.

**CT-02:** selecionar uma pasta com vários PDFs e pesquisar todos os arquivos válidos encontrados.

**CT-03:** localizar um número conhecido e informar corretamente o nome do arquivo e a página.

**CT-04:** apresentar um trecho de texto que contenha a ocorrência localizada.

**CT-05:** baixar e processar um PDF a partir de uma URL válida.

**CT-06:** informar adequadamente quando nenhuma ocorrência for encontrada.

**CT-07:** continuar a varredura mesmo quando um dos PDFs estiver corrompido ou inacessível.

**CT-08:** apresentar todas as ocorrências, inclusive quando o número estiver em vários documentos.

**CT-09:** informar o progresso e permitir o cancelamento da pesquisa.

**CT-10:** processar um PDF digitalizado utilizando OCR, quando essa funcionalidade estiver habilitada.

**CT-11:** não considerar como correspondência válida um número encontrado apenas como parte de outro identificador incompatível com o formato pesquisado.

## 9\. Entregáveis

O projeto deverá entregar:

1. Código-fonte em Python.
2. Arquivo de dependências `requirements.txt`.
3. Instruções de instalação e execução.
4. Testes automatizados.
5. Documentação de configuração do OCR.
6. Executável para Windows, gerado por PyInstaller, se solicitado.
7. Manual básico de utilização.
8. Relatório dos testes de aceitação.

## 10\. Evoluções futuras

Poderão ser implementadas em versões posteriores:

- Pesquisa automática em várias edições da RPI.
- Consulta de URLs de edições diretamente no portal oficial.
- Agendamento de pesquisas.
- Histórico de processos consultados.
- Exportação de resultados para Excel, CSV ou PDF.
- Destaque visual do número encontrado.
- Abertura do documento diretamente na página da ocorrência.
- Pesquisa recursiva em subpastas.
- Processamento em lote de diversos números de processo.
- Cache de documentos já processados.

## 11\. Premissas e decisões pendentes

Antes da implementação, deverão ser confirmados:

- O formato exato dos números de processo que serão pesquisados.
- Se a pesquisa deverá ser restrita à correspondência exata ou aceitar variações de formatação.
- Se os PDFs serão predominantemente digitais ou digitalizados.
- Se a pesquisa em pastas deverá incluir subpastas.
- Se a aplicação deverá funcionar exclusivamente no Windows.
- Se a pesquisa por URL será feita com endereços de PDFs já conhecidos ou se deverá localizar automaticamente as edições da RPI no portal oficial.

**Recomendação final:** implementar a primeira versão em Python com Tkinter e PyMuPDF, incluindo pesquisa em pastas, download por URL e apresentação dos resultados por arquivo, página e trecho de texto. O OCR deverá ser integrado como funcionalidade opcional, para garantir maior cobertura sem tornar toda pesquisa desnecessariamente lenta.

## Próximo passo recomendado

Antes de iniciar a programação, vale definir um detalhe que afeta bastante o projeto: como você pretende informar a URL da revista RPI?

- Opção A: você já tem o endereço direto do arquivo PDF e vai colá-lo no sistema.
- Opção B: você informa o endereço do portal do INPI, e o sistema localiza automaticamente a edição da RPI e baixa o PDF.

A opção B exige uma etapa adicional para identificar as edições disponíveis no portal, mas torna a aplicação mais automatizada.