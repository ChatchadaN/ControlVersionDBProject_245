-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_kanagata_cleanshot]
	-- Add the parameters for the stored procedure here
		@kanagataNo			VARCHAR(50)
	 ,  @OPNo				INT		
	 ,  @MCNO				VARCHAR(50)	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- ########## VERSION 001 ##########
	EXEC [APIStoredProVersionDB].[jig].[sp_set_kanagata_cleanshot_001]
		 	@kanagataNo		=  @kanagataNo	
		  ,  @OPNo			=  @OPNo		
		  ,  @MCNO			=  @MCNO		
		   
	-- ########## VERSION 001 ##########
 
END
