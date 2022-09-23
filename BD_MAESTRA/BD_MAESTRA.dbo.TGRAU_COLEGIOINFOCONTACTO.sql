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
Fecha		: 12/02/2018
Responsable	: Reinel José Ochoa
Descripción	: Registro en tabla integradora para pasar a Core
=============================================
Fecha		: 11/11/2020
Responsable	: Miguel Gallardo Medina
Descripción	: Se agrega el campo IDTipo en el insert de ColegioLogAAMO
=============================================
Fecha		: 21/12/2021
Responsable	: Reinel José Ochoa Quintero
Descripción	: Agregar: validaciones de AppAsesor para regional. Ajustar validación de IDGrupoAAMO
=============================================
Fecha		: 25/08/2022
Responsable	: Deicy Rojas Rosas
Descripción	: Se retira envio de informacion a TABLA INTEGRADORA pues la informacion
			  ya no llega a Martes de Prueba
=============================================
*/
CREATE OR ALTER TRIGGER [dbo].[TGRAU_COLEGIOINFOCONTACTO]
   ON [dbo].[ColegioInfoContacto]
   AFTER UPDATE
AS 
BEGIN
SET NOCOUNT ON;

/* VARIABLES */
DECLARE
@ID INT
,@IDColegio INT
,@IDRegional INT
,@IDGrupoAAMO INT
,@MensajeError VARCHAR(250)

/* ASIGNAR VALOR A VARIABLES */
SELECT 
@ID = i.IDColegioContacto
,@IDColegio = i.IDColegio
,@IDRegional = c.IDRegional
,@IDGrupoAAMO = c.IDGrupoAAMO
FROM Inserted i
INNER JOIN BD_MAESTRA.dbo.VW_COLEGIO_CONSULTA c ON c.IDColegio = i.IDColegio

/* REGISTRO EN TABLA INTEGRADORA */
/*IF @IDGrupoAAMO IS NOT NULL
BEGIN
	BEGIN TRY
		INSERT INTO BD_INTEGRACION.dbo.ColegioLogAAMO(IDTipo,IDColegio,IDGrupo)
		SELECT 2,@IDColegio,@IDGrupoAAMO
	END TRY
	BEGIN CATCH
		SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Integración de Colegio a plataforma AAMO errónea. Contacte al Administrador.','$|$');
		RAISERROR(@MensajeError,16,1);
		RETURN;
	END CATCH
END*/

/* REGISTRO EN TABLA INTEGRADORA */
IF(SELECT ISNULL(r.AppAsesor,0) FROM BD_MAESTRA.dbo.VW_REGIONAL_CONSULTA r WHERE r.Cod_Regional = @IDRegional) = 1
BEGIN
	BEGIN TRY
		INSERT INTO BD_INTEGRACION.dbo.ColegioInfoContacto(IDColegio,NombreContacto,TelefonoContacto,EmailContacto,NombreRector,TelefonoRector,EmailRector,
		NombreCoordinador,TelefonoCoordinador,EmailCoordinador,Procesado,Origen)
		SELECT i.IDColegio,i.NombreContacto,i.TelefonoContacto,i.EmailContacto,i.NombreRector,i.TelefonoRector,i.EmailRector,
		i.NombreCoordinador,i.TelefonoCoordinador,i.EmailCoordinador,0,0
		FROM Inserted i 
	END TRY
	BEGIN CATCH
		SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Integración de Colegio a Core errónea. Contacte al Administrador.','$|$')
		RAISERROR(@MensajeError,16,1)
		RETURN
	END CATCH
END

BEGIN TRY
	UPDATE BD_MAESTRA.dbo.ColegioInfoContacto SET ColegioInfoContacto.FechaActualizacion = GETDATE() WHERE ColegioInfoContacto.IDColegioContacto = @ID
END TRY
BEGIN CATCH
	SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Actualización de fecha de actualización errónea. Contacte al Administrador.','$|$')
	RAISERROR(@MensajeError,16,1)
	RETURN
END CATCH

--
END
GO
ALTER TABLE [dbo].[ColegioInfoContacto] ENABLE TRIGGER [TGRAU_COLEGIOINFOCONTACTO]
GO
