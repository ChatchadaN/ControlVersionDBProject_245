-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_jig_endlot]
	-- Add the parameters for the stored procedure here
		  @QRCode			AS NVARCHAR(100) 
		, @LOTNO			AS NVARCHAR(10)
		, @OPNo				AS NVARCHAR(6)
		, @MCNo				AS NVARCHAR(50)
		, @INPUT_QTY		AS INT			= 1
		, @version			INT				= 1	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	---- ########## VERSION 001 ##########
	--EXEC [APIStoredProVersionDB].[jig].[sp_set_jig_endlot_001]
	--	    @QRCode		=  @QRCode	
	--	  , @LOTNO		=  @LOTNO	
	--	  , @OPNo		=  @OPNo		
	--	  , @MCNo		=  @MCNo		
	--	  , @INPUT_QTY	=  @INPUT_QTY
	---- ########## VERSION 001 ##########
 

 	-- ########## VERSION 001 ##########
	EXEC [APIStoredProVersionDB].[jig].[sp_set_jig_endlot_002]
		    @QRCode		=  @QRCode	
		  , @LOTNO		=  @LOTNO	
		  , @OPNo		=  @OPNo		
		  , @MCNo		=  @MCNo		
		  , @INPUT_QTY	=  @INPUT_QTY
	-- ########## VERSION 001 ##########

END
