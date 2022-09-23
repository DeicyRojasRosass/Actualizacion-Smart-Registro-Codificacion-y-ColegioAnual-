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
Fecha		: 14/03/2019
Responsable	: Reinel José Ochoa
Descripción	: elimina registro en tabla integradora. Se realiza a través de procedimiento almacenado
=============================================
Fecha		: 11/11/2020
Responsable	: Miguel Gallardo Medina
Descripción	: Se agrega el campo IDTipo en el insert de ColegioLogAAMO
=============================================
Fecha		: 25/08/2022
Responsable	: Deicy Rojas Rosas
Descripción	: Se retira el envio de informacion a TABLA INTEGRADORA AAMO
=============================================
*/
CREATE OR ALTER TRIGGER [dbo].[TGRAI_COLEGIOINFOENVIO]
   ON [dbo].[ColegioInfoEnvio]
   AFTER INSERT
AS 
BEGIN
SET NOCOUNT,XACT_ABORT ON

/* VARIABLES */
DECLARE 
@IDColegio INT
,@IDRegional INT
,@IDGrupoAAMO INT
,@MensajeError VARCHAR(250)

/* ASIGNACIÓN DE VALOR A VARIABLES */
SELECT
@IDColegio = i.IDColegio
,@IDRegional = c.IDRegional
,@IDGrupoAAMO = c.IDGrupoAAMO
FROM Inserted i
INNER JOIN BD_MAESTRA.dbo.VW_COLEGIO_CONSULTA AS c ON c.IDColegio = i.IDColegio

/* REGISTRO TABLA INTEGRADORA AAMO */
/*IF @IDGrupoAAMO IS NOT NULL
BEGIN
	BEGIN TRY
		INSERT INTO BD_INTEGRACION.dbo.ColegioLogAAMO (IDTipo,IDColegio,IDGrupo)
		SELECT 2,i.IDColegio,c.IDGrupoAAMO
		FROM Inserted i 
		INNER JOIN BD_MAESTRA.dbo.Colegio c ON c.IDColegio = i.IDColegio
	END TRY
	BEGIN CATCH
		SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Integración de Colegio a plataforma AAMO errónea. Contacte al Administrador.','$|$')
		RAISERROR(@MensajeError,16,1)
		RETURN
	END CATCH
END*/

/* REGISTRO EN TABLA INTEGRADORA CORE */
IF(SELECT ISNULL(r.AppAsesor,0) FROM BD_MAESTRA.dbo.VW_REGIONAL_CONSULTA r WHERE r.Cod_Regional = @IDRegional) = 1
BEGIN
	BEGIN TRY
		INSERT INTO BD_INTEGRACION.dbo.ColegioInfoEnvio(IDColegio,Destinatario,Telefono,Email,Direccion,IDDepartamento,IDCiudad,IDLocalidad,IDTransportadora,Observacion,Procesado,Origen)
		SELECT i.IDColegio,i.Destinatario,i.Telefono,i.Email,i.Direccion,i.IDDepartamento,i.IDCiudad,i.IDLocalidad,i.IDTransportadora,i.Observacion,0,0
		FROM Inserted i 
	END TRY
	BEGIN CATCH
		SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Integración de Colegio a Core errónea. Contacte al Administrador.','$|$')
		RAISERROR(@MensajeError,16,1)
		RETURN
	END CATCH
END

--
END
GO
ALTER TABLE [dbo].[ColegioInfoEnvio] ENABLE TRIGGER [TGRAI_COLEGIOINFOENVIO]
GO
