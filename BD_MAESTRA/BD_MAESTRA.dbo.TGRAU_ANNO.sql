SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* 
=============================================
Responsable	: Reinel José Ochoa Quintero
Fecha		: 18/11/2021
Descripción	: Actualización de fecha automática
Email		: reinel.ochoa@ceinfes.com
=============================================
CONTROL DE CAMBIOS
=============================================
Responsable	: Reinel José Ochoa
Fecha		: 18/7/2017
Descripción	: Actualización en BD_CEINFES
=============================================
Responsable	: Deicy Rojas Rosas
Fecha		: 03/09/2022
Descripción	: Insercion de la tabla  prueba_paquete si no existe 
			  Actualizacion de la tabla prueba_paquete 
=============================================
*/
CREATE OR ALTER  TRIGGER [dbo].[TGRAU_ANNO]
   ON [dbo].[Anno]
   AFTER UPDATE
AS 
BEGIN
SET NOCOUNT ON

DECLARE 
@ID INT
,@Nombre VARCHAR(4)
,@ActivoA BIT
,@ActivoB BIT
,@HistoricoA BIT
,@HistoricoB BIT
,@MensajeError VARCHAR(250)

SELECT
@ID = i.ID
,@Nombre = i.Nombre
,@ActivoA = i.ActivoA
,@ActivoB = i.ActivoB
,@HistoricoA = i.HistoricoA
,@HistoricoB = i.HistoricoB
FROM Inserted i

BEGIN TRY
	UPDATE BD_MAESTRA.dbo.Anno SET Anno.FechaActualizacion = GETDATE() WHERE Anno.ID = @ID
END TRY
BEGIN CATCH
 	SET @MensajeError = concat('$|$USER_MSG$|$ERROR$|$','Registro en base integración errónea. Contacte al Administrador','.$|$')
	RAISERROR(@MensajeError,16,1)
	RETURN
END CATCH

/*INSERCION DE LA TABLA PRUEBA_PAQUETE SI NO EXISTE*/
BEGIN
	IF NOT EXISTS(SELECT Anno FROM BD_MARTESDEPRUEBA.dbo.Prueba_Paquete where Anno=@ID)
	BEGIN TRY
	INSERT INTO BD_MARTESDEPRUEBA.dbo.Prueba_Paquete(Nombre,Anno,Alias,ActivoA,ActivoB,HistoricoA,HistoricoB)
	SELECT  CONCAT('PRUEBAS AÑO ',i.ID),i.ID,CONCAT('A',(SUBSTRING(i.Nombre,3,2))),i.ActivoA,i.ActivoB,i.HistoricoA,i.HistoricoB  FROM Inserted i
	END TRY
	BEGIN CATCH
		SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Registro de Prueba_Paquete erróneo. Contacte al Administrador.','$|$')
		RAISERROR(@MensajeError,16,1)
		RETURN
	END CATCH
END

/*ACTUALIZACION EN PRUEBA_PAQUETE AAMO*/
BEGIN TRY
		IF EXISTS(SELECT Anno FROM BD_MARTESDEPRUEBA.dbo.Prueba_Paquete where Anno=@ID)
		UPDATE BD_MARTESDEPRUEBA.dbo.Prueba_Paquete SET ActivoA=@ActivoA, ActivoB=@ActivoB,HistoricoA=@HistoricoA,HistoricoB=@HistoricoB WHERE Anno=@ID
END TRY
BEGIN CATCH
 	SET @MensajeError = concat('$|$USER_MSG$|$ERROR$|$','Actualizacion errónea en prueba Paquete. Contacte al Administrador','.$|$')
	RAISERROR(@MensajeError,16,1)
	RETURN
END CATCH

--
END
GO
ALTER TABLE [dbo].[Anno] ENABLE TRIGGER [TGRAU_ANNO]
GO
