

CREATE FUNCTION  [man].[fnc_get_employees_id](
	@emp_no NVARCHAR(10)
	 
)
 RETURNS     @table_emp table (
		[emp_id]   INT
		)
 
BEGIN
		DECLARE @emp_id INT 

		INSERT INTO @table_emp  

		SELECT id  FROM [10.29.1.230].[DWH].[man].[employees]
			WHERE [employees].emp_code = @emp_no
 
 return
END;
