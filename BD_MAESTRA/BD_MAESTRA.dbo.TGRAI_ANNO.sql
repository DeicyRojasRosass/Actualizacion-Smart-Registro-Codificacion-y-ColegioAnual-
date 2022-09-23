SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* 
=============================================
Fecha		: 03/09/2022
Responsable	: Deicy Rojas Rosas 
Descripción	: Registro o actualizacion en la tabla AAMO Prueba_Paquete
Email		: deicy.rojas@ceinfes.com
=============================================
CONTROL DE CAMBIOS
=============================================
Fecha		: 
Responsable	: 
Descripción	: 
=============================================
*/
CREATE OR ALTER  TRIGGER [dbo].[TGRAI_ANNO]
   ON [dbo].[Anno]
   AFTER INSERT
AS 
BEGIN
SET NOCOUNT,XACT_ABORT ON

/* VARIABLES */
DECLARE 
@ID INT
,@Nombre VARCHAR(4)
,@ActivoA BIT
,@ActivoB BIT
,@HistoricoA BIT
,@HistoricoB BIT
,@MensajeError VARCHAR(250)

/* ASIGNACIÓN DE VALOR A VARIABLES */
SELECT
@ID = i.ID
,@Nombre = i.Nombre
,@ActivoA = i.ActivoA
,@ActivoB = i.ActivoB
,@HistoricoA = i.HistoricoA
,@HistoricoB = i.HistoricoB
FROM Inserted i

/* ACTUALIZACION PRUEBA_PAQUETE DE AAMO */
IF(@NOMBRE=@ID)
BEGIN
	IF NOT EXISTS(SELECT Anno FROM BD_MARTESDEPRUEBA.dbo.Prueba_Paquete where Anno=@ID)
	BEGIN TRY
	INSERT INTO BD_MARTESDEPRUEBA.dbo.Prueba_Paquete(Nombre,Anno,Alias,ActivoA,ActivoB,HistoricoA,HistoricoB)
	SELECT  CONCAT('PRUEBAS AÑO ',i.ID),i.ID,CONCAT('A',(SUBSTRING(i.Nombre,3,2))),ISNULL(i.ActivoA,0),ISNULL(i.ActivoB,0),ISNULL(i.HistoricoA,0),ISNULL(i.HistoricoB,0)  FROM Inserted i
	END TRY
	BEGIN CATCH
		SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Registro de Prueba_Paquete erróneo. Contacte al Administrador.','$|$')
		RAISERROR(@MensajeError,16,1)
		RETURN
	END CATCH

	ELSE
	BEGIN
		IF EXISTS(SELECT Anno FROM BD_MARTESDEPRUEBA.dbo.Prueba_Paquete where Anno=@ID)
		UPDATE BD_MARTESDEPRUEBA.dbo.Prueba_Paquete SET ActivoA=@ActivoA, ActivoB=@ActivoB, HistoricoA=@HistoricoA, HistoricoB=@HistoricoB WHERE Anno=@ID
	END
END

END
GO
ALTER TABLE [dbo].[Anno] ENABLE TRIGGER [TGRAI_ANNO]
GO
