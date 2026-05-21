%% RADOPINT - GENERADOR DE G-CODE MARLIN PARA SISTEMA REAL
% Version v5.1 - X calibrado; radomo con una vuelta por anillo y rpm creciente.
%
% Mapeo real de ejes:
%   X = desplazamiento radial/horizontal del aerografo.
%   Y = desplazamiento vertical del aerografo. Sube cuando Y disminuye.
%   Z = rotacion del aerografo. Z200 = frente; Z110 aprox = 90 deg.
%   E = rotacion del radomo.
%
% Punto inicial requerido despues de G28/setup:
%   X = 0, Y = 200, Z = 200
%
% Esta version hace:
%   - Base -> punta / abajo -> arriba.
%   - X ya NO usa una escala lineal fuerte desde el segundo anillo.
%   - X se mueve con una rampa no lineal y retardada: los primeros anillos
%     quedan casi en X0 para evitar que la distancia caiga de 6 cm a 4/3 cm.
%   - Z se inclina progresivamente, pero con ganancia reducida por defecto.
%   - Antes de reposicionar cada anillo, Z vuelve a 200 para evitar que el
%     sensor se dispare por desplazamientos con el aerografo inclinado.

clear; clc;

%% --------------------- ARCHIVOS DE ENTRADA -----------------------------
ringsFile = 'radome_ring_schedule.csv';
profileFile = 'radome_profile_processed.csv'; %#ok<NASGU>

rings = readtable(ringsFile);

% Orden obligatorio: base -> punta, es decir abajo -> arriba.
rings = sortrows(rings, 'z_center_mm', 'descend');

%% --------------------- PARAMETROS REALES DE LA MAQUINA -----------------
X_START = 0.0;
Y_START = 200.0;
Z_START = 200.0;
E_START = 0.0;

X_MIN = 0.0;     X_MAX = 75.0;
Y_MIN = 35.0;    Y_MAX = 200.0;
Z_MIN = 0.0;     Z_MAX = 200.0;

% En las pruebas reales, la version v4 acercaba demasiado el aerografo:
% anillo 1 ≈ 6 cm, anillo 2 ≈ 4 cm, anillo 3 ≈ 3 cm.
% Por eso X se genera con una rampa NO lineal y retardada.
% Mantiene X casi quieto al comienzo y acelera el acercamiento hacia la punta.
X_SCALE_MODE = 'delayed_power';   % 'delayed_power', 'full_range' o 'measured_mm'
X_TOP_CMD = 70.0;                 % margen de seguridad frente al limite 75

% Rampa no lineal para X:
% progress = 0 en la base, progress = 1 en la punta.
% X_RAMP_START_PROGRESS define desde que porcentaje de la trayectoria X empieza a moverse.
% X_POWER > 1 suaviza el inicio y concentra mas movimiento hacia la parte alta.
X_RAMP_START_PROGRESS = 0.15;
X_POWER = 1.45;

% Modo alternativo: usar calibracion fisica medida.
% Si X=0..75 equivale realmente a 250 mm, entonces X_CMD_PER_MM=0.300.
X_CMD_UNITS = 75.0;
X_REAL_TRAVEL_MM = 250.0;
X_CMD_PER_MM = X_CMD_UNITS / X_REAL_TRAVEL_MM;

% Compensacion opcional por giro del aerografo.
% Si al inclinar Z el pico del aerografo se acerca al radomo por la geometria
% del soporte, aumenta este valor. Empieza con 0 y prueba.
% Un valor de 40 a 80 mm suele ser razonable si el eje de giro esta atras del pico.
TOOL_PIVOT_COMP_MM = 0.0;

% Y se escala para usar el rango 200 -> 35 con la trayectoria real de boquilla.
Y_TOP_CMD = 35.0;

% Z: Z200 = frente. Si Z110 = 90 deg, entonces 1 unidad ~= 1 deg.
Z_CMD_PER_DEG = 1.0;
Z_ANGLE_GAIN = 0.85;
Z_MAX_ANGLE_DEG = 55.0;
Z_RETURN_FRONT_BEFORE_XY = true;

% Si al probar notas que bajar Z apunta al lado contrario, cambia a +1 y
% reindexa o amplia limite de software; con Z_START=200, normalmente se usa -1.
Z_DIRECTION = -1;   % -1: Zcmd = 200 - angulo

