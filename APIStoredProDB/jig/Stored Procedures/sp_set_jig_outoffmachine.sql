-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_jig_outoffmachine]
	-- Add the parameters for the stored procedure here
	  @QRCode	AS NVARCHAR(100) 
	, @MCNo		AS NVARCHAR(50) 
	, @OPNo		AS NVARCHAR(6) 
		 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- ########## VERSION 001 ##########
	EXEC [APIStoredProVersionDB].[jig].[sp_set_jig_outoffmachine_001]
		   
		     @QRCode	=  @QRCode	
		   , @MCNo		=  @MCNo		
		   , @OPNo		=  @OPNo		
		   
	-- ########## VERSION 001 ##########
 
END
