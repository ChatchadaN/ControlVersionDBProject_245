-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [req].[sp_set_user_by_task]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @table TABLE 
	(
		[emp_num] [nvarchar](10)
		, [password] [nvarchar](20)
		, [name] [nvarchar](255)
		, [full_name] [nvarchar](255)
		, [full_name_eng] [nvarchar](255)
		, [headquarter] [nvarchar](255)
		, [division] [nvarchar](255)
		, [department] [nvarchar](255)
		, [section] [nvarchar](255)
		, [is_permission] [tinyint]
	)

	INSERT INTO @table
	SELECT [CODEMPID] AS [emp_num]
		, [CODEMPID] AS [password]
		, [NICKNAME] AS [name]
		, [NAMEMPT] AS [full_name]
		, [NAMEMPE] AS [full_name_eng]
		, [SECTION] AS [headquarter]
		, [DEPARTMENT] AS [division]
		, [DEPARTMENT2] AS [department]
		, [DEPARTMENT3] AS [section]
		, 0 AS [is_permission]
	FROM [TECDB].[TEC_E_Learning].[dbo].[vew_HRMS_Employee]
	WHERE [INACTIVE] IS NULL
		AND [CODEMPID] != '';

	---- # เอา data เข้า
	MERGE [APCSProDWR].[req].[users] AS [emp_req]
	USING @table AS [emp] ON ([emp_req].[emp_num] = [emp].[emp_num]) 
	WHEN MATCHED AND (ISNULL([emp_req].[name], '') != ISNULL([emp].[name], '')
		OR ISNULL([emp_req].[full_name], '') != ISNULL([emp].[full_name], '')
		OR ISNULL([emp_req].[full_name_eng], '') != ISNULL([emp].[full_name_eng], '')
		OR ISNULL([emp_req].[headquarter], '') != ISNULL([emp].[headquarter], '')
		OR ISNULL([emp_req].[division], '') != ISNULL([emp].[division], '')
		OR ISNULL([emp_req].[department], '') != ISNULL([emp].[department], '')
		OR ISNULL([emp_req].[section], '') != ISNULL([emp].[section], '')
	)
	THEN UPDATE SET 
		--[emp_req].[name] = [emp].[name]
		--, [emp_req].[full_name] = [emp].[full_name]
		--, [emp_req].[full_name_eng] = [emp].[full_name_eng],
		[emp_req].[headquarter] = [emp].[headquarter]
		, [emp_req].[division] = [emp].[division]
		, [emp_req].[department] = [emp].[department]
		, [emp_req].[section] = [emp].[section]
	WHEN NOT MATCHED BY TARGET 
		THEN INSERT ( [emp_num]
			, [password]
			, [name]
			, [full_name]
			, [full_name_eng]
			, [headquarter]
			, [division]
			, [department]
			, [section]
			, [is_permission] ) 
		VALUES ( [emp].[emp_num]
			, [emp].[password]
			, [emp].[name]
			, [emp].[full_name]
			, [emp].[full_name_eng]
			, [emp].[headquarter]
			, [emp].[division]
			, [emp].[department]
			, [emp].[section]
			, [emp].[is_permission]);

	DECLARE @table_230 TABLE 
	(
		[emp_id] [int]
		, [emp_code] [nvarchar](10)
	)

	INSERT INTO @table_230
	SELECT [id]
      , [emp_code]
	FROM [10.29.1.230].[DWH].[man].[employees];

	UPDATE [old]
	SET [old].[dwh_employee_id] = [new].[emp_id]
	FROM [APCSProDWR].[req].[users] AS [old]
	INNER JOIN @table_230 AS [new] ON [old].[emp_num] = [new].[emp_code]
	WHERE [old].[dwh_employee_id] IS NULL;
END