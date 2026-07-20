# PDI: Processamento Digital de Imagens (Desktop)

Aplicação desktop em Free Pascal / Lazarus pra processamento de imagens em escala de cinza.

## Sobre

Imagens são convertidas pra escala de cinza ao abrir, usando luminância ITU-R 601: `0.299*R + 0.587*G + 0.114*B`. Filtros leem do array de entrada `E[x,y]` e escrevem no array de saída `S[x,y]`. O botão "Copiar S→E" copia a saída pra entrada, permitindo encadear filtros.

## Funcionalidades

| Operação | Descrição |
|---|---|
| RGB → HSV | Converte valores RGB pro espaço de cor HSV |
| HSV → RGB | Converte valores HSV pro espaço de cor RGB |
| Inversão | Inverte os tons da imagem: `255 - E[x,y]` |
| Ruído sal e pimenta | Adiciona ruído aleatório em 10% dos pixels (0 ou 255) |
| Equalização | Equaliza o histograma pra melhorar contraste |
| Filtro média N8 | Suavização por média aritmética em janela 3x3 |
| Filtro mediana N8 | Suavização por mediana em janela 3x3 (remove ruído) |
| Binarização | Limiariza a imagem: pixels acima de T viram 255, resto 0 |
| Laplaciano N4 | Detecta bordas com kernel de segunda derivada (4 vizinhos) |
| Sobel | Detecta bordas com gradiente Gx/Gy, exibe magnitude |
| Compressão gama | Correção de gama: `S = c * (E/255)^y * 255` |
| Limiarização | Pixels em [min, max] recebem valor fixo, fora mantém E |

No Sobel, passar o mouse sobre a imagem de saída mostra magnitude e direção do gradiente.

## Estrutura

```
Entrega1PDI/
├── project1.lpi     arquivo de projeto (abrir no Lazarus)
├── project1.lpr      programa principal
├── unit1.pas          lógica da aplicação e todos os filtros
├── unit1.lfm          layout do formulário
└── imagemTeste.bmp    imagem de entrada padrão
```

Veja também a versão web em [`../web/`](../web/README.md).

## Como executar

1. Abra `project1.lpi` no Lazarus
2. Pressione `F9` (Run) ou vá em **Run → Run**

Pra gerar o executável sem abrir: **Run → Build** (`Shift+F9`).

## Requisitos

- Lazarus IDE 2.0+
- Free Pascal Compiler (FPC) 3.2.2+
