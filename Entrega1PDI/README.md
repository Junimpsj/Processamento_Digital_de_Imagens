# PDI - Processamento Digital de Imagens

Aplicação desktop desenvolvida em Free Pascal / Lazarus para processamento de imagens em escala de cinza.

## Requisitos

- Lazarus IDE 2.0 ou superior
- Free Pascal Compiler (FPC) 3.2.2 ou superior

## Como executar

1. Abra o arquivo `project1.lpi` no Lazarus
2. Pressione `F9` ou acesse **Run > Run**

Para gerar o executável sem abrir: **Run > Build** (`Shift+F9`).

## Funcionalidades

| Operacao            | Descricao                                                  |
|---------------------|------------------------------------------------------------|
| RGB -> HSV          | Converte valores RGB para espaco de cor HSV                |
| HSV -> RGB          | Converte valores HSV para espaco de cor RGB                |
| Inversao            | Inverte os tons da imagem: `255 - E[x,y]`                 |
| Ruido sal e pimenta | Adiciona ruido aleatorio em 10% dos pixels (0 ou 255)      |
| Equalizacao         | Equaliza o histograma para melhorar contraste              |
| Filtro media N8     | Suavizacao por media aritmetica em janela 3x3              |
| Filtro mediana N8   | Suavizacao por mediana em janela 3x3 (remove ruido)        |
| Binarizacao         | Limiariza a imagem: pixels acima de T viram 255, resto 0   |
| Laplaciano N4       | Detecta bordas com kernel de segunda derivada (4 vizinhos) |
| Sobel               | Detecta bordas com gradiente Gx/Gy, exibe magnitude        |
| Compressao gama     | Aplica correcao de gama: `S = c * (E/255)^y * 255`        |
| Limiarizacao        | Pixels em [min, max] recebem valor fixo; fora mantem E     |

## Estrutura

```
project1.lpi   -- arquivo de projeto (abrir no Lazarus)
project1.lpr   -- programa principal
unit1.pas      -- logica da aplicacao e todos os filtros
unit1.lfm      -- layout do formulario
imagemTeste.bmp -- imagem de entrada padrao
web/           -- versao web da aplicacao (abrir web/index.html no navegador)
```

## Observacoes

- Imagens sao convertidas para escala de cinza ao abrir usando luminancia ITU-R 601: `0.299*R + 0.587*G + 0.114*B`
- Filtros leem do array de entrada `E[x,y]` e escrevem no array de saida `S[x,y]`
- O botao "Copiar S->E" copia a saida para a entrada, permitindo encadear filtros
- No Sobel, passar o mouse sobre a imagem de saida exibe magnitude e direcao do gradiente
