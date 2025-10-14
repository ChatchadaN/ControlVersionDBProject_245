-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[andon_insert_001]
	@op_emp_code		VARCHAR(6),
	@machine_id			INT,
	@sub_category_id	INT,
	@location_id		INT,
	@id_at_finding		INT,
	@comments			VARCHAR(MAX) =  '',
	@item				VARCHAR(50)
AS
BEGIN

	DECLARE @newid		INT
		,	@newdocno	VARCHAR(17)
		,	@emp_id		INT

	-- Get new id
	SELECT @newid = ISNULL(MAX(ID), 0) + 1 FROM [APCSProDB].[trans].[andon_controls];

	-- Get employee id
	SELECT @emp_id = id FROM [10.29.1.230].[DWH].[man].[employees] WHERE emp_code = @op_emp_code

	-- Generate new document no.
	EXEC [StoredProcedureDB].[trans].[gen_docno] @type = N'AND', @NewDocNo = @newdocno OUTPUT;

	BEGIN TRANSACTION
	BEGIN TRY
		-- insert to andon_controls
		INSERT INTO [APCSProDB].[trans].[andon_controls] 
		(
				  [id]
				, [andon_control_no]
				, [comment_id_at_finding]
				, [updated_at]
				, [updated_by]
				, [machine_id]
				, [comments]
		)
		VALUES 
		(		  
				  @newid
				, @newdocno
				, @id_at_finding
				, GETDATE()
				, @emp_id
				, @machine_id
				, @comments
		)

		-- insert to andon_items
		INSERT INTO [APCSProDB].[trans].[andon_items]
		(
				  [andon_control_id]
				, [item]
				, [sub_category_id]
				, [location_id]
				, [created_at]
				, [created_by]
		)
		VALUES 
		(
				  @newid
				, @item
				, @sub_category_id
				, @location_id
				, GETDATE()
				, @emp_id
		)


		SELECT    'TRUE'			AS Is_Pass 
				, 'Success'			AS Error_Message_ENG
				, N'บันทึกสำเร็จ'		AS Error_Message_THA	
				, ''				AS Handling
		COMMIT; 

		RETURN

	END TRY
	BEGIN CATCH
		ROLLBACK;

		SELECT    'FALSE'					AS Is_Pass 
				, 'Recording fail. !!'		AS Error_Message_ENG
				--, ERROR_MESSAGE()	AS Error_Message_ENG
				, N'การบันทึกผิดพลาด !!'		AS Error_Message_THA
				, ''						AS Handling

		RETURN
	END CATCH

END