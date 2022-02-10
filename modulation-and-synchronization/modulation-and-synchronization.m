%%
close all; clear all;
%pkg load communications %Para usar qfunc en Octave
%tic
linewidth = 1.5; % grosor de linea

%CONTENIDOS
% 01. Configuracion (linea 20)
% 02. Generacion de bits (linea 47)
% 03. Seleccion de amplitud (linea 59)
% 04. Modulacion (linea 63)
% 05. Generacion del ruido (linea 77)
% 06. Error de fase (linea 101)
% 07. Demodulacion [toma de decision] (linea 112)
% 08. Obtencion de la secuencia de bits (linea 127)
% 09. Calculo de errores de bit y simbolo (linea 143)
% 10. Graficos (linea 152)
% 11. Imagen recibida (linea 290)

%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% CONFIGURACION %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%

%%Seleccion de esquema de modulacion
MOD = 'BPSK'; %Grafico de Peb: Elapsed time is 20.4602 - 36.4994 seconds.
%MOD = 'QPSK';
%MOD = '16-QAM'; %Grafico de Peb: Elapsed time is 11.6697 - 29.3813 seconds.

%%Seleccion de la informacion a transmitir
DATA = 'random';
%DATA = 'imagen';

%Seleccion del tipo de ruido
RUIDO = 'fijo'; %Para Ej1.i y Ej2
%RUIDO = 'rango'; %Para relevar la curva de Peb (Ej1.ii)

%Cantidad de simbolos
switch MOD
    case 'BPSK'
        M = 2;
    case 'QPSK'
        M = 4;
    case '16-QAM'
        M = 16;
end

%%Generacion de los bits a transmitir
switch DATA
    case 'random'
      N = 250*M; %Para Ej1.i y Ej2
      %N = 100/1e-5; %Para Ej1.ii 
      b = randi([0, 1], 1, N); %secuencia de bits
    case 'imagen'
      imagen_in = imread('logo FI.tif'); %leer imagen
      dim = size(imagen_in);
      b = reshape(imagen_in,[1,dim(1)*dim(2)]); %secuencia de bits
end

%Amplitud
A = 2;
a = A*(b.*2 - 1);

%%Modulacion (generacion de los simbolos)
switch MOD
    case 'BPSK'
        si = a;
        sq = zeros(size(a));
    case 'QPSK'
        si = a(1:2:end);
        sq = a(2:2:end);
    case '16-QAM'
        si = sign(a(1:4:end)).*abs(2*A + a(3:4:end));
        sq = sign(a(2:4:end)).*abs(2*A + a(4:4:end));
end
s = si + 1i.*sq; %señal transmitida

%%Generacion del ruido
switch RUIDO
  case 'fijo'
    %EbN0dB = 2;
    EbN0dB = 10;
  case 'rango'
    if(strcmp(MOD, '16-QAM'))
      EbN0dB = 0:14; %en 16-QAM necesito mas Eb/N0 para llegar a Peb=1e-5
    else
      EbN0dB = 0:10;
    end
end

EbN0dB = EbN0dB';
Es = var(s); %obtengo la energia de simbolo a partir de la varianza de los simbolos
Eb = Es/log2(M); %Eb = Es/log2(cant. de simbolos)
N0 = Eb./10.^(0.1.*EbN0dB); %despejo la
%N0 = 0;

%Cada componente de ruido tiene varianza N0/2
ni = sqrt(N0./2).*randn(size(si));
nq = sqrt(N0./2).*randn(size(sq));
n = ni + 1i.*nq;

%%Error de fase
%theta = pi/8;
theta = 0;
ef = exp(1i.*theta);

%%Señal que llega al receptor (salida del filtro adaptado)
x = (s + n).*ef;

yi = real(x); %componente en fase de la señal recibida
yq = imag(x); %componente en cuadratura de la señal recibida

