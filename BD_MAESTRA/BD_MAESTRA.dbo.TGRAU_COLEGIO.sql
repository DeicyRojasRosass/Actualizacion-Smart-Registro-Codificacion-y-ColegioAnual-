SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* 
=============================================
Fecha		: 13/09/2017
Responsable	: Reinel José Ochoa
Descripción	: Gestionar estados de Colegio
Email		: tecnologia@ceinfes.com
=============================================
CONTROL DE CAMBIOS
=============================================
Fecha		: 24/05/2017
Responsable	: Reinel Ochoa
Descripción	: Actualizar clave en BD_FACTORYSUITE
=============================================
Fecha		: 25/09/2017
Responsable	: Miguel Gallardo Medina
Descripción	: Validar estado para crear usuario en Factory
=============================================
Fecha		: 03/10/2017
Responsable	: Reinel José Ochoa
Descripción	: Paso de creación de usuario al Procedimiento de Gestión de Estados de Colegio
=============================================
Fecha		: 05/12/2017: 
Responsable	: Miguel Gallardo
Descripción	: Actualizar información en la BD de AAMO 
=============================================
Fecha		: 17/05/2018
Responsable	: Reinel José Ochoa
Descripción	: Agrega columna de AppComunicacion para que una vez ocurra un cambio de valor se realice la integración a AAMO
=============================================
Fecha		: 13/02/2020
Responsable	: Miguel Gallardo Medina
Descripción	: Registrar colegio en BD_INSTEGRACION
			  04/11/2020: Se agrega el campo IdTipo en el insert de ColegioLogAAMO
			  10/04/2021: se valida que no exista un colegio con datos similares (nombre, calendario, ciudad y estado)
=============================================
Fecha		: 25/08/2022
Responsable	: Deicy Rojas 
Descripción	: se retira validacion de existe colegio con nombre regional calendario ciudad 
				se retira validaciones de codigo regional 
				se registran los campos de Dane,IDNaturaleza,Telefono,Direccion
				se agrega actualizacion directa a la tabla de Grupo
				05-09-2022 se agraga actualizacion a ColegioAnbual para el cambio de calendario.
=============================================
*/
CREATE OR ALTER  TRIGGER [dbo].[TGRAU_COLEGIO]
   ON [dbo].[Colegio]
   AFTER UPDATE
AS 
BEGIN
SET NOCOUNT,XACT_abort ON;

/* VARIABLES */
DECLARE 
@IDColegio INT,
@IDEstado INT,
@IdRegional INT,
@Nombre VARCHAR (150),
@IDCalendario INT,
@Dane VARCHAR(15),
@IDNaturaleza INT,
@Direccion VARCHAR(15),
@IDCiudad INT,
@Email VARCHAR(100),
@IDGrupoAAMO INT,
@CodigoAAMO INT,
@UserName VARCHAR(20),
@UserId UNIQUEIDENTIFIER,
@MensajeError VARCHAR(1000),
@Nit VARCHAR(15),
@Telefono VARCHAR(30)



/* Asignar Valores a Variables */
SELECT	 
	@IDColegio = i.IDColegio,
	@IDEstado = i.IDEstado,
	@IdRegional = i.IdRegional,
	@Nombre = i.Nombre,
	@IDCalendario = i.IDCalendario,
	@Dane = i.Dane,
	@IDNaturaleza = i.IDNaturaleza,
	@Direccion = i.Direccion,
	@IDCiudad = i.IDCiudad,
	@Email = i.Email,
	@UserName = i.CodigoAAMO,
	@UserId = i.UserId,
	@IDGrupoAAMO = i.IDGrupoAAMO,
	@CodigoAAMO = i.CodigoAAMO,
    @Nit = i.Nit,
    @Telefono = i.Telefono
FROM Inserted i;


/* VALIDAR SI EXISTE OTRO COLEGIO CON EL MISMO NOMBRE */
/*IF EXISTS(SELECT c.IDColegio FROM BD_MAESTRA.dbo.Colegio c WHERE c.Nombre = @Nombre AND c.IDRegional = @IDRegional AND c.IDCalendario = @IDCalendario AND c.IDCiudad = @IDCiudad AND c.IDEstado = @IDEstado AND c.IDColegio <> @IDColegio)
BEGIN
	SET @MensajeError = CONCAT('$|$USER_MSG$|$ADVERTENCIA$|$','No es posible continuar ya existe un colegio con el mismo nombre y ciudad para la regional. Verifique los datos e intente nuevamente.','$|$')
	RAISERROR(@MensajeError,16,1)
	RETURN
END
*/
-- =============================================
IF UPDATE (IDEstado)
BEGIN
	BEGIN TRY
		EXEC BD_MAESTRA.dbo.SP_GestionarEstadosColegio @IDColegio,@IDEstado
	END TRY
	BEGIN CATCH
		SET @MensajeError = CONCAT('RJOQ',ERROR_MESSAGE());
		RAISERROR(@MensajeError,16,1);
		RETURN;
	END CATCH