% Calibracion E del giro del radomo.
% Prueba real: G1 E10 F60 produjo 2 vueltas exactas del radomo.
% Por tanto: E10 = 2 vueltas -> E5 = 1 vuelta.
E_UNITS_PER_REV = 5.0;

%% --------------------- PARAMETROS DE MARLIN ----------------------------
WRITE_M92 = true;
M92_X = 80.0;
M92_Y = 80.0;
M92_Z = 1.7;
M92_E = 80.0;

% Movimiento conservador para disminuir vibracion.
F_XY_POS = 100.0;       % unidades Marlin/min para X e Y
F_Z_ANGLE = 100.0;      % unidades Marlin/min para giro del aerografo

% E gira el radomo. En Marlin, F de un movimiento solo en E esta en
% unidades E/min. Con E_UNITS_PER_REV=5: F=50 equivale a 10 rpm.
F_E_MIN = 3.0;          % unidades E/min, permite giros lentos si el modelo los pide
F_E_MAX = 150.0;        % unidades E/min, equivale a 30 rpm con E_UNITS_PER_REV=5

% Limites dinamicos conservadores.
M203_X = 5.0;  M203_Y = 5.0;  M203_Z = 4.0;  M203_E = 10.0;
M201_X = 60.0; M201_Y = 60.0; M201_Z = 40.0; M201_E = 120.0;
M204_P = 40.0; M204_T = 40.0; M204_R = 40.0;

% Recomendacion: dejar false durante pruebas. Hacer G28 manual y verificar.
INCLUDE_HOMING = false;
CALIBRATION_PAUSE_MS = 5000;   % pausa por anillo en archivo de calibracion

%% --------------------- ELECTROVALVULA ----------------------------------
VALVE_ON  = 'M42 P5 T1 S255';
VALVE_OFF = 'M42 P5 T1 S0';
VALVE_SETTLE_MS = 150;
LEAD_IN_DEG = 0;    % 0 para que cada anillo tenga una sola vuelta total
SEAM_OVERLAP_DEG = 0; % subir a 10-15 si aparece una marca de costura

%% --------------------- DATOS DE TRAYECTORIA ----------------------------
xNozzle = rings.nozzle_x_mm;
yNozzle = rings.nozzle_z_mm;  % coordenada DXF: menor valor = mas arriba
zSurface = rings.z_center_mm;
rSurface = rings.radius_mm;

if any(strcmp('theta_command_deg', rings.Properties.VariableNames))
    thetaDeg = rings.theta_command_deg;
else
    error('La tabla radome_ring_schedule.csv no tiene theta_command_deg. Corre primero el modelo v5.');
end

thetaDeg = Z_ANGLE_GAIN * thetaDeg;
thetaDeg = max(thetaDeg, 0);
thetaDeg = min(thetaDeg, Z_MAX_ANGLE_DEG);

if any(strcmp('rpm_radome', rings.Properties.VariableNames))
    rpmRadome = rings.rpm_radome;
else
    rpmRadome = rings.omega_practical_rpm;
end

% Logica de pintado del radomo:
% cada anillo se pinta con UNA vuelta exacta. La variacion de espesor se
% controla con la velocidad del eje E, no aumentando el numero de vueltas.
FORCE_ONE_TURN_PER_RING = true;
if FORCE_ONE_TURN_PER_RING
    turns = ones(height(rings),1);
elseif any(strcmp('turns', rings.Properties.VariableNames))
    turns = rings.turns;
else
    turns = ones(height(rings),1);
end

%% --------------------- MAPEO A COORDENADAS MARLIN ----------------------
% X: desplazamiento radial. Debe aumentar al subir y acercarse al centro,
% pero en la maquina real NO debe hacerlo de forma agresiva al inicio.
xRel_mm = xNozzle(1) - xNozzle;
xRel_mm = xRel_mm - min(xRel_mm);  % asegura inicio en 0
progress = linspace(0, 1, numel(xRel_mm)).';  % base -> punta

