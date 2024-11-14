-- Eliminar la base si existe
DROP DATABASE if EXISTS db_prueba_tecnica;
-- Crear la base de datos si no existe
CREATE DATABASE if NOT EXISTS db_prueba_tecnica;
-- Usar la base de datos
USE db_prueba_tecnica;

-- Crear la tabla de usuarios
CREATE TABLE tb_usuarios(
  id_usuario INT AUTO_INCREMENT PRIMARY KEY, -- llave primaria auto incremental
  nombre_usuario VARCHAR(100) NOT NULL,
  CONSTRAINT uq_nombre_usuario_unico UNIQUE(nombre_usuario),
  correo_electronico_usuario VARCHAR(100) NOT NULL,
  CONSTRAINT uq_correo_electronico_usuario_unico UNIQUE(correo_electronico_usuario),
  CONSTRAINT chk_correo_electronico_usuario_formato CHECK (correo_electronico_usuario REGEXP '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}$'),
  clave_usuario VARCHAR(100) NOT NULL,
  fecha_registro_usuario DATETIME DEFAULT NOW(),
  telefono_usuario VARCHAR(15) NOT NULL,
  dui_usuario VARCHAR(10) NOT NULL,
  CONSTRAINT uq_dui_usuario_unico UNIQUE(dui_usuario),
  fecha_nacimiento_usuario DATE NOT NULL,
  estado_usuario BOOLEAN DEFAULT 1,
  direccion_usuario VARCHAR(200)
);

DELIMITER ;
-- Vista para la tabla usuarios
DROP VIEW IF EXISTS vista_tabla_usuarios;
DELIMITER $$
CREATE VIEW vista_tabla_usuarios AS
SELECT id_usuario AS 'ID',
nombre_usuario AS 'NOMBRE',
correo_electronico_usuario AS 'CORREO',
telefono_usuario AS 'TELÉFONO',
dui_usuario AS 'DUI',
direccion_usuario AS 'DIRECCIÓN',
fecha_nacimiento_usuario AS 'NACIMIENTO',
fecha_registro_usuario AS 'REGISTRO',
    CASE
        WHEN estado_usuario = 1 THEN 'Activo'
        WHEN estado_usuario = 0 THEN 'Bloqueado'
    END AS 'ESTADO',
estado_usuario AS 'VALOR_ESTADO'
FROM tb_usuarios;
$$

DROP PROCEDURE IF EXISTS insertar_usuario;
DELIMITER $$
CREATE PROCEDURE insertar_usuario(
   IN p_nombre_usuario VARCHAR(100),
   IN p_correo_electronico_usuario VARCHAR(100),
   IN p_clave_usuario VARCHAR(100),
   IN p_telefono_usuario VARCHAR(15),
   IN p_dui_usuario VARCHAR(10),
   IN p_direccion_usuario VARCHAR(200),
   IN p_fecha_nacimiento_usuario DATE
)
BEGIN
    DECLARE email_count INT;
    DECLARE dui_count INT;
    DECLARE nombre_count INT;

    -- Validar formato de correo
    IF p_correo_electronico_usuario REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN

        -- Verificar si el correo ya existe
        SELECT COUNT(*) INTO email_count
        FROM tb_usuarios
        WHERE correo_electronico_usuario = p_correo_electronico_usuario;

        -- Verificar si el DUI ya existe
        SELECT COUNT(*) INTO dui_count
        FROM tb_usuarios
        WHERE dui_usuario = p_dui_usuario;
        
        -- Verificar si el nombre de usuario ya existe
        SELECT COUNT(*) INTO nombre_count
        FROM tb_usuarios
        WHERE nombre_usuario = p_nombre_usuario;

        -- Si existe un duplicado de correo, nombre o DUI, generar un error
        IF email_count > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Correo electrónico ya existe';
        ELSEIF dui_count > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'DUI ya existe';
        ELSEIF nombre_count > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nombre de usuario ya existe';
        ELSE
            -- Insertar el nuevo registro
            INSERT INTO tb_usuarios (nombre_usuario, correo_electronico_usuario, clave_usuario, telefono_usuario, dui_usuario, direccion_usuario, fecha_nacimiento_usuario)
            VALUES(p_nombre_usuario, p_correo_electronico_usuario, p_clave_usuario, p_telefono_usuario, p_dui_usuario, p_direccion_usuario, p_fecha_nacimiento_usuario);
        END IF;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Formato de correo electrónico no válido';
    END IF;
