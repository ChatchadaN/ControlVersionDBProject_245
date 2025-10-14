
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_edit_classfication]
	-- Add the parameters for the stored procedure here
	@id AS INT,
	@class_no AS VARCHAR(50),
	@rack_no AS INT,
	@name_of_process AS VARCHAR(100),
	@stock_class AS VARCHAR(5),
	@process_no AS VARCHAR(50),
	@process_name AS VARCHAR(100),
	@process_dept AS VARCHAR(50),
	@opnumber AS VARCHAR(10)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @emp_id int
		SELECT @emp_id = id 
		FROM APCSProDB.man.users
		WHERE emp_num = @opnumber

    -- Insert statements for procedure here
	BEGIN
	UPDATE [APCSProDB].[inv].[Inventory_classfications]
	SET 
		class_no = @class_no,
		rack_no = @rack_no,
		name_of_process = @name_of_process,
		process_no = @process_no,
		sheet_no_start = 1,
		sheet_no_end = 999,
		process_dept = @process_dept,
		section_code = '1',
		process_name = @process_name,
		updated_at = GETDATE(),
		updated_by = @emp_id,
		stock_class = FORMAT(CAST(@stock_class AS int), '00')
	WHERE id = @id;

	END
	
END
