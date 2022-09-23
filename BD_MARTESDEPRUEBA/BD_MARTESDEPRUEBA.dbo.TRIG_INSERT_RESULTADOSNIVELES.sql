SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* =============================================
-- Author:		  Fabio Alexander Doncel L.
-- Create date:   13- abril -2016 : Se crea temporalmente
-- update :       7- Febrero - 2017 : Queda pendiente probar prueba de niveles de la 9 a la 14. Cadena Respuesta mas long.
-- Description:	  Carga las Notas desde el excel Niveles
=============================================
CONTROL DE CAMBIOS
=============================================
Fecha		: 12/09/2022
Responsable	: Reinel José Ochoa Quintero
Descripción	: Insercion de los campos IdPruebaTipo,AnnoGrupoAnual,IdPrueba en las diferentes tablas de Resultados.
=============================================
*/

CREATE OR ALTER  TRIGGER [dbo].[Trig_Insert_ResultadosNiveles] ON [dbo].[V_SubirResultadosNiveles] --FOR EACH --ROW 
instead of insert
 -- instead of insert
   --Update 
 -- instead of  Update 
 -- after insert
AS

 Declare    
	  -- Son los que trae del webservis (Excel)
	  @Anno_Estudiante int,
	  @Codigo_grupo int,
	  @Grado int,
	  @Salon int,
	  @Estudiante int,

	  @Prueba int,
	  @Anno_prueba int,
	  @Respuestas nvarchar(max),
	  @GradoPrueba int,
	  @CantidadRespuestas int,
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
	  @Fecha date,
	  @Enviar int,
	  @Mensaje nvarchar(2000),

	  -- Datos de verificación del Funcionario	  	  	  
	  @Regional_Grupo int,
	  @Regional_Funcionario int,
	  @Permisos_Funcionario bit,
	  @Validar_Respuestas bit,

	  -- Datos de verificación de la Prueba-Paquete Año
	  
	  @IdPruebaEncabezado int,
	  @IdPruebaTipo int,
	  @IdPrueba int,
	  @NroPreguntas int,
	
	  -- Datos de verificación de la Tabla 
	  @ExisteResultados int,
	

	  -- Datos de verificación de Grupo-Anual
	  @AnnoGrupoAnual int,
	  @CalendarioGrupoAnual nvarchar(2),
	  @EstadoGrupOAnual int;
	  

BEGIN