%%Demodulacion
% r es la secuencia de simbolos tras la toma de decision
switch MOD
  case 'BPSK'
    r = A.*sign(yi); 
  case 'QPSK'
    ri = A.*sign(yi); 
    rq = A.*sign(yq);
    r = ri + 1i.*rq;
  case '16-QAM'
    ri = -3*A.*(yi<-2*A) - A.*(yi>=-2*A & yi<0) + A.*(yi>=0 & yi<2*A) +  3*A.*(yi>=2*A);
    rq = -3*A.*(yq<-2*A) - A.*(yq>=-2*A & yq<0) + A.*(yq>=0 & yq<2*A) +  3*A.*(yq>=2*A);
    r = ri + 1i.*rq;
end

% d es la secuencia de bits recibidos
switch MOD
    case 'BPSK'
        d = 1.*(r>=0) + 0.*(r<0);
    case 'QPSK'
        d1 = 1.*(ri>=0) + 0.*(ri<0);
        d2 = 1.*(rq>=0) + 0.*(rq<0);
        d = reshape([d1; d2], size(d1, 1), []);
    case '16-QAM'
        d1 = 1.*(ri>=0) + 0.*(ri<0);
        d2 = 1.*(rq>=0) + 0.*(rq<0);
        d3 = 1.*(abs(ri)>=2*A) + 0.*(abs(ri)<2*A);
        d4 = 1.*(abs(rq)>=2*A) + 0.*(abs(rq)<2*A);
        d = reshape([d1; d2; d3; d4], size(d1, 1), []);
end

%%Cantidad de errores y BER (tasa de error de bit)
error = sum(abs(b' - d'));
BER = error./length(b);

%%Cantidad de errores de simbolo y tasa de error de simbolo
ers = sum(1.*(s' ~= r'));
BERs = ers./length(s);


%%Graficos de los simbolos transmitidos
%y de las muestras a la salida del filtro adaptado
%Las fronteras de decision se marcan en rojo
if(strcmp(DATA, 'random') && strcmp(RUIDO, 'fijo'))
    %%Grafico de los simbolos a transmitir (constelacion)
    titulo = sprintf('Coordenadas de los simbolos a transmitir (%s)', MOD);
    figure(1); hold on; grid on; title(titulo);
    ax.XAxisLocation = 'origin'; ax.YAxisLocation = 'origin'; hold on
    grid on;
    set(gca,'xticklabel',{[]}); set(gca,'yticklabel',{[]})
    plot(si, sq, 'bo'); hold on
    xlabel('s_i', 'FontSize', 24); ylabel('s_q', 'FontSize', 24); hold on;
    switch MOD
      case 'BPSK'
            xlim([-2*A 2*A])
            ylim([-1 1])
            xticks([-A 0 A])
            xticklabels({'-a','0','a'})
            yticks([0])
            yticklabels({'0'})
            line([0 0], ylim, 'color', 'red'); hold on;
            
            %saveas(gcf,'Simbolos_BPSK.png')
      case 'QPSK'
            xlim([-2*A 2*A])
            ylim([-2*A 2*A])
            xticks([-A 0 A])
            xticklabels({'-a','0','a'})
            yticks([-A 0 A])
            yticklabels({'-a','0','a'})
            line([0 0], ylim, 'color', 'red'); 
            line(xlim, [0 0],'color', 'red'); hold on
            
            %saveas(gcf,'Simbolos_QPSK.png')
      case '16-QAM'
            xlim([-4*A 4*A])
            ylim([-4*A 4*A])
            xticks([-3*A -A 0 A 3*A])
            xticklabels({'-3a','-a','0','a','3a'})
            yticks([-3*A -A 0 A 3*A])
            yticklabels({'-3a','-a','0','a','3a'})
            line([0 0], ylim, 'color', 'red');
            line([2*A 2*A], ylim, 'color', 'red');  
            line([-2*A -2*A], ylim, 'color', 'red');
            line(xlim, [0 0],'color', 'red'); 
            line(xlim, [2*A 2*A], 'color', 'red');  
            line(xlim, [-2*A -2*A], 'color', 'red'); hold on
            
            %saveas(gcf,'Simbolos_16-QAM.png')
    end
    %close;
    %%Grafico de los simbolos recibidos
    titulo = sprintf('Coordenadas de los simbolos recibidos (%s, %d realizaciones)', MOD, N);
    figure(2); hold on; grid on; title(titulo);
    ax.XAxisLocation = 'origin'; ax.YAxisLocation = 'origin'; hold on
    grid on;
    set(gca,'xticklabel',{[]}); set(gca,'yticklabel',{[]})
    xlabel('r_i', 'FontSize', 24); ylabel('r_q', 'FontSize', 24);
    switch MOD
        case 'BPSK'
            xlim([-2*A 2*A])
            ylim([-2*A 2*A])
            xticks([-A 0 A])
            xticklabels({'-a','0','a'})
            yticks([0])
            yticklabels({'0'})
            line([0 0], ylim, 'color', 'red'); hold on;
            plot(yi, yq, 'bo'); hold on
            
            %saveas(gcf,'Recibidos_BPSK.png')
      case 'QPSK'
            xlim([-2*A 2*A])
            ylim([-2*A 2*A])
            xticks([-A 0 A])
            xticklabels({'-a','0','a'})
            yticks([-A 0 A])
            yticklabels({'-a','0','a'})
            line([0 0], ylim, 'color', 'red'); 
            line(xlim, [0 0],'color', 'red'); hold on
            plot(yi, yq, 'bo'); hold on
            
            %saveas(gcf,'Recibidos_QPSK.png')
      case '16-QAM'
            xlim([-4*A 4*A])
            ylim([-4*A 4*A])
            xticks([-3*A -A 0 A 3*A])
            xticklabels({'-3a','-a','0','a','3a'})
            yticks([-3*A -A 0 A 3*A])
            yticklabels({'-3a','-a','0','a','3a'})
            line([0 0], ylim, 'color', 'red');
            line([2*A 2*A], ylim, 'color', 'red');  
            line([-2*A -2*A], ylim, 'color', 'red');
            line(xlim, [0 0],'color', 'red'); 
            line(xlim, [2*A 2*A], 'color', 'red');  
            line(xlim, [-2*A -2*A], 'color', 'red'); hold on
            plot(yi, yq, 'bo'); hold on
            
            %saveas(gcf,'Recibidos_16-QAM.png')
    end
    %close;
