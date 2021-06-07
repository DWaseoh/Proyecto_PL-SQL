DECLARE
    NU NUMBER:=0;
BEGIN
    CASE NU
    WHEN 0 THEN
        MOSTRAR_FECHA(1947, 1980);
    WHEN 1 THEN
        MOSTRAR_INFO('Amadeus Mozart');
    WHEN 2 THEN
        MOSTRAR_GEN('Sinfonía', 'Amadeus Mozart');
        MOSTRAR_GEN('Opera', 'Amadeus Mozart');
        MOSTRAR_GEN('Misa', 'Amadeus Mozart');
    WHEN 3 THEN
        CREAR_ENT(2, '84425299G');
        CREAR_ENT(2, '86167931H');
        CREAR_ENT(3, '91423507W');
    END CASE;
END;
/

--1
/*
Procedimiento mostrar_fecha, que introduzca dos valores,
un rango de fechas, y dadas las fechas escribir en pantalla
los músicos y sus obras más famosas con un cursor.
*/
CREATE OR REPLACE PROCEDURE MOSTRAR_FECHA(ANIO_INI NUMBER, ANIO_FIN NUMBER) IS

--Variables
    V_NOMBRE VARCHAR2(20);
    V_OBRA_FAMOSA VARCHAR2(30);
    V_CONTROL_OBR BOOLEAN := TRUE;
    
    error_obra EXCEPTION;
--Cursor para el nombre de los músicos
    CURSOR MUSICOS IS
        SELECT DISTINCT M.NOMBRE_MUSICO AS "NOMBRE MÚSICO",
                        M.NOMBRE_GENERO AS "NOMBRE GENERO"
            FROM OBRA_FAMOSA OB, MUSICO M, MUS_OBR MOB
            WHERE ANIO_CREACION BETWEEN ANIO_INI AND ANIO_FIN
            AND OB.NOMBRE_OBRA=MOB.NOMBRE_OBRA AND MOB.NOMBRE_MUSICO=M.NOMBRE_MUSICO;
-- Cursor para el nombre de las obras    
    CURSOR OBRAS (NOMBRE VARCHAR2) IS
        SELECT DISTINCT OB.NOMBRE_OBRA AS "NOMBRE OBRA"
            FROM OBRA_FAMOSA OB, MUSICO M, MUS_OBR MOB
            WHERE ANIO_CREACION BETWEEN ANIO_INI AND ANIO_FIN
            AND OB.NOMBRE_OBRA=MOB.NOMBRE_OBRA AND MOB.NOMBRE_MUSICO=NOMBRE;
    
BEGIN
--Recorre el nombre de los músicos
    FOR REG IN MUSICOS LOOP
        DBMS_OUTPUT.PUT_LINE('Músico: ' || reg."NOMBRE MÚSICO" || '.');
        DBMS_OUTPUT.PUT_LINE('Género: ' || reg."NOMBRE GENERO" || '.');
        DBMS_OUTPUT.PUT_LINE('Obras: ');
        V_CONTROL_OBR := FALSE;
--Recorre el nombre de las obras de cada músico 
        FOR REGIS IN OBRAS (reg."NOMBRE MÚSICO") LOOP
            DBMS_OUTPUT.PUT_LINE(CHR(9) || '-' || regis."NOMBRE OBRA");
        END LOOP;
    END LOOP;
    
    IF V_CONTROL_OBR THEN
        RAISE error_obra;
    END IF;
    
EXCEPTION
    WHEN error_obra THEN
        DBMS_OUTPUT.PUT_LINE('No se han encontrado obras en entre las fechas dadas');
        WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ocurrió el error ' || SQLERRM);
END MOSTRAR_FECHA;
/

EXEC MOSTRAR_FECHA(1947, 1980);

--2
/*
Procedimiento mostrar_info, introducir el nombre de un músico
y mostrar todas sus obras junto con la fecha de creación con un cursor.
*/
CREATE OR REPLACE PROCEDURE MOSTRAR_INFO(V_NOMBRE VARCHAR2) IS
--Variables
    V_OBRA VARCHAR2(30);
    V_ANIO NUMBER(4);
    V_CONTROL BOOLEAN:= TRUE;
