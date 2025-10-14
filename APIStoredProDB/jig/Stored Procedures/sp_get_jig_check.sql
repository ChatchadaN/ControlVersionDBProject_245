-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_jig_check]
	-- Add the parameters for the stored procedure here
	  @QRCode			AS NVARCHAR(MAX)  
	, @Recipe			AS NVARCHAR(50)	=  ''    --, @WBCode	AS VARCHAR(50) = ''
	, @INPUT_QTY		AS INT			=  1
	, @LOTNO			AS NVARCHAR(10)
	, @OPNo				AS NVARCHAR(6) 
	, @version			INT			=		1
		 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- ########## VERSION 001 ##########
	--EXEC [APIStoredProVersionDB].[jig].[sp_get_jig_check_001]
	--	  @QRCode			=   @QRCode	
	--	, @Recipe	 		=  @Recipe	
	--	, @INPUT_QTY		=  @INPUT_QTY
	--	, @LOTNO			=  @LOTNO	
	--	, @OPNo				=  @OPNo		
		 
	------ ########## VERSION 002 ##########
 --	EXEC [APIStoredProVersionDB].[jig].[sp_get_jig_check_002]
	--	  @QRCode			=   @QRCode	
	--	, @Recipe	 		=  @Recipe	
	--	, @INPUT_QTY		=  @INPUT_QTY
	--	, @LOTNO			=  @LOTNO	
	--	, @OPNo				=  @OPNo		
		 
	---- ########## VERSION 002 ##########

	--	---- ########## VERSION 003 ##########
 --	EXEC [APIStoredProVersionDB].[jig].[sp_get_jig_check_003]
	--	  @QRCode			=   @QRCode	
	--	, @Recipe	 		=  @Recipe	
	--	, @INPUT_QTY		=  @INPUT_QTY
	--	, @LOTNO			=  @LOTNO	
	--	, @OPNo				=  @OPNo		
		 
	---- ########## VERSION 003 ##########

	------ ########## VERSION 004 ##########  Add special flow in jig set
 --	EXEC [APIStoredProVersionDB].[jig].[sp_get_jig_check_004]
	--	  @QRCode			=   @QRCode	
	--	, @Recipe	 		=  @Recipe	
	--	, @INPUT_QTY		=  @INPUT_QTY
	--	, @LOTNO			=  @LOTNO	
	--	, @OPNo				=  @OPNo		
		 
	---- ########## VERSION 004 ##########

	IF(@version = 1)
	BEGIN 
			-- ########## VERSION 005 ##########  Remove recipe of  kanagata
 			EXEC [APIStoredProVersionDB].[jig].[sp_get_jig_check_005]
				  @QRCode			=   @QRCode	
				, @Recipe	 		=  @Recipe	
				, @INPUT_QTY		=  @INPUT_QTY
				, @LOTNO			=  @LOTNO	
				, @OPNo				=  @OPNo		
		 
			-- ########## VERSION 005 ##########
	END
	ELSE
	BEGIN
			-- ########## VERSION 005 ##########  Remove recipe of  kanagata
 			EXEC [APIStoredProVersionDB].[jig].[sp_get_jig_check_006]
				  @QRCode			=   @QRCode	
				, @Recipe	 		=  @Recipe	
				, @INPUT_QTY		=  @INPUT_QTY
				, @LOTNO			=  @LOTNO	
				, @OPNo				=  @OPNo		
		 
			-- ########## VERSION 005 ##########
	END 

END
