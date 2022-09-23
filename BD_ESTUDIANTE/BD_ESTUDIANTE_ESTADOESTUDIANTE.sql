SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER TABLE [dbo].[EstadoEstudiante](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Nombre] [varchar](30) NOT NULL,
	[Orden] [tinyint] NOT NULL,
	[Activo] [bit] NOT NULL,
	[IDUsuarioRegistra] [int] NOT NULL,
	[FechaRegistro] [datetime] NOT NULL,
	[FechaActualizacion] [datetime] NULL,
 CONSTRAINT [PK_EstadoEstudiante] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[EstadoEstudiante] ADD  CONSTRAINT [DF_EstadoEstudiante_Activo]  DEFAULT ((0)) FOR [Activo]
GO
ALTER TABLE [dbo].[EstadoEstudiante] ADD  CONSTRAINT [DF_EstadoEstudiante_FechaRegistro]  DEFAULT (getdate()) FOR [FechaRegistro]
GO
