%% Codigo que bloque lineal (9,5)
clear; close all
format long
linewidth = 1.5; % grosor de linea

%MODO = "detector";
MODO = "corrector";

nc = 9; %largo de palabra de codigo
k = 5; %largo de palabra de fuente
tc = 1; %capacidad de correccion (calculado en distancia_minima.m)
td = 2; %capacidad de deteccion (calculado en distancia_minima.m)
P=[1 1 0 1;  0 1 1 1; 1 0 1 1; 1 1 1 1; 1 1 1 0]; %matriz de paridad
I = eye(k);
G=[I P]; %matriz generadorra

switch MODO
    case "corrector"
        rango = 1:10;
        rep = 1:2;
    case "detector"
        rango = 1:8;
        rep = 1:10;
end
Pep = zeros(1, rango(end));
Peb = zeros(1, rango(end));
for EbN0dB=rango
    eb = 0;
    ep = 0;
    for veces=rep
        N = 5e7; %numero total de muestras (fuente)
        U = randi([0, 1], N/k, k); %muestras organizadas en filas de k bits

        V = mod(U*G,2); %codificacion

        %Amplitud
        A = 1;
        a = A*(V.*2 - 1);
        si = a;
        sq = zeros(size(a));
        s = si + 1i.*sq; %señal transmitida (BPSK)

        Es = mean(var(s)); %obtengo la energia de simbolo a partir de la varianza de los simbolos
        Eb = Es*nc/k; %La energia se reparte entre los n bits transmitidos
        N0 = Eb./(10.^(0.1.*EbN0dB)); %Potencia de ruido
        %N0 = 0;

        %Matriz de ruido AWGN
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

        % R es la secuencia de bits recibidos
        R = 1.*(r>=0) + 0.*(r<0);

        %%%Cantidad de errores y BER (tasa de error de bit)
        error = length(find(V - R));
        BER = error./numel(V);

        Ht = [P; eye(4)]; %matriz de control de paridad (transpuesta)
        S = mod(R*Ht,2); %cálculo de los sindromes

        %Para comparar, paso los valores a decimal
        Htdec = bi2de(Ht);
        Sdec = bi2de(S);

        Ve = R;
        switch MODO
         case "detector"
              [filas,columnas] = find(Sdec); %hallo los sindromes distintos de cero
              filas = sort(filas, 'descend'); %ordeno los indices de mayor a menor 
                                              %para evitar errores al momento de
                                              %quitar filas
              %remuevo las filas con error
              Ve(filas,:) = [];
              V(filas,:) = [];
              U(filas,:) = [];
         case "corrector"  
              C = zeros(N/k, k); 
              for i=1:nc
                [filas,columnas] = find(Sdec==Htdec(i)); %comparo los sindromes con la matriz de  
                                                         %control de paridad 
                Ve(filas,i) = mod(Ve(filas,i)+1,2); %modifico los bits con error                             
              end
        end 

        %Errores de palabra de codigo
        Ep = mod(V-Ve,2); 
        [rows1,columns1] = find(Ep);
        ep = ep + nnz(sum(Ep,2));

        %Errores de fuente
        Ue = Ve(:,1:5);
        Eb = mod(U-Ue,2);
        [rows2,columns2] = find(Eb);
        eb = eb + length(rows2);
    end
    Pep(EbN0dB) = ep/(rep(end)*size(Ep,1)); %Pe de palabra
    Peb(EbN0dB) = eb/(rep(end)*numel(Eb)); % Pe de bit de fuente

end
%% Graficos de Peb y Pes 
  EbN0dB = 1:12;
  SNR = 10.^(EbN0dB./10);
  
  %Cotas de Peb obtenidas de forma analítica
  Pebsc = qfunc(sqrt(2.*SNR)); %probabilidad de error de bit sin codificar
  Pepsc = 1-((1-Pebsc).^k); %probabilidad de error de palabra de 5 bits sin codificar
  
  Pec = qfunc(sqrt(2.*SNR.*k/nc)); %probabilidad de error en el canal 
  PepT = 0;
  PebT = 0;
  switch MODO
      case "corrector"
          for i=tc+1:nc
            PepT = PepT + nchoosek(nc,i).*(Pec.^(i)).*((1-Pec).^(nc-i)); %Pep teorica (corrector)
            PebT = PebT + (i/nc).*nchoosek(nc,i).*(Pec.^(i)).*((1-Pec).^(nc-i)); %Peb teorica (corrector)
          end
      case "detector"
          w = [4    14     8     0     4     1     0]; %calculado en distancia_minima.m
        for i=td+1:nc
            PepT = PepT + (nchoosek(nc,i)-w(i-td)).*(Pec.^(i)).*((1-Pec).^(nc-i)); %Pep teorica (detector)
            PebT = PebT + (i/nc).*(nchoosek(nc,i)-w(i-td)).*(Pec.^(i)).*((1-Pec).^(nc-i)); %Peb teorica (detector)
        end
  end

figure(4);
semilogy(EbN0dB, Pebsc, 'g'); hold on;
semilogy(EbN0dB, PebT, 'r'); hold on;
semilogy(rango, Peb, 'b');
titulo = sprintf('Probabilidad de error de bit de fuente - %s', MODO);
 grid on;
title(titulo,'FontSize', 24); 
xlabel('E_b / N_0 [dB]', 'FontSize', 24); ylabel('P_e_b', 'FontSize', 24);
legend('Sin codificar','Valor teorico', 'Valor estimado','FontSize', 16); hold on;
xlim([1,EbN0dB(end)]);ylim([min(Peb),max(PebT)]);
set(gca,'FontSize',16)

figure(5);
semilogy(EbN0dB, Pepsc, 'g'); hold on;
semilogy(EbN0dB, PepT, 'r'); hold on;
semilogy(rango, Pep, 'b');
titulo = sprintf('Probabilidad de error de palabra - %s', MODO);
 grid on;
title(titulo,'FontSize', 24); 
xlabel('E_b / N_0 [dB]', 'FontSize', 24); ylabel('P_e_b', 'FontSize', 24);
legend('Sin codificar','Valor teorico', 'Valor estimado','FontSize', 16); hold on;
xlim([1,EbN0dB(end)]);ylim([min(Pep),max(Pepsc)]);
set(gca,'FontSize',16)