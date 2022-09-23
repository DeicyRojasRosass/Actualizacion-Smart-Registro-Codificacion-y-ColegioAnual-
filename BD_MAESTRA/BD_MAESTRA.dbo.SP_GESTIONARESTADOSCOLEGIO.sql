SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* 
=============================================
Fecha		: 14/09/2017
Responsable	: Reinel José Ochoa
Descripción	: Gestionar estados colegio
Email		: tecnologia@ceinfes.com
=============================================
CONTROL DE CAMBIOS
=============================================
Fecha		: 24/10/2017
Responsable	: Miguel Gallardo Medina
Descripción	: Se valida si el colegio ya tiene userid para crearlo en Factory
=============================================
Responsable	: Miguel Gallardo Medina
Fecha		: 19/06/2018
Descripción	: Se ajusta el proceso del estado 4 para que registre una tarea, y se crea instruccion para el estado "Bloque Despacho"
			  28/02/2020: Se agrega instrucción para activar o inactivar en BD_FACTORY
			  01/09/2020: Se agrega restriccion para validar si ya existe un colegio con los mismo datos en la regional
			  04/11/2020: Se agregan instrucciones para la codificacion colegios desde SMART, la activación del año y el registro en la tabla integradora
			  21/08/2021: Se ajustan instrucciones para validar si existe el IDGrupoAAMO y el ColegioAnual
=============================================
Responsable	: Deicy Rojas Rosas - Carlos Cardenas
Fecha		: 22/08/2022
Descripción	: Se Retira el envio de informacion a Integracion.ColegioLogAAMO 
			  06-09-2022 EL BACKOFFICE REGISTRA DIRECTAMENTE EL COLEGIO ANUAL PARA NO REALIZAR ESTA  VALIDACION EN LA CODIFICACION
				
=============================================
*/
CREATE OR ALTER PROCEDURE [dbo].[SP_GestionarEstadosColegio] 
	@IDColegio INT,
	@IDEstado INT
AS
BEGIN
SET NOCOUNT,xact_abort ON;

/* Declaración de Variables */
DECLARE 
@Nombre VARCHAR(150),
@IDRegional INT,
@IDCalendario INT,
@IDCiudad INT,
@CodigoAAMO INT,
@IDGrupoAAMO INT,
@IDUsuarioActualiza INT,
/* Valriables para codificar*/
@Inicio INT, 
@Fin INT,
@NuevoCodigo INT,
@Clave INT,
/* Variables para Creacion de Usuario */
@NombreUsuario VARCHAR(250),
@UserName VARCHAR(256),
@Password VARCHAR(128),
@Email VARCHAR(100),
@UserId VARCHAR(50),
@IDGrupo INT,
/* Variable para mostrar mensaje de error */
@MensajeError VARCHAR(500);

/* Asignar Valores a Variable */
SELECT 
	@Nombre = c.Nombre, 
	@IDRegional = c.IDRegional, 
	@IDCalendario = c.IDCalendario,
	@IDCiudad = c.IDCiudad,
	@CodigoAAMO = c.CodigoAAMO,
	@IDGrupoAAMO = c.IDGrupoAAMO,
	@IDUsuarioActualiza = c.IDUsuarioActualiza,
	
	@NombreUsuario = c.Nombre,
	@UserName = c.CodigoAAMO,
	@Password = c.Clave,
	@Email = c.Email,
	@UserId = c.UserId
FROM BD_MAESTRA.dbo.Colegio c 
WHERE c.IDColegio = @IDColegio