--Cursor que recorre las obras
    CURSOR OBRAS IS
        SELECT OB.NOMBRE_OBRA AS "NOMBRE",
                OB.ANIO_CREACION AS "ANIO",
                OB.NOMBRE_GENERO AS "GENERO"
                    FROM OBRA_FAMOSA OB, MUSICO M, MUS_OBR MOB
                    WHERE M.NOMBRE_MUSICO=V_NOMBRE
                    AND OB.NOMBRE_OBRA=MOB.NOMBRE_OBRA
                    AND MOB.NOMBRE_MUSICO=M.NOMBRE_MUSICO;

    error_al_buscar EXCEPTION;

BEGIN
--Loop que muestra las obras con su nombre y fecha de publicación.
    DBMS_OUTPUT.PUT_LINE('Obras: ');
    FOR REG IN OBRAS LOOP
        DBMS_OUTPUT.PUT_LINE('-Nombre: ' || reg."NOMBRE");
        DBMS_OUTPUT.PUT_LINE('-Género: ' || reg."GENERO");
        DBMS_OUTPUT.PUT_LINE('-Año: ' || reg."ANIO");
        DBMS_OUTPUT.PUT_LINE('');
        V_CONTROL := FALSE;
    END LOOP;
    IF V_CONTROL THEN
        RAISE error_al_buscar;
    END IF;

EXCEPTION
    WHEN error_al_buscar THEN
        DBMS_OUTPUT.PUT_LINE('No se han encontrado obras. Prueba a introducir un artista correcto.');
        WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ocurrió el error ' || SQLERRM);
END MOSTRAR_INFO;
/

EXEC MOSTRAR_INFO('Bob Marley');

--3
/*
Función ciento_gen donde se introduce un género y un músico,
si hay relación devolverá un número entero que es el porcentaje
de obras de ese género del músico en cuestión, si no hay relación
devolverá un 0.
*/
CREATE OR REPLACE FUNCTION CIENTO_GEN (V_GEN VARCHAR2, V_MUS VARCHAR2)
RETURN NUMBER IS

--Declaración de variables
V_DIVIDENDO NUMBER(3);
V_DIVISOR NUMBER(3);
V_CIENTO NUMBER(3);

BEGIN
-- Busca el número de canciones del género específico que se está consultando.
    SELECT COUNT(O.NOMBRE_GENERO)
        INTO V_DIVIDENDO
        FROM OBRA_FAMOSA O, MUS_OBR MOB
        WHERE NOMBRE_GENERO=V_GEN AND MOB.NOMBRE_MUSICO=V_MUS
        AND O.NOMBRE_OBRA=MOB.NOMBRE_OBRA;

-- Busca el número de canciones totales del artista consultado.
    SELECT COUNT(MO.NOMBRE_OBRA)
        INTO V_DIVISOR
        FROM MUSICO M, MUS_OBR MO
        WHERE MO.NOMBRE_MUSICO=V_MUS
        AND M.NOMBRE_MUSICO=MO.NOMBRE_MUSICO
        GROUP BY M.NOMBRE_MUSICO;

-- Calcula el porcentaje de canciones del género consultado.
    V_CIENTO:=(V_DIVIDENDO*100)/V_DIVISOR;

-- Devuelve el porcentaje en número entero.
    RETURN V_CIENTO;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END CIENTO_GEN;
/

--4
/*
Procedimiento mostrar_gen usando la función ciento_gen,
muestra el género y el porcentaje de obras que ha
realizado sobre ese género con un cursor.
*/
CREATE OR REPLACE PROCEDURE MOSTRAR_GEN(V_GEN VARCHAR2, V_MUS VARCHAR2) IS

BEGIN
--Muestra los datos buscados usando la función anterior. 
    DBMS_OUTPUT.PUT_LINE('--------------');
    DBMS_OUTPUT.PUT_LINE('Artista: ' || V_MUS);
    DBMS_OUTPUT.PUT_LINE('Género: '|| V_GEN);
    DBMS_OUTPUT.PUT_LINE('Porcentaje de obras: ' || CIENTO_GEN (V_GEN, V_MUS) || '%');
    DBMS_OUTPUT.PUT_LINE('--------------');
