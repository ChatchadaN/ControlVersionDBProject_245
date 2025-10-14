-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_regis_classfication]
	-- Add the parameters for the stored procedure here
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
	INSERT INTO [APCSProDB].[inv].[Inventory_classfications]
       ([class_no]
	   ,[rack_no]
	   ,[name_of_process]
	   ,[process_no]
	   ,[sheet_no_start]
	   ,[sheet_no_end]
	   ,[process_dept]
	   ,[section_code]
	   ,[process_name]
	   ,[created_at]
	   ,[created_by]
	   ,[stock_class]
	   )
       VALUES
	   (@class_no
	   , @rack_no
	   , @name_of_process
	   , @process_no
	   , 1
	   , 999
	   , @process_dept
	   , '1'
	   , @process_name
	   , GETDATE()
	   , @emp_id
	   , format(cast(@stock_class AS int),'00') 
	   )
	END
	
END