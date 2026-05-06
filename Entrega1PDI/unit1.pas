unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Menus,
  StdCtrls, Math;

type
  { TForm1 }
  TForm1 = class(TForm)
    Image1: TImage;
    Image2: TImage;
    BtnCopiar: TButton;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    MainMenu1: TMainMenu;
    MnuArquivo: TMenuItem;
    MnuAbrir: TMenuItem;
    MnuSalvar: TMenuItem;
    MnuSair: TMenuItem;
    MnuOperacoes: TMenuItem;
    MnuRGBtoHSV: TMenuItem;
    MnuHSVtoRGB: TMenuItem;
    MnuInversao: TMenuItem;
    MnuRuido: TMenuItem;
    MnuEqualizacao: TMenuItem;
    MnuMedia: TMenuItem;
    MnuMediana: TMenuItem;
    MnuBinarizacao: TMenuItem;
    MnuLaplaciano: TMenuItem;
    MnuSobel: TMenuItem;
    MnuCompressao: TMenuItem;
    MnuLimiarizacao: TMenuItem;
    EditVal1: TEdit;
    EditVal2: TEdit;
    EditVal3: TEdit;
    EditC: TEdit;
    EditGama: TEdit;
    EditLimiar: TEdit;
    EditLimMin: TEdit;
    EditLimMax: TEdit;
    EditLimVal: TEdit;
    EditMagnitude: TEdit;
    EditDirecao: TEdit;
    MemoInfo: TMemo;
    LblEntrada: TLabel;
    LblSaida: TLabel;
    LblRGBHSV: TLabel;
    LblVal1: TLabel;
    LblVal2: TLabel;
    LblVal3: TLabel;
    LblCompressao: TLabel;
    LblC: TLabel;
    LblGama: TLabel;
    LblBinarizacao: TLabel;
    LblLimiar: TLabel;
    LblLimiarizacao: TLabel;
    LblLimMin: TLabel;
    LblLimMax: TLabel;
    LblLimVal: TLabel;
    LblSobel: TLabel;
    LblMagnitude: TLabel;
    LblDirecao: TLabel;
    LblCopiar: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure BtnCopiarClick(Sender: TObject);
    procedure Image2MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure MnuAbrirClick(Sender: TObject);
    procedure MnuSalvarClick(Sender: TObject);
    procedure MnuSairClick(Sender: TObject);
    procedure MnuRGBtoHSVClick(Sender: TObject);
    procedure MnuHSVtoRGBClick(Sender: TObject);
    procedure MnuInversaoClick(Sender: TObject);
    procedure MnuRuidoClick(Sender: TObject);
    procedure MnuEqualizacaoClick(Sender: TObject);
    procedure MnuMediaClick(Sender: TObject);
    procedure MnuMedianaClick(Sender: TObject);
    procedure MnuBinarizacaoClick(Sender: TObject);
    procedure MnuLaplacianoClick(Sender: TObject);
    procedure MnuSobelClick(Sender: TObject);
    procedure MnuCompressaoClick(Sender: TObject);
    procedure MnuLimiarizacaoClick(Sender: TObject);
  private
  public
  end;

var
  Form1: TForm1;

  // Arrays de trabalho: E = entrada (cinza), S = saída processada
  E, S: array[0..599, 0..599] of Integer;

  // Guarda magnitude e direção do Sobel para exibir ao passar o mouse
  MagSobel: array[0..599, 0..599] of Double;
  DirSobel: array[0..599, 0..599] of Double;

  imgW, imgH: Integer; // dimensões da imagem carregada

implementation

{$R *.lfm}

// ===== Funções auxiliares de cor (cross-platform, sem depender da unit Windows) =====

function ExtrairR(c: TColor): Byte; inline;
begin
  Result := c and $FF;
end;

function ExtrairG(c: TColor): Byte; inline;
begin
  Result := (c shr 8) and $FF;
end;

function ExtrairB(c: TColor): Byte; inline;
begin
  Result := (c shr 16) and $FF;
end;

// ===== Conversão RGB ↔ HSV =====