--=============================================
/* Estado Activo */
--=============================================
IF (@IDEstado = 1) OR (@IDEstado = 7) --AND EXISTS(SELECT c.IDColegio FROM BD_MAESTRA.dbo.Colegio c WHERE c.IDColegio = @IDColegio AND c.UserId IS NULL)
BEGIN		
	/* CODIFICAR COLEGIO */
	IF @CodigoAAMO IS NULL
	BEGIN
		/* VALIDAR SI EXISTE OTRO COLEGIO */
		/*IF EXISTS(SELECT c.IDColegio FROM BD_MAESTRA.dbo.VW_COLEGIO_CONSULTA AS c WHERE c.Nombre = @Nombre AND c.IDRegional = @IDRegional AND c.IDCalendario = @IDCalendario AND c.IDCiudad = @IDCiudad AND c.IDColegio <> @IDColegio)
		BEGIN
			SET @MensajeError = CONCAT('$|$USER_MSG$|$ADVERTENCIA$|$','No es posible continuar ya existe un colegio con el mismo nombre y ciudad para la regional. Verifique los datos e intente nuevamente.','$|$')
			RAISERROR(@MensajeError,16,1)
			RETURN
		END*/

		/* VALIDAR INFORMACIÓN DE CONTACTO */
		/*IF (SELECT CASE
				WHEN cic.NombreContacto IS NULL THEN 1 
				WHEN cic.TelefonoContacto IS NULL THEN 1 
				WHEN cic.EmailContacto IS NULL THEN 1 
				WHEN cic.NombreRector IS NULL THEN 1 
				WHEN cic.TelefonoRector IS NULL THEN 1 
				ELSE 0 END Respuesta 
				FROM BD_MAESTRA.dbo.VW_COLEGIOINFOCONTACTO_CONSULTA AS cic WHERE cic.IDColegio = @IDColegio AND cic.Activo = 1) = 1
		BEGIN
			SET @MensajeError = CONCAT('$|$USER_MSG$|$ADVERTENCIA$|$','Información de contacto faltante. Verifique los datos e intente nuevamente.','$|$')
			RAISERROR(@MensajeError,16,1)
			RETURN
		END*/

		/* VALIDAR INFORMACIÓN DE FACTURACIÓN */
	/*	IF (SELECT CASE
				WHEN cif.RazonSocial IS NULL THEN 1 
				WHEN cif.Responsable IS NULL THEN 1 
				WHEN cif.IDTipoIdentificacion IS NULL THEN 1 
				WHEN cif.NoIdentificacion IS NULL THEN 1 
				WHEN cif.Telefono IS NULL THEN 1 
				WHEN cif.Email IS NULL THEN 1
				WHEN cif.Direccion IS NULL THEN 1 
				WHEN cif.IDDepartamento IS NULL THEN 1 
				WHEN cif.IDCiudad IS NULL THEN 1
				ELSE 0 END Respuesta FROM BD_MAESTRA.dbo.VW_COLEGIOINFOFACTURA_CONSULTA AS cif WHERE cif.IDColegio = @IDColegio AND cif.Activo = 1 ) = 1
		BEGIN
			SET @MensajeError = CONCAT('$|$USER_MSG$|$ADVERTENCIA$|$','Información de facturación faltante. Verifique los datos e intente nuevamente.','$|$')
			RAISERROR(@MensajeError,16,1)
			RETURN
		END*/

		/* VALIDAR INFORMACIÓN DE ENVÍO */
	/*IF (SELECT CASE
				WHEN cie.Destinatario IS NULL THEN 1 
				WHEN cie.Telefono IS NULL THEN 1 
				WHEN cie.Direccion IS NULL THEN 1 
				WHEN cie.IDDepartamento IS NULL THEN 1
				WHEN cie.IDCiudad IS NULL THEN 1 
				WHEN cie.IDTransportadora IS NULL THEN 1 
				ELSE 0 END Respuesta FROM BD_MAESTRA.dbo.VW_COLEGIOINFOENVIO_CONSULTA cie WHERE cie.IDColegio = @IDColegio AND cie.Activo = 1 AND cie.Principal = 1) = 1
		BEGIN
			SET @MensajeError = CONCAT('$|$USER_MSG$|$ADVERTENCIA$|$','Información de envío faltante. Verifique los datos e intente nuevamente.','$|$');
			RAISERROR(@MensajeError,16,1);
			RETURN
		END*/

		/* OBTENER VALORES DE REGIONALCODIGO */
		SELECT 
			@Inicio = r.inicio,
			@Fin = r.Fin,
			@NuevoCodigo = ISNULL(r.UltimoCodigo + 1,r.Inicio),
			@Clave = ((ISNULL(r.UltimoCodigo + 1,r.Inicio)+1000) * 2) + RIGHT(YEAR(GETDATE()),2)
		FROM BD_MAESTRA.dbo.RegionalCodigo r
		WHERE r.IDRegional = @IdRegional 
		AND r.Activo=1;
		
		/* VALIDAR CODIGOS DISPONIBLES */
	/*	IF NOT EXISTS(SELECT r.ID FROM BD_MAESTRA.dbo.RegionalCodigo r WHERE r.IDRegional = @IdRegional AND r.Activo = 1) OR (@NuevoCodigo > @Fin)
		BEGIN
			SET @MensajeError = CONCAT('$|$USER_MSG$|$ADVERTENCIA$|$','No es posible continuar, la regional no tiene códigos disponibles. Contacte al administrador.','$|$');
			RAISERROR(@MensajeError,16,1);
			RETURN
		END*/
		
		/* VALIDAR SI EL CODIGO YA ESTA ASIGNADO */
		/*IF EXISTS(SELECT c.IDColegio FROM BD_MAESTRA.dbo.VW_COLEGIO_CONSULTA c WHERE c.CodigoAAMO = @NuevoCodigo)
		BEGIN
			SET @MensajeError = CONCAT('$|$USER_MSG$|$ADVERTENCIA$|$','No es posible continuar, el código ya está asignado. Contacte al administrador.','$|$');
			RAISERROR(@MensajeError,16,1);
			RETURN
		END*/
		
		/* ASIGNAR CODIGO Y CLAVE */
		BEGIN TRY
			UPDATE BD_MAESTRA.dbo.Colegio 
			SET Colegio.CodigoAAMO = @NuevoCodigo, 
				Colegio.Clave = @Clave
			WHERE Colegio.IDColegio = @IDColegio;
		END TRY
		BEGIN CATCH
			SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Asignación de código a Colegio erróneo. Contacte al Administrador','$|$');
			RAISERROR(@MensajeError,16,1);
			ROLLBACK;
		END CATCH
		
		/* ACTUALIZAR REGIONALCODIGO */
		BEGIN TRY
			UPDATE BD_MAESTRA.dbo.RegionalCodigo 
			SET RegionalCodigo.Asignado = RegionalCodigo.Asignado+1, --(SELECT COUNT(c.IDColegio) FROM BD_MAESTRA.dbo.Colegio c WHERE /*c.IDRegional = RegionalCodigo.IDRegional AND*/ CodigoAAMO BETWEEN RegionalCodigo.Inicio AND RegionalCodigo.Fin),
				RegionalCodigo.UltimoCodigo = @NuevoCodigo
			WHERE RegionalCodigo.IDRegional = @IDRegional
			AND RegionalCodigo.Activo = 1;
		END TRY
		BEGIN CATCH
			SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Actualización de código en RegionalCodigo erróneo. Contacte al Administrador','$|$');
			RAISERROR(@MensajeError,16,1);
			ROLLBACK;
		END CATCH
	END

	/* REGISTRAR EN MARTES DE PRUEBA GRUPO */
	IF @IDGrupoAAMO IS NULL AND NOT EXISTS(SELECT M.IDColegio FROM BD_MARTESDEPRUEBA.dbo.Grupo M WHERE M.IDColegio = @IDColegio)
	BEGIN
		BEGIN TRY
			INSERT INTO BD_MARTESDEPRUEBA.dbo.Grupo(IDColegio,Codigo,Clave,IDGrupoEducativo,Cod_Regional,Nombre,Calendario,Direccion,Nit,Telefonos,Correo,Dane,IDCiudad,AppComunicacion)
				SELECT
				c.IDColegio,
				c.CodigoAAMO,
				c.Clave,
				(SELECT g.CodigoAAMO FROM BD_MAESTRA.dbo.GrupoEducativo g WHERE g.ID = c.IDGrupoEducativo) GrupoEducativo,
				(SELECT r.Cod_AAMO FROM BD_MAESTRA.dbo.Regional r WHERE r.Cod_Regional = c.IDRegional) Regional,
				SUBSTRING(UPPER(c.Nombre),1,150) Nombre,
				(SELECT cal.CodigoAAMO FROM BD_MAESTRA.dbo.Calendario cal WHERE cal.IDCalendario = c.IDCalendario) Calendario,
				SUBSTRING(c.Direccion,1,200),
				SUBSTRING(c.Nit,1,15),
				SUBSTRING(c.Telefono,1,50),
				SUBSTRING(c.Email,1,100),
				SUBSTRING(c.Dane,1,20),
				(SELECT ci.CodigoAAMO FROM BD_MAESTRA.dbo.Ciudad ci WHERE ci.IDCiudad = c.IDCiudad) Ciudad,
				c.AppComunicacion
				FROM dbo.VW_COLEGIO_CONSULTA c
				WHERE c.IDColegio = @IDColegio;

				/*OBTENER IDGRUPOAAMO*/
				SELECT @IDGrupo=MAX(IdGrupo) FROM BD_MARTESDEPRUEBA.dbo.Grupo
				/*ACTUALIZAR GRUPOAMMO EN COLEGIO*/
				UPDATE BD_MAESTRA.dbo.Colegio SET IDGrupoAAMO=@IDGrupo WHERE IDColegio = @IDColegio;
		END TRY
		BEGIN CATCH
			SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Registro en tabla AAMO erróneo. Contacte al Administrador.','$|$');
			RAISERROR(@MensajeError,16,1);
			RETURN;
		END CATCH
	END
	

	/* ACTIVAR AÑO EN COLEGIOANUAL */
	/*EL BACKOFFICE REGISTRA DIRECTAMENTE EL COLEGIO ANUAL PARA NO REALIZAR ESTA  VALIDACION EN LA CODIFICACION*/
	/*IF NOT EXISTS(SELECT c.ID FROM BD_MAESTRA.dbo.VW_COLEGIOANUAL_CONSULTA c WHERE c.IDColegio = @IDColegio)
	BEGIN
		BEGIN TRY
			INSERT INTO BD_MAESTRA.dbo.ColegioAnual(IDColegio,IDCalendario,Anno,IDEstado,IDUsuarioRegistra)
			SELECT @IDColegio, BD_MAESTRA.dbo.FN_IDCALENDARIO_COLEGIO(@IDColegio), BD_MAESTRA.dbo.FN_ANNO_COLEGIO(@IDColegio), 2, @IDUsuarioActualiza
		END TRY
		BEGIN CATCH
			SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Activación del año erróneo. Contacte al Administrador.',ERROR_MESSAGE(),'$|$');
			RAISERROR(@MensajeError,16,1);
			RETURN;
		END CATCH
	END*/

	/* REGISTRAR EN FACTORY SUITE Y OBTENER USUARIO */
	IF (@UserName IS NOT NULL) AND (@Password IS NOT NULL) AND (@UserId IS NULL)
	BEGIN
		BEGIN TRY
			/* Crear Usuario */
			EXEC BD_CEINFES.dbo.SP_CrearUsuario '/Frontal',@NombreUsuario,'COL',@UserName,@Password,@Email,0,0,'Colegio','12/12/2099',@UserId OUTPUT;
		
			/* Asignar UserID */
			UPDATE BD_MAESTRA.dbo.Colegio SET UserId = @UserId WHERE IDColegio = @IDColegio;
		END TRY
		BEGIN CATCH
			SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Creación de Usuario a Colegio erróneo. Contacte al Administrador','$|$');
			RAISERROR(@MensajeError,16,1);
			ROLLBACK;
		END CATCH
	END
	ELSE BEGIN
		/* ACTIVAR EN MEMBERSHIP */
		UPDATE BD_FACTORYSUITE.DBO.VW_ASPNET_MEMBERSHIP SET IsApproved = 1
		WHERE UserId = @UserId
	END

	
	/* 11/03/2019: Poner Activo en  1, dato que aplica para sincronizacion de la table */
	UPDATE BD_MAESTRA.dbo.Colegio 
	SET Colegio.Activo = 1, 
		Colegio.FechaActualizacion = GETDATE() 
	WHERE Colegio.IDColegio = @IDColegio;

	/* Notificar Director Comercial (DCO) y Coordinador Comercial (CCOM) */
	EXEC SP_NotificacionEstadoColegio @IDColegio,@IDEstado
