
-- =============================================
-- Author:		<Author,Sadanan B.>
-- Create date: <Create Date, 2025/09/29>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_set_delete_repack_001]
	-- Add the parameters for the stored procedure here
	  @material_repack_file_id		INT 
	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
  

	BEGIN TRY   

					DELETE APCSPRODB.[TRANS].[MATERIAL_REPACK_FILE]
					WHERE id  =   @material_repack_file_id
					 
					SELECT    'TRUE'							AS Is_Pass
							, N'Delete data successfully'		AS Error_Message_ENG
							, N'ลบข้อมูลการ repack สำเร็จ'			AS Error_Message_THA
							, ''								AS Handling 
					RETURN
			 

		END TRY  
		BEGIN CATCH  

					SELECT    'FALSE'					AS Is_Pass 
							, N'Failed to delete'		AS Error_Message_ENG
							, N'Failed to delete'		AS Error_Message_THA 
							, ''						AS Handling

		END CATCH  


END
