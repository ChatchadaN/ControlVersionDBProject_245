
-- =============================================
-- Author:		NUCHA
-- Create date: 2022/07/01
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_material_ogi_ai]
		 @LotNo					NVARCHAR(10)
		 ,@App_Name				NVARCHAR(20)
		 ,@OpNO				    NVARCHAR(20)
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
			, 'EXEC [material].[sp_get_material_ogi_ai_001] @LotNo  = ''' + ISNULL(CAST(@LotNo AS nvarchar(MAX)),'') 
				+ ''',@OpNO = ''' + ISNULL(CAST(@OpNO AS nvarchar(MAX)),'') +  
				+ ''', @App_Name = ''' + ISNULL(CAST(@App_Name AS nvarchar(MAX)),'') + ''''
			, @LotNo

	---- ########## VERSION 001 ##########
			EXEC [APIStoredProVersionDB].[material].[sp_get_material_ogi_ai_001]
				 	  @LotNo		 = 	 @LotNo			
				   ,  @OpNO			 =   @OpNO		
				   ,  @App_Name		 =   @App_Name	

	---- ########## VERSION 001 ##########
 
END
