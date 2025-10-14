
-- =============================================
-- Author:		NUCHA
-- Create date: 2022/07/01
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_checkmaterial_set]
		 @LotNo				NVARCHAR(20)  
	  ,  @QRCode			NVARCHAR(MAX)   
	  ,  @McNo				NVARCHAR(20)
	  ,  @OpNO				NVARCHAR(20)
	  ,  @App_Name			NVARCHAR(20)
	  ,  @Material_type		NVARCHAR(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

		INSERT INTO APIStoredProDB.[dbo].[exec_sp_history]
		   ([record_at]
		  , [record_class]
		  , [login_name]
		  , [hostname]
		  , [appname]
		  , [command_text]
		  , [lot_no])
		SELECT GETDATE()
			,'4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
			,ORIGINAL_LOGIN()
			,HOST_NAME()
			,APP_NAME()
			, 'EXEC [material].[sp_get_checkmaterial_set_09] @LotNo  = ''' + ISNULL(CAST(@LotNo AS nvarchar(MAX)),'') + ''', @QRCode = ''' + ISNULL(CAST(@QRCode AS nvarchar(MAX)),'') + ''',@OpNO = ''' 
				+ ISNULL(CAST(@OpNO AS nvarchar(MAX)),'') +  ''',@McNo = ''' + ISNULL(CAST(@McNo AS nvarchar(MAX)),'') + ''',@Material_type = ''' + ISNULL(CAST(@Material_type AS nvarchar(MAX)),'') + '''' 
				+ ''', @App_Name = ''' + ISNULL(CAST(@App_Name AS nvarchar(MAX)),'') + ''''
			, @LotNo

	---- ########## VERSION 001 ##########
	--		EXEC [APIStoredProVersionDB].[material].[sp_get_checkmaterial_set_001]
	--			 	  @LotNo		 = 	 @LotNo		
	--			   ,  @QRCode		 =   @QRCode	
	--			   ,  @McNo			 =   @McNo		
	--			   ,  @OpNO			 =   @OpNO		
	--			   ,  @App_Name		 =   @App_Name	
	--			   ,  @Material_type =   @Material_type
	---- ########## VERSION 001 ##########
 
 --	-- ########## VERSION 002 ##########
	--		EXEC [APIStoredProVersionDB].[material].[sp_get_checkmaterial_set_002]
	--			 	  @LotNo		 = 	 @LotNo		
	--			   ,  @QRCode		 =   @QRCode	
	--			   ,  @McNo			 =   @McNo		
	--			   ,  @OpNO			 =   @OpNO		
	--			   ,  @App_Name		 =   @App_Name	
	--			   ,  @Material_type =   @Material_type
	---- ########## VERSION 002 ##########

	---- ########## VERSION 003 ##########
	--		EXEC [APIStoredProVersionDB].[material].[sp_get_checkmaterial_set_003]
	--			 	  @LotNo		 = 	 @LotNo		
	--			   ,  @QRCode		 =   @QRCode	
	--			   ,  @McNo			 =   @McNo		
	--			   ,  @OpNO			 =   @OpNO		
	--			   ,  @App_Name		 =   @App_Name	
	--			   ,  @Material_type =   @Material_type
	---- ########## VERSION 003 ##########

	---- ########## VERSION 004 ##########  --ADD CONDITION CHECK EMBOSS NEW LABEL   
	--		EXEC [APIStoredProVersionDB].[material].[sp_get_checkmaterial_set_004]
	--			 	  @LotNo		 = 	 @LotNo		
	--			   ,  @QRCode		 =   @QRCode	
	--			   ,  @McNo			 =   @McNo		
	--			   ,  @OpNO			 =   @OpNO		
	--			   ,  @App_Name		 =   @App_Name	
	--			   ,  @Material_type =   @Material_type
	---- ########## VERSION 004 ##########

	---- ########## VERSION 005 ##########   --ADD CONDITION CHECK REEL  20230706

	--		EXEC [APIStoredProVersionDB].[material].[sp_get_checkmaterial_set_005]  
	--			 	  @LotNo		 = 	 @LotNo		
	--			   ,  @QRCode		 =   @QRCode	
	--			   ,  @McNo			 =   @McNo		
	--			   ,  @OpNO			 =   @OpNO		
	--			   ,  @App_Name		 =   @App_Name	
	--			   ,  @Material_type =   @Material_type
	---- ########## VERSION 005 ##########

	 --########## VERSION 006 ##########   --ADD CONDITION CHECK REEL  20230706
		--EXEC [APIStoredProVersionDB].[material].[sp_get_checkmaterial_set_006]   -- ADD QRCODE : C1010BS 130502-1557
		--		 	  @LotNo		 = 	 @LotNo		
		--		   ,  @QRCode		 =   @QRCode	
		--		   ,  @McNo			 =   @McNo		
		--		   ,  @OpNO			 =   @OpNO		
		--		   ,  @App_Name		 =   @App_Name	
		--		   ,  @Material_type =   @Material_type
	 --########## VERSION 006 ##########

	---- ########## VERSION 007 ##########   --ADD PACKAGE NEW 2023/12/22
	--	EXEC [APIStoredProVersionDB].[material].[sp_get_checkmaterial_set_007]    
	--			 	  @LotNo		 = 	 @LotNo		
	--			   ,  @QRCode		 =   @QRCode	
	--			   ,  @McNo			 =   @McNo		
	--			   ,  @OpNO			 =   @OpNO		
	--			   ,  @App_Name		 =   @App_Name	
	--			   ,  @Material_type =   @Material_type
	---- ########## VERSION 007 ##########

	---- ########## VERSION 008 ##########  --2024/01/09   OPEN ALL PACKAGE
	--	EXEC [APIStoredProVersionDB].[material].[sp_get_checkmaterial_set_008]    
	--			 	  @LotNo		 = 	 @LotNo		
	--			   ,  @QRCode		 =   @QRCode	
	--			   ,  @McNo			 =   @McNo		
	--			   ,  @OpNO			 =   @OpNO		
	--			   ,  @App_Name		 =   @App_Name	
	--			   ,  @Material_type =   @Material_type
	---- ########## VERSION 008 ##########	
	
	-- ########## VERSION 009 ##########  --2024/04/26   EDIT TEMP 
		EXEC [APIStoredProVersionDB].[material].[sp_get_checkmaterial_set_009]    
				 	  @LotNo		 = 	 @LotNo		
				   ,  @QRCode		 =   @QRCode	
				   ,  @McNo			 =   @McNo		
				   ,  @OpNO			 =   @OpNO		
				   ,  @App_Name		 =   @App_Name	
				   ,  @Material_type =   @Material_type
	-- ########## VERSION 009 ##########

END