// Entrada: R, G, B em 0..255
// Saída: H em 0..360, S em 0..1, V em 0..1
procedure RGBparaHSV(R, G, B: Single; var H, S, V: Single);
var
  rn, gn, bn, minVal, maxVal, delta: Single;
begin
  rn := R / 255;
  gn := G / 255;
  bn := B / 255;

  minVal := Min(Min(rn, gn), bn);
  maxVal := Max(Max(rn, gn), bn);
  delta  := maxVal - minVal;

  V := maxVal;

  if maxVal = 0 then
  begin
    S := 0; H := 0;
    Exit;
  end;

  S := delta / maxVal;

  if delta = 0 then
  begin
    H := 0;
    Exit;
  end;

  if rn = maxVal then
    H := (gn - bn) / delta
  else if gn = maxVal then
    H := 2 + (bn - rn) / delta
  else
    H := 4 + (rn - gn) / delta;

  H := H * 60;
  if H < 0 then H := H + 360;
end;

// Entrada: H em 0..360, S em 0..100, V em 0..100
// Saída: R, G, B em 0..255
procedure HSVparaRGB(H, S, V: Single; var R, G, B: Single);
var
  c, x, m, hp, modV: Single;
  seg: Integer;
begin
  // Normaliza S e V de porcentagem para 0..1
  S := S / 100;
  V := V / 100;

  // Garante H dentro de 0..360
  H := H - 360 * Floor(H / 360);

  c  := V * S;
  hp := H / 60;
  seg := Trunc(hp);
  modV := hp - 2 * Floor(hp / 2);
  x := c * (1 - Abs(modV - 1));
  m := V - c;

  case seg of
    0: begin R := c; G := x; B := 0; end;
    1: begin R := x; G := c; B := 0; end;
    2: begin R := 0; G := c; B := x; end;
    3: begin R := 0; G := x; B := c; end;
    4: begin R := x; G := 0; B := c; end;
    5: begin R := c; G := 0; B := x; end;
  else
    R := 0; G := 0; B := 0;
  end;

  R := (R + m) * 255;
  G := (G + m) * 255;
  B := (B + m) * 255;
end;

// ===== Inicialização =====

procedure TForm1.FormCreate(Sender: TObject);
begin
  imgW := 0;
  imgH := 0;
  Randomize;
end;

// ===== Arquivo =====

procedure TForm1.MnuAbrirClick(Sender: TObject);
var
  x, y, cinza: Integer;
  cor: TColor;
  R, G, B: Byte;
begin
  if not OpenDialog1.Execute then Exit;

  Image1.Picture.LoadFromFile(OpenDialog1.FileName);

  imgW := Image1.Picture.Bitmap.Width;
  imgH := Image1.Picture.Bitmap.Height;
  if imgW > 600 then imgW := 600;
  if imgH > 600 then imgH := 600;

  // Converte pra escala de cinza usando luminância padrão ITU-R 601
  for y := 0 to imgH - 1 do
    for x := 0 to imgW - 1 do
    begin
      cor := Image1.Canvas.Pixels[x, y];
      R   := ExtrairR(cor);
      G   := ExtrairG(cor);
      B   := ExtrairB(cor);
      cinza := Round(0.299 * R + 0.587 * G + 0.114 * B);
      E[x, y] := cinza;
      Image1.Canvas.Pixels[x, y] := RGBToColor(cinza, cinza, cinza);
    end;

  // Zera os dados do Sobel da imagem anterior
  for y := 0 to imgH - 1 do
    for x := 0 to imgW - 1 do
    begin
      MagSobel[x, y] := 0;
      DirSobel[x, y] := 0;
      S[x, y] := E[x, y];
    end;
end;

procedure TForm1.MnuSalvarClick(Sender: TObject);
begin
  if SaveDialog1.Execute then
    Image2.Picture.SaveToFile(SaveDialog1.FileName);
end;

procedure TForm1.MnuSairClick(Sender: TObject);
begin
  Close;
end;

// ===== Copiar saída para entrada =====

procedure TForm1.BtnCopiarClick(Sender: TObject);
var
  x, y: Integer;
begin
  if imgW = 0 then Exit;

  Image1.Picture.Assign(Image2.Picture);
  for y := 0 to imgH - 1 do
    for x := 0 to imgW - 1 do
      E[x, y] := S[x, y];
