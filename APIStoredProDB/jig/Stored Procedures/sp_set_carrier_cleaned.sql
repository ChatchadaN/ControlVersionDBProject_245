-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_carrier_cleaned]
	-- Add the parameters for the stored procedure here
		  @QRCode	AS VARCHAR(50)  
		, @OPNo		AS VARCHAR(10)  
		, @MCNo		AS VARCHAR(50)	=  NULL
		, @Status	AS VARCHAR(50) 	=  NULL--0 Appearance ,  1 Cleanliness 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- ########## VERSION 001 ##########
	EXEC [APIStoredProVersionDB].[jig].[sp_set_carrier_cleaned_001]
		 @QRCode	= @QRCode	,
		 @OPNo		= @OPNo		,
		 @MCNo		= @MCNo		,
		 @Status	= @Status
								 
	-- ########## VERSION 001 ##########
 
END
