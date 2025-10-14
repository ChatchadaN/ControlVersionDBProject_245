-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_jig_setup]
	-- Add the parameters for the stored procedure here
	  @QRCode			AS NVARCHAR(100)
	, @MCNo				AS NVARCHAR(50)
	, @OPNo				AS NVARCHAR(6) 
	, @Recipe			AS NVARCHAR(50)	=  NULL     
	, @INPUT_QTY		AS INT			= 1
	, @LOTNO			AS NVARCHAR(10) = NULL 
	, @version			INT			=		1	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- ########## VERSION 001 ##########
	--EXEC [APIStoredProVersionDB].[jig].[sp_get_jig_setup_001]
	--	   @QRCode		=  @QRCode		
	--	 , @MCNo		=  @MCNo				
	--	 , @OPNo		=  @OPNo				
	--	 , @Recipe		=  @Recipe		
	--	 , @INPUT_QTY	=  @INPUT_QTY	
	--	 , @LOTNO		=  @LOTNO		
	---- ########## VERSION 001 ##########
 

 --	EXEC [APIStoredProVersionDB].[jig].[sp_get_jig_setup_002]
	--	   @QRCode		=  @QRCode		
	--	 , @MCNo		=  @MCNo				
	--	 , @OPNo		=  @OPNo				
	--	 , @Recipe		=  @Recipe		
	--	 , @INPUT_QTY	=  @INPUT_QTY	
	--	 , @LOTNO		=  @LOTNO		
	---- ########## VERSION 002 ##########

	-- 	EXEC [APIStoredProVersionDB].[jig].[sp_get_jig_setup_003]
	--	   @QRCode		=  @QRCode		
	--	 , @MCNo		=  @MCNo				
	--	 , @OPNo		=  @OPNo				
	--	 , @Recipe		=  @Recipe		
	--	 , @INPUT_QTY	=  @INPUT_QTY	
	--	 , @LOTNO		=  @LOTNO		
	---- ########## VERSION 003 ##########

	------ ########## VERSION 002 ##########
	-- 	EXEC [APIStoredProVersionDB].[jig].[sp_get_jig_setup_004]
	--	   @QRCode		=  @QRCode		
	--	 , @MCNo		=  @MCNo				
	--	 , @OPNo		=  @OPNo				
	--	 , @Recipe		=  @Recipe		
	--	 , @INPUT_QTY	=  @INPUT_QTY	
	--	 , @LOTNO		=  @LOTNO		
	------ ########## VERSION 003 ##########
	IF(@version = 1)
	BEGIN 
		---- ########## VERSION 005 ##########
	 	EXEC [APIStoredProVersionDB].[jig].[sp_get_jig_setup_005]
		   @QRCode		=  @QRCode		
		 , @MCNo		=  @MCNo				
		 , @OPNo		=  @OPNo				
		 , @Recipe		=  @Recipe		
		 , @INPUT_QTY	=  @INPUT_QTY	
		 , @LOTNO		=  @LOTNO		
	-- ########## VERSION 005 ##########
	END
	ELSE
	BEGIN
	---- ########## VERSION 006 ##########
	 	EXEC [APIStoredProVersionDB].[jig].[sp_get_jig_setup_006]
		   @QRCode		=  @QRCode		
		 , @MCNo		=  @MCNo				
		 , @OPNo		=  @OPNo				
		 , @Recipe		=  @Recipe		
		 , @INPUT_QTY	=  @INPUT_QTY	
		 , @LOTNO		=  @LOTNO		
	-- ########## VERSION 006 ##########

	END  
END
