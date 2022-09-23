SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[VW_ANNO_CONSULTA]
AS
SELECT
a.ID
,a.Nombre
,a.Activo
,a.IDUsuarioRegistra
,a.FechaRegistro
,a.IDUsuarioActualiza
,a.FechaActualizacion
,a.ActivoA
,a.ActivoB
,a.HistoricoA
,a.HistoricoB
,a.Identificador                 
FROM BD_MAESTRA.dbo.Anno a
GO
