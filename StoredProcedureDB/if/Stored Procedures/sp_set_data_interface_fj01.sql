-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [if].[sp_set_data_interface_fj01]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	------------------------------------------------------------------------------------
	---- # CLARE data
	------------------------------------------------------------------------------------
	DELETE FROM [APCSProDWH].[if].[v_cps_stk_temp];

	------------------------------------------------------------------------------------
	---- # INSERT CPS data
	------------------------------------------------------------------------------------
	INSERT INTO [APCSProDWH].[if].[v_cps_stk_temp]
	SELECT [LOTN] AS [lot_no] 
        , [TKEM] AS [device_name] 
        , [MZAS] AS [qty] 
        , CAST([NKJD] AS DATETIME) AS [updated_at] 
	FROM [IFDB].[dbo].[V_CPS_STK] 
	WHERE ([SHGC] = 10) 
		AND ([MZAS] >= 0);
END
