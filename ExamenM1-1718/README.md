# Enunciado

PROGRAMA A REALIZAR:

1. Programad una subrutina en EASy68K llamada NWRTSEGM. Esta subrutina recibirá dentro de A0 la
  dirección de mapeo del conjunto de visualizadores de siete segmentos y dentro  D0.L un número 
  entero positivo de 32 bits. la subrutina debe mostrar a los visualizadores de siete segmentos 
  la codificaci'o hexadecimal de dicho número de 32 bits. La subrutina debe restaurar todos los 
  registros que modifique.

2. Haga un programa en EASy68K que, utilizando la subrutina anterior y todas las que crea convenientes haga lo siguiente:
  • Muestre la ventana de hardware.
  • Muestre una secuencia hexadecimal desde 00000000 hasta FFFFFFFF en los visualizadores de siete segmentos, incrementando en
    1 el valor mostrado cada segundo aproximadamente. Con el fin de esperar un segundo puede utilizar tanto la tarea 8 como la
    tarea 23 del TRAP # 15.
