SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* 
=============================================
Fecha		: 12/09/2017
Responsable	: Reinel José Ochoa
Descripción	: Actualizar información en plataforma AAMO
Email		: tecnologia@ceinfes.com
=============================================
CONTROL DE CAMBIOS
=============================================
Fecha		: 13/02/2018
Responsable	: Reinel José Ochoa
Descripción	: Registrar en tabla integradora- Core
=============================================
Fecha		: 11/11/2020
Responsable	: Miguel Gallardo Medina
Descripción	: Se agrega el campo IDTipo en el insert de ColegioLogAAMO
=============================================
Fecha		: 04/01/2022
Responsable	: Reinel José Ochoa Quintero
Descripción	: Agregar asignación de fecha de actualización automática y validar registro con asignación principal
=============================================
Fecha		: 25/08/2022
Responsable	: Deicy Rojas Rosas
Descripción	: Se retira el envio de informacion a TABLA INTEGRADORA AAMO
=============================================
*/
CREATE OR ALTER TRIGGER [dbo].[TGRAU_COLEGIOINFOENVIO]
   ON [dbo].[ColegioInfoEnvio]
   AFTER UPDATE
AS 
BEGIN
SET NOCOUNT ON;

/* VARIABLES */
DECLARE
@ID INT
,@IDOld INT
,@IDColegio INT
,@IDRegional INT
,@Principal BIT
,@IDGrupoAAMO INT
,@MensajeError VARCHAR(250)

/* ASIGNAR VALOR A VARIABLES */
SELECT
@ID = i.IDColegioEnvio
,@IDColegio = i.IDColegio
,@IDRegional = c.IDRegional
,@Principal = i.Principal
,@IDGrupoAAMO = c.IDGrupoAAMO
FROM Inserted i
INNER JOIN BD_MAESTRA.dbo.VW_COLEGIO_CONSULTA c ON c.IDColegio = i.IDColegio

SELECT
@IDOld = d.IDColegioEnvio
FROM Deleted d

/* VALIDAR EXISTA REGISTRO ACTIVO 
IF EXISTS(SELECT cie.IDColegio FROM BD_MAESTRA.dbo.VW_COLEGIOINFOENVIO_CONSULTA cie WHERE cie.IDColegio = @IDColegio AND cie.Principal = 1 AND cie.IDColegioEnvio <> @IDOld)
BEGIN
	SET @MensajeError = CONCAT('$|$USER_MSG$|$ADVERTENCIA$|$','Ya existe un dato marcado como principal. Inactiva el registro marcado como principal e intenta nuevamente.','$|$')
	RAISERROR(@MensajeError,16,1)
	RETURN
END*/

/* REGISTRO TABLA INTEGRADORA - AAMO */
/*IF @IDGrupoAAMO IS NOT NULL
BEGIN
	BEGIN TRY
		INSERT INTO BD_INTEGRACION.dbo.ColegioLogAAMO (IDTipo,IDColegio,IDGrupo)
		SELECT 2, c.IDColegio,c.IDGrupoAAMO 
		FROM BD_MAESTRA.dbo.Colegio c
		WHERE c.IDColegio = @IDColegio
	END TRY
	BEGIN CATCH
		SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Integración de Colegio a plataforma AAMO errónea. Contacte al Administrador.','$|$')
		RAISERROR(@MensajeError,16,1)
		RETURN
	END CATCH
END*/

/* REGISTRO EN TABLA INTEGRADORA PARA CORE*/
IF(SELECT ISNULL(r.AppAsesor,0) FROM BD_MAESTRA.dbo.VW_REGIONAL_CONSULTA r WHERE r.Cod_Regional = @IDRegional) = 1
BEGIN
	BEGIN TRY
		INSERT INTO BD_INTEGRACION.dbo.ColegioInfoEnvio(IDColegio,Destinatario,Telefono,Email,Direccion,IDDepartamento,IDCiudad,IDTransportadora,Procesado,Origen)
		SELECT i.IDColegio,i.Destinatario,i.Telefono,i.Email,i.Direccion,i.IDDepartamento,i.IDCiudad,i.IDTransportadora,0,0
		FROM Inserted i 
	END TRY
	BEGIN CATCH
		SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Integración de Colegio a Core errónea. Contacta al Administrador.','$|$')
		RAISERROR(@MensajeError,16,1)
		RETURN
	END CATCH
END

BEGIN TRY
	UPDATE BD_MAESTRA.dbo.ColegioInfoEnvio SET ColegioInfoEnvio.FechaActualizacion = GETDATE() WHERE ColegioInfoEnvio.IDColegioEnvio = @ID
END TRY
BEGIN CATCH
	SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Actualización de fecha de actualización errónea. Contacte al Administrador.','$|$')
	RAISERROR(@MensajeError,16,1)
	RETURN
END CATCH

--
END
GO
ALTER TABLE [dbo].[ColegioInfoEnvio] ENABLE TRIGGER [TGRAU_COLEGIOINFOENVIO]
GO
