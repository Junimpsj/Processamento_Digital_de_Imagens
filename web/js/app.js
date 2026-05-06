/**
 * app.js — UI, eventos, carregamento de imagem e despachante de comandos
 *
 * Dependências (carregar antes):  state.js, filters.js
 */

/* ── Referências DOM ─────────────────────────────────────── */

var canvas1 = document.getElementById('canvas1');
var canvas2 = document.getElementById('canvas2');
var ctx1    = canvas1.getContext('2d');
var ctx2    = canvas2.getContext('2d');

/* ── MENU ────────────────────────────────────────────────── */

document.querySelectorAll('.menu-root').forEach(function(root) {
  root.addEventListener('mouseenter', function() {
    var any = document.querySelector('.menu-root.open');
    if (any && any !== root) { any.classList.remove('open'); root.classList.add('open'); }
  });
  root.addEventListener('click', function(e) {
    e.stopPropagation();
    var was = root.classList.contains('open');
    closeMenus();
    if (!was) root.classList.add('open');
  });
});
document.addEventListener('click', closeMenus);

function closeMenus() {
  document.querySelectorAll('.menu-root.open').forEach(function(m) { m.classList.remove('open'); });
}

/* ── MODAL ───────────────────────────────────────────────── */

function showModal(title, html) {
  closeMenus();
  document.getElementById('modal-title').textContent = title;
  document.getElementById('modal-body').innerHTML = html;
  document.getElementById('overlay').classList.add('show');
}
function closeModal() { document.getElementById('overlay').classList.remove('show'); }

document.getElementById('overlay').addEventListener('click', closeModal);
document.getElementById('modal-win').addEventListener('click', function(e) { e.stopPropagation(); });
document.addEventListener('keydown', function(e) {
  if (e.key === 'Enter' || e.key === 'Escape') closeModal();
});

/* ── STATUS BAR ──────────────────────────────────────────── */

function setStatus(msg) { document.getElementById('status').textContent = msg; }
function setPosStatus(x, y, val) {
  document.getElementById('status-pos').textContent =
    'x=' + x + '  y=' + y + (val !== undefined ? '  val=' + val : '');
}

/* ── RENDER ──────────────────────────────────────────────── */

function renderArray(ctx, arr, w, h) {
  var id = ctx.createImageData(w, h);
  var d  = id.data;
  for (var i = 0; i < w * h; i++) {
    var v  = arr[i];
    var pi = i * 4;
    d[pi] = v; d[pi+1] = v; d[pi+2] = v; d[pi+3] = 255;
  }
  ctx.putImageData(id, 0, 0);
}

function renderS() { renderArray(ctx2, S, imgW, imgH); }

/* ── CARREGAMENTO DE IMAGEM ──────────────────────────────── */

function loadFromURL(url) {
  var img = new Image();
  img.onload = function() {
    imgW = Math.min(img.width,  600);
    imgH = Math.min(img.height, 600);

    var tmp = document.createElement('canvas');
    tmp.width = imgW; tmp.height = imgH;
    var tctx = tmp.getContext('2d');
    tctx.drawImage(img, 0, 0, imgW, imgH);

    var id = tctx.getImageData(0, 0, imgW, imgH);
    var d  = id.data;

    allocArrays();

    for (var i = 0; i < imgW * imgH; i++) {
      var pi   = i * 4;
      var gray = Math.round(0.299 * d[pi] + 0.587 * d[pi+1] + 0.114 * d[pi+2]);
      E_original[i] = gray;
      E[i] = gray;
      S[i] = gray;
    }

    canvas1.width  = imgW; canvas1.height = imgH;
    canvas2.width  = imgW; canvas2.height = imgH;

    renderArray(ctx1, E, imgW, imgH);
    renderArray(ctx2, S, imgW, imgH);

    setStatus('Imagem carregada: ' + imgW + ' × ' + imgH + ' px');
    if (url.startsWith('blob:')) URL.revokeObjectURL(url);
  };
  img.onerror = function() {
    setStatus('Falha ao carregar. Use "Abrir" para selecionar imagemTeste.bmp manualmente.');
    if (url.startsWith('blob:')) URL.revokeObjectURL(url);
  };
  img.crossOrigin = 'anonymous';
  img.src = url;
}

document.getElementById('fileInput').addEventListener('change', function(e) {
  var f = e.target.files[0];
  if (f) loadFromURL(URL.createObjectURL(f));
  e.target.value = '';
});

function needImg() {
  if (imgW === 0) {
    showModal('Atenção', 'Carregue uma imagem primeiro.<br>Use <b>Arquivo → Abrir</b>.');
    return false;
  }
  return true;
}

/* ── ARQUIVO ─────────────────────────────────────────────── */

function salvarSaida() {
  if (!needImg()) return;
  var a = document.createElement('a');
  a.download = 'saida_pdi.png';
  a.href = canvas2.toDataURL('image/png');
  a.click();
  setStatus('Saída salva como saida_pdi.png.');
}

/* ── COPIAR S → E ────────────────────────────────────────── */

function copiarSE() {
  if (!needImg()) return;
  E.set(S);
  ctx1.drawImage(canvas2, 0, 0);
  MagSobel.fill(0); DirSobel.fill(0);
  document.getElementById('eMag').value = '—';
  document.getElementById('eDir').value = '—';
  setStatus('Saída copiada para entrada.');
}

/* ── RESETAR PARA ORIGINAL ───────────────────────────────── */

function resetOriginal() {
  if (!needImg()) return;
  E.set(E_original);
  S.set(E_original);
  MagSobel.fill(0); DirSobel.fill(0);
  renderArray(ctx1, E, imgW, imgH);
  renderArray(ctx2, S, imgW, imgH);
  document.getElementById('eMag').value = '—';
  document.getElementById('eDir').value = '—';
  setStatus('Imagem restaurada para o original.');
}

