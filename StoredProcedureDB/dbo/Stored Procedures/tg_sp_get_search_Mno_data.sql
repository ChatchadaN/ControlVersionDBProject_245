-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_search_Mno_data] 
	-- Add the parameters for the stored procedure here
	@lotno varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--select CASE
	--			WHEN MNo is null THEN ' '
	--			ELSE MNo
	--		END As Mno
	--from DBxDW.TGOG.MIX_HIST as mixhist
	----from OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144;User ID=LSI;Password=LSI;' ).[DBLSISHT].[dbo].[MIX_HIST] as mixhist
	--where HASUU_LotNo = @lotno


	select CASE
				WHEN MNo is null THEN ' '
				ELSE MNo
			END As Mno
			--,trasecdata.ETC1 as mno_standard
			--,mixhist.LotNo
	from DBxDW.TGOG.MIX_HIST as mixhist
    --inner join DBx.dbo.TransactionData as trasecdata on trasecdata.LotNo = @lotno
	where HASUU_LotNo = @lotno

END
