%% Calculo de distancia mínima y capacidades de correccion y deteccion
nc=9;
k=5;
P=[0 1 1 1;  1 0 1 1; 1 1 0 1; 1 1 1 0; 1 1 1 1]; %MAtriz de paridad propuesta
I = eye(k);
G=[I P]; %Matriz generadora

max = 0;
for j=0:k-1
    max = max + 2^j; %Calculo el valor maximo (decimal) que se puede representar con 16 bits
end
U = zeros(max+1, k);
for n=1:max+1
    u = dec2bin(n-1,k) - '0'; %Convierto los valores decimales a arrays de bits
    U(n,:) = u;
end
V = mod(U*G,2); %Codifico las palabras
W = sum(V,2); %Calculo el peso de cada palabra de codigo
W(1,:) = []; %Remuevo la primer fila, que corresponde a la palabra '0'
Wmin = min(W); %Hallo el peso minimo
td = Wmin - 1; %Cantidad de errores que puede detectar
tc = floor((Wmin - 1)/2); %Cantidad de errores que puede corregir
err_det = sum(W==(td+1:nc)); %Cantidad de palabras con peso mayor a td (para la cota de la Peb)