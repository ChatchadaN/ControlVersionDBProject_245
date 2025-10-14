---- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_set_remove_stock_out_001]
	-- Add the parameters for the stored procedure here
		@material_id				NVARCHAR(255) 
		, @emp_id					INT	

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	 

	BEGIN TRANSACTION
	BEGIN TRY 
				

				IF NOT EXISTS (SELECT  1  FROM  APCSProDB.trans.material_pickup_file WHERE material_id IN  (SELECT  [value] FROM STRING_SPLIT(@material_id,',')))
				BEGIN 
					SELECT   'FALSE'							AS Is_Pass 
							, ERROR_MESSAGE()					AS Error_Message_ENG
							, N'การบันทึกข้อมูลผิดพลาด !!'			AS Error_Message_THA
							, N'กรุณาตรวจสอบข้อมูลที่เว็บ material'	AS Handling
					COMMIT;

					RETURN
				END 
				ELSE
				BEGIN

					DELETE  APCSProDB.trans.material_pickup_file
					WHERE material_id IN (SELECT  [value] FROM STRING_SPLIT(@material_id,','))
			 
		
					SELECT    'TRUE'						AS Is_Pass 
							, 'Successfully daleted data.'	AS Error_Message_ENG
							, N'ลบข้อมูลสำเร็จ'					AS Error_Message_THA	
							, ''							AS Handling	

						COMMIT;
						RETURN
				END  
				

		 
	END TRY
	BEGIN CATCH
		ROLLBACK;

			SELECT   'FALSE'							AS Is_Pass 
					, ERROR_MESSAGE()					AS Error_Message_ENG
					, N'การบันทึกข้อมูลผิดพลาด !!'			AS Error_Message_THA
					, N'กรุณาตรวจสอบข้อมูลที่เว็บ material'	AS Handling

	END CATCH


END
