SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* 
=============================================
Fecha		: 07/09/2022
Responsable	: Deicy Rojas Rosas
Descripción	: Registro de Informacion en las tablas Matricula y Aplicacion 
Email		: deicy.rojas@ceinfes.com
=============================================
CONTROL DE CAMBIOS
=============================================
Fecha		: 
Responsable	: 
Descripción	: 
=============================================
*/
 CREATE OR ALTER  TRIGGER [dbo].[TGRAI_COLEGIO]
   ON [dbo].[Colegio]
   AFTER INSERT
AS 
BEGIN
SET NOCOUNT,XACT_ABORT ON

/* VARIABLES */
DECLARE 
@IDColegio INT
,@IDRegional INT
,@IDUsuarioRegistra INT
,@MensajeError VARCHAR(250)

/* ASIGNAR VALOR A VARIABLES */
SELECT 
@IDColegio = i.IDColegio
,@IDRegional = i.IDRegional
,@IDUsuarioRegistra=i.IDUsuarioRegistra
FROM Inserted i


/* REGISTRAR INFORMACIÓN DE MATRICULA */
	BEGIN TRY
		IF NOT EXISTS(SELECT cim.ID FROM dbo.VW_COLEGIOINFOMATRICULA_CONSULTA AS cim WHERE cim.IDColegio = @IDColegio)
		BEGIN
			INSERT INTO dbo.ColegioInfoMatricula(IDColegio,AplicaMatricula,NotificarEstudiante,IDUsuarioRegistra)
			SELECT @IDColegio,1,1,@IDUsuarioRegistra
		END
	END TRY
	BEGIN CATCH
		SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Registro de Información de Matrícula erróneo. Contacte al Administrador','$|$')
		RAISERROR(@MensajeError,16,1)
		RETURN
	END CATCH

	/* REGISTRAR INFORMACIÓN DE APLICACIÓN */
	BEGIN TRY
		IF EXISTS(SELECT ria.ID FROM dbo.VW_REGIONALINFOAPLICACION_CONSULTA AS ria WHERE ria.IDRegional = @IDRegional AND ria.Activo = 1)
		BEGIN
			INSERT INTO dbo.ColegioInfoAplicacion(IDColegio,DiaAplicacion,DiaPublicacion,HoraInicioAplicacion,HoraFinAplicacion,Activo,IDUsuarioRegistra)
			SELECT @IDColegio,ria.DiaAplicacion,NULL,ria.HoraInicioAplicacion,ria.HoraFinAplicacion,ria.Activo,@IDUsuarioRegistra
			FROM dbo.VW_REGIONALINFOAPLICACION_CONSULTA AS ria 
			WHERE ria.IDRegional = @IDRegional
			AND ria.Activo = 1
		END
		ELSE
		BEGIN
			INSERT INTO dbo.ColegioInfoAplicacion(IDColegio,DiaAplicacion,DiaPublicacion,HoraInicioAplicacion,HoraFinAplicacion,Activo,IDUsuarioRegistra)
			SELECT @IDColegio,3,8,'07:00','19:00',1,@IDUsuarioRegistra
		END
	END TRY
	BEGIN CATCH
		SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Registro de información de aplicación erróneo. Contacte al Administrador','$|$')
		RAISERROR(@MensajeError,16,1)
		RETURN
	END CATCH

--
END
GO
ALTER TABLE [dbo].[Colegio] ENABLE TRIGGER [TGRAI_COLEGIO]
GO
