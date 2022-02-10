%%
clear all; close all

linewidth = 1.5; % grosor de linea
tc = 1;
td = 2;
nc = 9;
k = 5;
P=[1 1 0 1;  0 1 1 1; 1 0 1 1; 1 1 1 1; 1 1 1 0];
%P=[0 1 1 1;  1 0 1 1; 1 1 0 1; 1 1 1 0; 1 1 1 1];
I = eye(5);
G=[I P];

for EbN0dB=1:8

MOD = 'BPSK';
M = 2;
%%Seleccion de la informacion a transmitir
DATA = 'random';
%DATA = 'imagen';

%Seleccion del tipo de ruido
RUIDO = 'fijo'; %Para Ej1.i y Ej2
%RUIDO = 'rango'; %Para relevar la curva de Peb (Ej1.ii)

switch DATA
    case 'random'
     %N = 250*M; %Para Ej1.i y Ej2
      N = 100/1e-5; %Para Ej1.ii 
      U = randi([0, 1], N/k, k); %secuencia de bits
    case 'imagen'
      imagen_in = imread('logo FI.tif'); %leer imagen
      dim = size(imagen_in);
      b = reshape(imagen_in,[1,dim(1)*dim(2)]); %secuencia de bits
end

V = mod(U*G,2);
%Amplitud
A = 1;
a = A*(V.*2 - 1);
si = a;
sq = zeros(size(a));
s = si + 1i.*sq; %señal transmitida

%EbN0dB = EbN0dB';
Es = mean(var(s)); %obtengo la energia de simbolo a partir de la varianza de los simbolos
Eb = Es*nc/k; %Eb = Es/log2(cant. de simbolos)
N0 = Eb./(10.^(0.1.*EbN0dB)); %despejo la
%N0 = 0;

%Cada componente de ruido tiene varianza N0/2
ni = sqrt(N0./2).*randn(size(si));
nq = sqrt(N0./2).*randn(size(sq));
n = ni + 1i.*nq;

%%Señal que llega al receptor (salida del filtro adaptado)
x = (s + n);

yi = real(x); %componente en fase de la señal recibida
yq = imag(x); %componente en cuadratura de la señal recibida

%%Demodulacion
% r es la secuencia de simbolos tras la toma de decision
r = A.*sign(yi); 

% d es la secuencia de bits recibidos
R = 1.*(r>=0) + 0.*(r<0);

%%%Cantidad de errores y BER (tasa de error de bit)
error = length(find(V - R));
BER = error./numel(V);

Ht = [P; eye(4)];
S = mod(R*Ht,2);

Htdec = bi2de(Ht);
Sdec = bi2de(S);

%MODO = "detector";
MODO = "corrector";
Ve = R;
switch MODO
 case "detector"
      [filas,columnas] = find(Sdec);
      filas = sort(filas, 'descend');
      Ve(filas,:) = [];
      V(filas,:) = [];
      U(filas,:) = [];
 case "corrector"  
      C = zeros(N/k, k); 
      for i=1:k
        C(:,i) = Sdec - Htdec(i);
      end
      [filas,columnas] = find(~C);
      indices = sub2ind(size(Ve),filas,columnas);
      Ve(indices) = mod(Ve(indices)+1,2);
end 

Ep = mod(V-Ve,2);
Ue = Ve(:,1:5);
Eb = mod(U-Ue,2);

[rows1,columns1] = find(Ep);
ep = length(rows1);
Pep(EbN0dB) = ep/numel(Ep);

[rows2,columns2] = find(Eb);
eb = length(rows2);
Peb(EbN0dB) = eb/numel(Eb);

end
EbN0dB = 1:8;
%

%
%%Graficos de Peb y Pes
if strcmp(RUIDO, 'fijo')
  
  
  SNR = 10.^(EbN0dB./10);
  %Cotas de Peb obtenidas de forma analítica
  Pesc = qfunc(sqrt(2.*SNR));
  Pec = qfunc(sqrt(2.*SNR.*k/nc));
  
  %PepT = nchoosek(nc,tc+1).*(Pec.^(tc+1));
  PepT = nchoosek(nc,td+1).*(Pec.^(td+1));
  
  %PebT = ((tc + 1)/nc).*PepT;
  PebT = ((td + 1)/nc).*nchoosek(nc,td+1).*(Pec.^(td+1));
  %Peb
  
  
  %close;

end
figure(4);
semilogy(EbN0dB, Pesc, 'g'); hold on;
semilogy(EbN0dB, PebT, 'r'); hold on;
semilogy(EbN0dB, Peb, 'b');
titulo = sprintf('Probabilidad de error de bit de fuente - detector');
 grid on;
title(titulo,'FontSize', 24); 
xlabel('E_b / N_0 [dB]', 'FontSize', 24); ylabel('P_e_b', 'FontSize', 24);
legend('Sin codificar','Valor teorico', 'Valor estimado','FontSize', 16); hold on;
xlim([1,EbN0dB(end)]);ylim([min(Peb),max(PebT)]);
set(gca,'FontSize',16)
saveas(gcf,'Peb.png')

figure(5);
semilogy(EbN0dB, Pesc, 'g'); hold on;
semilogy(EbN0dB, PepT, 'r'); hold on;
semilogy(EbN0dB, Pep, 'b');
titulo = sprintf('Probabilidad de error de bit de palabra - detector');
 grid on;
title(titulo,'FontSize', 24); 
xlabel('E_b / N_0 [dB]', 'FontSize', 24); ylabel('P_e_b', 'FontSize', 24);
legend('Sin codificar','Valor teorico', 'Valor estimado','FontSize', 16); hold on;
xlim([1,EbN0dB(end)]);ylim([min(PepT),max(PepT)]);
set(gca,'FontSize',16)
saveas(gcf,'Pep.png')
%
%%%Mostrar/guardar imagen
%if strcmp(DATA, 'imagen')
%  imagen_out = reshape(d,dim);
%  imshow(imagen_out);
%  %imwrite(imagen_out, 'imagen_out.png')
%end