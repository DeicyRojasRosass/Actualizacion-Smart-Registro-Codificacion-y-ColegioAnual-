SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* =============================================
-- Author:		  Admin FS
-- Create date:   11-09-2015
-- Description:	  Carga las Notas desde el excel a cada tabla de resultados.
-- Update1: 29-05-2018, División tabla resultados/Resultados1 Grados 10°-11°.
=============================================
CONTROL DE CAMBIOS
=============================================
Fecha		: 12/09/2022
Responsable	: Reinel José Ochoa Quintero
Descripción	: Insercion de los campos IdPruebaTipo,AnnoGrupoAnual,IdPrueba en las diferentes tablas de Resultados.
=============================================
*/

CREATE OR ALTER  TRIGGER [dbo].[Trig_Insert_Resultados] ON [dbo].[V_SubirResultados] --FOR EACH --ROW 
INSTEAD OF INSERT
AS

 DECLARE    
	  
	  -- Son los que trae del webservis (Excel)
	  @Anno_Estudiante int,
	  @Codigo_grupo int,
	  @Grado int,
	  @Salon nvarchar(1),
	  @Estudiante int,

	  @Prueba int,
	  @Anno_prueba int,
	  @Respuestas nvarchar(max),
	  @CantRespuestasEstudiante int,
	  
	  @UserId  uniqueidentifier,

	  @Sesion int,
	  @Cargue nvarchar(5),
	  @Tiempo  nvarchar(50),


	  -- Envio de correos
	  @Enviadoalumno nvarchar(1),

	  -- Datos Consultados
	  @IdGrupo int,
	  @Calendario nvarchar(2),
	  @IdEstudiante int,
	  @IdFuncionario int,

	   -- Datos calculados
	  @Enviar int,
	  @Mensaje nvarchar(2000),

	  -- Datos de verificación del Funcionario	  	  	  
	  @Regional_Grupo int,
	  @Regional_Funcionario int,
	  @Permisos_Funcionario bit,
	  @Validar_Respuestas bit,

	  -- @Validar_Sesion int,

	  -- Datos de verificación de la Prueba-Paquete Año
	  
	  @IdPruebaEncabezado int,
	  @IdPruebaTipo int,
	  @IdPrueba int,
	  @Idpaquete int,
	  @NroPreguntas int,
	
	  -- Datos de verificación de la Tabla 
	  @ExisteResultados int,
	

	  -- Datos de verificación de Grupo-Anual
	  @AnnoGrupoAnual int,
	  @CalendarioGrupoAnual nvarchar(2),
	  @EstadoGrupoAnual int;
	  

BEGIN

