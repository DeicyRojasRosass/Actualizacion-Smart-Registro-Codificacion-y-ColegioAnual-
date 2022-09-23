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
Fecha		: 25/08/2025
Responsable	: deicy Rojas
Descripción	: Se retira enl envio de informacion a tabla integradora AAMO
=============================================
*/
CREATE OR ALTER TRIGGER [dbo].[TGRAU_COLEGIOINFOFACTURA]
   ON [dbo].[ColegioInfoFactura]
   AFTER UPDATE
AS 
BEGIN
SET NOCOUNT ON;

/* VARIABLES */
DECLARE 
@IDColegio INT,
@MensajeError VARCHAR(250);

/* ASIGNAR VALOR A VARIABLES */
SELECT
@IDColegio = i.IDColegio
FROM Inserted i

/* Registro en tabla integradora */
/*IF (SELECT c.IDGrupoAAMO FROM BD_MAESTRA.dbo.Colegio c WHERE c.IDColegio = @IDColegio) IS NOT NULL
BEGIN
	BEGIN TRY
		INSERT INTO BD_INTEGRACION.dbo.ColegioLogAAMO (IDTipo,IDColegio,IDGrupo)
		SELECT 2,i.IDColegio,c.IDGrupoAAMO FROM Inserted i INNER JOIN BD_MAESTRA.dbo.Colegio c ON c.IDColegio = i.IDColegio
	END TRY
	BEGIN CATCH
		SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Integración de Colegio a plataforma AAMO errónea. Contacte al Administrador.','$|$');
		RAISERROR(@MensajeError,16,1);
		RETURN;
	END CATCH
END
*/
/* Registro en tabla integradora para pasar a Core */
BEGIN TRY
	INSERT INTO BD_INTEGRACION.dbo.ColegioInfoFactura (IDColegio,RazonSocial,Responsable,Telefono,Email,Direccion,IDDepartamento,IDCiudad,IDLocalidad,Procesado,Origen)
	SELECT i.IDColegio,i.RazonSocial,i.Responsable,i.Telefono,i.Email,i.Direccion,i.IDDepartamento,i.IDCiudad,i.IDLocalidad,0,0
	FROM Inserted i
END TRY
BEGIN CATCH
	SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Integración de Colegio a Core errónea. Contacte al Administrador.','$|$')
	RAISERROR(@MensajeError,16,1)
	RETURN
END CATCH

--
END
GO
ALTER TABLE [dbo].[ColegioInfoFactura] ENABLE TRIGGER [TGRAU_COLEGIOINFOFACTURA]
GO
