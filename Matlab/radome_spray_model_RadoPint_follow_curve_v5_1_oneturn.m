%% RADOPINT - MODELO DE ASPERSION PARA RADOMO REAL
% Version v5.1 - seguimiento de curva; una vuelta por anillo y velocidad radial corregida.
%
% Logica de esta version:
%   - El primer anillo es la parte mas baja del radomo.
%   - En el primer anillo el aerografo queda mirando de frente: angulo = 0 deg.
%   - A medida que sube, el angulo aumenta de forma progresiva siguiendo la
%     variacion de la curva del perfil, NO la normal absoluta. Esto evita que
%     desde el segundo anillo se incline excesivamente hacia la mesa.
%   - La boquilla se posiciona a una distancia aproximada de 65 mm desde el
%     punto objetivo sobre la curva, usando el angulo calculado.
%   - Cada anillo se pinta con UNA vuelta del radomo. La uniformidad se
%     controla aumentando la velocidad angular a medida que disminuye el radio.
%
% Convencion geometrica interna del DXF:
%   z = 0 mm      -> punta / zona superior del radomo en el perfil.
%   z = zMax mm   -> base / parte mas baja del radomo.
%
% Archivos de salida:
%   - radome_profile_processed.csv
%   - radome_ring_schedule.csv

clear; clc; close all;

%% ---------------------- PARAMETROS DEL USUARIO -------------------------
dxfFile = 'radomo.DXF';       % Perfil DXF del radomo

% Aerografo y pintura. Calibrar Qgun midiendo cuantos mL salen en 60 s.
Qgun_ml_min    = 2.5;         % caudal volumetrico estimado [mL/min]
eta_transfer   = 0.35;        % eficiencia de transferencia estimada [-]
h_target_um    = 25;          % espesor objetivo teorico [um]

% Patron de aspersion medido sobre la pieza.
fanWidth_mm    = 25;          % diametro aproximado del circulo pintado [mm]
overlap        = 0.50;        % solape entre anillos [-]

% Estrategia de pintado por anillos.
nTurnsMain     = 1.0;         % vueltas completas por anillo
omegaMax_rpm   = 25;          % limite maximo de giro del radomo [rpm]; subir si arriba queda muy cargado
omegaMin_rpm   = 1.0;         % limite minimo para evitar tiempos excesivos [rpm]

% Distancia entre boquilla y punto objetivo del radomo.
standOff_mm    = 65;          % distancia objetivo aerografo-radomo [mm]

% Limite de inclinacion del aerografo. Con Z200->Z110 = 90 deg, 60 deg
% corresponde aproximadamente a Z140. Ajustar tras dry-run si hace falta.
maxAngle_deg   = 60;
angleGain      = 1.00;

%% ---------------------- CONVERSION DE UNIDADES -------------------------
Qe       = Qgun_ml_min * eta_transfer * 1e-6 / 60;  % [m^3/s]
hTarget  = h_target_um * 1e-6;                      % [m]
fanW     = fanWidth_mm * 1e-3;                      % [m]
ds       = fanW * (1 - overlap);                    % [m]
omegaMax = omegaMax_rpm * 2*pi/60;                  % [rad/s]
omegaMin = omegaMin_rpm * 2*pi/60;                  % [rad/s]
standOff = standOff_mm * 1e-3;                      % [m]

%% -------------------- LECTURA Y PROCESAMIENTO DEL DXF ------------------
profileXY = readProfileFromDXF(dxfFile);

% Orientar para que el primer punto sea la punta: menor x+y.
if sum(profileXY(1,:)) > sum(profileXY(end,:))
    profileXY = flipud(profileXY);
end

% Llevar la punta a (0,0).
tipXY = profileXY(1,:);
profileXY = profileXY - tipXY;

r_full = profileXY(:,1) * 1e-3;   % [m]
z_full = profileXY(:,2) * 1e-3;   % [m]

% Si el DXF tiene cara plana en la base, se excluye de la superficie lateral.
tol = 1e-9;
hasFlatBaseFace = abs(z_full(end) - z_full(end-1)) < tol;
if hasFlatBaseFace
    rBaseOuter = r_full(end);
    r = r_full(1:end-1);
    z = z_full(1:end-1);
