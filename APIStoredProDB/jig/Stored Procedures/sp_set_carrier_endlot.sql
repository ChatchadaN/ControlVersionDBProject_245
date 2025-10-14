-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_carrier_endlot]
	-- Add the parameters for the stored procedure here
		  @QRCode	AS VARCHAR(50) 
		, @MCNo		AS NVARCHAR(50) 
		, @OPNo		AS NVARCHAR(6) 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- ########## VERSION 001 ##########
	EXEC [APIStoredProVersionDB].[jig].[sp_set_carrier_endlot_001]
		@QRCode			= @QRCode	,
		@MCNo			= @MCNo		,
		@OPNo			= @OPNo		 
								 
	-- ########## VERSION 001 ##########
 
END
