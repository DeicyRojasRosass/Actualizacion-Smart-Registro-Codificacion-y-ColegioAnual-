--BD_MAESTRA.dbo.ANNO 

ALTER TABLE BD_MAESTRA.dbo.ANNO ADD  ActivoA bit NOT NULL CONSTRAINT [DF_Anno_ActivoA]  DEFAULT (0); 

ALTER TABLE BD_MAESTRA.dbo.ANNO ADD  ActivoB bit NOT NULL CONSTRAINT [DF_Anno_ActivoB]  DEFAULT (0); 

ALTER TABLE BD_MAESTRA.dbo.ANNO ADD  HistoricoA bit NOT NULL CONSTRAINT [DF_Anno_HistoricoA]  DEFAULT (0); 

ALTER TABLE BD_MAESTRA.dbo.ANNO ADD  HistoricoB bit NOT NULL CONSTRAINT [DF_Anno_HistoricoB]  DEFAULT (0); 

ALTER TABLE BD_MAESTRA.[dbo].[Anno] ADD Identificador INT IDENTITY(1,1); 

/*creación de la llave primaria*/ 
ALTER TABLE [dbo].[Anno] ADD   CONSTRAINT [PK_Anno] PRIMARY KEY(ID); 

GO 