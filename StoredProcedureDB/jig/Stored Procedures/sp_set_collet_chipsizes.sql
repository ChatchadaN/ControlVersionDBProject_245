
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [jig].[sp_set_collet_chipsizes]
	-- Add the parameters for the stored procedure here
	   @xmin				FLOAT			= NULL 
	 , @xmax				FLOAT			= NULL 
	 , @ymin				FLOAT			= NULL 
	 , @ymax				FLOAT			= NULL 
	 , @rubber_no			NVARCHAR(100)	= NULL 
	 , @chipsize_id			INT				= NULL 
	 , @created_by			INT  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	BEGIN  TRY
	IF NOT EXISTS (SELECT 'xxx'  FROM [APCSProDB].[jig].[chipsizes]  WHERE id  =  @chipsize_id)
	BEGIN

		INSERT INTO [APCSProDB].[jig].[chipsizes] 
		(	  [id]
			, xmin
			, xmax
			, ymin
			, ymax
			, created_at
			, created_by
			 
		) 	  
		VALUES
		(	  (SELECT  ISNULL(MAX([id]),0) + 1 AS id FROM [APCSProDB].[jig].[chipsizes])
			, @xmin
			, @xmax
			, @ymin
			, @ymax
			, GETDATE()
			, @created_by
		)
		 
		INSERT INTO [APCSProDB].[jig].[collet_chipsize_recipes] 
		(   
			  [id]
			, [rubber_no]
			, [chipsize_id]
			, [created_at]
			, [created_by]
		) 
        VALUES 
		(
			  (SELECT ISNULL(MAX([id]),0)  + 1 AS id FROM [APCSProDB].[jig].[collet_chipsize_recipes])
			, @rubber_no
			, (SELECT ISNULL(MAX([id]),0)  FROM [APCSProDB].[jig].[chipsizes])
			, GETDATE()
			, @created_by
		)

		SELECT    'TRUE'												AS Is_Pass
				, N'Successfully registered !!'							AS Error_Message_ENG
				, N'ลงทะเบียนเรียบร้อย !!'									AS Error_Message_THA
				, ''													AS Handling
				, ''													AS Warning

	END 
	ELSE IF (@rubber_no IS NOT NULL AND @chipsize_id <> 0 )
	BEGIN 
		
		UPDATE  [APCSProDB].[jig].[chipsizes] 
		SET   xmin			=  @xmin		
			, xmax			=  @xmax		
			, ymin			=  @ymin		
			, ymax			=  @ymax		
			, updated_at	=  GETDATE()
			, updated_by	=  @created_by
		WHERE id  = @chipsize_id

		
		UPDATE [APCSProDB].[jig].[collet_chipsize_recipes] 
		SET   rubber_no		= @rubber_no
			, [updated_at]	= GETDATE()
			, [updated_by]	= @created_by
		WHERE chipsize_id	= @chipsize_id
		 
		SELECT    'TRUE'												AS Is_Pass
				, N'Successfully update !!'								AS Error_Message_ENG
				, N'แก้ไขข้อมูลเรียบร้อย !!'									AS Error_Message_THA
				, ''													AS Handling
				, ''													AS Warning
	END
	ELSE
	BEGIN

		DELETE FROM [APCSProDB].[jig].[chipsizes] 
		WHERE [id] = @chipsize_id


		SELECT    'TRUE' AS Is_Pass
				, N'Successfully delete !!' AS Error_Message_ENG
				, N'ลบข้อมูลเรียบร้อยแล้ว !!' AS Error_Message_THA
				, '' AS Handling
				, '' AS Warning

	END 
	END	TRY
	BEGIN CATCH

		SELECT    'FALSE'					AS Is_Pass 
				, N'Failed to register !!'	AS Error_Message_ENG
				, N'ลงทะเบียนไม่สำเร็จ !!'		AS Error_Message_THA 
				, ''						AS Handling
		
	END CATCH	 
	 
END
