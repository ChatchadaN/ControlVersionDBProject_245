-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_jig_setup]
	-- Add the parameters for the stored procedure here
	  @QRCode			AS VARCHAR(100)
	, @MCNo				AS VARCHAR(50)
	, @OPNo				AS VARCHAR(6) 
	, @LOTNO			AS NVARCHAR(10) =  NULL
	, @Recipe			AS NVARCHAR(50)	=  NULL
	, @version			INT				=	1	 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	---- ########## VERSION 001 ##########
	--EXEC [APIStoredProVersionDB].[jig].[sp_set_jig_setup_001]
	--	  @QRCode		=  @QRCode
	--	, @MCNo			=  @MCNo	
	--	, @OPNo			=  @OPNo	
	--	, @LOTNO		=  @LOTNO
	--	, @Recipe		=  @Recipe
	  
	---- ########## VERSION 001 ##########
 
 --	EXEC [APIStoredProVersionDB].[jig].[sp_set_jig_setup_002]
	--	  @QRCode		=  @QRCode
	--	, @MCNo			=  @MCNo	
	--	, @OPNo			=  @OPNo	
	--	, @LOTNO		=  @LOTNO
	--	, @Recipe		=  @Recipe
	  
	---- ########## VERSION 002 ##########
 
 -- 	-- ########## VERSION 003 ##########
 --	EXEC [APIStoredProVersionDB].[jig].[sp_set_jig_setup_003]
	--	  @QRCode		=  @QRCode
	--	, @MCNo			=  @MCNo	
	--	, @OPNo			=  @OPNo	
	--	, @LOTNO		=  @LOTNO
	--	, @Recipe		=  @Recipe
	  
	---- ########## VERSION 003 ##########
 
	IF(@version = 1)
	BEGIN 
 			-- ########## VERSION 004 ##########
 			EXEC [APIStoredProVersionDB].[jig].[sp_set_jig_setup_004]
				  @QRCode		=  @QRCode
				, @MCNo			=  @MCNo	
				, @OPNo			=  @OPNo	
				, @LOTNO		=  @LOTNO
				, @Recipe		=  @Recipe
			-- ########## VERSION 004 ##########
 	END
	ELSE
	BEGIN
		 	-- ########## VERSION 005 ##########
 			EXEC [APIStoredProVersionDB].[jig].[sp_set_jig_setup_005]
				  @QRCode		=  @QRCode
				, @MCNo			=  @MCNo	
				, @OPNo			=  @OPNo	
				, @LOTNO		=  @LOTNO
				, @Recipe		=  @Recipe
			-- ########## VERSION 005 ##########
	END 

END
