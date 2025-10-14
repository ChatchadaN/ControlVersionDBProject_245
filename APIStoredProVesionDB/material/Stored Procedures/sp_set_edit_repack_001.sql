
-- =============================================
-- Author:		<Author,Sadanan B.>
-- Create date: <Create Date, 2025/09/29>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_set_edit_repack_001]
	-- Add the parameters for the stored procedure here
	  @material_repack_file_id		INT 
	, @repack_qty					INT  
	, @pack_unit_qty				INT 
	, @emp_id						INT			= 1

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
  

	BEGIN TRY  

				IF ( @repack_qty > (SELECT quantity  FROM  APCSPRODB.[TRANS].[MATERIAL_REPACK_FILE] WHERE id  = @material_repack_file_id ))
				BEGIN
					
					SELECT    'TRUE'							AS Is_Pass
							, N'Material quantiry less than repack quantity'	AS Error_Message_ENG
							, N'Material quantiry less than repack quantity'	AS Error_Message_THA
							, ''								AS Handling 
					RETURN

				END 
				ELSE  
				BEGIN 
				 

					UPDATE APCSPRODB.[TRANS].[MATERIAL_REPACK_FILE]
					SET	pack_unit_qty	= @pack_unit_qty
					, repack_qty		= @repack_qty
					, updated_at		= GETDATE()
					, updated_by		= @emp_id
					WHERE id  =   @material_repack_file_id

					 

					SELECT    'TRUE'										AS Is_Pass
							, N'Repack data update completed successfully'	AS Error_Message_ENG
							, N'แก้ไขข้อมูลการ repack สำเร็จ'						AS Error_Message_THA
							, ''											AS Handling 
					RETURN
				END 

		END TRY  
		BEGIN CATCH  

					SELECT    'FALSE'					AS Is_Pass 
							, N'Failed to update !!'	AS Error_Message_ENG
							, N'Failed to update !!'	AS Error_Message_THA 
							, ''						AS Handling

		END CATCH  


END