END

-- =============================================
/* 05/12/2017: ACTUALIZAR INFORMACIÓN EN LA BD DE AAMO */
-- =============================================
IF (UPDATE (Nombre) OR UPDATE(IDCalendario) OR UPDATE(DANE) OR UPDATE(IDNaturaleza) OR UPDATE(Direccion) OR UPDATE(Telefono) OR UPDATE(Email) OR UPDATE(NIT) OR UPDATE(AppComunicacion)) 
	AND EXISTS(SELECT d.IDColegio FROM deleted d WHERE d.IDColegio = @IDColegio AND d.IDGrupoAAMO IS NOT NULL)
BEGIN
	BEGIN TRY
		/*INSERT INTO BD_INTEGRACION.dbo.ColegioLogAAMO (IDTipo, IDColegio, IDGrupo, Procesado)
		SELECT 2, d.IDColegio, d.IDGrupoAAMO, 0 FROM Deleted d WHERE d.IDGrupoAAMO IS NOT NULL*/

		/*ACTUALIZACION DIRECTA A LA TABLA GRUPO PARA NO PASAR POR INTEGRADORA*/
		UPDATE BD_MARTESDEPRUEBA.dbo.GRUPO SET Nombre=@Nombre,Calendario=(SELECT cal.CodigoAAMO FROM dbo.VW_CALENDARIO_CONSULTA cal WHERE cal.IDCalendario = @IDCalendario),Direccion=@Direccion,Nit=@Nit,Telefonos=@Telefono,correo=@Email,Naturaleza=@IDNaturaleza WHERE idColegio=@IDColegio 

	END TRY
	BEGIN CATCH
		SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Colegio: registro en tabla Grupo errónea. Contacte al Administrador.','$|$');
		RAISERROR(@MensajeError,16,1);
		RETURN;
	END CATCH
END

-- =============================================
/* 05-09-2022: ACTUALIZAR CALENDARIO EN COLEGIOANUAL */
-- =============================================
IF UPDATE (IDCalendario)
BEGIN
	BEGIN TRY
		UPDATE BD_MAESTRA.dbo.ColegioAnual SET IDCalendario=@IDCalendario WHERE idColegio=@IDColegio 
	END TRY
	BEGIN CATCH
		SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$',error_message(),'Colegio: actualización de CALENDARIO erróneo. Contacte al Administrador.','$|$')
		;THROW
		RAISERROR(@MensajeError,16,1)
		RETURN
	END CATCH
END



-- =============================================
/* 24/05/2017: ACTUALIZAR CLAVE EN BD_FACTORYSUITE */
-- =============================================
IF UPDATE (Clave)
BEGIN
	BEGIN TRY
		EXEC BD_MAESTRA.dbo.SP_ActualizarClaveColegio @IDColegio
	END TRY
	BEGIN CATCH
		SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$',error_message(),'Colegio: actualización de clave erróneo. Contacte al Administrador.','$|$')
		;THROW
		RAISERROR(@MensajeError,16,1)
		RETURN
	END CATCH
END

-- =============================================
/* 28/02/2020: ACTUALIZAR NOMBRE Y CORREO EN BD_FACTORYSUITE */
-- =============================================
IF UPDATE(Nombre) OR UPDATE(Email)
BEGIN
	BEGIN TRY
		/* ACTUALIZAR EL NOMBRE EN USERS */
		UPDATE BD_FACTORYSUITE.dbo.Vw_Aspnet_Users 
		SET UserName = @UserName, 
			LoweredUserName = @UserName , 
			NombreUsuario = @Nombre
		WHERE UserId = @UserId;

		/* ACTUALIZAR EL EMAIL EN EL MEMBERSHIP */
		UPDATE BD_FACTORYSUITE.dbo.Vw_Aspnet_Membership SET Email = @Email,LoweredEmail = @Email WHERE UserId = @UserId;
	END TRY
	BEGIN CATCH
		SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Actualización de nombre y correo erróneo. ',ERROR_MESSAGE(),' Contacte al Administrador','$|$');
		;THROW
		RAISERROR(@MensajeError,16,1)
		RETURN
	END CATCH
END

-- =============================================
/* 13/02/2020: REGISTRAR BD INTEGRACIÓN */
-- =============================================
BEGIN TRY
	IF (SELECT r.AppAsesor FROM BD_MAESTRA.dbo.Regional r WHERE r.Cod_Regional = @IDRegional) = 1
	BEGIN
		EXEC BD_MAESTRA.dbo.SP_Registrar_ColegioSMARTCORE @IDColegio
	END
END TRY
BEGIN CATCH
	SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Registro de integración de colegio erróneo. Contacte al Administrador.','$|$')
	RAISERROR(@MensajeError,16,1)
	RETURN
END CATCH

--
END
GO
ALTER TABLE [dbo].[Colegio] ENABLE TRIGGER [TGRAU_COLEGIO]
GO
