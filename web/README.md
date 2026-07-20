# PDI: Processamento Digital de Imagens (Web)

Porte web da aplicação desktop de processamento de imagens ([`../Entrega1PDI/`](../Entrega1PDI/README.md)), com a mesma lógica e os mesmos filtros implementados em JavaScript.

## Sobre

Interface no navegador com menus estilo aplicação desktop. Todos os filtros seguem as fórmulas idênticas ao `unit1.pas` original, operando sobre os arrays `E[]` (entrada) e `S[]` (saída).

## Stack

- HTML5 + CSS3
- JavaScript vanilla, sem dependências

## Estrutura

```
web/
├── index.html
├── css/
│   └── style.css
└── js/
    ├── app.js        controle geral da aplicação
    ├── filters.js     algoritmos de processamento (RGB↔HSV, filtros, bordas, etc.)
    └── state.js       estado global: E, S, dimensões da imagem
```

## Como executar

Estático, sem build. Abra `index.html` direto no navegador.
