-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_temporary_location] 
	-- Add the parameters for the stored procedure here
	@process VARCHAR(30) 
	,@package VARCHAR(30) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT 
CASE
    WHEN @process in ( 'DB','WB') THEN 'A01'
	WHEN @process in ( 'MP','TC') THEN 'C02'
	WHEN @process in ( 'PL','XRAY') THEN 'B02'
	WHEN @process in ( 'FL','FT','TP','OG')  THEN
		CASE @package
		----- SOP ------
		WHEN 'SOP20' THEN 'C01'
		WHEN 'SOP22' THEN 'C01'
		WHEN 'SOP24' THEN 'C01'
		WHEN 'SOP24-HF' THEN 'C01'
		WHEN 'SSOP-A20' THEN 'C01'
		WHEN 'SSOP-A24' THEN 'C01'
		WHEN 'SSOP-A32' THEN 'C01'
		WHEN 'SSOP-B24' THEN 'C01'
		WHEN 'SSOP-B28' THEN 'C01'
		WHEN 'SSOP-B40' THEN 'C01'
		WHEN 'HSOP-M36' THEN 'C01'
		WHEN 'TSSOP-B30' THEN 'C01'
		------ SMALL --------
		WHEN 'HSON-A8' THEN 'C01'
		WHEN 'HSON8' THEN 'C01'
		WHEN 'HSON8-HF' THEN 'C01'
		WHEN 'HVSOF5' THEN 'C01'
		WHEN 'HVSOF6' THEN 'C01'
		WHEN 'HVSOF6-HF' THEN 'C01'
		WHEN 'MSOP10' THEN 'C01'
		WHEN 'MSOP8' THEN 'C01'
		WHEN 'MSOP8-HF' THEN 'C01'
		WHEN 'SOP4' THEN 'C01'
		WHEN 'SOP4-HF' THEN 'C01'
		WHEN 'SSOP6' THEN 'C01'
		WHEN 'TSSOP-B8J' THEN 'C01'
		WHEN 'TSSOP-C10J' THEN 'C01'
		WHEN 'VSOF5' THEN 'C01'
		WHEN 'WSOF5' THEN 'C01'
		WHEN 'WSOF6' THEN 'C01'
		WHEN 'WSOF6I' THEN 'C01'
		WHEN 'WSOP-L10' THEN 'C01'
		WHEN 'WSOP10-G1' THEN 'C01'
		------ POWER --------
		WHEN 'HRP5' THEN 'C01'
		WHEN 'HRP7' THEN 'C01'
		WHEN 'SDIP18' THEN 'C01'
		WHEN 'SDIP22' THEN 'C01'
		WHEN 'SIP9' THEN 'C01'
		WHEN 'SOT223-4' THEN 'C01'
		WHEN 'SOT223-4F' THEN 'C01'
		WHEN 'SOT223-5' THEN 'C01'
		WHEN 'TO220-6M' THEN 'C01'
		WHEN 'TO220-7M' THEN 'C01'
		WHEN 'TO252-3' THEN 'C01'
		WHEN 'TO252-5' THEN 'C01'
		WHEN 'TO252-J3' THEN 'C01'
		WHEN 'TO252-J5' THEN 'C01'
		WHEN 'TO252-J5F' THEN 'C01'
		WHEN 'TO252S-3' THEN 'C01'
		WHEN 'TO252S-3+' THEN 'C01'
		WHEN 'TO252S-5' THEN 'C01'
		WHEN 'TO252S-5+' THEN 'C01'
		WHEN 'TO252S-7+' THEN 'C01'
		WHEN 'TO263-3' THEN 'C01'
		WHEN 'TO263-3F' THEN 'C01'
		WHEN 'TO263-5' THEN 'C01'
		WHEN 'TO263-5F' THEN 'C01'
		WHEN 'TO263-7' THEN 'C01'
		WHEN 'TO263-7L' THEN 'C01'
		WHEN 'TO263-9' THEN 'C01'
		ELSE 'B01'
		END
    ELSE 'D01'
END AS RESULT
END