end;

// ===== Mouse sobre Image2 — exibe info do Sobel =====

procedure TForm1.Image2MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if (imgW = 0) or (X < 0) or (Y < 0) or (X >= imgW) or (Y >= imgH) then Exit;
  EditMagnitude.Text := FormatFloat('0.00', MagSobel[X, Y]);
  EditDirecao.Text   := FormatFloat('0.00', DirSobel[X, Y]) + '°';
end;

// ===== RGB ↔ HSV =====

procedure TForm1.MnuRGBtoHSVClick(Sender: TObject);
var
  R, G, B, H, S, V: Single;
begin
  R := StrToFloat(EditVal1.Text);
  G := StrToFloat(EditVal2.Text);
  B := StrToFloat(EditVal3.Text);
  RGBparaHSV(R, G, B, H, S, V);
  ShowMessage(Format('RGB(%.0f, %.0f, %.0f)  →  HSV(%.1f°,  %.1f%%,  %.1f%%)',
    [R, G, B, H, S * 100, V * 100]));
end;

procedure TForm1.MnuHSVtoRGBClick(Sender: TObject);
var
  H, S, V, R, G, B: Single;
begin
  H := StrToFloat(EditVal1.Text);
  S := StrToFloat(EditVal2.Text);
  V := StrToFloat(EditVal3.Text);
  HSVparaRGB(H, S, V, R, G, B);
  ShowMessage(Format('HSV(%.1f°,  %.1f%%,  %.1f%%)  →  RGB(%.0f,  %.0f,  %.0f)',
    [H, S, V, R, G, B]));
end;

// ===== Inversão de imagem (cinza) =====

procedure TForm1.MnuInversaoClick(Sender: TObject);
var
  x, y, inv: Integer;
begin
  if imgW = 0 then begin ShowMessage('Carregue uma imagem primeiro.'); Exit; end;

  Image2.Picture.Bitmap.Width  := imgW;
  Image2.Picture.Bitmap.Height := imgH;

  for y := 0 to imgH - 1 do
    for x := 0 to imgW - 1 do
    begin
      inv := 255 - E[x, y];
      S[x, y] := inv;
      Image2.Canvas.Pixels[x, y] := RGBToColor(inv, inv, inv);
    end;
end;

// ===== Ruído sal e pimenta (10% dos pixels) =====

procedure TForm1.MnuRuidoClick(Sender: TObject);
var
  i, x, y, ruido: Integer;
begin
  if imgW = 0 then begin ShowMessage('Carregue uma imagem primeiro.'); Exit; end;

  // Começa com a imagem atual na saída
  for y := 0 to imgH - 1 do
    for x := 0 to imgW - 1 do
    begin
      S[x, y] := E[x, y];
      Image2.Canvas.Pixels[x, y] := RGBToColor(S[x, y], S[x, y], S[x, y]);
    end;

  // Aplica 10% de ruído: pixels alternados recebem 0 (pimenta) ou 255 (sal)
  for i := 0 to Round(0.1 * imgW * imgH) do
  begin
    x := Random(imgW);
    y := Random(imgH);
    if (i mod 2 = 0) then ruido := 0 else ruido := 255;
    S[x, y] := ruido;
    Image2.Canvas.Pixels[x, y] := RGBToColor(ruido, ruido, ruido);
  end;
end;

// ===== Equalização de histograma =====

procedure TForm1.MnuEqualizacaoClick(Sender: TObject);
var
  i, x, y, pixel, total: Integer;
  freq:    array[0..255] of Integer;
  freqAcc: array[0..255] of Integer;
  valorEq: array[0..255] of Integer;
