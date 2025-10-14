
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [jig].[sp_set_tsukiage_recipes]
	-- Add the parameters for the stored procedure here
	   @production_id		INT				=  NULL
	 , @tsukiage_no			NVARCHAR(100)	=  NULL
	 , @machine_type		NVARCHAR(100)	=  NULL
	 , @created_by			INT				=  NULL
	 , @id					INT				=  NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	BEGIN  TRY
	IF NOT EXISTS (SELECT 'xxx'  FROM [APCSProDB].[jig].[tsukiage_recipes] WHERE id  = @id)
	BEGIN

		INSERT INTO [APCSProDB].[jig].[tsukiage_recipes] 
		(	  [id]
			, [production_id]
			, [tsukiage_no]
			, [machine_type]
			, [created_at]
			, [created_by]
		) 	  
		VALUES
		(	  (SELECT ISNULL(MAX([id]),0) + 1 As id FROM [APCSProDB].[jig].[tsukiage_recipes])
			, @production_id
			, @tsukiage_no
			, @machine_type
			, GETDATE()
			, @created_by
		)
		 
		SELECT    'TRUE'												AS Is_Pass
				, N'('+(@tsukiage_no)+') Successfully registered !!'	AS Error_Message_ENG
				, N'('+(@tsukiage_no)+N') ลงทะเบียนเรียบร้อย !!'				AS Error_Message_THA
				, ''													AS Handling
				, ''													AS Warning

	END   
	ELSE IF (@production_id <> 0)
	BEGIN

		UPDATE	  [APCSProDB].[jig].[tsukiage_recipes]
		SET		  [production_id]	= @production_id
				, tsukiage_no		= @tsukiage_no
				, [machine_type]	= @machine_type
				, updated_at		= GETDATE()
				, updated_by		= @created_by
		WHERE  id  	= @id

			SELECT    'TRUE' AS Is_Pass
					, N'('+(@tsukiage_no)+') Successfully updated !!' AS Error_Message_ENG
					, N'('+(@tsukiage_no)+N') แก้ไขข้อมูลเรียบร้อย !!' AS Error_Message_THA
					, '' AS Handling
					, '' AS Warning
 
	END
	ELSE
	BEGIN

			DELETE FROM [APCSProDB].[jig].[tsukiage_recipes]
			WHERE [id] = @id


			SELECT    'TRUE' AS Is_Pass
					, N'Successfully delete !!' AS Error_Message_ENG
					, N'ลบข้อมูลเรียบร้อยแล้ว !!' AS Error_Message_THA
					, '' AS Handling
					, '' AS Warning

	END 
	   	  
	END	TRY
	BEGIN CATCH

		SELECT    'FALSE'						AS Is_Pass 
				, N'Failed to register !!'		AS Error_Message_ENG
				, N'ลงทะเบียนไม่สำเร็จ !!'			AS Error_Message_THA 
				, ''							AS Handling

	END CATCH	 
	 
END