switch lower(X_SCALE_MODE)
    case 'delayed_power'
        q = (progress - X_RAMP_START_PROGRESS) ./ max(1e-9, (1 - X_RAMP_START_PROGRESS));
        q = min(max(q, 0), 1);
        Xcmd = X_START + (X_TOP_CMD - X_START) .* (q .^ X_POWER);
    case 'full_range'
        if max(xRel_mm) < 1e-9
            Xcmd = X_START * ones(size(xRel_mm));
        else
            Xcmd = X_START + (X_TOP_CMD - X_START) * xRel_mm ./ max(xRel_mm);
        end
    case 'measured_mm'
        Xcmd = X_START + X_CMD_PER_MM * xRel_mm;
    otherwise
        error('X_SCALE_MODE debe ser delayed_power, full_range o measured_mm.');
end

% Compensacion por desplazamiento real del pico al inclinar el aerografo.
% Reduce X cuando Z se inclina, alejando el pico del radomo.
% Si TOOL_PIVOT_COMP_MM = 0, no hace nada.
if TOOL_PIVOT_COMP_MM > 0
    Xcmd = Xcmd - (TOOL_PIVOT_COMP_MM * X_CMD_PER_MM) .* sind(thetaDeg);
end

% Y: movimiento vertical. Inicia en 200 y sube disminuyendo el valor.
yRel_mm = yNozzle(1) - yNozzle;
yRel_mm = yRel_mm - min(yRel_mm);
if max(yRel_mm) < 1e-9
    Ycmd = Y_START * ones(size(yRel_mm));
else
    Ycmd = Y_START - (Y_START - Y_TOP_CMD) * yRel_mm ./ max(yRel_mm);
end

% Z: angulo del aerografo. Inicia mirando al frente y aumenta la inclinacion.
Zcmd = Z_START + Z_DIRECTION * Z_CMD_PER_DEG .* thetaDeg;

% Saturacion de seguridad.
Xcmd = min(max(Xcmd, X_MIN), X_MAX);
Ycmd = min(max(Ycmd, Y_MIN), Y_MAX);
Zcmd = min(max(Zcmd, Z_MIN), Z_MAX);

% E: giro acumulado del radomo.
leadInUnits = E_UNITS_PER_REV * LEAD_IN_DEG / 360;
seamUnits = E_UNITS_PER_REV * SEAM_OVERLAP_DEG / 360;
paintUnits = E_UNITS_PER_REV * turns;
F_E = E_UNITS_PER_REV .* rpmRadome;
F_E = min(max(F_E, F_E_MIN), F_E_MAX);
rpmCommand = F_E ./ E_UNITS_PER_REV;

%% --------------------- CHEQUEOS DE SEGURIDAD ---------------------------
fprintf('\n================ CHECK DE TRAYECTORIA RADOPINT V5 ================\n');
fprintf('Orden de pintado: base -> punta / abajo -> arriba\n');
fprintf('Inicio requerido: X=%.3f, Y=%.3f, Z=%.3f\n', Xcmd(1), Ycmd(1), Zcmd(1));
fprintf('Rango X generado: %.3f a %.3f\n', min(Xcmd), max(Xcmd));
fprintf('Rango Y generado: %.3f a %.3f\n', min(Ycmd), max(Ycmd));
fprintf('Rango Z generado: %.3f a %.3f\n', min(Zcmd), max(Zcmd));
fprintf('Angulo aerografo min/max: %.3f a %.3f deg\n', min(thetaDeg), max(thetaDeg));
fprintf('Modo X: %s\n', X_SCALE_MODE);
fprintf('X_RAMP_START_PROGRESS: %.3f | X_POWER: %.3f | TOOL_PIVOT_COMP_MM: %.1f mm\n', X_RAMP_START_PROGRESS, X_POWER, TOOL_PIVOT_COMP_MM);
fprintf('Numero de anillos: %d\n', height(rings));
fprintf('Vueltas pintadas por anillo: %.3f\n', turns(1));
fprintf('E_UNITS_PER_REV: %.3f unidades E/vuelta\n', E_UNITS_PER_REV);
fprintf('RPM comandada min/max: %.3f / %.3f rpm\n', min(rpmCommand), max(rpmCommand));
fprintf('F_E min/max: %.3f / %.3f unidades E/min\n', min(F_E), max(F_E));

if abs(Xcmd(1) - X_START) > 1e-6 || abs(Ycmd(1) - Y_START) > 1e-6 || abs(Zcmd(1) - Z_START) > 1e-6
    warning('El primer punto no quedo exactamente en X0 Y200 Z200. Revisa la tabla.');
