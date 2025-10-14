
CREATE PROCEDURE [man].[sp_set_dwh_employee_info_by_task_TEST]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	---- create temp
	DECLARE @table_user TABLE 
	(
		[emp_code] [varchar](10)
		, [full_name_th] [nvarchar](50)
		, [full_name_eng] [varchar](50)
		, [display_name] [nvarchar](50)
		, [date_birth] [date]
		, [default_language] [varchar](5)
		, [extension] [varchar](10)
		, [email] [varchar](50)
		, [picture_data] [varbinary](max)
		, [password] [varchar](20)
		, [is_admin] [tinyint]
		, [working_date] [date]
		, [emp_card] [varchar](50)
		, [shift_id] [int]
		, [resign_date] [date]
		, [position_id] [int]
		, [created_at] [datetime]
		, [created_by] [int]
		, [updated_at] [datetime]
		, [updated_by] [int]
	)

	---- insert data to temp
	INSERT INTO @table_user
	SELECT [emp_code]
      ,[full_name_th]
      ,[full_name_eng]
      ,[display_name]
      ,[date_birth]
      ,[default_language]
      ,[extension]
      ,[email]
      ,[picture_data]
      ,[password]
      ,[is_admin]
      ,[working_date] 
      ,[emp_card]
      ,[shift_id]
      ,[resign_date]
      ,[position_id]
      ,[created_at]
      ,[created_by]
      ,[updated_at]
      ,[updated_by]
  FROM [10.29.1.230].[DWH].[man].[employees]
	ORDER BY [working_date], [emp_code] ASC;

	---- insert or update data to table
	MERGE [DWH].[man].[employees] AS [emp_new]
	USING @table_user AS [emp] ON ([emp_new].[emp_code] = [emp].[emp_code]) 
	WHEN MATCHED AND 
	(
		ISNULL([emp_new].[full_name_th], '') != ISNULL([emp].[full_name_th], '')
		OR ISNULL([emp_new].[full_name_eng], '') != ISNULL([emp].[full_name_eng], '')
		OR ISNULL([emp_new].[display_name], '') != ISNULL([emp].[display_name], '')
		OR ISNULL([emp_new].[email], '') != ISNULL([emp].[email], '')
		OR ISNULL([emp_new].[shift_id], '') != ISNULL([emp].[shift_id], '')
		OR ISNULL([emp_new].[resign_date], '') != ISNULL([emp].[resign_date], '')
		OR ISNULL([emp_new].[position_id], '') != ISNULL([emp].[position_id], '')
	)
	THEN UPDATE SET 
		[emp_new].[full_name_th] = [emp].[full_name_th]
		, [emp_new].[full_name_eng] = [emp].[full_name_eng]
		, [emp_new].[display_name] = [emp].[display_name]
		, [emp_new].[email] = CASE WHEN [emp].[email] IS NOT NULL THEN [emp].[email] ELSE [emp_new].[email]  END
		, [emp_new].[shift_id] = [emp].[shift_id]
		, [emp_new].[resign_date] = [emp].[resign_date]
		, [emp_new].[position_id] = [emp].[position_id]
		, [emp_new].[updated_at] = GETDATE()
	WHEN NOT MATCHED BY TARGET 
	THEN INSERT 
	( 
		[emp_code]
		, [full_name_th]
		, [full_name_eng]
		, [display_name]
		, [date_birth]
		, [default_language]
		, [extension]
		, [email]
		, [picture_data]
		, [password]
		, [is_admin]
		, [working_date]
		, [emp_card]
		, [shift_id]
		, [resign_date]
		, [position_id]
		, [created_at]
		, [created_by]
		, [updated_at]
		, [updated_by] 
	) 
	VALUES 
	( 
		[emp].[emp_code]
		, [emp].[full_name_th]
		, [emp].[full_name_eng]
		, [emp].[display_name]
		, [emp].[date_birth]
		, [emp].[default_language]
		, [emp].[extension]
		, [emp].[email]
		, [emp].[picture_data]
		, [emp].[password]
		, [emp].[is_admin]
		, [emp].[working_date]
		, [emp].[emp_card]
		, [emp].[shift_id]
		, [emp].[resign_date]
		, [emp].[position_id]
		, [emp].[created_at]
		, [emp].[created_by]
		, [emp].[updated_at]
		, [emp].[updated_by] 
	);
END