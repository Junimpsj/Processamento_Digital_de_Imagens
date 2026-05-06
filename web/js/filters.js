/**
 * filters.js — algoritmos de processamento de imagem
 *
 * Todos lêem de E[] e escrevem em S[].
 * Dependências globais: E, S, MagSobel, DirSobel, imgW, imgH  (de state.js)
 * Fórmulas idênticas ao unit1.pas (Free Pascal).
 */

/* ── Conversão RGB ↔ HSV ─────────────────────────────────── */

/**
 * Entrada: R,G,B em 0..255
 * Saída:   {H: 0..360, S: 0..1, V: 0..1}
 */
function rgbToHsv(R, G, B) {
  var rn = R / 255, gn = G / 255, bn = B / 255;
  var mn = Math.min(rn, gn, bn);
  var mx = Math.max(rn, gn, bn);
  var d  = mx - mn;
  var H = 0, Sv = 0, V = mx;

  if (mx > 0) Sv = d / mx;
  if (d > 0) {
    if      (rn === mx) H = (gn - bn) / d;
    else if (gn === mx) H = 2 + (bn - rn) / d;
    else                H = 4 + (rn - gn) / d;
    H *= 60;
    if (H < 0) H += 360;
  }
  return { H: H, S: Sv, V: V };
}

/**
 * Entrada: H em 0..360, S e V em 0..100  (igual ao Pascal: divide por 100 internamente)
 * Saída:   {R, G, B} em 0..255
 */
function hsvToRgb(H, S, V) {
  S /= 100; V /= 100;
  H -= 360 * Math.floor(H / 360);
  var c   = V * S;
  var hp  = H / 60;
  var seg = Math.floor(hp);
  var mv  = hp - 2 * Math.floor(hp / 2);
  var x   = c * (1 - Math.abs(mv - 1));
  var m   = V - c;
  var r = 0, g = 0, b = 0;
  switch (seg) {
    case 0: r=c; g=x;       break;
    case 1: r=x; g=c;       break;
    case 2:      g=c; b=x;  break;
    case 3:      g=x; b=c;  break;
    case 4: r=x;      b=c;  break;
    case 5: r=c;      b=x;  break;
  }
  return {
    R: Math.round((r + m) * 255),
    G: Math.round((g + m) * 255),
    B: Math.round((b + m) * 255)
  };
}

/* ── Inversão ────────────────────────────────────────────── */

function filtInversao() {
  for (var i = 0; i < imgW * imgH; i++) S[i] = 255 - E[i];
}

/* ── Ruído sal e pimenta (10%) ───────────────────────────── */

function filtRuido() {
  var n = imgW * imgH;
  for (var i = 0; i < n; i++) S[i] = E[i];

  var total = Math.round(0.1 * n);
  for (var k = 0; k <= total; k++) {
    var x = Math.floor(Math.random() * imgW);
    var y = Math.floor(Math.random() * imgH);
    S[x + y * imgW] = (k % 2 === 0) ? 0 : 255;
  }
}

/* ── Equalização de histograma ───────────────────────────── */

function filtEqualizacao() {
  var total   = imgW * imgH;
  var freq    = new Int32Array(256);
  var freqAcc = new Int32Array(256);
  var valorEq = new Uint8Array(256);

  for (var i = 0; i < total; i++) freq[E[i]]++;

  freqAcc[0] = freq[0];
  for (var i = 1; i < 256; i++) freqAcc[i] = freq[i] + freqAcc[i - 1];

  for (var i = 0; i < 256; i++)
    valorEq[i] = Math.max(0, Math.round((255 * freqAcc[i]) / total) - 1);

  for (var i = 0; i < total; i++) S[i] = valorEq[E[i]];
}

/* ── Filtro média N8 (janela 3×3) ────────────────────────── */

function filtMedia() {
  var W = imgW;
  S.fill(0);
  for (var y = 1; y < imgH - 1; y++) {
    for (var x = 1; x < imgW - 1; x++) {
      var soma = E[(x-1)+(y-1)*W] + E[x+(y-1)*W] + E[(x+1)+(y-1)*W]
               + E[(x-1)+ y   *W] + E[x+ y   *W] + E[(x+1)+ y   *W]
               + E[(x-1)+(y+1)*W] + E[x+(y+1)*W] + E[(x+1)+(y+1)*W];
      S[x + y * W] = Math.round(soma / 9);
    }
  }
}