end
if any(Xcmd < X_MIN | Xcmd > X_MAX)
    warning('X se sale del rango seguro. Ajusta X_TOP_CMD o X_SCALE_MODE.');
end
if any(Ycmd < Y_MIN | Ycmd > Y_MAX)
    warning('Y se sale del rango seguro. Ajusta Y_TOP_CMD.');
end
if any(Zcmd < Z_MIN | Zcmd > Z_MAX)
    warning('Z se sale del rango seguro. Ajusta Z_MAX_ANGLE_DEG o Z_DIRECTION.');
end

Tcheck = table(rings.ring_id, zSurface, rSurface, xNozzle, yNozzle, thetaDeg, ...
    Xcmd, Ycmd, Zcmd, turns, rpmRadome, rpmCommand, F_E, ...
    'VariableNames', {'ring_id','z_surface_mm','radius_mm','nozzle_x_mm','nozzle_z_mm', ...
    'theta_deg','X_cmd','Y_cmd','Z_cmd','turns','rpm_model','rpm_command','F_E'});
writetable(Tcheck, 'radome_RadoPint_v5_1_command_check.csv');

%% --------------------- ESCRITURA DE G-CODE -----------------------------
writeGcode('radome_RadoPint_v5_1_DRYRUN_follow_curve_oneturn.gcode', false, Xcmd, Ycmd, Zcmd, ...
    leadInUnits, paintUnits, seamUnits, F_E, rpmCommand, rings, X_START, Y_START, Z_START, E_START, ...
    INCLUDE_HOMING, WRITE_M92, M92_X, M92_Y, M92_Z, M92_E, ...
    M203_X, M203_Y, M203_Z, M203_E, M201_X, M201_Y, M201_Z, M201_E, ...
    M204_P, M204_T, M204_R, F_XY_POS, F_Z_ANGLE, VALVE_ON, VALVE_OFF, VALVE_SETTLE_MS, ...
    Z_RETURN_FRONT_BEFORE_XY);

writeGcode('radome_RadoPint_v5_1_PAINT_follow_curve_oneturn.gcode', true, Xcmd, Ycmd, Zcmd, ...
    leadInUnits, paintUnits, seamUnits, F_E, rpmCommand, rings, X_START, Y_START, Z_START, E_START, ...
    INCLUDE_HOMING, WRITE_M92, M92_X, M92_Y, M92_Z, M92_E, ...
    M203_X, M203_Y, M203_Z, M203_E, M201_X, M201_Y, M201_Z, M201_E, ...
    M204_P, M204_T, M204_R, F_XY_POS, F_Z_ANGLE, VALVE_ON, VALVE_OFF, VALVE_SETTLE_MS, ...
    Z_RETURN_FRONT_BEFORE_XY);


writeCalibrationGcode('radome_RadoPint_v5_1_CALIBRATE_DISTANCE.gcode', Xcmd, Ycmd, Zcmd, rings, ...
    X_START, Y_START, Z_START, E_START, INCLUDE_HOMING, WRITE_M92, M92_X, M92_Y, M92_Z, M92_E, ...
    M203_X, M203_Y, M203_Z, M203_E, M201_X, M201_Y, M201_Z, M201_E, ...
    M204_P, M204_T, M204_R, F_XY_POS, F_Z_ANGLE, VALVE_OFF, CALIBRATION_PAUSE_MS, ...
    Z_RETURN_FRONT_BEFORE_XY);

fprintf('\nArchivos generados:\n');
fprintf('  - radome_RadoPint_v5_1_DRYRUN_follow_curve_oneturn.gcode\n');
fprintf('  - radome_RadoPint_v5_1_PAINT_follow_curve_oneturn.gcode\n');
fprintf('  - radome_RadoPint_v5_1_CALIBRATE_DISTANCE.gcode\n');
fprintf('  - radome_RadoPint_v5_1_command_check.csv\n');