begin
  if imgW = 0 then begin ShowMessage('Carregue uma imagem primeiro.'); Exit; end;

  total := imgW * imgH;
  for i := 0 to 255 do freq[i] := 0;

  // 1. Conta frequência de cada tom
  for y := 0 to imgH - 1 do
    for x := 0 to imgW - 1 do
      Inc(freq[E[x, y]]);

  // 2. Frequência acumulada
  freqAcc[0] := freq[0];
  for i := 1 to 255 do
    freqAcc[i] := freq[i] + freqAcc[i - 1];

  // 3. Calcula o novo valor para cada tom
  for i := 0 to 255 do
    valorEq[i] := Max(0, Round((255 * freqAcc[i]) / total) - 1);

  // 4. Aplica na imagem de saída
  for y := 0 to imgH - 1 do
    for x := 0 to imgW - 1 do
    begin
      pixel   := E[x, y];
      S[x, y] := valorEq[pixel];
      Image2.Canvas.Pixels[x, y] := RGBToColor(S[x, y], S[x, y], S[x, y]);
    end;
end;

// ===== Filtro da média (janela 3x3 / N8) =====

procedure TForm1.MnuMediaClick(Sender: TObject);
var
  x, y, soma: Integer;
begin
  if imgW = 0 then begin ShowMessage('Carregue uma imagem primeiro.'); Exit; end;

  Image2.Picture.Bitmap.Width  := imgW;
  Image2.Picture.Bitmap.Height := imgH;

  // Bordas ficam pretas (sem vizinhança completa)
  for y := 1 to imgH - 2 do
    for x := 1 to imgW - 2 do
    begin
      soma := E[x-1, y-1] + E[x, y-1] + E[x+1, y-1]
            + E[x-1, y]   + E[x, y]   + E[x+1, y]
            + E[x-1, y+1] + E[x, y+1] + E[x+1, y+1];
      S[x, y] := Round(soma / 9);
      Image2.Canvas.Pixels[x, y] := RGBToColor(S[x, y], S[x, y], S[x, y]);
    end;
end;

// ===== Filtro da mediana (janela 3x3 / N8) =====

procedure TForm1.MnuMedianaClick(Sender: TObject);
var
  x, y, i, j, k, tmp: Integer;
  viz: array[0..8] of Integer;
begin
  if imgW = 0 then begin ShowMessage('Carregue uma imagem primeiro.'); Exit; end;

  Image2.Picture.Bitmap.Width  := imgW;
  Image2.Picture.Bitmap.Height := imgH;

  for y := 1 to imgH - 2 do
    for x := 1 to imgW - 2 do
    begin
      // Coleta os 9 vizinhos
      k := 0;
      for j := -1 to 1 do
        for i := -1 to 1 do
        begin
          viz[k] := E[x + i, y + j];
          Inc(k);
        end;

      // Ordena com bubble sort (9 elementos, não tem custo relevante)
      for i := 0 to 7 do
        for j := 0 to 7 - i do
          if viz[j] > viz[j + 1] then
          begin
            tmp      := viz[j];
            viz[j]   := viz[j + 1];
            viz[j+1] := tmp;
          end;

      S[x, y] := viz[4]; // elemento central = mediana
      Image2.Canvas.Pixels[x, y] := RGBToColor(S[x, y], S[x, y], S[x, y]);
    end;
end;

// ===== Binarização (usuário define o limiar T) =====

procedure TForm1.MnuBinarizacaoClick(Sender: TObject);
var
  x, y, T: Integer;
begin
  if imgW = 0 then begin ShowMessage('Carregue uma imagem primeiro.'); Exit; end;

  T := StrToInt(EditLimiar.Text);

  for y := 0 to imgH - 1 do
    for x := 0 to imgW - 1 do
    begin
      if E[x, y] > T then S[x, y] := 255 else S[x, y] := 0;
      Image2.Canvas.Pixels[x, y] := RGBToColor(S[x, y], S[x, y], S[x, y]);
    end;
end;

// ===== Laplaciano vizinhança 4 =====

procedure TForm1.MnuLaplacianoClick(Sender: TObject);
var
  x, y, lap: Integer;
begin
  if imgW = 0 then begin ShowMessage('Carregue uma imagem primeiro.'); Exit; end;

  Image2.Picture.Bitmap.Width  := imgW;
  Image2.Picture.Bitmap.Height := imgH;
  Image2.Picture.Bitmap.Canvas.Brush.Color := clBlack;
  Image2.Picture.Bitmap.Canvas.FillRect(0, 0, imgW, imgH);

  // Kernel N4: 4*centro - vizinhos direita/esquerda/cima/baixo
  for y := 1 to imgH - 2 do
    for x := 1 to imgW - 2 do
    begin
      lap := 4 * E[x, y] - E[x-1, y] - E[x+1, y] - E[x, y-1] - E[x, y+1];
      S[x, y] := EnsureRange(Abs(lap), 0, 255);
      Image2.Canvas.Pixels[x, y] := RGBToColor(S[x, y], S[x, y], S[x, y]);
    end;
