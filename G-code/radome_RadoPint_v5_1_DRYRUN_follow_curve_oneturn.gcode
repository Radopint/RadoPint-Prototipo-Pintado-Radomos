; ===============================================================
; RADOPINT V5.1 - G-CODE MARLIN - X CALIBRADO / RADOMO 1 VUELTA
; X = radial aerografo | Y = vertical | Z = angulo aerografo | E = radomo
; Inicio esperado: X0.000 Y200.000 Z200.000 E0.000
; MODO: DRY RUN - no activa electrovalvula
; ===============================================================
G21 ; unidades en mm/unidades Marlin
G90 ; coordenadas absolutas
M82 ; E absoluto
M17 ; motores habilitados
M302 P1 ; permite mover E sin temperatura
M211 S1 ; mantener endstops/limites de software activos
M92 X80.0000 Y80.0000 Z1.7000 E80.0000
M203 X5.000 Y5.000 Z4.000 E10.000
M201 X60.000 Y60.000 Z40.000 E120.000
M204 P40.000 T40.000 R40.000
M42 P5 T1 S0 ; electrovalvula apagada
; G28 se hace manualmente antes de correr este archivo
G92 X0.000 Y200.000 Z200.000 E0.000
M400

; ---- Anillo 01 | src_ring 19 ----
; X=0.000 Y=200.000 Z=200.000 | vueltas=1.000 | rpm=2.565 | F_E=12.824
G1 Y200.000 F100.000
G1 X0.000 F100.000
G1 Z200.000 F100.000
M400
; M42 P5 T1 S255 ; DRY RUN, electrovalvula no se activa
G1 E5.00000 F12.824 ; pintar anillo + solape
M400
; M42 P5 T1 S0 ; DRY RUN

; ---- Anillo 02 | src_ring 18 ----
; X=0.000 Y=192.196 Z=194.499 | vueltas=1.000 | rpm=2.762 | F_E=13.809
G1 Y192.196 F100.000
G1 X0.000 F100.000
G1 Z194.499 F100.000
M400
; M42 P5 T1 S255 ; DRY RUN, electrovalvula no se activa
G1 E10.00000 F13.809 ; pintar anillo + solape
M400
; M42 P5 T1 S0 ; DRY RUN

; ---- Anillo 03 | src_ring 17 ----
; X=0.000 Y=184.506 Z=189.969 | vueltas=1.000 | rpm=2.987 | F_E=14.937
G1 Y184.506 F100.000
G1 X0.000 F100.000
G1 Z189.969 F100.000
M400
; M42 P5 T1 S255 ; DRY RUN, electrovalvula no se activa
G1 E15.00000 F14.937 ; pintar anillo + solape
M400
; M42 P5 T1 S0 ; DRY RUN

; ---- Anillo 04 | src_ring 16 ----
; X=0.234 Y=176.181 Z=185.650 | vueltas=1.000 | rpm=3.246 | F_E=16.229
G1 Y176.181 F100.000
G1 X0.234 F100.000
G1 Z185.650 F100.000
M400
; M42 P5 T1 S255 ; DRY RUN, electrovalvula no se activa
G1 E20.00000 F16.229 ; pintar anillo + solape
M400
; M42 P5 T1 S0 ; DRY RUN

; ---- Anillo 05 | src_ring 15 ----
; X=1.961 Y=167.560 Z=181.736 | vueltas=1.000 | rpm=3.543 | F_E=17.714
G1 Y167.560 F100.000
G1 X1.961 F100.000
G1 Z181.736 F100.000
M400
; M42 P5 T1 S255 ; DRY RUN, electrovalvula no se activa
G1 E25.00000 F17.714 ; pintar anillo + solape
M400
; M42 P5 T1 S0 ; DRY RUN

; ---- Anillo 06 | src_ring 14 ----
; X=4.485 Y=158.724 Z=178.210 | vueltas=1.000 | rpm=3.886 | F_E=19.429
G1 Y158.724 F100.000
G1 X4.485 F100.000
G1 Z178.210 F100.000
M400
; M42 P5 T1 S255 ; DRY RUN, electrovalvula no se activa
G1 E30.00000 F19.429 ; pintar anillo + solape
M400
; M42 P5 T1 S0 ; DRY RUN

; ---- Anillo 07 | src_ring 13 ----
; X=7.571 Y=149.736 Z=175.053 | vueltas=1.000 | rpm=4.285 | F_E=21.425
G1 Y149.736 F100.000
G1 X7.571 F100.000
G1 Z175.053 F100.000
M400
; M42 P5 T1 S255 ; DRY RUN, electrovalvula no se activa
G1 E35.00000 F21.425 ; pintar anillo + solape
M400
; M42 P5 T1 S0 ; DRY RUN

; ---- Anillo 08 | src_ring 12 ----
; X=11.113 Y=140.635 Z=172.235 | vueltas=1.000 | rpm=4.754 | F_E=23.772
G1 Y140.635 F100.000
G1 X11.113 F100.000
G1 Z172.235 F100.000
M400
; M42 P5 T1 S255 ; DRY RUN, electrovalvula no se activa
G1 E40.00000 F23.772 ; pintar anillo + solape
M400
; M42 P5 T1 S0 ; DRY RUN

