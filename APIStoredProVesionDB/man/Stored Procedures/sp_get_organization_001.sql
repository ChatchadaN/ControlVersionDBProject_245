-- =============================================
-- Author:		<Author,,Name>
-- Create date: <03/03/2021,,>
-- Description:	<ORGANIZATION,,>
-- =============================================
CREATE PROCEDURE [man].[sp_get_organization_001]
	-- Add the parameters for the stored procedure here
	@table_name int --1 = factories, 2 = groups, 3 = headquarters, 4 = divisions, 5 = departments , 6 = sections, 7 = organizationList

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	-- Start Check table name
		IF @table_name = 1
	BEGIN
	---factories
	SELECT [id]
      ,[name]
      ,[short_name]
      ,[factory_code]
      ,isnull([factory_bu_code],'') AS factory_bu_code
      ,[factory_char]
      ,[default_language]
      --,[created_at]
      --,[created_by]
      --,[updated_at]
      --,[updated_by]
      --,[is_active]
  FROM [DWH].[man].[factories]
  where [is_active] = 1
  ---factories
  END
	ELSE IF @table_name = 2
	BEGIN
	---groups
	SELECT  [id]
      ,[name]
      ,isnull([short_name],'') AS short_name
      ,[group_code]
      ,[factory_id]
      --,[created_at]
      --,[created_by]
      --,[updated_at]
      --,[updated_by]
      --,[is_active]
  FROM [DWH].[man].[groups]
  where [is_active] = 1
  ---groups
  END
		ELSE IF @table_name = 3
	BEGIN
		---headquarters
	SELECT  [id]
      ,[name]
      ,isnull([short_name],'') AS short_name
      ,[hq_code]
      ,[group_id]
      --,[created_at]
      --,[created_by]
      --,[updated_at]
      --,[updated_by]
      --,[is_active]
  FROM [DWH].[man].[headquarters]
    where [is_active] = 1
		
		---headquarters
	END
	ELSE IF @table_name = 4
	BEGIN
		---divisions
	SELECT [id]
      ,[name]
      ,isnull([short_name],'') AS short_name
      ,[division_code]
      ,[headquarter_id]
      --,[is_production]
      --,[created_at]
      --,[created_by]
      --,[updated_at]
      --,[updated_by]
      --,[is_active]
  FROM [DWH].[man].[divisions]
    where  [is_active] = 1
		
		---division
	END
	ELSE IF @table_name = 5
	BEGIN
		--departments
		SELECT [id]
      ,[name]
      ,isnull([short_name],'') AS short_name
      ,[department_code]
      ,[division_id]
      --,[created_at]
      --,[created_by]
      --,[updated_at]
      --,[updated_by]
      --,[is_active]
  FROM [DWH].[man].[departments]
  where [is_active] = 1
		
		--department
	END
	ELSE IF @table_name = 6
	BEGIN
		--sections
SELECT [id]
      ,[name]
      ,isnull([short_name],'') AS short_name
      ,[section_code]
      ,[department_id]
      --,[created_at]
      --,[created_by]
      --,[updated_at]
      --,[updated_by]
      --,[is_active]
  FROM [DWH].[man].[sections]
   where  [is_active] = 1
		
		--section
	END
	ELSE IF @table_name = 7
	BEGIN
		--organizations
	 SELECT [id]
      ,[business_unit_id]
      ,[business_unit_code]
      ,[business_unit_level]
      ,[business_unit_name_eng]
      ,[business_unit_name_th]
      ,isnull([group],'') AS [group]
      ,isnull([hq],'') AS [hq]
      ,isnull([division],'') as [division]
      ,isnull([department],'') as [department]
      ,isnull([section],'')  as [section]
      --,[is_active]
      --,[created_at]
      --,[created_by]
      --,[updated_at]
      --,[updated_by]
  FROM [DWH].[man].[organizations]
  where   [is_active] = 1 
		--organizations

	END
	
END
