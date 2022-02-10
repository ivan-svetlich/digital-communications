%% Calculo de frecuencias relativas
imagen_in = imread('logo FI.tif');
n = 2; %cantidad de simbolos
orden = 2; %orden de la fuente
data_in = reshape(imagen_in,orden,[]);

S = 0:(n^orden)-1; %notacion de los mensajes
k = 1;
w = bi2de(data_in'); %paso los mensajes a decimal

for i=1:orden^2
  f(i) = sum(w==i-1); %calculo frecuencia de c/mensaje
end
Pe = f./(numel(data_in)/orden); %frecuencia relativa 

map = [S; Pe];

%% Codificacion (orden 2)
dict = {[0], [1 1 1], [1 1 0], [1 0]}; %diccionario calculado "a mano"
H = [];
for i=1:length(w)
    h = dict(w+1);
    H = [H h]; %secuencia codificada
end
%for i=1:orden^2
%  ind = find(map(:,1)==w);
%  h = cell2mat(dict(ind));
%  H = [H h];
%endfor
sig = huffmandeco(h,dict) - 1;
data_out = dec2bin(sig) - '0';

%hcode = huffmanenco(data_in,dict);
%data_out = huffmandeco(hcode,dict);
%isequal(data_in,data_out)