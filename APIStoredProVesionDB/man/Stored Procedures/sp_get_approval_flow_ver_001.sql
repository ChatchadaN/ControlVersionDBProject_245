-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [man].[sp_get_approval_flow_ver_001]
	@emp_code varchar(10)
AS
BEGIN
	
	SET NOCOUNT ON;

	IF EXISTS ( SELECT e.id FROM DWH.man.employees e 
				JOIN [DWH].[man].[employees_supervisor_span] ep ON e.id = ep.emp_id
				WHERE e.emp_code = @emp_code )
	BEGIN
		SELECT
			'TRUE' AS Is_Pass 
		  , '' AS Error_Message_ENG
		  , '' AS Error_Message_THA
		  , '' AS Handling,
 		  emp_self.emp_code,
		  MAX(CASE WHEN role = 'supervisor_1' THEN emp.emp_code END) AS s1_emp_code,
		  MAX(CASE WHEN role = 'supervisor_1' THEN emp.display_name END) AS s1_display_name,
		  MAX(CASE WHEN role = 'supervisor_1' THEN emp.email END) s1_email,
		  MAX(CASE WHEN role = 'supervisor_2' THEN emp.emp_code END) AS s2_emp_code,
		  MAX(CASE WHEN role = 'supervisor_2' THEN emp.display_name END) AS s2_display_name,
		  MAX(CASE WHEN role = 'supervisor_2' THEN emp.email END) s2_email,
		  MAX(CASE WHEN role = 'supervisor_3' THEN emp.emp_code END) AS s3_emp_code,
		  MAX(CASE WHEN role = 'supervisor_3' THEN emp.display_name END) AS s3_display_name,
		  MAX(CASE WHEN role = 'supervisor_3' THEN emp.email END) s3_email,
		  MAX(CASE WHEN role = 'supervisor_4' THEN emp.emp_code END) AS s4_emp_code,
		  MAX(CASE WHEN role = 'supervisor_4' THEN emp.display_name END) AS s4_display_name,
		  MAX(CASE WHEN role = 'supervisor_4' THEN emp.email END) s4_email,
		  MAX(CASE WHEN role = 'supervisor_5' THEN emp.emp_code END) AS s5_emp_code,
		  MAX(CASE WHEN role = 'supervisor_5' THEN emp.display_name END) AS s5_display_name,
		  MAX(CASE WHEN role = 'supervisor_5' THEN emp.email END) s5_email,
		  MAX(CASE WHEN role = 'supervisor_6' THEN emp.emp_code END) AS s6_emp_code,
		  MAX(CASE WHEN role = 'supervisor_6' THEN emp.display_name END) AS s6_display_name,
		  MAX(CASE WHEN role = 'supervisor_6' THEN emp.email END) s6_email
		FROM [DWH].[man].[employees_supervisor_span] af
		CROSS APPLY (
 		  VALUES
   			(af.supervisor_id_step1, 'supervisor_1'),
   			(af.supervisor_id_step2, 'supervisor_2'),
   			(af.supervisor_id_step3, 'supervisor_3'),
			(af.supervisor_id_step4, 'supervisor_4'),
			(af.supervisor_id_step5, 'supervisor_5'),
			(af.supervisor_id_step6, 'supervisor_6')
		) AS roles(employee_id, role)
		LEFT JOIN DWH.man.employees emp_self ON emp_self.id = af.emp_id
		LEFT JOIN DWH.man.employees emp ON emp.id = roles.employee_id
		WHERE emp_self.emp_code = @emp_code
		GROUP BY af.emp_id, emp_self.emp_code;
	END
	ELSE
	BEGIN
		SELECT
			'FALSE'				AS Is_Pass 
		  , 'Data not found!'	AS Error_Message_ENG
		  , N'ไม่พบข้อมูล'         AS Error_Message_THA
		  , N''                 AS Handling;

	END

END
