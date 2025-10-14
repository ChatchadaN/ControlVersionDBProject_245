-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_carrier_check]
	-- Add the parameters for the stored procedure here
		  @QRCode	AS VARCHAR(50) 
		 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- ########## VERSION 001 ##########
	EXEC [APIStoredProVersionDB].[jig].[sp_get_carrier_check_001]
		 @QRCode			= @QRCode	 
	  
	-- ########## VERSION 001 ##########
 
END
