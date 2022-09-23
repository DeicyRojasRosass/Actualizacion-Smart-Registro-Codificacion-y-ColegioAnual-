SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* 
=============================================
Fecha		: 31/08/2022
Responsable	: Deicy Rojas Rosas
Descripción	: Inactivar Estudiantes y años anteriores  -- procesar Colegio Regional
Email		: deicy.rojas@ceinfes.com
=============================================
CONTROL DE CAMBIOS
=============================================
Fecha		: 02-09-2022
Responsable	: Deicy Rojas Rosas
Descripción	: Se asigna el estado  inactivo para la actualizacion de los estudiantes desde el colegioAnual
			  06-09-2022 se registra datos en GrupoAnual AAMO 
=============================================

*/
CREATE OR ALTER  TRIGGER [dbo].[TGRAI_COLEGIOANUAL]
   ON [dbo].[ColegioAnual]
   AFTER INSERT
AS 
BEGIN
SET NOCOUNT,XACT_ABORT ON

/* VARIABLE */
DECLARE
@ID INT
,@IDColegio INT
,@Calendario VARCHAR(50)
,@Anno INT
,@IDEstado INT
,@IDGrupo INT
,@IDGrupoAnual INT
,@ClaveEstudiante INT
,@IDColegioAnual INT
,@MensajeError VARCHAR(250)
,@l_cmd varchar(200);

SET @l_cmd = NULL;

/* ASIGNAR VALOR A VARIABLE */
SELECT
@IDColegio = i.IDColegio,
@IDEstado = i.IDEstado,
@Anno = i.Anno
FROM Inserted i



/* VARIABLES  TABLA TEMPORAL GRUPO ANUAL */
DECLARE @TableGrupoAnual TABLE 
(
	ID INT NOT NULL,
	IDColegio INT NOT NULL,
	IDGrupoAAMO INT NOT NULL,
	IDGrupoAnual INT,
	Anno INT NOT NULL,
	Calendario VARCHAR(1),
	Estado INT NOT NULL,
	IDFuncionario INT NOT NULL,
	Accion VARCHAR(1) NOT NULL,
	Fila INT NOT NULL
)

/* VARIABLES  TABLA TEMPORAL COLEGIO*/
DECLARE @TableColegio TABLE
(
	IDGrupoAnual INT NULL,
	ClaveEstudiante INT,
	IDColegioAnual INT NOT NULL,
	Fila INT NOT NULL
)
	
/* REGISTRAR COLEGIO ANUAL */
SET @ID = (SELECT MAX(ca.ID) FROM BD_MAESTRA.dbo.ColegioAnual ca)

/*ESTADO ACTIVO */
IF @IDEstado IN (2)
BEGIN
	UPDATE dbo.ColegioAnual SET Activo=1
	FROM Inserted i
	WHERE ColegioAnual.IDColegio = i.IDColegio
	AND ColegioAnual.Anno = i.Anno
END

/* PASO A HISTORICO */
IF @IDEstado IN (1,3)
BEGIN
	/* INACTIVAR LOS ESTUDIANTES DEL COLEGIO */
	BEGIN TRY
		UPDATE BD_ESTUDIANTE.dbo.Estudiante
		SET Estudiante.Activo = 0
		,Estudiante.IDEstado=2   --estado Inactivo
		FROM Inserted i
		WHERE Estudiante.IDColegio = i.IDColegio
		AND Estudiante.Anno = i.Anno
	END TRY
	BEGIN CATCH
		SET @MensajeError = ERROR_MESSAGE()
		RAISERROR(@MensajeError,16,1)
		RETURN
	END CATCH
		
	/* INACTIVAR AÑOS ANTERIORES */
	BEGIN TRY
		UPDATE BD_MAESTRA.dbo.ColegioAnual SET ColegioAnual.Activo = 0
		FROM Inserted i
		WHERE ColegioAnual.IDColegio = i.IDColegio
		AND ColegioAnual.Anno <= i.Anno
		AND ColegioAnual.Activo = 1
	END TRY
	BEGIN CATCH
		SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Inactivar año anterior erróneo. Contacte al Administrador.','$|$')
		RAISERROR(@MensajeError,16,1)
		RETURN
	END CATCH