end;

// ===== Detecção de bordas por Sobel =====

procedure TForm1.MnuSobelClick(Sender: TObject);
var
  x, y, gx, gy: Integer;
  minMag, maxMag: Double;
begin
  if imgW = 0 then begin ShowMessage('Carregue uma imagem primeiro.'); Exit; end;

  Image2.Picture.Bitmap.Width  := imgW;
  Image2.Picture.Bitmap.Height := imgH;

  minMag := MaxDouble;
  maxMag := 0;

  // Calcula Gx, Gy, magnitude e direção
  for y := 1 to imgH - 2 do
    for x := 1 to imgW - 2 do
    begin
      // Máscara Gx (detecta bordas verticais)
      gx := -E[x-1, y-1] + E[x+1, y-1]
            -2*E[x-1, y] + 2*E[x+1, y]
            -E[x-1, y+1] + E[x+1, y+1];

      // Máscara Gy (detecta bordas horizontais)
      gy := -E[x-1, y-1] - 2*E[x, y-1] - E[x+1, y-1]
            +E[x-1, y+1] + 2*E[x, y+1] + E[x+1, y+1];

      MagSobel[x, y] := Sqrt(gx * gx + gy * gy);
      DirSobel[x, y] := ArcTan2(gy, gx) * 180 / Pi; // graus

      if MagSobel[x, y] < minMag then minMag := MagSobel[x, y];
      if MagSobel[x, y] > maxMag then maxMag := MagSobel[x, y];
    end;

  if maxMag = minMag then Exit;

  // Normaliza magnitudes para 0..255 e exibe na imagem de saída
  for y := 1 to imgH - 2 do
    for x := 1 to imgW - 2 do
    begin
      S[x, y] := Round(((MagSobel[x, y] - minMag) / (maxMag - minMag)) * 255);
      Image2.Canvas.Pixels[x, y] := RGBToColor(S[x, y], S[x, y], S[x, y]);
    end;
end;

// ===== Compressão de escala dinâmica: S = c * r^γ =====

procedure TForm1.MnuCompressaoClick(Sender: TObject);
var
  x, y: Integer;
  c, gama, vn: Double;
begin
  if imgW = 0 then begin ShowMessage('Carregue uma imagem primeiro.'); Exit; end;

  c    := StrToFloat(EditC.Text);
  gama := StrToFloat(EditGama.Text);

  for y := 0 to imgH - 1 do
    for x := 0 to imgW - 1 do
    begin
      vn      := E[x, y] / 255; // normaliza para 0..1
      S[x, y] := EnsureRange(Round(c * Power(vn, gama) * 255), 0, 255);
      Image2.Canvas.Pixels[x, y] := RGBToColor(S[x, y], S[x, y], S[x, y]);
    end;
end;

// ===== Limiarização (usuário define intervalo e valor de saída) =====

procedure TForm1.MnuLimiarizacaoClick(Sender: TObject);
var
  x, y, limMin, limMax, valSaida: Integer;
begin
  if imgW = 0 then begin ShowMessage('Carregue uma imagem primeiro.'); Exit; end;

  limMin   := StrToInt(EditLimMin.Text);
  limMax   := StrToInt(EditLimMax.Text);
  valSaida := StrToInt(EditLimVal.Text);

  for y := 0 to imgH - 1 do
    for x := 0 to imgW - 1 do
    begin
      // Pixels dentro do intervalo recebem o valor fixo; fora mantêm o original
      if (E[x, y] >= limMin) and (E[x, y] <= limMax) then
        S[x, y] := valSaida
      else
        S[x, y] := E[x, y];

      Image2.Canvas.Pixels[x, y] := RGBToColor(S[x, y], S[x, y], S[x, y]);
    end;
end;

end.