; ---- Anillo 09 | src_ring 11 ----
; X=15.049 Y=131.439 Z=169.717 | vueltas=1.000 | rpm=5.313 | F_E=26.567
G1 Y131.439 F100.000
G1 X15.049 F100.000
G1 Z169.717 F100.000
M400
; M42 P5 T1 S255 ; DRY RUN, electrovalvula no se activa
G1 E45.00000 F26.567 ; pintar anillo + solape
M400
; M42 P5 T1 S0 ; DRY RUN

; ---- Anillo 10 | src_ring 10 ----
; X=19.335 Y=122.158 Z=167.462 | vueltas=1.000 | rpm=5.990 | F_E=29.952
G1 Y122.158 F100.000
G1 X19.335 F100.000
G1 Z167.462 F100.000
M400
; M42 P5 T1 S255 ; DRY RUN, electrovalvula no se activa
G1 E50.00000 F29.952 ; pintar anillo + solape
M400
; M42 P5 T1 S0 ; DRY RUN

; ---- Anillo 11 | src_ring 09 ----
; X=23.939 Y=112.795 Z=165.435 | vueltas=1.000 | rpm=6.826 | F_E=34.131
G1 Y112.795 F100.000
G1 X23.939 F100.000
G1 Z165.435 F100.000
M400
; M42 P5 T1 S255 ; DRY RUN, electrovalvula no se activa
G1 E55.00000 F34.131 ; pintar anillo + solape
M400
; M42 P5 T1 S0 ; DRY RUN

; ---- Anillo 12 | src_ring 08 ----
; X=28.838 Y=103.352 Z=163.602 | vueltas=1.000 | rpm=7.885 | F_E=39.423
G1 Y103.352 F100.000
G1 X28.838 F100.000
G1 Z163.602 F100.000
M400
; M42 P5 T1 S255 ; DRY RUN, electrovalvula no se activa
G1 E60.00000 F39.423 ; pintar anillo + solape
M400
; M42 P5 T1 S0 ; DRY RUN

; ---- Anillo 13 | src_ring 07 ----
; X=34.009 Y=93.835 Z=161.939 | vueltas=1.000 | rpm=9.269 | F_E=46.343
G1 Y93.835 F100.000
G1 X34.009 F100.000
G1 Z161.939 F100.000
M400
; M42 P5 T1 S255 ; DRY RUN, electrovalvula no se activa
G1 E65.00000 F46.343 ; pintar anillo + solape
M400
; M42 P5 T1 S0 ; DRY RUN

; ---- Anillo 14 | src_ring 06 ----
; X=39.438 Y=84.249 Z=160.427 | vueltas=1.000 | rpm=11.156 | F_E=55.780
G1 Y84.249 F100.000
G1 X39.438 F100.000
G1 Z160.427 F100.000
M400
; M42 P5 T1 S255 ; DRY RUN, electrovalvula no se activa
G1 E70.00000 F55.780 ; pintar anillo + solape
M400
; M42 P5 T1 S0 ; DRY RUN

; ---- Anillo 15 | src_ring 05 ----
; X=45.109 Y=74.568 Z=159.011 | vueltas=1.000 | rpm=13.883 | F_E=69.414
G1 Y74.568 F100.000
G1 X45.109 F100.000
G1 Z159.011 F100.000
M400
; M42 P5 T1 S255 ; DRY RUN, electrovalvula no se activa
G1 E75.00000 F69.414 ; pintar anillo + solape
M400
; M42 P5 T1 S0 ; DRY RUN

; ---- Anillo 16 | src_ring 04 ----
; X=51.010 Y=64.840 Z=157.736 | vueltas=1.000 | rpm=18.169 | F_E=90.845
G1 Y64.840 F100.000
G1 X51.010 F100.000
G1 Z157.736 F100.000
M400
; M42 P5 T1 S255 ; DRY RUN, electrovalvula no se activa
G1 E80.00000 F90.845 ; pintar anillo + solape
M400
; M42 P5 T1 S0 ; DRY RUN

; ---- Anillo 17 | src_ring 03 ----
; X=57.132 Y=55.110 Z=156.633 | vueltas=1.000 | rpm=25.000 | F_E=125.000
G1 Y55.110 F100.000
G1 X57.132 F100.000
G1 Z156.633 F100.000
M400
; M42 P5 T1 S255 ; DRY RUN, electrovalvula no se activa
G1 E85.00000 F125.000 ; pintar anillo + solape
M400
; M42 P5 T1 S0 ; DRY RUN

; ---- Anillo 18 | src_ring 02 ----
; X=63.465 Y=45.113 Z=155.336 | vueltas=1.000 | rpm=25.000 | F_E=125.000
G1 Y45.113 F100.000
G1 X63.465 F100.000
G1 Z155.336 F100.000
M400
; M42 P5 T1 S255 ; DRY RUN, electrovalvula no se activa
G1 E90.00000 F125.000 ; pintar anillo + solape
M400
; M42 P5 T1 S0 ; DRY RUN

; ---- Anillo 19 | src_ring 01 ----
; X=70.000 Y=35.000 Z=154.076 | vueltas=1.000 | rpm=25.000 | F_E=125.000
G1 Y35.000 F100.000
G1 X70.000 F100.000
G1 Z154.076 F100.000
M400
; M42 P5 T1 S255 ; DRY RUN, electrovalvula no se activa
G1 E95.00000 F125.000 ; pintar anillo + solape
M400
; M42 P5 T1 S0 ; DRY RUN

; ---- Fin del programa ----
G1 Z200.000 F100.000 ; dejar aerografo mirando de frente
M42 P5 T1 S0 ; asegurar electrovalvula apagada
M400