else
    rBaseOuter = NaN;
    r = r_full;
    z = z_full;
end

% Longitud meridiana acumulada.
s = [0; cumsum(sqrt(diff(r).^2 + diff(z).^2))];
Lmeridian = s(end);

%% -------------------- PERFIL CONTINUO ----------------------------------
zFine = linspace(z(1), z(end), 3000).';
rFine = pchip(z, r, zFine);
drdzFine = gradient(rFine, zFine);

% Area lateral de revolucion.
dA_dz = 2*pi*rFine .* sqrt(1 + drdzFine.^2);
A_lateral = trapz(zFine, dA_dz);

% Angulo de la tangente respecto al eje radial, usando la convencion del DXF.
% En la base este angulo es grande; hacia la punta disminuye. La diferencia
% respecto a la base da una inclinacion progresiva, empezando en 0 deg.
thetaTangentFine_deg = atan2d(drdzFine, 1);

%% -------------------- DISCRETIZACION EN ANILLOS ------------------------
sCenters = (ds/2 : ds : (Lmeridian - ds/2)).';
zRing = pchip(s, z, sCenters);
rRing = pchip(s, r, sCenters);
drdzRing = interp1(zFine, drdzFine, zRing, 'linear', 'extrap');
thetaTangentRing_deg = atan2d(drdzRing, 1);

% Angulo relativo: base = 0 deg, punta = mayor inclinacion.
% Como los anillos estan en orden punta->base, la base corresponde al ultimo.
thetaBase_deg = thetaTangentRing_deg(end);
thetaCommandRing_deg = angleGain * (thetaBase_deg - thetaTangentRing_deg);
thetaCommandRing_deg = max(thetaCommandRing_deg, 0);
thetaCommandRing_deg = min(thetaCommandRing_deg, maxAngle_deg);

% Posicion de boquilla a distancia standOff sobre la direccion de disparo.
% theta=0: boquilla a la misma altura que el punto objetivo y 65 mm hacia afuera.
% theta>0: boquilla sube y se acerca radialmente al centro para apuntar al radomo.
xGunRing = rRing + standOff .* cosd(thetaCommandRing_deg);
zGunRing = zRing - standOff .* sind(thetaCommandRing_deg);

% Distancia geometrica resultante para verificacion.
standOffCheck_mm = sqrt((xGunRing-rRing).^2 + (zGunRing-zRing).^2) * 1e3;

%% -------------------- LEY DE VELOCIDAD ANGULAR -------------------------
% Logica usada en el prototipo real:
%   - Cada anillo recibe exactamente una vuelta pintando.
%   - El tiempo de exposicion se controla con la velocidad del eje E.
%   - Como el area por vuelta disminuye al subir hacia la punta, la velocidad
%     angular debe aumentar cuando el radio local es menor.
%
% Modelo fisico simplificado para espesor uniforme:
%   h = Qe * n / (omega * r * ds)
%   Para h constante y n = 1 vuelta: omega proporcional a 1/r.
turnsRing = ones(size(rRing));
omegaIdeal = Qe .* turnsRing ./ (hTarget * ds .* rRing);
rpmIdeal = omegaIdeal * 60 / (2*pi);

% Se limita la velocidad para que el eje E no pierda pasos ni vibre.
omegaRing = min(max(omegaIdeal, omegaMin), omegaMax);
rpmRing = omegaRing * 60 / (2*pi);
tRing = 60 * turnsRing ./ rpmRing;

% Espesor teorico resultante con las limitaciones de velocidad.
A_ring = 2*pi * rRing * ds;
V_ring = Qe * tRing;
hRing = V_ring ./ A_ring;
vAdvance = ds ./ tRing;

%% -------------------- EXPORTAR TABLAS ----------------------------------
Tprofile = table(z*1e3, r*1e3, ...
    interp1(zFine, drdzFine, z, 'linear', 'extrap'), ...
    interp1(zFine, thetaTangentFine_deg, z, 'linear', 'extrap'), ...
    'VariableNames', {'z_mm','r_mm','dr_dz','theta_tangent_deg'});
