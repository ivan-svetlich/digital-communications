%% Curva largo promedio vs. n
rango = 1:10;
L = zeros(1,length(rango));
for orden=rango
    

    imagen_in = imread('logo FI.tif');
    n = 2; %cantidad de simbolos
    %orden = 4; %orden de la fuente (cambiar en la seccion diccionarios segun corresponda)
    %data_in = reshape(imagen_in,orden,[]);
    %data_in = logical(reshape([imagen_in(:);nan(mod(-numel(imagen_in),orden),1)],orden,[])); % first variant
    data_in = reshape(imagen_in(1:fix(numel(imagen_in)/orden)*orden),orden,[]);        % second variant

    S = 0:(n^orden)-1; %notacion de los mensajes
    k = 1;
    w = bi2de(data_in(:,1:end)'); %paso los mensajes a decimal
    f = zeros(1,n^orden);
    Pe = 0;
    for i=1:n^orden
      f(i) = sum(w==i-1); %calculo frecuencia de c/mensaje
    end
    Pe = f./(numel(data_in)/orden); %frecuencia relativa 
    map = [S; Pe];

    dict = huffmandict(S,Pe);

    largo = zeros(n^orden,1);
    for i=1:n^orden
        largo(i) = length(cell2mat(dict(i,2)));
    end
    L(orden) = sum(Pe*largo); %largo promedio
end
figure;
plot(rango,L,'o',rango,L,'b')
titulo = sprintf('Largo promedio vs. n');
grid on;
title(titulo,'FontSize', 24); 
xlabel('n', 'FontSize', 24); ylabel('Largo promedio', 'FontSize', 24);
grid on