END
	
/* PROCESAR COLEGIOS REGIONALES */
IF EXISTS(SELECT cir.IDColegio FROM BD_MAESTRA.dbo.ColegioInfoRegional cir WHERE cir.IDColegio = @IDColegio)
BEGIN
	BEGIN TRY
		UPDATE BD_MAESTRA.dbo.ColegioAnual 
		SET ColegioAnual.ProcesadoAFactory = 1,
			ColegioAnual.Procesado = 1
		WHERE ColegioAnual.ID = @ID
	END TRY
	BEGIN CATCH
		SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Procesamiento de Colegio Regional erróneo. Contacte al Administrador.','$|$')
		RAISERROR(@MensajeError,16,1)
		RETURN
	END CATCH
END


/* PROCESAR COLEGIOANUAL DE AAMO A SMART */	
BEGIN TRY 
	IF EXISTS(SELECT ca.ID FROM BD_MAESTRA.dbo.ColegioAnual ca WHERE ca.ProcesadoAFactory = 0 AND ca.id = @ID )
	BEGIN
		INSERT INTO @TableGrupoAnual
		SELECT 
		ca.ID, ca.IDColegio, c.IDGrupoAAMO, c.IDGrupoAnualAAMO, ca.Anno, cal.CodigoAAMO Calendario, eca.CodigoAAMO Estado,
		CASE
			c.IDRegional
			/* Bogotá, Caldas, Meta, Valle y Cundinamarca */
			WHEN 4 THEN 1159
			WHEN 11 THEN 1340
			WHEN 13 THEN 1360
			WHEN 15 THEN 1159
			/* Antioquia, Tolima y Chocó */
			WHEN 5 THEN 1117
			WHEN 1113 THEN 1117
			WHEN 1114 THEN 1117
			/* Córdoba y Sucre */
			WHEN 1118 THEN 1416
			WHEN 1119 THEN 1416
			/* Caldas, Quindio y Risaralda */
			WHEN 10 THEN 1083
			WHEN 7 THEN 1083
			WHEN 1120 THEN 1083
			ELSE 1125
		END IDFuncionario,
		eca.AccionAAMO,
		ROW_NUMBER() OVER(ORDER BY ca.IDColegio) Fila
		FROM BD_MAESTRA.dbo.ColegioAnual ca
		INNER JOIN BD_MAESTRA.dbo.Colegio c ON c.IDColegio = ca.IDColegio
		INNER JOIN BD_MAESTRA.dbo.Calendario cal ON cal.IDCalendario = ca.IDCalendario
		INNER JOIN BD_MAESTRA.dbo.EstadoColegioAnual eca ON eca.ID = ca.IDEstado
		WHERE ca.ProcesadoAFactory = 0
		AND ca.IDColegio NOT IN (SELECT cir.IDColegio FROM BD_MAESTRA.dbo.ColegioInfoRegional cir)
		AND c.IDGrupoAAMO IS NOT NULL
		AND ca.id = @ID
	END

	/*ASIGNACION DE VALOR A VARIABLES IDGRUPO */
	SELECT	@IDGrupo= t.IDGrupoAAMO, @Calendario = t.Calendario FROM @TableGrupoAnual AS t


	/*REGISTRO DE DATOS ACTIVOS*/
	IF (SELECT Accion FROM @TableGrupoAnual) ='I'
	BEGIN
		IF NOT EXISTS(SELECT ga.IDGrupoAnual FROM BD_MARTESDEPRUEBA.dbo.GrupoAnual ga WHERE ga.IDGrupo = @IdGrupo AND ga.Anno = @Anno AND ga.Calendario = @Calendario AND ga.Estado = 1)
		BEGIN TRY
			INSERT INTO BD_MARTESDEPRUEBA.dbo.GrupoAnual(IDGrupo,Anno,Calendario,Clave_Estudiante,Estado, IdFuncionario,IDColegioAnual)
			SELECT t.IDGrupoAAMO,t.Anno,t.Calendario,NULL,t.Estado,t.IDFuncionario,t.ID
			FROM @TableGrupoAnual t
		END TRY
		BEGIN CATCH
			--SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Registro de Grupo anual erróneo. Contacte al Administrador.','$|$')
			SET @MensajeError = ERROR_MESSAGE()
			RAISERROR(@MensajeError,16,1)
			RETURN
		END CATCH

		BEGIN TRY
			/* ACTUALIZAR PROCESADO */
			UPDATE BD_MAESTRA.dbo.ColegioAnual 
			SET ColegioAnual.ProcesadoAFactory = 1,
				ColegioAnual.FechaProcesadoAFactory = GETDATE()
			WHERE ColegioAnual.ID = @ID

		END TRY
		BEGIN CATCH
			SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Actualizacion Colegio Anual erróneo. Contacte al Administrador.','$|$')
			RAISERROR(@MensajeError,16,1)
			RETURN
		END CATCH
	END

	/*REGISTRO DE DATOS HISTORICOS*/
	IF	(SELECT Accion FROM @TableGrupoAnual) ='U'
	BEGIN
		IF NOT EXISTS(SELECT ga.IDGrupoAnual FROM BD_MARTESDEPRUEBA.dbo.GrupoAnual ga WHERE ga.IDGrupo = @IdGrupo AND ga.Anno = @Anno AND ga.Calendario = @Calendario AND ga.Estado IN (0))
		BEGIN TRY
				INSERT INTO BD_MARTESDEPRUEBA.dbo.GrupoAnual(IDGrupo,Anno,Calendario,Clave_Estudiante,Estado, IdFuncionario,IDColegioAnual)
				SELECT t.IDGrupoAAMO,t.Anno,t.Calendario,NULL,t.Estado,t.IDFuncionario,t.ID
				FROM @TableGrupoAnual t
		END TRY
		BEGIN CATCH
			SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Registro de Grupo anual Para Historico erróneo. Contacte al Administrador.','$|$')
			RAISERROR(@MensajeError,16,1)
			RETURN
		END CATCH

		BEGIN TRY
				/* ACTUALIZAR PROCESADO */
			UPDATE BD_MAESTRA.dbo.ColegioAnual 
			SET ColegioAnual.ProcesadoAFactory = 1,
				ColegioAnual.FechaProcesadoAFactory = GETDATE()
			WHERE ColegioAnual.ID = @ID
		END TRY
		BEGIN CATCH
			SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','ACTUALIZACION  DE COLEGIO ANUAL ERRONEA. Contacte al Administrador.','$|$')
			RAISERROR(@MensajeError,16,1)
			RETURN
		END CATCH

		/*BEGIN TRY
			---SI EL CONTEO DE ESTUDIANTE ES > 0 ASIGNA UN 0 ->ESTADO HISTORICO SINO ASIGNA 4 ->HISTORICO SIN ESTUDIANTES
			UPDATE BD_MARTESDEPRUEBA.dbo.GrupoAnual SET Estado = IIF((SELECT COUNT(*) FROM BD_MARTESDEPRUEBA.dbo.Estudiante WHERE IdGrupo=@IdGrupo AND Anno=@Anno)>0,0,4), Calendario=@Calendario WHERE IdGrupo = @Idgrupo AND Anno = @Anno;
			END TRY
		BEGIN CATCH
			SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','aCTUALIZACION  DE GRUPOOO ANUAL ERRONEAAAA. Contacte al Administrador.','$|$')
			RAISERROR(@MensajeError,16,1)
			RETURN
		END CATCH*/
	END
	