SET NOCOUNT ON;

	  BEGIN

	  SELECT @Anno_Estudiante=Anno_Estudiante, 
			 @Codigo_Grupo= Codigo_Grupo,
			 @Grado=grado,
			 @Salon=Salon,
			 @Estudiante=Estudiante, 
			 @Prueba= prueba, 
			 @Anno_Prueba = Anno_prueba, 
			 @Respuestas = respuestas, 
			 @CantRespuestasEstudiante= (Len(Respuestas)),
			 @UserId=UserId,
			 @Sesion=Sesion,
			 @Cargue=Cargue,
			 @Tiempo=Tiempo
			 FROM inserted;

	 SELECT @IdFuncionario=id FROM Funcionario WHERE UserId=@UserId;

	  Set @Permisos_Funcionario = 'FALSE';
	  Set @IdPruebaEncabezado = 0;
	  Set @NroPreguntas = 0;
	  Set @Validar_Respuestas = 1;

	  Set @Enviadoalumno = 'N';

	 SELECT @IdGrupo = g.IdGrupo,@Regional_Grupo = g.Cod_Regional,@Calendario = g.Calendario FROM dbo.Grupo AS g WHERE g.Activo = 2 AND g.Codigo = @Codigo_Grupo;
	 
	 SELECT 
	 @IdEstudiante = IdEstudiante
	 ,@Enviadoalumno='N'
	 FROM Estudiante 
	 WHERE Anno = @Anno_Estudiante 
	 AND IdGrupo = @IdGrupo 
	 AND Codigo_Grupo = @Codigo_Grupo 
	 AND Grado = @Grado 
	 AND Salon = @Salon 
	 AND Estudiante = @Estudiante
     
	 SELECT 
	 @IdPruebaEncabezado = IdPruebaencabezado
	 ,@IdPruebaTipo = IdPruebaTipo
	 ,@IdPrueba=idPrueba
	 ,@IdPaquete=idPaquete
	 ,@NroPreguntas=NroPreguntas 
	 FROM dbo.FN_LTS_Resultados_Datos_Prueba(@Anno_Prueba, @Prueba, @Grado)

 	 SELECT @Regional_Funcionario = Idregional FROM Regional_Funcionario WHERE Idfuncionario IN (SELECT Id FROM Funcionario WHERE id = @IdFuncionario) AND IdRegional=@Regional_Grupo  AND IdCargo=5;
   -- Verifica con la Tabla Grupo Anual, estado del colegio para el año y Calendario
	SELECT @AnnoGrupoAnual = Anno, @CalendarioGrupoAnual = @Calendario, @EstadoGrupoAnual = Estado FROM GrupoAnual WHERE idgrupo=@IdGrupo AND Estado=1 

	IF (@AnnoGrupoAnual <> @Anno_Estudiante)
	 BEGIN 
		   RAISERROR ('$|$USER_MSG$|$ADVERTENCIA$|$ GA 000: El año del estudiante No esta activo para recibir cargues. Revizar la opción de "Activar año Calendario".$|$',16,1);
		RETURN;
	END

	IF (@Regional_Grupo = @Regional_Funcionario)
	BEGIN 
		SET @Permisos_Funcionario = 'True'
	END  

	-- Saberes(5) y Simualcros(2)
	IF @IdPruebaTipo IN (5,2) AND LEN(@Respuestas)= LEN(@Respuestas) - LEN(REPLACE(@Respuestas, 'N', ''))
	BEGIN
		SET @Validar_Respuestas = 0
	END 

    IF (@IdPruebaTipo NOT IN (5,2)) AND LEN(@Respuestas)<>LEN(REPLACE(@Respuestas, 'N', ''))
	BEGIN
	  SET @Validar_Respuestas = 0
	END 

	--IF @IdPruebaTipo=2 and @Sesion Not In (0,1,2)
	--BEGIN
	 -- SET @Validar_Sesion=0;
	--END

	IF @Sesion =''  OR @Sesion IS NULL
	BEGIN
		Set @Sesion=0;
	END
	
	SELECT @ExisteResultados = [dbo].[FN_Verificar_Resultados_IdEstudiante](@IdPruebaTipo,@IdPrueba,@Idgrupo,@Grado,@Idestudiante);
	
	IF (@Permisos_Funcionario = 1 AND  @IdGrupo IS NOT NULL AND  (@IdEstudiante IS NOT NULL) AND @IdPruebaTipo > 0 AND  @IdPruebaEncabezado is not null and  @IdPrueba IS NOT NULL AND @ExisteResultados=0)  AND @Validar_Respuestas= 1
	BEGIN

	-- Martes de Prueba
	IF (@IdPruebaTipo = 1 )
	BEGIN
	   IF (@Grado IN (10,11))
	   BEGIN
			INSERT INTO  [dbo].[Resultados1] -- Martes de Prueba, Grados (10° a 11°)
			(IdGrupo, Codigo_Grupo, IdEstudiante, Grado, Salon, Estudiante, Anno, IdPruebaEncabezado, prueba, Respuestas, EnviadoAlumno, IdFuncionario,Sesion,Cargue,Tiempo,IDPruebaTipo,AnnoGrupoAnual,IDPrueba) 
			VALUES (@Idgrupo,  @Codigo_Grupo,@IdEstudiante, @Grado, @Salon, @Estudiante, @Anno_Prueba, @IdPruebaEncabezado, @prueba, @Respuestas,@EnviadoAlumno, @IdFuncionario,@Sesion,@Cargue,@Tiempo,@IdPruebaTipo,@AnnoGrupoAnual,@IdPrueba)  
		END ELSE
		BEGIN
			INSERT INTO dbo.Resultados(IdGrupo,Codigo_Grupo,IdEstudiante,Grado,Salon,Estudiante,Anno,IdPruebaEncabezado,prueba,Respuestas,EnviadoAlumno,IdFuncionario,Sesion,Cargue,Tiempo,IDPruebaTipo,AnnoGrupoAnual,IDPrueba)
			VALUES (@Idgrupo,@Codigo_Grupo,@IdEstudiante,@Grado,@Salon,@Estudiante,@Anno_Prueba,@IdPruebaEncabezado,@prueba,@Respuestas,@EnviadoAlumno,@IdFuncionario,@Sesion,@Cargue,@Tiempo,@IdPruebaTipo,@AnnoGrupoAnual,@IdPrueba)  
		END
	 END 
 
	 IF (@IdPruebaTipo = 2)-- and @Validar_Sesion=1 -- Simulacros
	 BEGIN	
		IF(@Sesion IN (0,1))
		BEGIN
			Insert Into [dbo].[Resultados2]
			(IdGrupo, IdEstudiante, IdPruebaEncabezado, Anno, Codigo_Grupo, Grado, Salon, Estudiante, prueba, Respuestas, EnviadoAlumno, IdFuncionario,Sesion,Cargue,Tiempo,IDPruebaTipo,AnnoGrupoAnual,IDPrueba)
			Values (@Idgrupo, @IdEstudiante, @IdPruebaEncabezado, @Anno_Prueba, @Codigo_Grupo, @Grado, @Salon, @Estudiante, @prueba, @Respuestas, @EnviadoAlumno, @IdFuncionario,@Sesion,@Cargue,@Tiempo,@IdPruebaTipo,@AnnoGrupoAnual,@IDPrueba)
		END

		If(@Sesion = 2) --Update
		BEGIn
			UPDATE [dbo].[Resultados2] SET Def=NULL, Respuestas=Concat(Respuestas,@Respuestas),Sesion=0
			WHERE IdGrupo=@IdGrupo AND Grado=@Grado AND Salon=@Salon AND Estudiante=@Estudiante AND Prueba=@Prueba and Sesion=1
		END
	END 

	 IF (@IdPruebaTipo = 10) -- Ser Más Digital
	 BEGIN
		 Insert Into [dbo].[Resultados_SerMasDigital]
			       (IdGrupo, IdEstudiante, IdPruebaEncabezado, Anno, Codigo_Grupo, Grado, Salon, Estudiante, prueba, Respuestas, EnviadoAlumno, IdFuncionario)
			Values (@Idgrupo, @IdEstudiante, @IdPruebaEncabezado, @Anno_Prueba, @Codigo_Grupo, @Grado, @Salon, @Estudiante, @prueba, @Respuestas, @EnviadoAlumno, @IdFuncionario)
	 END 

     IF (@IdPruebaTipo = 3) --Ciudadanas
	 BEGIN
	     INSERT INTO [dbo].[Ciudadanas]
                (IdGrupo, IdEstudiante, IdPruebaEncabezado, Anno, Codigo_Grupo, Grado, Salon, Estudiante, prueba, Respuestas, EnviadoAlumno, IdFuncionario,Sesion,Cargue,Tiempo) 
		 VALUES (@Idgrupo, @IdEstudiante, @IdPruebaEncabezado, @Anno_Prueba, @Codigo_Grupo, @Grado, @Salon, @Estudiante, @prueba, @Respuestas, @EnviadoAlumno, @IdFuncionario,@Sesion,@Cargue,@Tiempo)
      END 

	IF (@IdPruebaTipo = 4) --Mi Primer Martes de Prueba
	BEGIN
		 INSERT INTO [dbo].[Resultados_MMP]
		        (IdGrupo, IdEstudiante, IdPruebaEncabezado, Anno, Codigo_Grupo, Grado, Salon, Estudiante, prueba, Respuestas,EnviadoAlumno, IdFuncionario,Sesion,Cargue,Tiempo) 
		 VALUES (@Idgrupo, @IdEstudiante, @IdPruebaEncabezado, @Anno_Prueba, @Codigo_Grupo, @Grado, @Salon, @Estudiante, @prueba, @Respuestas, @EnviadoAlumno, @IdFuncionario,@Sesion,@Cargue,@Tiempo)
	END 

	IF (@IdPruebaTipo = 5)  -- Saberes
	BEGIN
		 INSERT INTO [dbo].[Saberes]
		         (IdGrupo, IdEstudiante, IdPruebaEncabezado, Anno, Codigo_Grupo, Grado, Salon, Estudiante, prueba, Respuestas,EnviadoAlumno, IdFuncionario,Sesion,Cargue,Tiempo) 
		  VALUES (@Idgrupo, @IdEstudiante, @IdPruebaEncabezado, @Anno_Prueba, @Codigo_Grupo, @Grado, @Salon, @Estudiante, @prueba, @Respuestas,@EnviadoAlumno, @IdFuncionario,@Sesion,@Cargue,@Tiempo)
	END 

	IF (@IdPruebaTipo = 6 ) -- Integradas
	BEGIN
		Set @Validar_Respuestas=0;
	END 
 
	IF (@IdPruebaTipo = 7) -- Pensares
	BEGIN
		INSERT INTO [dbo].[Pensares]
		(Anno, IdPruebaEncabezado, IdEstudiante, IdGrupo, Codigo_Grupo, Grado, Salon, Estudiante, prueba, Respuestas, EnviadoAlumno, IdFuncionario,Sesion,Cargue,Tiempo) 
		VALUES (@Anno_Prueba, @IdPruebaEncabezado, @IdEstudiante, @Idgrupo,  @Codigo_Grupo, @Grado, @Salon, @Estudiante, @prueba, @Respuestas,@EnviadoAlumno, @IdFuncionario,@Sesion,@Cargue,@Tiempo)  
	END 
 END