END;
$$
DELIMITER ;

DROP PROCEDURE IF EXISTS actualizar_usuario;
DELIMITER $$
CREATE PROCEDURE actualizar_usuario(
   IN p_id_usuario INT,
   IN p_nombre_usuario VARCHAR(100),
   IN p_correo_electronico_usuario VARCHAR(100),
   IN p_telefono_usuario VARCHAR(15),
   IN p_dui_usuario VARCHAR(10),
   IN p_direccion_usuario VARCHAR(200),
   IN p_fecha_nacimiento_usuario DATE,
   IN p_estado_usuario BOOLEAN
)
BEGIN
    DECLARE email_count INT;
    DECLARE dui_count INT;
    DECLARE nombre_count INT;

    -- Validar formato de correo
    IF p_correo_electronico_usuario REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN

        -- Verificar si el correo ya existe para otro usuario
        SELECT COUNT(*) INTO email_count
        FROM tb_usuarios
        WHERE correo_electronico_usuario = p_correo_electronico_usuario
        AND id_usuario <> p_id_usuario;

        -- Verificar si el DUI ya existe para otro usuario
        SELECT COUNT(*) INTO dui_count
        FROM tb_usuarios
        WHERE dui_usuario = p_dui_usuario
        AND id_usuario <> p_id_usuario;

        -- Verificar si el nombre de usuario ya existe para otro usuario
        SELECT COUNT(*) INTO nombre_count
        FROM tb_usuarios
        WHERE nombre_usuario = p_nombre_usuario
        AND id_usuario <> p_id_usuario;
        
        -- Si existe un duplicado de correo, nombre o DUI, generar un error
        IF email_count > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Correo electrónico ya existe';
        ELSEIF dui_count > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'DUI ya existe';
        ELSEIF nombre_count > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nombre de usuario ya existe';
        ELSE
            -- Actualizar el registro del usuario
            UPDATE tb_usuarios SET
                nombre_usuario = p_nombre_usuario,
                correo_electronico_usuario = p_correo_electronico_usuario,
                telefono_usuario = p_telefono_usuario,
                dui_usuario = p_dui_usuario,
                direccion_usuario = p_direccion_usuario,
                fecha_nacimiento_usuario = p_fecha_nacimiento_usuario,
                estado_usuario = p_estado_usuario
            WHERE id_usuario = p_id_usuario;
        END IF;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Formato de correo electrónico no válido';
    END IF;
END;
$$

DELIMITER ;
DROP PROCEDURE IF EXISTS eliminar_usuario;
DELIMITER $$
CREATE PROCEDURE eliminar_usuario(
    IN p_id_usuario INT
)
BEGIN
    DECLARE user_exists INT;

    -- Verificar si el usuario existe
    SELECT COUNT(*) INTO user_exists 
    FROM tb_usuarios 
    WHERE id_usuario = p_id_usuario;

    IF user_exists = 0 THEN
        -- Si no existe, generar un error
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario no existe';
    ELSE
        -- Si existe, proceder a eliminar el usuario
        DELETE FROM tb_usuarios
        WHERE id_usuario = p_id_usuario;
    END IF;
END;
$$
DELIMITER ;



DROP PROCEDURE IF EXISTS actualizar_estado_usuario;
DELIMITER $$
CREATE PROCEDURE actualizar_estado_usuario(
    IN p_id_usuario INT
)
BEGIN
    -- Actualizar el estado del usuario alternando su valor
    UPDATE tb_usuarios
    SET estado_usuario = NOT estado_usuario
    WHERE id_usuario = p_id_usuario;
END;
$$
DELIMITER ;


SELECT * FROM vista_tabla_usuarios;


