; ===============================================================
; RADOPINT V5 - CALIBRACION DE DISTANCIA POR ANILLO
; No gira E y no activa electrovalvula. Pausa en cada anillo.
; Medir distancia aerografo-radomo en cada pausa.
; ===============================================================
G21
G90
M82
M17
M302 P1
M211 S1
M92 X80.0000 Y80.0000 Z1.7000 E80.0000
M203 X5.000 Y5.000 Z4.000 E10.000
M201 X60.000 Y60.000 Z40.000 E120.000
M204 P40.000 T40.000 R40.000
M42 P5 T1 S0
; G28 se hace manualmente antes de correr este archivo
G92 X0.000 Y200.000 Z200.000 E0.000
M400

; ---- Medicion de distancia - Anillo 01 | src_ring 19 ----
G1 Y200.000 F100.000
G1 X0.000 F100.000
G1 Z200.000 F100.000
M400
M117 Medir anillo 01
G4 P5000

; ---- Medicion de distancia - Anillo 02 | src_ring 18 ----
G1 Z200.000 F100.000
M400
G1 Y192.196 F100.000
G1 X0.000 F100.000
G1 Z194.499 F100.000
M400
M117 Medir anillo 02
G4 P5000

; ---- Medicion de distancia - Anillo 03 | src_ring 17 ----
G1 Z200.000 F100.000
M400
G1 Y184.506 F100.000
G1 X0.000 F100.000
G1 Z189.969 F100.000
M400
M117 Medir anillo 03
G4 P5000

; ---- Medicion de distancia - Anillo 04 | src_ring 16 ----
G1 Z200.000 F100.000
M400
G1 Y176.181 F100.000
G1 X0.234 F100.000
G1 Z185.650 F100.000
M400
M117 Medir anillo 04
G4 P5000

; ---- Medicion de distancia - Anillo 05 | src_ring 15 ----
G1 Z200.000 F100.000
M400
G1 Y167.560 F100.000
G1 X1.961 F100.000
G1 Z181.736 F100.000
M400
M117 Medir anillo 05
G4 P5000

; ---- Medicion de distancia - Anillo 06 | src_ring 14 ----
G1 Z200.000 F100.000
M400
G1 Y158.724 F100.000
G1 X4.485 F100.000
G1 Z178.210 F100.000
M400
M117 Medir anillo 06
G4 P5000

; ---- Medicion de distancia - Anillo 07 | src_ring 13 ----
G1 Z200.000 F100.000
M400
G1 Y149.736 F100.000
G1 X7.571 F100.000
G1 Z175.053 F100.000
M400
M117 Medir anillo 07
G4 P5000

; ---- Medicion de distancia - Anillo 08 | src_ring 12 ----
G1 Z200.000 F100.000
M400
G1 Y140.635 F100.000
G1 X11.113 F100.000
G1 Z172.235 F100.000
M400
M117 Medir anillo 08
G4 P5000

; ---- Medicion de distancia - Anillo 09 | src_ring 11 ----
G1 Z200.000 F100.000
M400
G1 Y131.439 F100.000
G1 X15.049 F100.000
G1 Z169.717 F100.000
M400
M117 Medir anillo 09
G4 P5000

; ---- Medicion de distancia - Anillo 10 | src_ring 10 ----
G1 Z200.000 F100.000
M400
G1 Y122.158 F100.000
G1 X19.335 F100.000
G1 Z167.462 F100.000
M400
M117 Medir anillo 10
G4 P5000

; ---- Medicion de distancia - Anillo 11 | src_ring 09 ----
G1 Z200.000 F100.000
M400
G1 Y112.795 F100.000
G1 X23.939 F100.000
G1 Z165.435 F100.000
M400
M117 Medir anillo 11
G4 P5000

; ---- Medicion de distancia - Anillo 12 | src_ring 08 ----
G1 Z200.000 F100.000
M400
G1 Y103.352 F100.000
G1 X28.838 F100.000
G1 Z163.602 F100.000
M400
M117 Medir anillo 12
G4 P5000

; ---- Medicion de distancia - Anillo 13 | src_ring 07 ----
G1 Z200.000 F100.000
M400
G1 Y93.835 F100.000
G1 X34.009 F100.000
G1 Z161.939 F100.000
M400
M117 Medir anillo 13
G4 P5000

; ---- Medicion de distancia - Anillo 14 | src_ring 06 ----
G1 Z200.000 F100.000
M400
G1 Y84.249 F100.000
G1 X39.438 F100.000
G1 Z160.427 F100.000
M400
M117 Medir anillo 14
G4 P5000

; ---- Medicion de distancia - Anillo 15 | src_ring 05 ----
G1 Z200.000 F100.000
M400
G1 Y74.568 F100.000
G1 X45.109 F100.000
G1 Z159.011 F100.000
M400
M117 Medir anillo 15
G4 P5000

; ---- Medicion de distancia - Anillo 16 | src_ring 04 ----
G1 Z200.000 F100.000
M400
G1 Y64.840 F100.000
G1 X51.010 F100.000
G1 Z157.736 F100.000
M400
M117 Medir anillo 16
G4 P5000

; ---- Medicion de distancia - Anillo 17 | src_ring 03 ----
G1 Z200.000 F100.000
M400
G1 Y55.110 F100.000
G1 X57.132 F100.000
G1 Z156.633 F100.000
M400
M117 Medir anillo 17
G4 P5000

; ---- Medicion de distancia - Anillo 18 | src_ring 02 ----
G1 Z200.000 F100.000
M400
G1 Y45.113 F100.000
G1 X63.465 F100.000
G1 Z155.336 F100.000
M400
M117 Medir anillo 18
G4 P5000

; ---- Medicion de distancia - Anillo 19 | src_ring 01 ----
G1 Z200.000 F100.000
M400
G1 Y35.000 F100.000
G1 X70.000 F100.000
G1 Z154.076 F100.000
M400
M117 Medir anillo 19
G4 P5000

G1 Z200.000 F100.000
M42 P5 T1 S0
M400
