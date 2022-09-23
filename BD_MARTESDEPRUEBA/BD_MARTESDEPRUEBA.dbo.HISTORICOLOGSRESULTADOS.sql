SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER TABLE [dbo].[HistoricoLogsResultados](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[IDGrupo] [int] NOT NULL,
	[AnnoGrupoAnual] [int] NOT NULL,
	[PasoAAMO] [bit] NOT NULL,
	[PasoHistoricoResultados] [bit] NOT NULL,
	[PasoCuboResultados] [bit] NOT NULL,
	[Mensajes] [varchar](4000) NULL,
	[FechaRegistro] [datetime] NOT NULL,
	[TotalEstudiantesCubo] [int] NULL,
	[Res] [int] NULL,
	[Res1] [int] NULL,
	[Res2] [int] NULL,
	[Ciu] [int] NULL,
	[Pen] [int] NULL,
	[Sab] [int] NULL,
	[ResMMP] [int] NULL,
	[Niv] [int] NULL,
	[TotalCuboResultado]  AS ((((((([Res]+[Res1])+[Res2])+[Ciu])+[Pen])+[Sab])+[ResMMP])+[Niv]),
 CONSTRAINT [PK_LogHistoricosResultados] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[HistoricoLogsResultados] ADD  CONSTRAINT [DF_LogHistoricosResultados_PasoAAMO]  DEFAULT ((0)) FOR [PasoAAMO]
GO
ALTER TABLE [dbo].[HistoricoLogsResultados] ADD  CONSTRAINT [DF_LogHistoricosResultados_PasoHistoricoResultados]  DEFAULT ((0)) FOR [PasoHistoricoResultados]
GO
ALTER TABLE [dbo].[HistoricoLogsResultados] ADD  CONSTRAINT [DF_LogHistoricosResultados_PasoCuboResultados]  DEFAULT ((0)) FOR [PasoCuboResultados]
GO
ALTER TABLE [dbo].[HistoricoLogsResultados] ADD  CONSTRAINT [DF_LogHistoricosResultados_FechaRegistro]  DEFAULT (getdate()) FOR [FechaRegistro]
GO