%% --------------------- FUNCION LOCAL -----------------------------------
function writeGcode(filename, usePaint, Xcmd, Ycmd, Zcmd, leadInUnits, paintUnits, seamUnits, F_E, rpmCommand, rings, ...
    X_START, Y_START, Z_START, E_START, INCLUDE_HOMING, WRITE_M92, M92_X, M92_Y, M92_Z, M92_E, ...
    M203_X, M203_Y, M203_Z, M203_E, M201_X, M201_Y, M201_Z, M201_E, ...
    M204_P, M204_T, M204_R, F_XY_POS, F_Z_ANGLE, VALVE_ON, VALVE_OFF, VALVE_SETTLE_MS, ...
    Z_RETURN_FRONT_BEFORE_XY)

    fid = fopen(filename, 'w');
    assert(fid >= 0, 'No se pudo crear el archivo G-code.');

    fprintf(fid, '; ===============================================================\n');
    fprintf(fid, '; RADOPINT V5.1 - G-CODE MARLIN - X CALIBRADO / RADOMO 1 VUELTA\n');
    fprintf(fid, '; X = radial aerografo | Y = vertical | Z = angulo aerografo | E = radomo\n');
    fprintf(fid, '; Inicio esperado: X%.3f Y%.3f Z%.3f E%.3f\n', X_START, Y_START, Z_START, E_START);
    if usePaint
        fprintf(fid, '; MODO: PAINT - activa electrovalvula\n');
    else
        fprintf(fid, '; MODO: DRY RUN - no activa electrovalvula\n');
    end
    fprintf(fid, '; ===============================================================\n');
    fprintf(fid, 'G21 ; unidades en mm/unidades Marlin\n');
    fprintf(fid, 'G90 ; coordenadas absolutas\n');
    fprintf(fid, 'M82 ; E absoluto\n');
    fprintf(fid, 'M17 ; motores habilitados\n');
    fprintf(fid, 'M302 P1 ; permite mover E sin temperatura\n');
    fprintf(fid, 'M211 S1 ; mantener endstops/limites de software activos\n');
    if WRITE_M92
        fprintf(fid, 'M92 X%.4f Y%.4f Z%.4f E%.4f\n', M92_X, M92_Y, M92_Z, M92_E);
    end
    fprintf(fid, 'M203 X%.3f Y%.3f Z%.3f E%.3f\n', M203_X, M203_Y, M203_Z, M203_E);
    fprintf(fid, 'M201 X%.3f Y%.3f Z%.3f E%.3f\n', M201_X, M201_Y, M201_Z, M201_E);
    fprintf(fid, 'M204 P%.3f T%.3f R%.3f\n', M204_P, M204_T, M204_R);
    fprintf(fid, '%s ; electrovalvula apagada\n', VALVE_OFF);

    if INCLUDE_HOMING
        fprintf(fid, 'G28\n');
    else
        fprintf(fid, '; G28 se hace manualmente antes de correr este archivo\n');
    end

    fprintf(fid, 'G92 X%.3f Y%.3f Z%.3f E%.3f\n', X_START, Y_START, Z_START, E_START);
    fprintf(fid, 'M400\n\n');

    Epos = E_START;
    for k = 1:numel(Xcmd)
        fprintf(fid, '; ---- Anillo %02d | src_ring %02d ----\n', k, rings.ring_id(k));
        fprintf(fid, '; X=%.3f Y=%.3f Z=%.3f | vueltas=1.000 | rpm=%.3f | F_E=%.3f\n', Xcmd(k), Ycmd(k), Zcmd(k), rpmCommand(k), F_E(k));

        % Para evitar activar sensor moviendose con el aerografo inclinado,
        % primero se vuelve a Z200 y luego se reposiciona X/Y.
       

        fprintf(fid, 'G1 Y%.3f F%.3f\n', Ycmd(k), F_XY_POS);
        fprintf(fid, 'G1 X%.3f F%.3f\n', Xcmd(k), F_XY_POS);
        fprintf(fid, 'G1 Z%.3f F%.3f\n', Zcmd(k), F_Z_ANGLE);
        fprintf(fid, 'M400\n');

        
        if usePaint
            fprintf(fid, '%s ; abrir electrovalvula\n', VALVE_ON);
            fprintf(fid, 'G4 P%d\n', VALVE_SETTLE_MS);
        else
            fprintf(fid, '; %s ; DRY RUN, electrovalvula no se activa\n', VALVE_ON);
        end

        Epos = Epos + paintUnits(k) + seamUnits;
        fprintf(fid, 'G1 E%.5f F%.3f ; pintar anillo + solape\n', Epos, F_E(k));
        fprintf(fid, 'M400\n');

        if usePaint
            fprintf(fid, '%s ; cerrar electrovalvula\n', VALVE_OFF);
            fprintf(fid, 'G4 P%d\n', VALVE_SETTLE_MS);
        else
            fprintf(fid, '; %s ; DRY RUN\n', VALVE_OFF);
        end
        fprintf(fid, '\n');
    end

    fprintf(fid, '; ---- Fin del programa ----\n');
    if Z_RETURN_FRONT_BEFORE_XY
        fprintf(fid, 'G1 Z%.3f F%.3f ; dejar aerografo mirando de frente\n', Z_START, F_Z_ANGLE);
    end
    fprintf(fid, '%s ; asegurar electrovalvula apagada\n', VALVE_OFF);
    fprintf(fid, 'M400\n');
    fclose(fid);