writetable(Tprofile, 'radome_profile_processed.csv');

Trings = table((1:numel(sCenters)).', sCenters*1e3, zRing*1e3, rRing*1e3, ...
    xGunRing*1e3, zGunRing*1e3, drdzRing, thetaTangentRing_deg, thetaCommandRing_deg, ...
    standOffCheck_mm, rpmIdeal, rpmRing, turnsRing, tRing, hRing*1e6, vAdvance*1e3, ...
    'VariableNames', {'ring_id','s_center_mm','z_center_mm','radius_mm', ...
    'nozzle_x_mm','nozzle_z_mm','dr_dz','theta_tangent_deg','theta_command_deg', ...
    'standOff_check_mm','rpm_ideal','rpm_radome','turns','dwell_time_s','thickness_um','v_advance_equiv_mm_s'});
writetable(Trings, 'radome_ring_schedule.csv');

%% -------------------- RESUMEN ------------------------------------------
fprintf('\n=================== RADOPINT V5 - RESUMEN GEOMETRICO ===================\n');
fprintf('Archivo DXF                              : %s\n', dxfFile);
fprintf('Altura axial lateral del radomo          : %.3f mm\n', z(end)*1e3);
fprintf('Radio lateral en la base                 : %.3f mm\n', r(end)*1e3);
if hasFlatBaseFace
    fprintf('Radio exterior de cara plana/base        : %.3f mm\n', rBaseOuter*1e3);
end
fprintf('Longitud meridiana lateral               : %.3f mm\n', Lmeridian*1e3);
fprintf('Area lateral aproximada                  : %.6f m^2\n', A_lateral);
fprintf('Distancia boquilla-punto objetivo        : %.3f mm\n', standOff_mm);
fprintf('Diametro de patron usado                 : %.3f mm\n', fanWidth_mm);
fprintf('Separacion efectiva entre anillos        : %.3f mm\n', ds*1e3);
fprintf('Numero de anillos                        : %d\n', numel(sCenters));
fprintf('Angulo relativo min/max                  : %.3f / %.3f deg\n', min(thetaCommandRing_deg), max(thetaCommandRing_deg));
fprintf('Modo de trayectoria                      : seguimiento relativo de curva\n');

fprintf('\n=================== RADOPINT V5 - RESUMEN DE PROCESO ====================\n');
fprintf('Caudal estimado en pistola               : %.3f mL/min\n', Qgun_ml_min);
fprintf('Caudal efectivo estimado                 : %.3f mL/min\n', Qe*60*1e6);
fprintf('Espesor objetivo teorico                 : %.3f um\n', h_target_um);
fprintf('Vueltas por anillo                       : %.3f vuelta\n', 1.0);
fprintf('Velocidad ideal radomo min/max           : %.3f / %.3f rpm\n', min(rpmIdeal), max(rpmIdeal));
fprintf('Velocidad comandada radomo min/max       : %.3f / %.3f rpm\n', min(rpmRing), max(rpmRing));
fprintf('Tiempo total estimado                    : %.2f s (%.2f min)\n', sum(tRing), sum(tRing)/60);
fprintf('Espesor teorico min/max                  : %.3f / %.3f um\n', min(hRing)*1e6, max(hRing)*1e6);

%% -------------------- GRAFICAS -----------------------------------------
figure('Name','RadoPint V5 - perfil y boquilla','Color','w');
plot(r*1e3, z*1e3, 'LineWidth', 1.8); hold on;
plot(Trings.nozzle_x_mm, Trings.nozzle_z_mm, 'o-', 'LineWidth', 1.2, 'MarkerSize', 4);
for k = 1:2:height(Trings)
    plot([Trings.nozzle_x_mm(k), Trings.radius_mm(k)], ...
         [Trings.nozzle_z_mm(k), Trings.z_center_mm(k)], ':', 'LineWidth', 0.8);