END

--=============================================
/* Estado Inactivo */
--=============================================
IF (@IDEstado = 2)
BEGIN
	/* Notificar Director Comercial (DCO) y Coordinador Comercial (CCOM) */
	BEGIN TRY
		/* INACTIVAR EN MEMBERSHIP */
		UPDATE BD_FACTORYSUITE.DBO.VW_ASPNET_MEMBERSHIP SET IsApproved = 0
		WHERE UserId = (SELECT c.UserId FROM BD_MAESTRA.dbo.VW_COLEGIO_CONSULTA c WHERE c.IDColegio = @IDColegio);

		EXEC BD_MAESTRA.dbo.SP_NotificacionEstadoColegio @IDColegio,@IDEstado
	END TRY
	BEGIN CATCH
		SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Notificación de cambio de estado Inactivo erróneo. Contacte al Administrador','$|$');
		RAISERROR(@MensajeError,16,1);
		RETURN
	END CATCH
END

--=============================================
/* Estado Pasar A Codificar */
--=============================================
IF (@IDEstado = 4)
BEGIN
	/* VALIDAR SI EXISTE OTRO COLEGIO */
	IF EXISTS(SELECT c.IDColegio FROM BD_MAESTRA.dbo.Colegio c WHERE c.Nombre = @Nombre AND c.IDRegional = @IDRegional AND c.IDCalendario = @IDCalendario AND c.IDCiudad = @IDCiudad AND c.IDColegio <> @IDColegio)
	BEGIN
		SET @MensajeError = CONCAT('$|$USER_MSG$|$ADVERTENCIA$|$','No es posible continuar ya existe un colegio con el mismo nombre y ciudad para la regional. Verifique los datos e intente nuevamente.','$|$')
		RAISERROR(@MensajeError,16,1)
		RETURN
	END

	/* VALIDAR INFORMACIÓN DE CONTACTO */
	IF (SELECT CASE
			WHEN cic.NombreContacto IS NULL THEN 1 
			WHEN cic.TelefonoContacto IS NULL THEN 1 
			WHEN cic.EmailContacto IS NULL THEN 1 
			WHEN cic.NombreRector IS NULL THEN 1 
			WHEN cic.TelefonoRector IS NULL THEN 1 
			ELSE 0 END Respuesta 
			FROM BD_MAESTRA.dbo.ColegioInfoContacto cic WHERE cic.IDColegio = @IDColegio AND cic.Activo = 1) = 1
	BEGIN
		SET @MensajeError = CONCAT('$|$USER_MSG$|$ADVERTENCIA$|$','Información de contacto faltante. Verifique los datos e intente nuevamente.','$|$')
		RAISERROR(@MensajeError,16,1)
		RETURN
	END

	/* VALIDAR INFORMACIÓN DE FACTURACIÓN */
	IF (SELECT CASE
			WHEN cif.RazonSocial IS NULL THEN 1 
			WHEN cif.Responsable IS NULL THEN 1 
			WHEN cif.IDTipoIdentificacion IS NULL THEN 1 
			WHEN cif.NoIdentificacion IS NULL THEN 1 
			WHEN cif.Telefono IS NULL THEN 1 
			WHEN cif.Email IS NULL THEN 1
			WHEN cif.Direccion IS NULL THEN 1 
			WHEN cif.IDDepartamento IS NULL THEN 1 
			WHEN cif.IDCiudad IS NULL THEN 1
			ELSE 0 END Respuesta FROM ColegioInfoFactura cif WHERE cif.IDColegio = @IDColegio) = 1
	BEGIN
		SET @MensajeError = CONCAT('$|$USER_MSG$|$ADVERTENCIA$|$','Información de facturación faltante. Verifique los datos e intente nuevamente.','$|$')
		RAISERROR(@MensajeError,16,1)
		RETURN
	END

	/* VALIDAR INFORMACIÓN DE ENVÍO */
	IF (SELECT TOP 1 CASE
			WHEN cie.Destinatario IS NULL THEN 1 
			WHEN cie.Telefono IS NULL THEN 1 
			WHEN cie.Direccion IS NULL THEN 1 
			WHEN cie.IDDepartamento IS NULL THEN 1
			WHEN cie.IDCiudad IS NULL THEN 1 
			WHEN cie.IDTransportadora IS NULL THEN 1 
			ELSE 0 END Respuesta FROM ColegioInfoEnvio cie WHERE cie.IDColegio = @IDColegio) = 1
	BEGIN
		SET @MensajeError = CONCAT('$|$USER_MSG$|$ADVERTENCIA$|$','Información de envío faltante. Verifique los datos e intente nuevamente.','$|$');
		RAISERROR(@MensajeError,16,1);
		RETURN
	END
END

--=============================================
/* Estado Bloqueo Despacho */
--=============================================
IF (@IDEstado = 8)
BEGIN
	/* Notificar Director Comercial (DCO), Coordinador Comercial (CCOM), Fidelizador y al colegio */
	BEGIN TRY
		EXEC BD_MAESTRA.dbo.SP_NotificacionEstadoColegio @IDColegio,@IDEstado
	END TRY
	BEGIN CATCH
		SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Notificación de Bloqueo Despacho erróneo. Contacte al Administrador', ERROR_MESSAGE(),'$|$');
		RAISERROR(@MensajeError,16,1);
		RETURN
	END CATCH
END

--
END
GO