end

%Graficos de Peb y Pes
if strcmp(RUIDO, 'rango')
  titulo = sprintf('Probabilidad de error de bit (%s)', MOD);
  figure(4); hold on; grid on;
  title(titulo); 
  xlabel('E_b / N_0 [dB]', 'FontSize', 16); ylabel('P_e_b', 'FontSize', 16);
  
  SNR = 10.^(EbN0dB./10);
  %Cotas de Peb obtenidas de forma analítica
  if(strcmp(MOD, '16-QAM'))
    Peb = (3/4).*qfunc(sqrt((4/5).*SNR));
  else
    Peb = qfunc(sqrt(2.*SNR));
  end
  
  %Peb
  semilogy(EbN0dB, Peb); hold on;
  xlim([0,EbN0dB(end)]);ylim([1e-5,max(BERs)]);hold on;
  semilogy(EbN0dB, BER); legend('Valor teorico', 'Valor estimado'); hold on;
  saveas(gcf,'Peb.png')
  %close;
  
  %Pes
  Pes = log2(M).*Peb;
  titulo = sprintf('Probabilidad de error de simbolo (%s)', MOD);
  figure(5); hold on; title(titulo); grid on;
  title(titulo); 
  xlabel('E_b / N_0 [dB]', 'FontSize', 16); ylabel('P_e_s', 'FontSize', 16);
  semilogy(EbN0dB, Pes); hold on;
  xlim([0,EbN0dB(end)]);ylim([1e-5,max(Pes)]);hold on;
  semilogy(EbN0dB, BERs); legend('Valor teorico', 'Valor estimado'); hold on;
  saveas(gcf,'Pes.png')
  %close;
end


%%Mostrar/guardar imagen
if strcmp(DATA, 'imagen')
  imagen_out = reshape(d,dim);
  imshow(imagen_out);
  %imwrite(imagen_out, 'imagen_out.png')
end
%toc