END MOSTRAR_GEN;
/

EXEC MOSTRAR_GEN('Sinfonía', 'Amadeus Mozart');
EXEC MOSTRAR_GEN('Opera', 'Amadeus Mozart');
EXEC MOSTRAR_GEN('Misa', 'Amadeus Mozart');

--5
/*
Función ent_dis introduce el número de ID un evento
y devuelve un número que son las entradas libres
del evento (Aforo ocupado - Aforo total).
*/
CREATE OR REPLACE FUNCTION ENT_DIS(V_ID NUMBER)
RETURN NUMBER IS

/* Declaración de variables, donde:
        V_ESPACIO es el número de entradas vendidas para un evento, lo que se resume en
            el espacio de una sala que está ocupado.

        V_AFORO es el número de aforo total de la sala.
*/
V_ESPACIO NUMBER(2);
V_AFORO NUMBER(2);

BEGIN

-- Con este select conseguimos las variables que buscabamos.
    SELECT COUNT(EN.ID_EVENTO), S.AFORO
        INTO V_ESPACIO, V_AFORO
        FROM ENTRADA EN, SALA S, EVENTO E
        WHERE E.NUM_ID=V_ID
        AND EN.ID_EVENTO=E.NUM_ID AND E.ID_SALA=S.NUM_ID
        GROUP BY S.AFORO;

-- Si el espacio ocupado y el aforo son iguales el aforo está completo.
    IF V_ESPACIO=V_AFORO THEN
        RETURN -1;
    ELSE
-- Si hay entradas devolvera el número de aforo libre.
        RETURN V_AFORO-V_ESPACIO;
    END IF;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;

END ENT_DIS;
/

--6
/*
Procedimiento CREAR_ENT usando ENT_DIS, si existe aforo libre
se introducirá el DNI del cliente y se creará una entrada.
Al finalizar mostrará las entradas libres que quedan, por
el contrario mostrará un mensaje de error.
*/
CREATE OR REPLACE PROCEDURE CREAR_ENT (V_EVE NUMBER, V_NIF VARCHAR2) IS

    V_FECHA DATE;
    V_NOMBRE VARCHAR2(20);

BEGIN
    SELECT NOMBRE, FECHA_HORA
        INTO V_NOMBRE, V_FECHA
        FROM EVENTO
        WHERE NUM_ID=V_EVE;
-- Si no hay aforo libre no quedan entradas.
    IF ENT_DIS(V_EVE)=-1 THEN
        DBMS_OUTPUT.PUT_LINE('No quedan entradas disponibles');
    ELSE
-- Si hay aforo libre se creará un cliente vacio con DNI y una entrada.
        INSERT INTO CLIENTE VALUES (V_NIF, 'S/N', 'S/N', null);
        INSERT INTO ENTRADA VALUES (V_EVE, V_FECHA, V_NIF);
        DBMS_OUTPUT.PUT_LINE('Entrada creada con exito');
        DBMS_OUTPUT.PUT_LINE('Quedan ' || ENT_DIS(V_EVE) || ' entradas disponibles para ' || V_NOMBRE || '.');
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No se han encontrado eventos');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ocurrió el error ' || SQLERRM);
END;
/

EXEC CREAR_ENT(15, '28836725S');
EXEC CREAR_ENT(2, '84425299G');
EXEC CREAR_ENT(2, '86167931H');
EXEC CREAR_ENT(3, '91423507W');

-- Disparadores de fila.

CREATE TABLE ACTUALIZAR(
    DNI VARCHAR2(9) REFERENCES CLIENTE
);
-- 7
/* Disparador de fila que se lanza despues de insertar una entrada.
        Añade a la tabla ACTUALIZAR el DNI del cliente que tenga
        nombre o apellidos vacíos.
*/
CREATE OR REPLACE TRIGGER ACT_CLI
    AFTER INSERT ON ENTRADA
    FOR EACH ROW
DECLARE

-- Declaro 3 variables, nombre, apellido y un control booleano.
    V_NOMBRE VARCHAR2(20);
    V_APELLIDO VARCHAR2(10);
    V_ENTRA BOOLEAN:=FALSE;