end


function writeCalibrationGcode(filename, Xcmd, Ycmd, Zcmd, rings, ...
    X_START, Y_START, Z_START, E_START, INCLUDE_HOMING, WRITE_M92, M92_X, M92_Y, M92_Z, M92_E, ...
    M203_X, M203_Y, M203_Z, M203_E, M201_X, M201_Y, M201_Z, M201_E, ...
    M204_P, M204_T, M204_R, F_XY_POS, F_Z_ANGLE, VALVE_OFF, CALIBRATION_PAUSE_MS, ...
    Z_RETURN_FRONT_BEFORE_XY)

    fid = fopen(filename, 'w');
    assert(fid >= 0, 'No se pudo crear el archivo G-code de calibracion.');

    fprintf(fid, '; ===============================================================\n');
    fprintf(fid, '; RADOPINT V5 - CALIBRACION DE DISTANCIA POR ANILLO\n');
    fprintf(fid, '; No gira E y no activa electrovalvula. Pausa en cada anillo.\n');
    fprintf(fid, '; Medir distancia aerografo-radomo en cada pausa.\n');
    fprintf(fid, '; ===============================================================\n');
    fprintf(fid, 'G21\nG90\nM82\nM17\nM302 P1\nM211 S1\n');
    if WRITE_M92
        fprintf(fid, 'M92 X%.4f Y%.4f Z%.4f E%.4f\n', M92_X, M92_Y, M92_Z, M92_E);
    end
    fprintf(fid, 'M203 X%.3f Y%.3f Z%.3f E%.3f\n', M203_X, M203_Y, M203_Z, M203_E);
    fprintf(fid, 'M201 X%.3f Y%.3f Z%.3f E%.3f\n', M201_X, M201_Y, M201_Z, M201_E);
    fprintf(fid, 'M204 P%.3f T%.3f R%.3f\n', M204_P, M204_T, M204_R);
    fprintf(fid, '%s\n', VALVE_OFF);
    if INCLUDE_HOMING
        fprintf(fid, 'G28\n');
    else
        fprintf(fid, '; G28 se hace manualmente antes de correr este archivo\n');
    end
    fprintf(fid, 'G92 X%.3f Y%.3f Z%.3f E%.3f\nM400\n\n', X_START, Y_START, Z_START, E_START);

    for k = 1:numel(Xcmd)
        fprintf(fid, '; ---- Medicion de distancia - Anillo %02d | src_ring %02d ----\n', k, rings.ring_id(k));
        if Z_RETURN_FRONT_BEFORE_XY && k > 1
            fprintf(fid, 'G1 Z%.3f F%.3f\nM400\n', Z_START, F_Z_ANGLE);
        end
        fprintf(fid, 'G1 Y%.3f F%.3f\n', Ycmd(k), F_XY_POS);
        fprintf(fid, 'G1 X%.3f F%.3f\n', Xcmd(k), F_XY_POS);
        fprintf(fid, 'G1 Z%.3f F%.3f\n', Zcmd(k), F_Z_ANGLE);
        fprintf(fid, 'M400\n');
        fprintf(fid, 'M117 Medir anillo %02d\n', k);
        fprintf(fid, 'G4 P%d\n\n', CALIBRATION_PAUSE_MS);
    end

    fprintf(fid, 'G1 Z%.3f F%.3f\n', Z_START, F_Z_ANGLE);
    fprintf(fid, '%s\nM400\n', VALVE_OFF);
    fclose(fid);
end