/* ── MOUSE HOVER — info Sobel + coordenadas ──────────────── */

canvas2.addEventListener('mousemove', function(e) {
  if (imgW === 0) return;
  var r  = canvas2.getBoundingClientRect();
  var sx = imgW / r.width;
  var sy = imgH / r.height;
  var x  = Math.floor((e.clientX - r.left) * sx);
  var y  = Math.floor((e.clientY - r.top)  * sy);
  if (x < 0 || y < 0 || x >= imgW || y >= imgH) return;

  var idx = x + y * imgW;
  setPosStatus(x, y, S[idx]);

  if (MagSobel[idx] !== 0) {
    document.getElementById('eMag').value = MagSobel[idx].toFixed(2);
    document.getElementById('eDir').value = DirSobel[idx].toFixed(2) + '°';
  }
});

canvas1.addEventListener('mousemove', function(e) {
  if (imgW === 0) return;
  var r = canvas1.getBoundingClientRect();
  var x = Math.floor((e.clientX - r.left) * imgW / r.width);
  var y = Math.floor((e.clientY - r.top)  * imgH / r.height);
  if (x < 0 || y < 0 || x >= imgW || y >= imgH) return;
  setPosStatus(x, y, E[x + y * imgW]);
});

/* ── DESPACHANTE DE COMANDOS ─────────────────────────────── */

function cmd(op) {
  closeMenus();
  switch (op) {

    case 'abrir':   document.getElementById('fileInput').click(); break;
    case 'salvar':  salvarSaida(); break;
    case 'copiar':  copiarSE(); break;
    case 'reset':   resetOriginal(); break;
    case 'sair':    if (confirm('Sair da aplicação?')) window.close(); break;

    /* ── conversões de cor ── */
    case 'rgbhsv': {
      var R = parseFloat(document.getElementById('v1').value);
      var G = parseFloat(document.getElementById('v2').value);
      var B = parseFloat(document.getElementById('v3').value);
      var hsv = rgbToHsv(R, G, B);
      showModal('RGB → HSV',
        '<tt>RGB(' + R.toFixed(0) + ', ' + G.toFixed(0) + ', ' + B.toFixed(0) + ')</tt>' +
        '<br><br>&nbsp;&nbsp;&nbsp;↓<br><br>' +
        '<tt>HSV(' + hsv.H.toFixed(1) + '°, ' +
        (hsv.S * 100).toFixed(1) + '%, ' +
        (hsv.V * 100).toFixed(1) + '%)</tt>');
      break;
    }
    case 'hsvrgb': {
      var H  = parseFloat(document.getElementById('v1').value);
      var Sv = parseFloat(document.getElementById('v2').value);
      var V  = parseFloat(document.getElementById('v3').value);
      var rgb = hsvToRgb(H, Sv, V);
      showModal('HSV → RGB',
        '<tt>HSV(' + H.toFixed(1) + '°, ' + Sv.toFixed(1) + '%, ' + V.toFixed(1) + '%)</tt>' +
        '<br><br>&nbsp;&nbsp;&nbsp;↓<br><br>' +
        '<tt>RGB(' + rgb.R + ', ' + rgb.G + ', ' + rgb.B + ')</tt>');
      break;
    }

    /* ── filtros sem parâmetros ── */
    case 'inversao':    if (!needImg()) break; filtInversao();    renderS(); setStatus('Inversão aplicada.'); break;
    case 'ruido':       if (!needImg()) break; filtRuido();       renderS(); setStatus('Ruído sal e pimenta (10%) aplicado.'); break;
    case 'equalizacao': if (!needImg()) break; filtEqualizacao(); renderS(); setStatus('Equalização de histograma aplicada.'); break;
    case 'media':       if (!needImg()) break; filtMedia();       renderS(); setStatus('Filtro média N8 aplicado.'); break;
    case 'mediana':     if (!needImg()) break; filtMediana();     renderS(); setStatus('Filtro mediana N8 aplicado.'); break;
    case 'laplaciano':  if (!needImg()) break; filtLaplaciano();  renderS(); setStatus('Laplaciano N4 aplicado.'); break;

    case 'sobel':
      if (!needImg()) break;
      if (filtSobel()) {
        renderS();
        setStatus('Sobel aplicado — passe o mouse sobre a saída para ver magnitude e direção.');
      }
      break;

    /* ── filtros com parâmetros ── */
    case 'binarizacao': {
      if (!needImg()) break;
      var T = parseInt(document.getElementById('limiar').value);
      filtBinarizacao(T); renderS(); setStatus('Binarização aplicada (T=' + T + ').'); break;
    }
    case 'compressao': {
      if (!needImg()) break;
      var c    = parseFloat(document.getElementById('editC').value);
      var gama = parseFloat(document.getElementById('editGama').value);
      filtCompressao(c, gama); renderS();
      setStatus('Compressão gama aplicada (c=' + c + ', γ=' + gama + ').'); break;
    }
    case 'limiarizacao': {
      if (!needImg()) break;
      var mn = parseInt(document.getElementById('limMin').value);
      var mx = parseInt(document.getElementById('limMax').value);
      var vs = parseInt(document.getElementById('limVal').value);
      filtLimiarizacao(mn, mx, vs); renderS();
      setStatus('Limiarização [' + mn + ', ' + mx + '] → ' + vs + ' aplicada.'); break;
    }
  }
}

/* ── INICIALIZAÇÃO ───────────────────────────────────────── */

window.addEventListener('load', function() {
  loadFromURL('imagemTeste.bmp');
});
