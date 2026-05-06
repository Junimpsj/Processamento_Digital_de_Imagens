/**
 * state.js — estado global compartilhado entre todos os módulos
 *
 * Convenção de indexação (mesma do Pascal):
 *   E[x, y]  ↔  arr[x + y * imgW]
 */

var imgW = 0;
var imgH = 0;

/** @type {Uint8Array|null} — pixels originais (cinza, imutável após carga) */
var E_original = null;

/** @type {Uint8Array|null} — pixels de entrada (cinza) */
var E = null;

/** @type {Uint8Array|null} — pixels de saída */
var S = null;

/** @type {Float64Array|null} — magnitude do Sobel por pixel */
var MagSobel = null;

/** @type {Float64Array|null} — direção do Sobel por pixel (graus) */
var DirSobel = null;

/** Aloca todos os arrays para as dimensões atuais de imgW×imgH */
function allocArrays() {
  var n    = imgW * imgH;
  E_original = new Uint8Array(n);
  E          = new Uint8Array(n);
  S          = new Uint8Array(n);
  MagSobel   = new Float64Array(n);
  DirSobel   = new Float64Array(n);
}