end
axis equal; grid on;
xlabel('Radio / posicion radial [mm]');
ylabel('Coordenada axial desde la punta [mm]');
title('Perfil lateral y trayectoria de boquilla con seguimiento relativo');
legend('Superficie lateral','Boquilla','Linea de disparo','Location','best');

figure('Name','RadoPint V5 - angulo de aerografo','Color','w');
plot(Trings.z_center_mm, Trings.theta_command_deg, 'o-', 'LineWidth', 1.2);
grid on;
xlabel('z desde la punta [mm]'); ylabel('Angulo relativo del aerografo [deg]');
title('Inclinacion progresiva: 0 deg en base, mayor hacia punta');

figure('Name','RadoPint V5 - velocidad del radomo','Color','w');
plot(Trings.z_center_mm, Trings.rpm_radome, 'o-', 'LineWidth', 1.2);
grid on;
xlabel('z desde la punta [mm]'); ylabel('Velocidad del radomo [rpm]');
title('Velocidad angular por anillo');

%% -------------------- FUNCIONES LOCALES --------------------------------
function profile = readProfileFromDXF(filename)
    rawLines = readDXFLines(filename);
    rawLines = removeDuplicateSegments(rawLines, 1e-6);
    profile = orderOpenPolyline(rawLines, 1e-6);
end

function seg = readDXFLines(filename)
    fid = fopen(filename, 'r');
    assert(fid >= 0, 'No se pudo abrir el archivo DXF: %s', filename);
    C = textscan(fid, '%s', 'Delimiter', '\n', 'Whitespace', '');
    fclose(fid);

    L = strtrim(C{1});
    seg = zeros(0,4);
    i = 1;
    while i <= numel(L)-1
        code = L{i};
        value = L{i+1};
        if strcmp(code, '0') && strcmpi(value, 'LINE')
            x1 = NaN; y1 = NaN; x2 = NaN; y2 = NaN;
            i = i + 2;
            while i <= numel(L)-1
                code = L{i};
                value = L{i+1};
                if strcmp(code, '0')
                    break;
                end
                switch code
                    case '10'
                        x1 = str2double(value);
                    case '20'
                        y1 = str2double(value);
                    case '11'
                        x2 = str2double(value);
                    case '21'
                        y2 = str2double(value);
                end
                i = i + 2;
            end
            seg(end+1,:) = [x1 y1 x2 y2]; %#ok<AGROW>
        else
            i = i + 2;
        end
    end
end

function segOut = removeDuplicateSegments(segIn, tol)
    a = round(segIn(:,1:2)/tol)*tol;
    b = round(segIn(:,3:4)/tol)*tol;
    minAB = min(cat(3,a,b), [], 3);
    maxAB = max(cat(3,a,b), [], 3);
    key = [minAB maxAB];
    [~, ia] = unique(key, 'rows', 'stable');
    segOut = segIn(ia,:);
end

function profile = orderOpenPolyline(seg, tol)
    pts = [seg(:,1:2); seg(:,3:4)];
    ptsRound = round(pts/tol)*tol;
    [nodes, ~, ic] = unique(ptsRound, 'rows', 'stable');

    nSeg = size(seg,1);
    segNodes = [ic(1:nSeg), ic(nSeg+1:end)];

    deg = accumarray(segNodes(:), 1, [size(nodes,1), 1]);
    endNodes = find(deg == 1);
    assert(numel(endNodes) == 2, 'La geometria no parece ser una polilinea abierta.');

    current = endNodes(1);
    used = false(nSeg,1);
    profile = zeros(nSeg+1,2);
    k = 1;

    while true
        profile(k,:) = nodes(current,:);
        idx = find((segNodes(:,1) == current | segNodes(:,2) == current) & ~used);
        if isempty(idx)
            break;
        end
        thisSeg = idx(1);
        used(thisSeg) = true;

        if segNodes(thisSeg,1) == current
            current = segNodes(thisSeg,2);
        else
            current = segNodes(thisSeg,1);
        end
        k = k + 1;
    end

    profile = profile(1:k,:);
    if sum(profile(1,:)) > sum(profile(end,:))
        profile = flipud(profile);
    end
end
