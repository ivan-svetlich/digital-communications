%% Calculo de frecuencias relativas
imagen_in = imread('logo FI.tif');
n = 2; %cantidad de simbolos
orden = 2; %orden de la fuente (cambiar en la seccion diccionarios segun corresponda)
data_in = reshape(imagen_in,orden,[]);

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

%% Diccionarios
%dict = {0 [0];1 [1]}; %orden 1
dict = {0 [1 0]; 1 [1 1 1]; 2 [1 1 0]; 3 [0]}; %orden 2
%dict = {0 [0 0]; 1 [0 1 0 0]; 2 [0 1 1 1 1 0]; 3 [0 1 0 1]; 4 [0 1 1 1 0]; 5 [0 1 1 1 1 1]; 6 [0 1 1 0]; 7 [1]}; %orden 3

%% Codificacion
C = [];
C = cell2mat(dict(w+1,2)'); %archivo comprimido

%% Tasa de compresion
s0 = numel(data_in);
s1 = numel(C);
Rc = s0/s1; %tasa de compresion

%% Calculo teorico de la tasa de compresion
largo = zeros(n^orden,1);
for i=1:n^orden
    largo(i) = length(cell2mat(dict(i,2)));
end
L = sum(Pe*largo); %largo promedio
M = numel(data_in)*L/orden; %tamaño del archivo
Rt = numel(data_in)/M; %tasa de compresion
H = orden*0.999383659706028; %orden x entropia de la fuente de orden 1
eff = H/L; %eficiencia