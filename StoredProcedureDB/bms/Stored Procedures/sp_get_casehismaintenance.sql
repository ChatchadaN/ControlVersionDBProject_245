-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [bms].[sp_get_casehismaintenance]
	-- Add the parameters for the stored procedure here
	@problem varchar(25) = 'ALARM 11'
	-- 0 = all,1 = sop,2 = small
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	 select ROW_NUMBER() OVER(ORDER BY ID desc) AS RowId ,* from Dbx.dbo.BMMaintenance where 
     ID in (SELECT BM_ID FROM [DBx].[dbo].[BMPM6Detail] UNION ALL 
     SELECT BM_ID FROM [DBx].[dbo].[BMTEDetail] UNION ALL 
     SELECT BM_ID FROM [DBx].[dbo].[BMPM8Detail]) 
     and BMMaintenance.ID in ( select Top 10 ID from (  select ID from Dbx.dbo.BMMaintenance where problem like @problem                 
     Union All select ID from Dbx.dbo.BMMaintenance where problem like @problem) 
     AS XXXX group by ID order by ID Desc ) 
END
