SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* 
=============================================
Fecha		: 13-09-2022
Responsable	: Deicy Rojas Rosas - Carlos Cardenas 
Descripción	: Ejecucion del paso a Historicos (creacion de tablas de Historico Resultados)
Email		: deicy.rojas@ceinfes.com - carlos.cardenas@ceinfes.com
=============================================
CONTROL DE CAMBIOS
=============================================
Fecha		: 
Responsable	: 
Descripción	: 
Email		: 
=============================================
*/

CREATE OR ALTER  PROCEDURE [dbo].[SP_PasoHistoricosV2]
@IDGrupo INT 
,@AnnoGrupoAnual INT 
AS
BEGIN
	/*VARIABLES */
	DECLARE 
	@nombreTabla VARCHAR(100)
	,@MensajeError VARCHAR(4000)
	,@TotalEstud INT = 0
	,@Res INT = 0
	,@Res1 INT = 0
	,@Res2 INT = 0
	,@Ciu INT = 0
	,@Pen INT = 0
	,@Sab INT = 0
	,@ResMMP INT = 0
	,@Niv INT = 0

	BEGIN TRY
		INSERT INTO BD_MARTESDEPRUEBA.dbo.HistoricoLogsResultados
				(IDGrupo,AnnoGrupoAnual,Mensajes)
		SELECT @IDGrupo,@AnnoGrupoAnual,'Inicio de Paso a Históricos'

		BEGIN TRAN
			/*PASO DE ESTUDIANTES A CUBO DE RESULTADOS */
			IF EXISTS(SELECT e.IDEstudiante FROM BD_MARTESDEPRUEBA.dbo.Estudiante AS e WHERE  e.IDGrupo = @IDGrupo AND Anno=@AnnoGrupoAnual)
			BEGIN
				BEGIN TRY
					INSERT INTO BD_CUBORESULTADOS.dbo.Estudiante
					(IdEstudiante, IdEstudianteServis,IdGrupo,Codigo_Grupo, Anno,
					Grado,Estudiante,Salon,Nombres,Tipo_Documento,
					Cedula, Usuario,Clave,Tipo,Est_Correo,
					Est_Correo_R,Activo,FechaIngreso, IdSolicitudIngreso,IdSolicitudInactivar,
					Aut_Fecha, Aut_Correo, Aut_Nombre,Aut_Tipo_Documento,Aut_Documento,
					Aut_Telefono,Aut_Version,Aut_Cookies, Aut_Terminos,Aut_Politica,
					Aut_Publicidad,Ultimo_Acceso,Est_Fecha_Nacimiento
					) 
					OUTPUT inserted.IdEstudiante, inserted.IdEstudianteServis,inserted.IdGrupo,inserted.Codigo_Grupo, inserted.Anno,
					inserted.Grado,inserted.Estudiante,inserted.Salon,inserted.Nombres,inserted.Tipo_Documento,
					inserted.Cedula, inserted.Usuario,inserted.Clave,inserted.Tipo,inserted.Est_Correo,
					inserted.Est_Correo_R,inserted.Activo,inserted.FechaIngreso, inserted.IdSolicitudIngreso,inserted.IdSolicitudInactivar,
					inserted.Aut_Fecha, inserted.Aut_Correo, inserted.Aut_Nombre,inserted.Aut_Tipo_Documento,inserted.Aut_Documento,
					inserted.Aut_Telefono,inserted.Aut_Version,inserted.Aut_Cookies, inserted.Aut_Terminos,inserted.Aut_Politica,
					inserted.Aut_Publicidad,inserted.Ultimo_Acceso,inserted.Est_Fecha_Nacimiento
					INTO BD_MARTESDEPRUEBA.dbo.HistoricoEstudiantes
					SELECT              
					IdEstudiante,IdEstudianteServis,IdGrupo, Codigo_Grupo,Anno,
					Grado,Estudiante,Salon, Nombres, Tipo_Documento,
					Cedula,Usuario, Clave,Tipo, Est_Correo,
					Est_Correo_R,Activo,FechaIngreso, IdSolicitudIngreso, IdSolicitudInactivar,
					Aut_Fecha,Aut_Correo, Aut_Nombre,Aut_Tipo_Documento,Aut_Documento,
					Aut_Telefono, Aut_Version,Aut_Cookies, Aut_Terminos,Aut_Politica,
					Aut_Publicidad,Ultimo_Acceso, Est_Fecha_Nacimiento
					FROM BD_MARTESDEPRUEBA.dbo.Estudiante 
					WHERE  IDGrupo =@IDGrupo 
					AND Anno=@AnnoGrupoAnual
	
				SET @TotalEstud = (SELECT @@ROWCOUNT);

				END TRY
				BEGIN CATCH
					SET @MensajeError = CONCAT('Error de Registro de Estudiantes en Cubo de Resultados: ',ERROR_MESSAGE())
					RAISERROR(@MensajeError,16,1)
					RETURN
				END CATCH
			END

			/*--MARTES DE PRUEBA, INTEGRADAS*/
			IF EXISTS(SELECT r.IDResultado FROM dbo.Resultados AS r WHERE r.IdGrupo = @IDGrupo AND r.AnnoGrupoAnual = @AnnoGrupoAnual )
			BEGIN
				BEGIN TRY
					INSERT INTO [BD_CUBORESULTADOS].DBO.Resultados  (IDPruebaTipo,PuestoN,PuestoC,Anno_Paquete,Anno_Estudiante,Calendario,IdPruebaEncabezado,IdEstudiante,Codigo_Grupo,Grado,Estudiante ,Salon,Prueba,Cie,Mat,Esp,Soc,Ing, Def,Respuestas,EnviadoAlumno,strMensaje,FechaCreacion,IdGrupo,Cargue,AnnoGrupoAnual,IDPrueba)

					SELECT 
					r.IdPruebatipo AS IdPruebaTipo, 
					NULL AS PuestoN, 
					NULL AS PuestoC,
					R.anno Anno_Paquete
					,(SELECT e.Anno FROM dbo.Estudiante AS e WHERE e.IdEstudiante = r.IdEstudiante AND e.Grado = r.Grado AND e.Salon = r.Salon) Anno_Estudiante
					,(SELECT g.Calendario FROM dbo.Grupo AS g WHERE g.IdGrupo = r.IdGrupo) Calendario
					, R.IdPruebaEncabezado, R.IdEstudiante, R.Codigo_Grupo, R.Grado, R.Estudiante, R.Salon, R.Prueba, 
					R.Cie,R.Mat,R.Esp,R.Soc,R.Ing,
					R.Def, 
					R.Respuestas,
					R.EnviadoAlumno,
					R.strMensaje,
					R.FechaCreacion,
					R.IdGrupo,
					R.Cargue,
					R.AnnoGrupoAnual,
					R.IDPrueba
					FROM dbo.Resultados AS r
					WHERE r.IdGrupo = @IDGrupo
					AND r.AnnoGrupoAnual = @AnnoGrupoAnual

					SET @Res = (SELECT @@ROWCOUNT);

					SET @nombreTabla = CONCAT('HistoricoResultados_',@AnnoGrupoAnual)
					/*CREACION TABLA TEMPORAL PARA RESULTADOS AÑO GRUPO ANUAL*/
					IF NOT EXISTS (SELECT * FROM sysobjects where name = @nombreTabla AND xtype='U')
					BEGIN
						EXECUTE ('SELECT IDPruebaTipo ,IdPruebaEncabezado ,IdEstudiante ,Anno,Codigo_Grupo ,Grado ,Estudiante ,Salon ,Prueba ,Cie ,Mat ,Esp ,Soc ,Ing ,Def ,Respuestas ,EnviadoAlumno ,strMensaje ,FechaCreacion ,IdGrupo ,Cargue ,AnnoGrupoAnual ,IDPrueba INTO ' + @nombreTabla +  ' FROM dbo.Resultados AS r WHERE r.IdGrupo = '+ @IDGrupo  + ' AND r.AnnoGrupoAnual = ' + @AnnoGrupoAnual )
					END
					ELSE
					BEGIN 
						EXECUTE ('INSERT INTO ' + @nombreTabla + ' (IDPruebaTipo,IdPruebaEncabezado,IdEstudiante,Anno,Codigo_Grupo,Grado,Estudiante ,Salon,Prueba,Cie,Mat,Esp,Soc,Ing, Def,Respuestas,EnviadoAlumno,strMensaje,FechaCreacion,IdGrupo,Cargue,AnnoGrupoAnual,IDPrueba)  
						SELECT 	r.IdPruebatipo, R.IdPruebaEncabezado, R.IdEstudiante,R.Anno, R.Codigo_Grupo, R.Grado, R.Estudiante, R.Salon, R.Prueba, R.Cie,R.Mat,R.Esp,R.Soc,R.Ing,R.Def, R.Respuestas,R.EnviadoAlumno,R.strMensaje,
						R.FechaCreacion,R.IdGrupo,R.Cargue,	R.AnnoGrupoAnual,R.IDPrueba	FROM dbo.Resultados AS r	WHERE r.IdGrupo = '+ @IDGrupo  + 'AND r.AnnoGrupoAnual = ' + @AnnoGrupoAnual )
					END
				END TRY
				BEGIN CATCH
					SET @MensajeError = CONCAT('Error en Registro y paso de Resultados: ' ,ERROR_MESSAGE())
					RAISERROR(@MensajeError,16,1)
					RETURN
				END CATCH

				/*ELIMINACION DE RESULTADOS*/
				BEGIN TRY
					DELETE FROM dbo.Resultados 
					WHERE IdGrupo = @IDGrupo
					AND AnnoGrupoAnual = @AnnoGrupoAnual
				END TRY
				BEGIN CATCH
					SET @MensajeError = 'Eliminación de Resultados Erróneo. Contacte al Administrador.'
					RAISERROR(@MensajeError,16,1)
					RETURN
				END CATCH
			END

			/*RESULTADOS 1*/
			IF EXISTS(SELECT r.IDResultado FROM dbo.Resultados1 AS r WHERE r.IdGrupo = @IDGrupo AND r.AnnoGrupoAnual = @AnnoGrupoAnual)
			BEGIN
				BEGIN TRY 
					INSERT INTO [BD_CUBORESULTADOS].DBO.Resultados (IDPruebaTipo,PuestoN,PuestoC,Anno_Paquete,Anno_Estudiante,Calendario,IdPruebaEncabezado,IdEstudiante,Codigo_Grupo,Grado,Estudiante ,Salon,Prueba,Cie,Mat,Esp,Soc,Ing,Qui,Fis,Fil,Mat2,Ciu,CTS,Def,Respuestas,EnviadoAlumno,strMensaje,FechaCreacion,IdGrupo,Cargue,AnnoGrupoAnual,IDPrueba)
					SELECT 
					R.IDPruebaTipo AS IdPruebaTipo, 
					NULL AS PuestoN, 
					NULL AS PuestoC,
					R.anno Anno_Paquete
					,(SELECT e.Anno FROM dbo.Estudiante AS e WHERE e.IdEstudiante = r.IdEstudiante AND e.Grado = r.Grado AND e.Salon = r.Salon) Anno_Estudiante
					,(SELECT g.Calendario FROM dbo.Grupo AS g WHERE g.IdGrupo = r.IdGrupo) Calendario
					, R.IdPruebaEncabezado, R.IdEstudiante, R.Codigo_Grupo, R.Grado, R.Estudiante, R.Salon, R.Prueba, 
					R.Cie,R.Mat,R.Esp,R.Soc,R.Ing,R.Qui,R.Fis,R.Fil,R.Mat2,R.Ciu,R.CTS, 
					R.Def, 
					R.Respuestas,
					R.EnviadoAlumno,
					R.strMensaje,
					R.FechaCreacion,
					R.IdGrupo,
					R.Cargue,
					R.AnnoGrupoAnual,
					R.IDPrueba
					FROM dbo.Resultados1 AS r
					WHERE r.IdGrupo = @IDGrupo
					AND r.AnnoGrupoAnual = @AnnoGrupoAnual

					SET @Res1 = (SELECT @@ROWCOUNT);

					SET @nombreTabla = CONCAT('HistoricoResultados1_',@AnnoGrupoAnual)
					/*CREACION TABLA TEMPORAL PARA RESULTADOS AÑO GRUPO ANUAL*/
					IF NOT EXISTS (SELECT * FROM sysobjects where name = @nombreTabla AND xtype='U')
					BEGIN
						EXECUTE ('SELECT IDPruebaTipo ,IdPruebaEncabezado ,IdEstudiante ,Anno,Codigo_Grupo ,Grado ,Estudiante ,Salon ,Prueba ,Cie ,Mat ,Esp ,Soc ,Ing,Qui,Fis,Fil,Mat2,Ciu,CTS,Def ,Respuestas ,EnviadoAlumno ,strMensaje ,FechaCreacion ,IdGrupo ,Cargue ,AnnoGrupoAnual ,IDPrueba INTO ' + @nombreTabla +  ' FROM dbo.Resultados1 AS r WHERE r.IdGrupo = '+ @IDGrupo  + ' AND r.AnnoGrupoAnual = ' + @AnnoGrupoAnual  )
					END
					ELSE
					BEGIN 
						EXECUTE ('INSERT INTO ' + @nombreTabla + ' (IDPruebaTipo,IdPruebaEncabezado,IdEstudiante,Anno,Codigo_Grupo,Grado,Estudiante ,Salon,Prueba,Cie,Mat,Esp,Soc,Ing,Qui,Fis,Fil,Mat2,Ciu,CTS,Def,Respuestas,EnviadoAlumno,strMensaje,FechaCreacion,IdGrupo,Cargue,AnnoGrupoAnual,IDPrueba)  
						SELECT 	r.IdPruebatipo, R.IdPruebaEncabezado, R.IdEstudiante,R.Anno, R.Codigo_Grupo, R.Grado, R.Estudiante, R.Salon, R.Prueba, R.Cie,R.Mat,R.Esp,R.Soc,R.Ing, R.Qui,R.Fis,R.Fil,R.Mat2,R.Ciu,R.CTS,R.Def, R.Respuestas,R.EnviadoAlumno,R.strMensaje,
						R.FechaCreacion,R.IdGrupo,R.Cargue,	R.AnnoGrupoAnual,R.IDPrueba	FROM dbo.Resultados1 AS r	WHERE r.IdGrupo = '+ @IDGrupo  + ' AND r.AnnoGrupoAnual = ' + @AnnoGrupoAnual  )
					END
				END TRY
				BEGIN CATCH
					SET @MensajeError = CONCAT('Error en Registro y paso de Resultados 1: ' ,ERROR_MESSAGE())
					RAISERROR(@MensajeError,16,1)
					RETURN
				END CATCH

				/*ELIMINACION DE RESULTADOS1*/
				BEGIN TRY
					DELETE FROM dbo.Resultados1
					WHERE IdGrupo = @IDGrupo
					AND AnnoGrupoAnual = @AnnoGrupoAnual
				END TRY
				BEGIN CATCH
					SET @MensajeError = 'Eliminación de Resultados1 Erróneo. Contacte al Administrador.'
					RAISERROR(@MensajeError,16,1)
					RETURN
				END CATCH
			END

			/*RESULTADOS 2*/
			IF EXISTS(SELECT r.IDResultado FROM dbo.Resultados2 AS r WHERE r.IdGrupo = @IDGrupo AND r.AnnoGrupoAnual = @AnnoGrupoAnual )
			BEGIN
				BEGIN TRY
					INSERT INTO [BD_CUBORESULTADOS].DBO.Resultados (IDPruebaTipo,PuestoN,PuestoC,Anno_Paquete,Anno_Estudiante,Calendario,IdPruebaEncabezado,IdEstudiante,Codigo_Grupo,Grado,Estudiante ,Salon,Prueba,Cie,Mat,Esp,Soc,Ing,Qui,Fis,Fil,Mat2,Ciu,CTS,Def,Respuestas,EnviadoAlumno,strMensaje,FechaCreacion,IdGrupo,Cargue,AnnoGrupoAnual,IDPrueba)
					SELECT
					R.IDPruebaTipo AS IdPruebaTipo 
					,NULL AS PuestoN
					,NULL AS PuestoC
					,R.anno Anno_Paquete
					,(SELECT e.Anno FROM dbo.Estudiante AS e WHERE e.IdEstudiante = r.IdEstudiante AND e.Grado = r.Grado AND e.Salon = r.Salon) Anno_Estudiante
					,(SELECT g.Calendario FROM dbo.Grupo AS g WHERE g.IdGrupo = r.IdGrupo) Calendario
					,R.IdPruebaEncabezado, R.IdEstudiante, R.Codigo_Grupo, R.Grado, R.Estudiante, R.Salon, R.Prueba, 
					R.Cie,R.Mat,R.Esp,R.Soc,R.Ing,R.Qui,R.Fis,R.Fil,R.Mat2,R.Ciu,R.CTS,
					R.Def, 
					R.Respuestas, 
					R.EnviadoAlumno, 
					NULL AS strMensaje, 
					R.FechaCreacion,
					R.IdGrupo,
					R.Cargue,
					R.AnnoGrupoAnual,
					R.IDPrueba
					FROM dbo.Resultados2 AS r
					WHERE r.IdGrupo = @IDGrupo
					AND r.AnnoGrupoAnual = @AnnoGrupoAnual

					SET @Res2 = (SELECT @@ROWCOUNT);

					SET @nombreTabla = CONCAT('HistoricoResultados2_',@AnnoGrupoAnual)
					/*CREACION TABLA TEMPORAL PARA RESULTADOS AÑO GRUPO ANUAL*/
					IF NOT EXISTS (SELECT * FROM sysobjects where name = @nombreTabla AND xtype='U')
					BEGIN
						EXECUTE ('SELECT IDPruebaTipo ,IdPruebaEncabezado ,IdEstudiante ,Anno,Codigo_Grupo ,Grado ,Estudiante ,Salon ,Prueba ,Cie ,Mat ,Esp ,Soc ,Ing,Qui,Fis,Fil,Mat2,Ciu,CTS,Def ,Respuestas ,EnviadoAlumno ,FechaCreacion ,IdGrupo ,Cargue ,AnnoGrupoAnual ,IDPrueba INTO ' + @nombreTabla +  ' FROM dbo.Resultados2 AS r WHERE r.IdGrupo = '+ @IDGrupo  + ' AND r.AnnoGrupoAnual = ' + @AnnoGrupoAnual  )
					END
					ELSE
					BEGIN 
						EXECUTE ('INSERT INTO ' + @nombreTabla + ' (IDPruebaTipo,IdPruebaEncabezado,IdEstudiante,Anno,Codigo_Grupo,Grado,Estudiante ,Salon,Prueba,Cie,Mat,Esp,Soc,Ing,Qui,Fis,Fil,Mat2,Ciu,CTS,Def,Respuestas,EnviadoAlumno,FechaCreacion,IdGrupo,Cargue,AnnoGrupoAnual,IDPrueba)   
						SELECT 	r.IdPruebatipo, R.IdPruebaEncabezado, R.IdEstudiante,R.Anno, R.Codigo_Grupo, R.Grado, R.Estudiante, R.Salon, R.Prueba, R.Cie,R.Mat,R.Esp,R.Soc,R.Ing, R.Qui,R.Fis,R.Fil,R.Mat2,R.Ciu,R.CTS,R.Def, R.Respuestas,R.EnviadoAlumno,
						R.FechaCreacion,R.IdGrupo,R.Cargue,	R.AnnoGrupoAnual,R.IDPrueba	FROM dbo.Resultados2 AS r	WHERE r.IdGrupo = '+ @IDGrupo  + ' AND r.AnnoGrupoAnual = ' + @AnnoGrupoAnual  )
					END
				END TRY
				BEGIN CATCH
					SET @MensajeError = CONCAT('Error en Registro y paso de Resultados 2: ' ,ERROR_MESSAGE())
					RAISERROR(@MensajeError,16,1)
					RETURN
				END CATCH

				/*ELIMINACION DE RESULTADOS2*/
				BEGIN TRY
					DELETE FROM dbo.Resultados2
					WHERE IdGrupo = @IDGrupo
					AND AnnoGrupoAnual = @AnnoGrupoAnual
				END TRY
				BEGIN CATCH
					SET @MensajeError = 'Eliminación en  Resultados2 Erróneo. Contacte al Administrador.'
					RAISERROR(@MensajeError,16,1)
					RETURN
				END CATCH
			END

			/*CIUDADANAS*/
			IF EXISTS(SELECT r.IDResultado FROM dbo.Ciudadanas AS r WHERE r.IdGrupo = @IDGrupo AND r.AnnoGrupoAnual = @AnnoGrupoAnual )
			BEGIN
				BEGIN TRY
					INSERT INTO [BD_CUBORESULTADOS].DBO.Resultados (IDPruebaTipo,PuestoN,PuestoC,Anno_Paquete,Anno_Estudiante,Calendario,IdPruebaEncabezado,IdEstudiante,Codigo_Grupo,Grado,Estudiante ,Salon,Prueba,Ciu,Def,Respuestas,EnviadoAlumno,FechaCreacion,IdGrupo,Cargue,AnnoGrupoAnual,IDPrueba)
					SELECT TOP 1
					R.IDPruebaTipo AS IdPruebaTipo, 
					NULL AS PuestoN, 
					NULL AS PuestoC,
					R.anno Anno_Paquete
					,(SELECT e.Anno FROM dbo.Estudiante AS e WHERE e.IdEstudiante = r.IdEstudiante AND e.Grado = r.Grado AND e.Salon = r.Salon) Anno_Estudiante
					,(SELECT g.Calendario FROM dbo.Grupo AS g WHERE g.IdGrupo = r.IdGrupo) Calendario
					, R.IdPruebaEncabezado, R.IdEstudiante, R.Codigo_Grupo, R.Grado, R.Estudiante, R.Salon, R.Prueba, 
					R.Ciu, 
					R.Def, 
					R.Respuestas, 
					R.EnviadoAlumno, 
					R.FechaCreacion,
					R.IdGrupo,
					R.Cargue,
					R.AnnoGrupoAnual,
					R.IDPrueba
					FROM dbo.Ciudadanas AS r
					WHERE r.IdGrupo = @IDGrupo
					AND r.AnnoGrupoAnual = @AnnoGrupoAnual

					SET @Ciu = (SELECT @@ROWCOUNT);

					SET @nombreTabla = CONCAT('HistoricoCiudadanas_',@AnnoGrupoAnual)
					/*CREACION TABLA TEMPORAL PARA RESULTADOS AÑO GRUPO ANUAL*/
					IF NOT EXISTS (SELECT * FROM sysobjects where name = @nombreTabla AND xtype='U')
					BEGIN
					EXECUTE ('SELECT IDPruebaTipo ,IdPruebaEncabezado ,IdEstudiante ,Anno,Codigo_Grupo ,Grado ,Estudiante ,Salon ,Prueba ,Ciu,Def ,Respuestas ,EnviadoAlumno ,FechaCreacion ,IdGrupo ,Cargue ,AnnoGrupoAnual ,IDPrueba INTO ' + @nombreTabla +  ' FROM dbo.Ciudadanas AS r WHERE r.IdGrupo = '+ @IDGrupo  + ' AND r.AnnoGrupoAnual = ' + @AnnoGrupoAnual )
					END
					ELSE
					BEGIN 
						EXECUTE ('INSERT INTO ' + @nombreTabla + '(IDPruebaTipo,IdPruebaEncabezado,IdEstudiante,Anno,Codigo_Grupo,Grado,Estudiante ,Salon,Prueba,Ciu,Def,Respuestas,EnviadoAlumno,FechaCreacion,IdGrupo,Cargue,AnnoGrupoAnual,IDPrueba)  
						SELECT 	r.IdPruebatipo, R.IdPruebaEncabezado, R.IdEstudiante,R.Anno, R.Codigo_Grupo, R.Grado, R.Estudiante, R.Salon, R.Prueba, R.Ciu,R.Def, R.Respuestas,R.EnviadoAlumno,
						R.FechaCreacion,R.IdGrupo,R.Cargue,	R.AnnoGrupoAnual,R.IDPrueba	FROM dbo.Ciudadanas AS r	WHERE r.IdGrupo = '+ @IDGrupo  + ' AND r.AnnoGrupoAnual = ' + @AnnoGrupoAnual  )
					END
				END TRY
				BEGIN CATCH
					SET @MensajeError =CONCAT('Error en Registro y paso de Ciudadanas: ' ,ERROR_MESSAGE())
					RAISERROR(@MensajeError,16,1)
					RETURN
				END CATCH

				/*ELIMINACION DE CIUDADANAS*/
				BEGIN TRY
					DELETE FROM dbo.Ciudadanas 
					WHERE IdGrupo = @IDGrupo
					AND AnnoGrupoAnual = @AnnoGrupoAnual
				END TRY
				BEGIN CATCH
					SET @MensajeError = 'Eliminación en  Ciudadanas Erróneo. Contacte al Administrador.'
					RAISERROR(@MensajeError,16,1)
					RETURN
				END CATCH
			END
	
			/*SABERES*/
			IF EXISTS(SELECT r.IDResultado FROM dbo.Saberes AS r WHERE r.IdGrupo = @IDGrupo AND r.AnnoGrupoAnual = @AnnoGrupoAnual )
			BEGIN
				BEGIN TRY 
					INSERT INTO [BD_CUBORESULTADOS].DBO.Resultados (IDPruebaTipo,PuestoN,PuestoC,Anno_Paquete,Anno_Estudiante,Calendario,IdPruebaEncabezado,IdEstudiante,Codigo_Grupo,Grado,Estudiante ,Salon,Prueba,Ciu,Mat,Esp,Def,Respuestas,EnviadoAlumno,FechaCreacion,IdGrupo,Cargue,AnnoGrupoAnual,IDPrueba)
					SELECT 
					R.IDPruebaTipo AS IdPruebaTipo, 
					NULL AS PuestoN, 
					NULL AS PuestoC,
					R.anno Anno_Paquete 
					,(SELECT e.Anno FROM dbo.Estudiante AS e WHERE e.IdEstudiante = r.IdEstudiante AND e.Grado = r.Grado AND e.Salon = r.Salon) Anno_Estudiante
					,(SELECT g.Calendario FROM dbo.Grupo AS g WHERE g.IdGrupo = r.IdGrupo) Calendario
					, R.IdPruebaEncabezado, R.IdEstudiante, R.Codigo_Grupo, R.Grado, R.Estudiante, R.Salon, R.Prueba, 
					R.Cie, 
					R.Mat, 
					R.Esp, 
					R.Def, 
					R.Respuestas,
					R.EnviadoAlumno, 
					R.FechaCreacion,
					R.IdGrupo,
					R.Cargue,
					R.AnnoGrupoAnual,
					R.IDPrueba
					FROM dbo.Saberes AS r
					WHERE r.IdGrupo = @IDGrupo
					AND r.AnnoGrupoAnual = @AnnoGrupoAnual

					SET @Sab = (SELECT @@ROWCOUNT);

					SET @nombreTabla = CONCAT('HistoricoSaberes_',@AnnoGrupoAnual)
					/*CREACION TABLA TEMPORAL PARA RESULTADOS AÑO GRUPO ANUAL*/
					IF NOT EXISTS (SELECT * FROM sysobjects where name = @nombreTabla AND xtype='U')
					BEGIN
						EXECUTE ('SELECT IDPruebaTipo ,IdPruebaEncabezado ,IdEstudiante ,Anno,Codigo_Grupo ,Grado ,Estudiante ,Salon ,Prueba ,Cie,Mat,Esp,Def ,Respuestas ,EnviadoAlumno ,FechaCreacion ,IdGrupo ,Cargue ,AnnoGrupoAnual ,IDPrueba INTO ' + @nombreTabla +  ' FROM dbo.Saberes AS r WHERE r.IdGrupo = '+ @IDGrupo  + ' AND r.AnnoGrupoAnual = ' + @AnnoGrupoAnual )
					END
					ELSE
					BEGIN 
						EXECUTE ('INSERT INTO ' + @nombreTabla + '(IDPruebaTipo,IdPruebaEncabezado,IdEstudiante,Anno,Codigo_Grupo,Grado,Estudiante ,Salon,Prueba,Cie,Mat,Esp,Def,Respuestas,EnviadoAlumno,FechaCreacion,IdGrupo,Cargue,AnnoGrupoAnual,IDPrueba)  
						SELECT 	r.IdPruebatipo, R.IdPruebaEncabezado, R.IdEstudiante,R.Anno, R.Codigo_Grupo, R.Grado, R.Estudiante, R.Salon, R.Prueba, R.Cie,R.Mat,R.Esp,R.Def, R.Respuestas,R.EnviadoAlumno,
						R.FechaCreacion,R.IdGrupo,R.Cargue,	R.AnnoGrupoAnual,R.IDPrueba	FROM dbo.Saberes AS r	WHERE r.IdGrupo = '+ @IDGrupo  + ' AND r.AnnoGrupoAnual = ' + @AnnoGrupoAnual  )
					END
				END TRY
				BEGIN CATCH
					SET @MensajeError = CONCAT('Error en Registro y paso de Saberes: ' ,ERROR_MESSAGE())
					RAISERROR(@MensajeError,16,1)
					RETURN
				END CATCH

				/*ELIMINACION DE SABERES*/
				BEGIN TRY
					DELETE FROM dbo.Saberes 
					WHERE IdGrupo = @IDGrupo
					AND AnnoGrupoAnual = @AnnoGrupoAnual
				END TRY
				BEGIN CATCH
					SET @MensajeError = 'Eliminación en Saberes Erróneo. Contacte al Administrador.'
					RAISERROR(@MensajeError,16,1)
					RETURN
				END CATCH
			END

			/*MI PRIMER MARTES DE PRUEBA*/
			IF EXISTS(SELECT r.IDResultado FROM dbo.Resultados_MMP AS r WHERE r.IdGrupo = @IDGrupo AND r.AnnoGrupoAnual = @AnnoGrupoAnual )
			BEGIN
				BEGIN TRY
					INSERT INTO [BD_CUBORESULTADOS].DBO.Resultados (IDPruebaTipo,PuestoN,PuestoC,Anno_Paquete,Anno_Estudiante,Calendario,IdPruebaEncabezado,IdEstudiante,Codigo_Grupo,Grado,Estudiante ,Salon,Prueba,Cor,Cog,Com,Eti,Def,Respuestas,EnviadoAlumno,FechaCreacion,IdGrupo,Cargue,AnnoGrupoAnual,IDPrueba)
					SELECT
					R.IDPruebaTipo AS IdPruebaTipo, 
					NULL AS PuestoN, 
					NULL AS PuestoC,
					R.anno Anno_Paquete
					,(SELECT e.Anno FROM dbo.Estudiante AS e WHERE e.IdEstudiante = r.IdEstudiante AND e.Grado = r.Grado AND e.Salon = r.Salon) Anno_Estudiante
					,(SELECT g.Calendario FROM dbo.Grupo AS g WHERE g.IdGrupo = r.IdGrupo) Calendario
					, R.IdPruebaEncabezado, R.IdEstudiante, R.Codigo_Grupo, R.Grado, R.Estudiante, R.Salon, R.Prueba, 
					R.Cor, 
					R.Cog,
					R.Com, 
					R.Eti, 
					R.Def,
					R.Respuestas,
					R.EnviadoAlumno,
					R.FechaCreacion,
					R.IdGrupo,
					R.Cargue,
					R.AnnoGrupoAnual,
					R.IDPrueba
					FROM dbo.Resultados_MMP AS r
					WHERE r.IdGrupo = @IDGrupo
					AND r.AnnoGrupoAnual = @AnnoGrupoAnual

					SET @ResMMP = (SELECT @@ROWCOUNT);

					SET @nombreTabla = CONCAT('HistoricoResultados_MMP_',@AnnoGrupoAnual)
					/*CREACION TABLA TEMPORAL PARA RESULTADOS AÑO GRUPO ANUAL*/
					IF NOT EXISTS (SELECT * FROM sysobjects where name = @nombreTabla AND xtype='U')
					BEGIN
						EXECUTE ('SELECT IDPruebaTipo ,IdPruebaEncabezado ,IdEstudiante ,Anno,Codigo_Grupo ,Grado ,Estudiante ,Salon ,Prueba ,Cor,Cog,Com,Eti,Def ,Respuestas ,EnviadoAlumno ,FechaCreacion ,IdGrupo ,Cargue ,AnnoGrupoAnual ,IDPrueba INTO ' + @nombreTabla +  ' FROM dbo.Resultados_MMP AS r WHERE r.IdGrupo = '+ @IDGrupo   + ' AND r.AnnoGrupoAnual = ' + @AnnoGrupoAnual  )
					END
					ELSE
					BEGIN 
						EXECUTE ('INSERT INTO ' + @nombreTabla + '(IDPruebaTipo,IdPruebaEncabezado,IdEstudiante,Anno,Codigo_Grupo,Grado,Estudiante ,Salon,Prueba,Cor,Cog,Com,Eti,Def,Respuestas,EnviadoAlumno,FechaCreacion,IdGrupo,Cargue,AnnoGrupoAnual,IDPrueba)  
						SELECT 	r.IdPruebatipo, R.IdPruebaEncabezado, R.IdEstudiante,R.Anno, R.Codigo_Grupo, R.Grado, R.Estudiante, R.Salon, R.Prueba, R.Cor, R.Cog,R.Com, R.Eti,R.Def, R.Respuestas,R.EnviadoAlumno,
						R.FechaCreacion,R.IdGrupo,R.Cargue,	R.AnnoGrupoAnual,R.IDPrueba	FROM dbo.Resultados_MMP AS r	WHERE r.IdGrupo = '+ @IDGrupo  + ' AND r.AnnoGrupoAnual = ' + @AnnoGrupoAnual  )
					END
				END TRY
				BEGIN CATCH
					SET @MensajeError = CONCAT('Error en Registro y paso de Resultados mi primer Martes de Prueba: ' ,ERROR_MESSAGE())
					RAISERROR(@MensajeError,16,1)
					RETURN
				END CATCH

				/*ELIMINACION DE RESULTADOS_MMP*/
				BEGIN TRY
					DELETE FROM dbo.Resultados_MMP 
					WHERE IdGrupo = @IDGrupo
					AND AnnoGrupoAnual = @AnnoGrupoAnual
				END TRY
				BEGIN CATCH
					SET @MensajeError = 'Eliminación en Resultados MMP Erroneo. Contacte al Administrador.'
					RAISERROR(@MensajeError,16,1)
					RETURN
				END CATCH

			END


			/*NIVELOMETRO*/
			IF EXISTS(SELECT r.IDResultado FROM dbo.ResultadosNivelometro AS r WHERE r.IdGrupo = @IDGrupo AND r.AnnoGrupoAnual = @AnnoGrupoAnual )
			BEGIN
				BEGIN TRY 
					INSERT INTO [BD_CUBORESULTADOS].DBO.Resultados (IDPruebaTipo,PuestoN,PuestoC,Anno_Paquete,Anno_Estudiante,Calendario,IdPruebaEncabezado,IdEstudiante,Codigo_Grupo,Grado,Estudiante ,Salon,Prueba,Cie,Mat,Esp,Soc,Ing,Qui,Fis,Fil,Mat2,Ciu,CTS,Def,Respuestas,EnviadoAlumno,strMensaje,FechaCreacion,IdGrupo,Cargue,AnnoGrupoAnual,IDPrueba)
					SELECT TOP 1
					R.IDPruebaTipo AS IdPruebaTipo, 
					NULL AS PuestoN, 
					NULL AS PuestoC,
					R.anno Anno_Paquete
					,(SELECT e.Anno FROM dbo.Estudiante AS e WHERE e.IdEstudiante = r.IdEstudiante AND e.Grado = r.Grado AND e.Salon = r.Salon) Anno_Estudiante
					,(SELECT g.Calendario FROM dbo.Grupo AS g WHERE g.IdGrupo = r.IdGrupo) Calendario
					, R.IdPruebaEncabezado, R.IdEstudiante, R.Codigo_Grupo, R.Grado, R.Estudiante, R.Salon, R.Prueba, 
					R.Cie,
					R.Mat,
					R.Esp,
					R.Soc,
					R.Ing,
					R.Qui,
					R.Fis,
					R.Fil,
					R.Mat2,
					R.Ciu,
					R.CTS, 
					R.Def, 
					R.Respuestas,
					R.EnviadoAlumno,
					R.strMensaje,
					R.FechaCreacion,
					R.IdGrupo,
					R.Cargue,
					R.AnnoGrupoAnual,
					R.IDPrueba
					FROM dbo.ResultadosNivelometro AS r
					WHERE r.IdGrupo = @IDGrupo
					AND r.AnnoGrupoAnual = @AnnoGrupoAnual
		
					SET @Niv= (SELECT @@ROWCOUNT);

					SET @nombreTabla = CONCAT('HistoricosNivelometro_',@AnnoGrupoAnual)
					/*CREACION TABLA TEMPORAL PARA RESULTADOS AÑO GRUPO ANUAL*/
					IF NOT EXISTS (SELECT * FROM sysobjects where name = @nombreTabla AND xtype='U')
					BEGIN
						EXECUTE ('SELECT IDPruebaTipo ,IdPruebaEncabezado ,IdEstudiante ,Anno,Codigo_Grupo ,Grado ,Estudiante ,Salon ,Prueba ,Cie,
					Mat,	Esp,	Soc,	Ing,	Qui,	Fis,	Fil,	Mat2,	Ciu,	CTS, Def ,Respuestas ,EnviadoAlumno ,strMensaje ,FechaCreacion ,IdGrupo ,Cargue ,AnnoGrupoAnual ,IDPrueba INTO ' + @nombreTabla +  ' FROM dbo.ResultadosNivelometro AS r WHERE r.IdGrupo = '+ @IDGrupo  + ' AND r.AnnoGrupoAnual = ' + @AnnoGrupoAnual  )
					END
					ELSE
					BEGIN 
						EXECUTE ('INSERT INTO ' + @nombreTabla + '(IDPruebaTipo,IdPruebaEncabezado,IdEstudiante,Anno,Codigo_Grupo,Grado,Estudiante ,Salon,Prueba,Cie,
						Mat,	Esp,	Soc,	Ing,	Qui,	Fis,	Fil,	Mat2,	Ciu,	CTS, Def,Respuestas,EnviadoAlumno,strMensaje,FechaCreacion,IdGrupo,Cargue,AnnoGrupoAnual,IDPrueba)  
						SELECT 	r.IdPruebatipo, R.IdPruebaEncabezado, R.IdEstudiante,R.Anno, R.Codigo_Grupo, R.Grado, R.Estudiante, R.Salon, R.Prueba,R.Cie,	R.Mat,	R.Esp,	R.Soc,	R.Ing,	R.Qui,	R.Fis,	R.Fil,	R.Mat2,	R.Ciu,	R.CTS,R.Def, R.Respuestas,R.EnviadoAlumno,R.strMensaje,
						R.FechaCreacion,R.IdGrupo,R.Cargue,	R.AnnoGrupoAnual,R.IDPrueba	FROM dbo.ResultadosNivelometro AS r	WHERE r.IdGrupo = '+ @IDGrupo  + ' AND r.AnnoGrupoAnual = ' + @AnnoGrupoAnual  )
					END
				END TRY
				BEGIN CATCH
					SET @MensajeError = CONCAT('Error en Registro y paso de Nivelometros: ' ,ERROR_MESSAGE())
					RAISERROR(@MensajeError,16,1)
					RETURN
				END CATCH

				BEGIN TRY
					DELETE FROM dbo.ResultadosNivelometro 
					WHERE IdGrupo = @IDGrupo
					AND AnnoGrupoAnual = @AnnoGrupoAnual
				END TRY
				BEGIN CATCH
					SET @MensajeError = 'Eliminación en Nivelometros Erróneo. Contacte al Administrador.'
					RAISERROR(@MensajeError,16,1)
					RETURN
				END CATCH
			END

			/*PENSARES*/
			IF EXISTS(SELECT r.IDResultado FROM dbo.Pensares AS r WHERE r.IdGrupo = @IDGrupo AND r.AnnoGrupoAnual = @AnnoGrupoAnual )
			BEGIN
				BEGIN TRY 
					INSERT INTO [BD_CUBORESULTADOS].DBO.Resultados (IDPruebaTipo,PuestoN,PuestoC,Anno_Paquete,Anno_Estudiante,Calendario,IdPruebaEncabezado,IdEstudiante,Codigo_Grupo,Grado,Estudiante ,Salon,Prueba,Cie,Mat,Esp,Soc,Ing,Qui,Fis,Fil,Mat2,Ciu,CTS,Def,Respuestas,EnviadoAlumno,strMensaje,FechaCreacion,IdGrupo,Cargue,AnnoGrupoAnual,IDPrueba)
					SELECT
					R.IDPruebaTipo AS IdPruebaTipo,
					NULL AS PuestoN, 
					NULL AS PuestoC,
					R.anno Anno_Paquete
					,(SELECT e.Anno FROM dbo.Estudiante AS e WHERE e.IdEstudiante = r.IdEstudiante AND e.Grado = r.Grado AND e.Salon = r.Salon) Anno_Estudiante
					,(SELECT g.Calendario FROM dbo.Grupo AS g WHERE g.IdGrupo = r.IdGrupo) Calendario
					, R.IdPruebaEncabezado, R.IdEstudiante, R.Codigo_Grupo, R.Grado, R.Estudiante, R.Salon, R.Prueba, 
					R.Cie,
					R.Mat,
					R.Esp,
					R.Soc,
					R.Ing,
					R.Qui,
					R.Fis,
					R.Fil,
					R.Mat2,
					R.Ciu,
					R.CTS, 
					R.Def, 
					R.Respuestas,
					R.EnviadoAlumno,
					R.strMensaje,
					R.FechaCreacion,
					R.IdGrupo,
					R.Cargue,
					R.AnnoGrupoAnual,
					R.IDPrueba
					FROM dbo.Pensares AS r
					WHERE r.IdGrupo = @IDGrupo
					AND r.AnnoGrupoAnual = @AnnoGrupoAnual

					SET @Pen = (SELECT @@ROWCOUNT);

					SET @nombreTabla = CONCAT('HistoricoPensares_',@AnnoGrupoAnual)
					/*CREACION TABLA TEMPORAL PARA RESULTADOS AÑO GRUPO ANUAL*/
					IF NOT EXISTS (SELECT * FROM sysobjects where name = @nombreTabla AND xtype='U')
					BEGIN
						EXECUTE ('SELECT IDPruebaTipo ,IdPruebaEncabezado ,IdEstudiante ,Anno,Codigo_Grupo ,Grado ,Estudiante ,Salon ,Prueba ,Cie,Mat,Esp,Soc,Ing,Qui,Fis,Fil,Mat2,Ciu,CTS,Def ,Respuestas ,EnviadoAlumno ,strMensaje ,FechaCreacion ,IdGrupo ,Cargue ,AnnoGrupoAnual ,IDPrueba INTO ' + @nombreTabla +  ' FROM dbo.Pensares AS r WHERE r.IdGrupo = '+ @IDGrupo  + ' AND r.AnnoGrupoAnual = ' + @AnnoGrupoAnual )
					END
					ELSE
					BEGIN 
						EXECUTE ('INSERT INTO ' + @nombreTabla + '(IDPruebaTipo,IdPruebaEncabezado,IdEstudiante,Anno,Codigo_Grupo,Grado,Estudiante ,Salon,Prueba,Cie,Mat,Esp,Soc,Ing,Qui,Fis,Fil,Mat2,Ciu,CTS,Def,Respuestas,EnviadoAlumno,strMensaje,FechaCreacion,IdGrupo,Cargue,AnnoGrupoAnual,IDPrueba)  
						SELECT 	r.IdPruebatipo, R.IdPruebaEncabezado, R.IdEstudiante,R.Anno, R.Codigo_Grupo, R.Grado, R.Estudiante, R.Salon, R.Prueba,R.Cie,R.Mat,R.Esp,R.Soc,R.Ing,R.Qui,R.Fis,R.Fil,R.Mat2,R.Ciu,R.CTS,R.Def,R.Respuestas,R.EnviadoAlumno,R.strMensaje,
						R.FechaCreacion,R.IdGrupo,R.Cargue,	R.AnnoGrupoAnual,R.IDPrueba	FROM dbo.Pensares AS r	WHERE r.IdGrupo = '+ @IDGrupo  + ' AND r.AnnoGrupoAnual = ' + @AnnoGrupoAnual )
					END
				END TRY
				BEGIN CATCH
					SET @MensajeError = CONCAT('Error en Registro y paso de Pensares: ' ,ERROR_MESSAGE())
					RAISERROR(@MensajeError,16,1)
					RETURN
				END CATCH

				/*ELIMINACION DE PENSARES*/
				BEGIN TRY
					DELETE FROM dbo.Pensares 
					WHERE IdGrupo = @IDGrupo
					AND AnnoGrupoAnual = @AnnoGrupoAnual
				END TRY
				BEGIN CATCH
					SET @MensajeError = 'Eliminación en Pensares Erróneo. Contacte al Administrador.'
					RAISERROR(@MensajeError,16,1)
					RETURN
				END CATCH
			END

			/*ELIMINACION DE ESTUDIANTES
			======================================================================*/
			BEGIN TRY 
				DELETE FROM dbo.Estudiante 
				WHERE  IDGrupo =@IDGrupo 
				AND Anno=@AnnoGrupoAnual
			END TRY
			BEGIN CATCH
				SET @MensajeError = CONCAT('Eliminación de Estudiantes Erróneo. Contacte al Administrador. ' ,ERROR_MESSAGE())
				RAISERROR(@MensajeError,16,1)
				RETURN
			END CATCH


			/*REGISTRO DE LA TRAZABILIDAD EN HISTORICOLOGSRESULTADOS*/
			INSERT INTO BD_MARTESDEPRUEBA.dbo.HistoricoLogsResultados(IDGrupo,AnnoGrupoAnual,Mensajes,PasoAAMO,PasoCuboResultados,PasoHistoricoResultados,Res,Res1,Res2,Ciu,Pen,Sab,ResMMP,Niv,TotalEstudiantesCubo)
			SELECT 
			@IDGrupo,@AnnoGrupoAnual,'Ejecución realizada con éxito',1,1,1,@Res,@Res1,@Res2,@Ciu,@Pen,@Sab,@ResMMP,@Niv,@TotalEstud

			/*ACTUALIZACION DE MENSAJE y PROCESADO CORRECTAMENTE EN AAMO*/
			UPDATE BD_MARTESDEPRUEBA.dbo.GrupoAnual 
			SET Procesado = 1
			,MensajePasoHistorico='Ejecución realizada con éxito' 
			WHERE IdGrupo=@IDGrupo 
			AND Anno=@AnnoGrupoAnual AND Estado=0

			/*ACTUALIZACION DE MENSAJE y PROCESADO CORRECTAMENTE EN SMART*/
			UPDATE BD_MAESTRA.dbo.ColegioAnual 
			SET MensajePasoHistorico='Ejecución realizada con éxito'
			,Procesado = 1
			,FechaProcesado = GETDATE()
			WHERE  Anno=@AnnoGrupoAnual 
			AND IDEstado=1

		COMMIT
	END TRY
	BEGIN CATCH
			SELECT 'Error en el paso a Históricos no se completo el proceso, Error: ',CONCAT(@MensajeError, ERROR_MESSAGE(),' Línea: ',ERROR_LINE()),ERROR_PROCEDURE()
			ROLLBACK;

			INSERT INTO BD_MARTESDEPRUEBA.dbo.HistoricoLogsResultados
				(IDGrupo,AnnoGrupoAnual,Mensajes)
				SELECT 
				@IDGrupo,@AnnoGrupoAnual,@MensajeError

			/*ACTUALIZACION DE MENSAJE DE ERROR EN GRUPOANUAL*/
			UPDATE BD_MARTESDEPRUEBA.dbo.GrupoAnual 
			SET MensajePasoHistorico=CONCAT('Error en el paso a Históricos no se completo el proceso, Error: ' , @MensajeError, ERROR_MESSAGE(),' Línea: ',ERROR_LINE(),ERROR_PROCEDURE()) 
			WHERE IdGrupo=@IDGrupo 
			AND Anno=@AnnoGrupoAnual 
			AND Estado=0

			/*ACTUALIZACION DE MENSAJE DE ERROR EN GRUPOANUAL*/
			UPDATE BD_MAESTRA.dbo.ColegioAnual
			SET MensajePasoHistorico=CONCAT('Error en el paso a Históricos no se completo el proceso, Error: ' , @MensajeError, ERROR_MESSAGE(),' Línea: ',ERROR_LINE(),ERROR_PROCEDURE())
			WHERE  Anno=@AnnoGrupoAnual 
			AND IDEstado=1
	END CATCH

END
	
GO
