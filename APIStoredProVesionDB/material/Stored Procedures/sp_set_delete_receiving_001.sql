---- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_set_delete_receiving_001]
	-- Add the parameters for the stored procedure here
		  @material_receiving_process_id		NVARCHAR(255)  
		  , @emp_id								INT	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	  
	BEGIN TRANSACTION
	BEGIN TRY 

	  
				DELETE FROM [APCSProDB].[TRANS].[MATERIAL_RECORDS] 
				WHERE MATERIAL_ID IN (SELECT MATERIAL_ID 
										FROM [APCSPRODB].[TRANS].[MATERIAL_RECEIVING_RECORDS] 
										WHERE MATERIAL_RECEIVING_PROCESS_ID IN (SELECT  [value] FROM STRING_SPLIT(@material_receiving_process_id,',')));

				DELETE FROM [APCSProDB].[TRANS].[MATERIAL_ARRIVAL_RECORDS] 
				WHERE MATERIAL_ID IN (SELECT MATERIAL_ID 
										FROM [APCSPRODB].[TRANS].[MATERIAL_RECEIVING_RECORDS] 
										WHERE MATERIAL_RECEIVING_PROCESS_ID IN (SELECT  [value] FROM STRING_SPLIT(@material_receiving_process_id,',')));

				DELETE FROM [APCSProDB].[TRANS].[MATERIAL_INVENTORY_FILE] 
				WHERE BARCODE IN (SELECT BARCODE FROM [APCSProDB].[TRANS].[MATERIALS] 
						WHERE ID IN (SELECT MATERIAL_ID 
										FROM [APCSPRODB].[TRANS].[MATERIAL_RECEIVING_RECORDS] 
										WHERE MATERIAL_RECEIVING_PROCESS_ID IN (SELECT  [value] FROM STRING_SPLIT(@material_receiving_process_id,','))));

				DELETE FROM [APCSProDB].[TRANS].[MATERIAL_OUTGOING_ITEMS] 
				WHERE MATERIAL_ID IN (SELECT MATERIAL_ID 
										FROM [APCSPRODB].[TRANS].[MATERIAL_RECEIVING_RECORDS] 
										WHERE MATERIAL_RECEIVING_PROCESS_ID IN (SELECT  [value] FROM STRING_SPLIT(@material_receiving_process_id,',')));

				DELETE FROM [APCSProDB].[TRANS].[MATERIALS] 
				WHERE ID IN (SELECT MATERIAL_ID 
								FROM [APCSPRODB].[TRANS].[MATERIAL_RECEIVING_RECORDS] 
								WHERE MATERIAL_RECEIVING_PROCESS_ID IN (SELECT  [value] FROM STRING_SPLIT(@material_receiving_process_id,',')));

				DELETE FROM [APCSPRODB].[TRANS].[MATERIAL_RECEIVING_RECORDS] 
				WHERE MATERIAL_RECEIVING_PROCESS_ID IN (SELECT  [value] FROM STRING_SPLIT(@material_receiving_process_id,','));

				DELETE FROM [APCSProDB].[TRANS].[MATERIAL_RECEIVING_PROCESS] 
				WHERE ID IN (SELECT  [value] FROM STRING_SPLIT(@material_receiving_process_id,','));

				 
				SELECT    'TRUE'						AS Is_Pass 
						, 'Successfully daleted data.'	AS Error_Message_ENG
						, N'ลบข้อมูลสำเร็จ'					AS Error_Message_THA	
						, ''							AS Handling	
		COMMIT;

		 
	END TRY
	BEGIN CATCH
		ROLLBACK;

			SELECT   'FALSE'							AS Is_Pass 
					, ERROR_MESSAGE()					AS Error_Message_ENG
					, N'การบันทึกข้อมูลผิดพลาด !!'			AS Error_Message_THA
					, N'กรุณาตรวจสอบข้อมูลที่เว็บ material'	AS Handling

	END CATCH


END
