

CREATE PROCEDURE [trans].[get_data_lot_history_log_001] 
	 @lot_no varchar(10)
	
AS
BEGIN
  select [lot_no]
		, [item_no] 
		, [qrcode_1]
		, [qrcode_2]
		, item_labels.label_eng AS [status]
		,emp_no
		,divisions.id as divisions_id
		,divisions.[name] as Division

	from [AppDB_app_244].[trans].[compare_data_center]
	 INNER JOIN [DWH].[man].[employees] on emp_no = emp_code
	 INNER JOIN [DWH].man.employee_organizations ON employees.id = employee_organizations.emp_id
	 INNER JOIN [DWH].man.organizations on employee_organizations.organization_id = organizations.id
	 LEFT JOIN [DWH].man.divisions ON [DWH].man.divisions.name = [DWH].man.organizations.division
	 --LEFT JOIN [DWH].man.departments  ON [DWH].man.departments.name = [DWH].man.organizations.department
	 --LEFT JOIN [DWH].man.sections  ON [DWH].man.sections.name = [DWH].man.organizations.section
	 LEFT JOIN [AppDB_app_244].[trans].[item_labels] on [compare_data_center].[status] = [item_labels].val and item_labels.name = 'vca.state'
	where [lot_no] = @lot_no;
END