/* ── Filtro mediana N8 (janela 3×3, bubble sort) ─────────── */

function filtMediana() {
  var W   = imgW;
  var viz = new Array(9);
  S.fill(0);
  for (var y = 1; y < imgH - 1; y++) {
    for (var x = 1; x < imgW - 1; x++) {
      viz[0]=E[(x-1)+(y-1)*W]; viz[1]=E[x+(y-1)*W]; viz[2]=E[(x+1)+(y-1)*W];
      viz[3]=E[(x-1)+ y   *W]; viz[4]=E[x+ y   *W]; viz[5]=E[(x+1)+ y   *W];
      viz[6]=E[(x-1)+(y+1)*W]; viz[7]=E[x+(y+1)*W]; viz[8]=E[(x+1)+(y+1)*W];

      for (var i = 0; i < 8; i++)
        for (var j = 0; j < 8 - i; j++)
          if (viz[j] > viz[j+1]) { var t=viz[j]; viz[j]=viz[j+1]; viz[j+1]=t; }

      S[x + y * W] = viz[4];
    }
  }
}

/* ── Binarização ─────────────────────────────────────────── */

function filtBinarizacao(T) {
  for (var i = 0; i < imgW * imgH; i++) S[i] = E[i] > T ? 255 : 0;
}

/* ── Laplaciano N4 ───────────────────────────────────────── */

function filtLaplaciano() {
  var W = imgW;
  S.fill(0);
  for (var y = 1; y < imgH - 1; y++) {
    for (var x = 1; x < imgW - 1; x++) {
      var c   = x + y * W;
      var lap = 4*E[c] - E[(x-1)+y*W] - E[(x+1)+y*W] - E[x+(y-1)*W] - E[x+(y+1)*W];
      S[c] = Math.min(255, Math.abs(lap));
    }
  }
}

/* ── Sobel ───────────────────────────────────────────────── */

/**
 * Preenche MagSobel[], DirSobel[] e S[] (magnitude normalizada 0..255).
 * @returns {boolean} false se maxMag === minMag (imagem uniforme)
 */
function filtSobel() {
  var W = imgW;
  MagSobel.fill(0); DirSobel.fill(0); S.fill(0);

  var minM = Infinity, maxM = 0;

  for (var y = 1; y < imgH - 1; y++) {
    for (var x = 1; x < imgW - 1; x++) {
      var gx = -E[(x-1)+(y-1)*W] + E[(x+1)+(y-1)*W]
             - 2*E[(x-1)+y*W]    + 2*E[(x+1)+y*W]
             - E[(x-1)+(y+1)*W]  + E[(x+1)+(y+1)*W];

      var gy = -E[(x-1)+(y-1)*W] - 2*E[x+(y-1)*W] - E[(x+1)+(y-1)*W]
             +  E[(x-1)+(y+1)*W] + 2*E[x+(y+1)*W] + E[(x+1)+(y+1)*W];

      var idx = x + y * W;
      MagSobel[idx] = Math.sqrt(gx*gx + gy*gy);
      DirSobel[idx] = Math.atan2(gy, gx) * 180 / Math.PI;

      if (MagSobel[idx] < minM) minM = MagSobel[idx];
      if (MagSobel[idx] > maxM) maxM = MagSobel[idx];
    }
  }

  if (maxM === minM) return false;

  var range = maxM - minM;
  for (var y = 1; y < imgH - 1; y++)
    for (var x = 1; x < imgW - 1; x++) {
      var idx = x + y * W;
      S[idx] = Math.round(((MagSobel[idx] - minM) / range) * 255);
    }

  return true;
}

/* ── Compressão gama:  S = c · (E/255)^γ · 255 ──────────── */

function filtCompressao(c, gama) {
  for (var i = 0; i < imgW * imgH; i++) {
    var vn = E[i] / 255;
    S[i] = Math.min(255, Math.max(0, Math.round(c * Math.pow(vn, gama) * 255)));
  }
}

/* ── Limiarização ────────────────────────────────────────── */

function filtLimiarizacao(limMin, limMax, valSaida) {
  for (var i = 0; i < imgW * imgH; i++)
    S[i] = (E[i] >= limMin && E[i] <= limMax) ? valSaida : E[i];
}