ELSE
BEGIN

	IF (@IdEstudiante IS NULL OR  @IdEstudiante = 0)
	BEGIN 
	    RAISERROR ('$|$USER_MSG$|$ADVERTENCIA$|$ Error 001:(Estudiante no existe). $|$',16,1);
	RETURN;
	END
	
	IF (@Permisos_Funcionario = 0)
	Begin 
	     RAISERROR ('$|$USER_MSG$|$ADVERTENCIA$|$ Error 002:(No tiene permisos el Usuario sobre la Regional). $|$',16,1);
	RETURN;
	END

	IF (@IdGrupo IS NULL OR @IdGrupo = 0)
	BEGIN 
	    RAISERROR ('$|$USER_MSG$|$ADVERTENCIA$|$ Error 003:(Código Colegio ó Plantel) No existe. $|$',16,1);
	RETURN;
	END

	IF  (@IdPruebaEncabezado = 0 OR  @IdPrueba = 0  AND @IdPruebaTipo = 0 OR @IdPaquete = 0)
	BEGIN 
	    RAISERROR ('$|$USER_MSG$|$ADVERTENCIA$|$ Error 004:(Prueba-grado ó Prueba-Año / Paquete) No existe. $|$',16,1);
	RETURN;
	END
			
	IF (@ExisteResultados > 0)
	BEGIN 
	    RAISERROR ('$|$USER_MSG$|$ADVERTENCIA$|$ Error 005:(Ya tiene Notas, ver Prueba-año). $|$',16,1);
	RETURN;
	END
	
	IF (@CantRespuestasEstudiante <> @NroPreguntas)
	BEGIN 
	    RAISERROR ('$|$USER_MSG$|$ADVERTENCIA$|$ Error 006:(No coincide la cantidad de Respuestas VS Nro de Preguntas de la Prueba-Año). $|$',16,1);
	RETURN;
	END

	IF (@IdPruebaTipo = 5 AND @Validar_Respuestas=0)
	BEGIN 
	    RAISERROR ('$|$USER_MSG$|$ADVERTENCIA$|$ Error 007:(No presentó ninguna materia, respuestas en NNN). $|$',16,1);
	RETURN;
	END

	IF (@IdPruebaTipo NOT IN (5,2) AND @Validar_Respuestas=0)
	BEGIN 
	    RAISERROR ('$|$USER_MSG$|$ADVERTENCIA$|$ Error 008:(Hay respuestas en NNN, Exlcusivas de Saberes). $|$',16,1);
	RETURN;
	END
	
	IF (@IdPruebaTipo = 6 AND @Validar_Respuestas=0)
	BEGIN 
	    RAISERROR ('$|$USER_MSG$|$ADVERTENCIA$|$ Error 009:(IdPruebatipo=6) No permite el cargue de Integradas. $|$',16,1);
	RETURN;
	END

	
	--IF (@IdPruebaTipo = 2 AND @Validar_Sesion=0)
	--BEGIN 
	--    RAISERROR ('$|$USER_MSG$|$ADVERTENCIA$|$ Error 010:(IdPruebatipo=2) El valor de la Sesión no es valido $|$',16,1);
	--RETURN;
	--END



	END

    
	
	END  
	
 END





	
GO