SET NOCOUNT ON;

	  BEGIN

	--RAISERROR ('$|$USER_MSG$|$ADVERTENCIA$|$ @UserId $|$',16,1);

  Select @Anno_Estudiante=Anno_Estudiante, @Codigo_Grupo= Codigo_Grupo,@Grado=grado,@Salon=Salon,@Estudiante=Estudiante, 
      @Prueba= prueba, @Anno_Prueba = Anno_prueba, @Respuestas = respuestas, @GradoPrueba=GradoPrueba, @CantidadRespuestas= (Len(Respuestas)), @UserId=UserId,
  	  @Sesion =Sesion,	  @Cargue =Cargue,	  @Tiempo =Tiempo

  from inserted

	-- @UserId=UserId
	-- Set @UserId='51D13F52-2529-49F9-9D4C-73FB12D673CD';

	 Select @IdFuncionario=id From Funcionario where UserId=@UserId;

	  Set @Permisos_Funcionario='False';
	  Set @IdPruebaEncabezado=0;
	  Set @Fecha= GETDATE();
	  Set @NroPreguntas=0;
	  Set @Validar_Respuestas=1;
	-- Consulta datos del Estudiante

	  Set @Enviadoalumno = 'N';

	--iif(Est_Correo_R=1 or Acu_Correo_R=1,'P','N ') --- envio de correos.

	 SELECT @IdEstudiante = IdEstudiante, @IdGrupo = IdGrupo , @Enviadoalumno=(iif(Est_Correo_R=1 or Aut_Terminos=1,'P','N')) FROM Estudiante WHERE Anno = @Anno_Estudiante AND Codigo_Grupo = @Codigo_Grupo AND Grado = @Grado AND Salon=@Salon AND Estudiante = @Estudiante;
	 -- se actualiza el campo Acu_Correo_R por el campo Aut_Terminos

	 SELECT @Regional_Grupo = Cod_Regional,@Calendario=Calendario FROM grupo WHERE  idGrupo = @IdGrupo AND codigo = @Codigo_Grupo;




     SELECT @IdPruebaEncabezado = IdPruebaencabezado, @IdPruebaTipo = IdPruebaTipo, @IdPrueba=idPrueba, @NroPreguntas=NroPreguntas 	FROM [dbo].[FN_LTS_Resultados_Datos_Prueba] (@Anno_Prueba, @Prueba, @GradoPrueba);
	
	 SELECT @Regional_Funcionario = Idregional FROM Regional_Funcionario WHERE Idfuncionario in(SELECT Id From Funcionario WHERE id = @IdFuncionario) and IdRegional=@Regional_Grupo  and IdCargo=5;

   -- Verifica con la Tabla Grupo Anual, estado del colegio para el año y Calendario

		SELECT @AnnoGrupoAnual=Anno, @CalendarioGrupoAnual=@Calendario,@EstadoGrupoAnual=Estado FROM grupoAnual WHERE idgrupo=@IdGrupo and Estado=1 

	  	IF (@AnnoGrupoAnual <> @Anno_Estudiante)
		BEGIN 
		   RAISERROR ('$|$USER_MSG$|$ADVERTENCIA$|$ GA 000: El año del estudiante No esta activo para recibir cargues. Revizar la opción de "Activar año Calendario".$|$',16,1);
		return;
		END

	If (@Regional_Grupo = @Regional_Funcionario)
	Begin 
		Set @Permisos_Funcionario='True'
	End  


	if @IdPruebaTipo=5 and LEN(@Respuestas)=LEN(@Respuestas) - LEN(REPLACE(@Respuestas, 'N', ''))
	Begin
	 Set @Validar_Respuestas=0
	End 

   if @IdPruebaTipo <> 5 and LEN(@Respuestas)<>LEN(REPLACE(@Respuestas, 'N', ''))
	Begin
	 Set @Validar_Respuestas=0
	End 

     -- Debe consultar en la tabla de resultados de acurdo al @IdPruebaTipo 
	 --- PARA QUE SUBA A LAS MALAS SIN CONTROL
	 Set @ExisteResultados = (select Count(*) from [ResultadosNivelometro] Where 1=1 and Anno=@Anno_Prueba and IdPruebaEncabezado=@IdPruebaEncabezado and IdEstudiante=@IdEstudiante and IdGrupo=@IdGrupo and Codigo_grupo=@Codigo_grupo and Grado=@Grado and Salon=@Salon and Estudiante=@Estudiante and Prueba= @Prueba)  -- Resultados,Resultados2 etc
	     --Set @IdEstudiante = 1

		 ---- END
  

    -- print(Concat('@@UserId :',@UserId))

    -- 	print  (concat('Cod Grupo : ',@Codigo_Grupo,' IdGrupo :',@IdGrupo,' Grado :',@Grado,' Salon :',@Salon,'Est :',@Estudiante, 'IdEs :',@IdEstudiante,'P :',@IdPruebaEncabezado))
	
	if  (@Permisos_Funcionario = 1 and  @IdGrupo is not null and  (@IdEstudiante is not null) and @IdPruebaTipo>0 and  @IdPruebaEncabezado is not null and  @IdPrueba is not null  and @ExisteResultados=0)  and @Validar_Respuestas= 1 --and @NroPreguntas=@CantidadRespuestas)
	
	BEGIN
	 -- Insert Into [dbo].[Resultados]
     --  (IdGrupo, IdEstudiante, IdPruebaEncabezado, Anno, Codigo_Grupo, Grado, Salon, Estudiante, prueba, Respuestas, IdFuncionario) 
	 --	 Values (@Idgrupo, @IdEstudiante, @IdPruebaEncabezado, @Anno_Prueba, @Codigo_Grupo, @Grado, @Salon, @Estudiante, @prueba, @Respuestas, @IdFuncionario)    
	 Insert Into [dbo].[ResultadosNivelometro]
       (Anno,IdPruebaEncabezado, IdEstudiante, codigo_grupo, grado, salon,estudiante,prueba, Respuestas,Enviadoalumno, IdFuncionario,Idgrupo,cargue,Sesion,Tiempo) 
		 Values (@Anno_prueba, @IdPruebaEncabezado, @IdEstudiante, @codigo_grupo, @grado, @salon, @estudiante, @prueba, @Respuestas,@Enviadoalumno, @IdFuncionario,@idGrupo,@Cargue,@sesion,@Tiempo)
	 END
	Else

	BEGIN


	IF (@IdEstudiante is null or  @IdEstudiante=0)
	Begin 
	    RAISERROR ('$|$USER_MSG$|$ADVERTENCIA$|$ Error 001: (Estudiante) Código del estudiante no Existe, $|$',16,1);
	return;
	end

	
	if @Permisos_Funcionario = 0
	Begin 
	     RAISERROR ('$|$USER_MSG$|$ADVERTENCIA$|$ Error 002: (No tine permisos el Usuario sobre la Regional). $|$',16,1);
	return;
	end



	if (@IdGrupo is null  or @IdGrupo=0 )
	Begin 
	    RAISERROR ('$|$USER_MSG$|$ADVERTENCIA$|$ Error 003: (Código colegio ó Plantel) No Existe. $|$',16,1);
	return;
	end

	if  @IdPruebaEncabezado =0 or  @IdPrueba =0  and @IdPruebaTipo=0
	Begin 


	    RAISERROR ('$|$USER_MSG$|$ADVERTENCIA$|$ Error 004:(Prueba-grado ó Prueba-Año / Paquete) No existe. $|$',16,1);
	return;
	end
			
	if (@ExisteResultados>0)
	Begin 
	    RAISERROR ('$|$USER_MSG$|$ADVERTENCIA$|$ Error 005:(Estudiante ya tiene Notas Prueba-Grado-Año). $|$',16,1);
	return;
	end

	
	if (@CantidadRespuestas<>@NroPreguntas)
	Begin 
	    RAISERROR ('$|$USER_MSG$|$ADVERTENCIA$|$ Error 006:(No coincide la cantidad de Respuestas VS Nro de Preguntas de la Prueba-Grado-Año). $|$',16,1);
	return;
	end

	if  (@Validar_Respuestas=0)
	Begin 
	    RAISERROR ('$|$USER_MSG$|$ADVERTENCIA$|$ Error 007:(No tiene Respuestas ). $|$',16,1);
	return;
	end

	



	END

    END  

	
 END



--BEGIN
 

    
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	--SET NOCOUNT ON;
    -- Insert statements for procedure here

	--http://www.codigomaestro.com/mssql/scripts-para-controlar-el-uso-de-memoria-de-sql-server-y-el-buffer-pool/
  
--END
--GO
GO
