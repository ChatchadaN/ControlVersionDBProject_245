------------------------------ Creater Rule ------------------------------
-- Project Name				: material
-- Author Name              : Sadanun.B
-- Written Date             : 2025/10/02
-- Procedure Name 	 		: [material].[sp_get_categories]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.material.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [material].[sp_set_edit_locations_001]
(
		  @name					NVARCHAR(40)
		, @headquarter_id		INT
		, @address				VARCHAR(5)
		, @x					VARCHAR(5)
		, @y					VARCHAR(5)
		, @z					VARCHAR(5)
		, @depth				INT
		, @queue				INT
		, @wh_code				VARCHAR(5)
		, @lsi_process_id		INT
		, @emp_id				INT  
		, @locations_id			INT
)
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRANSACTION
	BEGIN TRY
 
				UPDATE  [APCSProDB].[material].[locations]
				SET   [name]			= @name
					, [headquarter_id]	= @headquarter_id
					, [address]			= @address
					, [x]				= @x
					, [y]				= @y
					, [z]				= @z
					, [depth]			= @depth
					, [queue]			= @queue
					, [wh_code]			= @wh_code	
					, [lsi_process_id]	= @lsi_process_id
					, [updated_at]		= GETDATE()
					, [updated_by]		= @emp_id
				WHERE [id]				= @locations_id

 
				SELECT    'TRUE' AS Is_Pass
						, N'('+(@name)+') Successfully edit ' AS Error_Message_ENG
						, N'('+(@name)+') Successfully edit ' AS Error_Message_THA
						, '' AS Handling

	COMMIT; 

	END TRY

	BEGIN CATCH
		ROLLBACK;

		SELECT   'FALSE'							AS Is_Pass 
				, ERROR_MESSAGE()					AS Error_Message_ENG
				, N'การบันทึกข้อมูลผิดพลาด !!'				AS Error_Message_THA
				, N'กรุณาตรวจสอบข้อมูลที่เว็บ material'		AS Handling

	END CATCH


END