END TRY
BEGIN CATCH
	--SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','actualización de datos de SMART a AAMO erróneos. Contacte al Administrador.',ERROR_MESSAGE(),'$|$')
	SET @MensajeError = ERROR_MESSAGE()
	RAISERROR(@MensajeError,16,1)
	RETURN
END CATCH


--INICIO SP JOB
        declare 
        @carlos VARCHAR(50)=concat('carlos',@IdGrupo)
		SET @l_cmd=  CONCAT('EXECUTE BD_MARTESDEPRUEBA.dbo.SP_PASOHISTORICOSV2 ',@IdGrupo,' , ',@Anno)
		EXECUTE BD_MARTESDEPRUEBA.dbo.sp_async_execute  @l_cmd,@carlos,'BD_MARTESDEPRUEBA','sa'


/* PROCESAR COLEGIOANUAL DE AAMO A SMART */
BEGIN TRY
	IF EXISTS(SELECT g.IDGrupoAnual FROM BD_MARTESDEPRUEBA.dbo.GrupoAnual g WHERE g.Procesado = 1  AND g.IDColegioAnual IN (SELECT c.ID FROM BD_MAESTRA.dbo.ColegioAnual c WHERE c.Procesado = 0 AND c.ID = @ID))

	INSERT INTO @TableColegio
	SELECT g.IDGrupoAnual,g.Clave_Estudiante,g.IDColegioAnual,ROW_NUMBER()OVER(ORDER BY g.IDGrupoAnual) Fila
	FROM BD_MARTESDEPRUEBA.dbo.GrupoAnual g 
	WHERE g.Procesado = 1 
	AND g.IDColegioAnual IN (SELECT c.ID FROM BD_MAESTRA.dbo.ColegioAnual c WHERE c.Procesado = 0 AND c.ID = @ID)

	SELECT 
	@IDGrupoAnual = tc.IDGrupoAnual,
	@ClaveEstudiante = tc.ClaveEstudiante,
	@IDColegioAnual = tc.IDColegioAnual 
	FROM @TableColegio tc 

	/*ACTUALIZAR COLEGIO ANUAL */
	UPDATE BD_MAESTRA.dbo.ColegioAnual
	SET ColegioAnual.IDGrupoAnual = @IDGrupoAnual,
	ColegioAnual.ClaveEstudiante = @ClaveEstudiante,
	ColegioAnual.Procesado = 1,
	ColegioAnual.FechaProcesado = GETDATE()
	WHERE ColegioAnual.ID = @IDColegioAnual

	/* VALIDAR SI COLEGIO ANUAL QUEDO PROCESADO */
	IF EXISTS(SELECT c.ID FROM BD_MAESTRA.dbo.ColegioAnual c WHERE c.ID = @IDColegioAnual AND c.Procesado = 1)
	BEGIN TRY
		/*ACTUALIZAR PROCESADO SMART EN AAMO */
		UPDATE BD_MARTESDEPRUEBA.dbo.GrupoAnual
		SET GrupoAnual.ProcesadoSMART = 1,
		GrupoAnual.FechaProcesadoSMART = GETDATE()
		WHERE GrupoAnual.IDColegioAnual = @IDColegioAnual
	END TRY
	BEGIN CATCH
		-- SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','actualización de datos de Grupo Anual erróneos. Contacte al Administrador.',ERROR_MESSAGE(),'$|$')
        SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Severity: ',ERROR_SEVERITY(),' State',ERROR_STATE(),' Mensaje',ERROR_MESSAGE(),'$|$')
		RAISERROR(@MensajeError,16,1)
		RETURN
	END CATCH
END TRY
BEGIN CATCH
	--SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','actualización de datos de AAMO a SMART erróneos. Contacte al Administrador.',ERROR_MESSAGE(),'$|$')
    SET @MensajeError = CONCAT('$|$USER_MSG$|$ERROR$|$','Severity: ',ERROR_SEVERITY(),' State',ERROR_STATE(),' Mensaje',ERROR_MESSAGE(),'$|$')
	RAISERROR(@MensajeError,16,1)
	RETURN
END CATCH

END
GO
ALTER TABLE [dbo].[ColegioAnual] ENABLE TRIGGER [TGRAI_COLEGIOANUAL]
GO