BEGIN
-- Hago un cursor implicito para conseguir el nombre del cliente donde el DNI
--  sea el DNI de la nueva entrada que se está creando.
    SELECT NOMBRE, APELLIDO
        INTO V_NOMBRE, V_APELLIDO
        FROM CLIENTE
        WHERE DNI=:NEW.DNI_CLI;

-- Si el nombre o el apellido del cliente estan vacios
--  el booleano tomará valor true.
    IF V_NOMBRE IN ('', 'S/N') THEN
        V_ENTRA:=TRUE;
    ELSIF V_APELLIDO IN ('', 'S/N') THEN
        V_ENTRA:=TRUE;
    END IF;

-- Al tener valor true insertará el DNI en la tabla actualizar.
    IF V_ENTRA THEN
        INSERT INTO ACTUALIZAR VALUES (:NEW.DNI_CLI);
    END IF;
END ACT_CLI;
/

-- Insert para comprobar que este DNI no se añade a la tabla ACTUALIZAR.
INSERT INTO CLIENTE VALUES ('2154789R', 'Manuel', 'Perez', 654789321);
INSERT INTO ENTRADA VALUES (2, '06/07/21', '2154789R');

-- Insert en ENTRADA que si inserta el DNI en ACTUALIZAR
--  por crear un cliente vacio.
EXEC CREAR_ENT(2, '78945412R');

-- 8
/*  Disparador de fila que hace un control de los clientes y la tabla Actualizar.
        Si el cliente que se actualiza tenía el nombre o el apellido vacío
        se eliminará el DNI correspondiente de la tabla ACTUALIZAR.
*/
CREATE OR REPLACE TRIGGER CTRL_CLI
    AFTER UPDATE ON CLIENTE
    FOR EACH ROW
DECLARE
-- Variable de control booleano.
    V_ENTRA BOOLEAN:=FALSE;
    
BEGIN
-- Si el nombre o el apellido antiguo del cliente que se esta actualizando
--  estaba vacío, la variable de control tomará valor true.
    IF :OLD.NOMBRE IN ('', 'S/N') THEN
        V_ENTRA:=TRUE;
    ELSIF :OLD.APELLIDO IN ('', 'S/N') THEN
        V_ENTRA:=TRUE;
    END IF;

-- Al tomar valor true eliminará de la tabla actualizar aquel DNI
--  del cliente que se está actualizando.
    IF V_ENTRA THEN
        DELETE ACTUALIZAR WHERE :NEW.DNI=DNI;
    END IF;
END ACT_CLI;
/

-- Update que actualiza un cliente que tiene su DNI en ACTUALIZAR.
--  El DNI en ACTUALIZAR se borra, porque era un cliente vacio.
UPDATE CLIENTE SET NOMBRE='Paco', APELLIDO='Ferrero' WHERE DNI='78945412R';

--Disparadores de instrucción.

-- 9
/*  Disparador de instrucción que controla que no se pueda hacer ninguna
        operacion en las entradas mientras sea festivo nacional.
*/
CREATE OR REPLACE TRIGGER DENEGAR
    BEFORE INSERT OR UPDATE OR DELETE ON ENTRADA
    FOR EACH ROW
BEGIN    
    IF TO_CHAR(SYSDATE, 'DD/MM') IN ('12/10', '02/11', '08/12', '25/12', '01/01', '06/01', '02/04', '01/05', '03/06') THEN
        IF INSERTING THEN
            RAISE_APPLICATION_ERROR(-20001, 'No puedes comprar una entrada para un evento en festivo nacional.');
        ELSIF UPDATING THEN
            RAISE_APPLICATION_ERROR(-20002, 'No puedes modificar una entrada para un evento en festivo nacional.');
        ELSE
            RAISE_APPLICATION_ERROR(-20003, 'No puedes eliminar una entrada para un evento en festivo nacional.');
        END IF;
    END IF;
END;
/

-- Si se prueba a hacer cualquier operacion en ENTRADA en festivo nacional
--  saltará un error.
EXEC CREAR_ENT(3, '28836723D');