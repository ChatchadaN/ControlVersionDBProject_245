
CREATE PROCEDURE [man].[merge_man_from_onebook]
	-- Add the parameters for the stored procedure here
	 @target_tb AS VARCHAR(100)
AS
BEGIN
BEGIN try


	IF (@target_tb = 'groups')
		BEGIN
			MERGE INTO DWH.man.groups AS grp
			USING (
				SELECT grp_name, tb.factory_code, tb.group_code , fact.id as fact_id, tb.is_active
				  FROM
					  (
						SELECT DISTINCT [Group] as grp_name
							, SUBSTRING(BusinessUnitCode, 1,3) AS factory_code
							, SUBSTRING(BusinessUnitCode, 4,3) AS group_code
							, iif([Status]='active',1,0) as is_active
						FROM [10.29.1.88].[HRMSLocal].[dbo].[OneBook_BusinessUnitMaster]
						WHERE [Group] IS NOT NULL
						AND LEN(BusinessUnitCode) = 6
					  ) AS tb
				  LEFT JOIN [DWH].[man].[factories] fact ON  tb.factory_code = fact.factory_bu_code collate SQL_Latin1_General_CP1_CI_AS
				) AS source_tb
			ON grp.factory_id = source_tb.fact_id and grp.group_code = source_tb.group_code collate SQL_Latin1_General_CP1_CI_AS
			WHEN MATCHED AND (
				ISNULL([grp].[name] COLLATE SQL_Latin1_General_CP1_CI_AS, '') != ISNULL([source_tb].grp_name COLLATE SQL_Latin1_General_CP1_CI_AS, '')
				OR [grp].[is_active] <> [source_tb].[is_active] )				
			THEN
				UPDATE SET grp.name = source_tb.grp_name, grp.is_active = source_tb.is_active, grp.updated_at = getdate()
			WHEN NOT MATCHED THEN
				INSERT (name, group_code, factory_id, created_at) VALUES (source_tb.grp_name, source_tb.group_code, source_tb.fact_id, getdate());
		
		END

	ELSE IF (@target_tb = 'headquarters')
		BEGIN
			MERGE INTO DWH.man.headquarters AS h
			USING (
				SELECT HQ as name, groups.id group_id, hq_code, create_date, create_by, tb.is_active
				 FROM 
				 ( 
					 SELECT DISTINCT HQ, SUBSTRING(BusinessUnitCode, 1,3) AS factory_code
						, SUBSTRING(BusinessUnitCode, 4,3) AS group_code
						, SUBSTRING(BusinessUnitCode, 7,3) AS hq_code
						, GETDATE() as create_date, 703 as create_by
						, iif([Status]='active',1,0) as is_active
					  FROM [10.29.1.88].[HRMSLocal].[dbo].[OneBook_BusinessUnitMaster]
					  WHERE HQ IS NOT NULL
					  AND LEN(BusinessUnitCode) = 9
				  ) AS tb
				  LEFT JOIN [DWH].[man].[factories] ON  tb.factory_code = factories.factory_bu_code collate SQL_Latin1_General_CP1_CI_AS
				  LEFT JOIN [DWH].[man].[groups] ON  tb.group_code = groups.group_code collate SQL_Latin1_General_CP1_CI_AS
				) AS s
			ON h.group_id = s.group_id and h.hq_code = s.hq_code collate SQL_Latin1_General_CP1_CI_AS
			WHEN MATCHED AND  ( 
				ISNULL([h].[name]COLLATE SQL_Latin1_General_CP1_CI_AS, '') != ISNULL([s].[name]COLLATE SQL_Latin1_General_CP1_CI_AS, '')
				OR [h].[is_active] <> [s].[is_active] )  
			THEN
				UPDATE SET h.name = s.name, h.is_active = s.is_active, h.updated_at = getdate()
			WHEN NOT MATCHED THEN
				INSERT (name, hq_code, group_id, created_at) VALUES (s.name, s.hq_code, s.group_id, getdate());

		END

	ELSE IF (@target_tb = 'divisions')
		BEGIN
			MERGE INTO DWH.man.divisions AS div
			USING (
				SELECT  tb.division_name, tb.division_code, headquarters.id hq_id, tb.is_active
				 FROM 
				 ( 
					SELECT DISTINCT division as division_name
						, SUBSTRING(BusinessUnitCode, 1,3) AS fac_code
						, SUBSTRING(BusinessUnitCode, 4,3) AS grp_code
						, SUBSTRING(BusinessUnitCode, 7,3) AS hq_code
						, SUBSTRING(BusinessUnitCode, 10,3) AS division_code
						, iif([Status]='active',1,0) as is_active
					  FROM [10.29.1.88].[HRMSLocal].[dbo].[OneBook_BusinessUnitMaster]
					  WHERE division IS NOT NULL
					  AND LEN(BusinessUnitCode) = 12
				 ) as tb
				 JOIN [DWH].[man].headquarters ON tb.hq_code = headquarters.hq_code collate SQL_Latin1_General_CP1_CI_AS
				 JOIN [DWH].[man].groups ON  headquarters.group_id = groups.id and tb.grp_code = groups.group_code collate SQL_Latin1_General_CP1_CI_AS
				 JOIN [DWH].[man].[factories] ON  groups.factory_id = factories.id and tb.fac_code = [factories].factory_bu_code collate SQL_Latin1_General_CP1_CI_AS
				) AS sour
			ON div.headquarter_id = sour.hq_id and div.division_code = sour.division_code collate SQL_Latin1_General_CP1_CI_AS
			WHEN MATCHED AND  ( 
				ISNULL([div].[name]COLLATE SQL_Latin1_General_CP1_CI_AS, '') != ISNULL([sour].[division_name]COLLATE SQL_Latin1_General_CP1_CI_AS, '')
				OR [div].[is_active] <> [sour].[is_active] )  
			THEN
				UPDATE SET div.name = sour.division_name, div.is_active = sour.is_active, div.updated_at = getdate()
			WHEN NOT MATCHED THEN
				INSERT (name, division_code, headquarter_id, created_at) VALUES (sour.division_name, sour.division_code, sour.hq_id, getdate());

		END

	ELSE IF (@target_tb = 'departments')
		BEGIN
			MERGE INTO DWH.man.departments AS dept
			USING (
				SELECT  tb.Department, tb.dept_code, divisions.id divisions_id, tb.is_active
				 FROM 
				 ( 
					SELECT DISTINCT Department as Department
						, SUBSTRING(BusinessUnitCode, 1,3) AS fac_code
						, SUBSTRING(BusinessUnitCode, 4,3) AS grp_code
						, SUBSTRING(BusinessUnitCode, 7,3) AS hq_code
						, SUBSTRING(BusinessUnitCode, 10,3) AS divion_code
						, SUBSTRING(BusinessUnitCode, 13,3) AS dept_code
						, iif([Status]='active',1,0) as is_active
					  FROM [10.29.1.88].[HRMSLocal].[dbo].[OneBook_BusinessUnitMaster]
					  WHERE Department IS NOT NULL
					  AND LEN(BusinessUnitCode) = 15
				 ) as tb
				 JOIN [DWH].[man].divisions ON  tb.divion_code = divisions.division_code collate SQL_Latin1_General_CP1_CI_AS
				 JOIN [DWH].[man].headquarters ON  divisions.headquarter_id = headquarters.id and tb.hq_code = headquarters.hq_code collate SQL_Latin1_General_CP1_CI_AS
				 JOIN [DWH].[man].groups ON  headquarters.group_id = groups.id and tb.grp_code = groups.group_code collate SQL_Latin1_General_CP1_CI_AS
				 JOIN [DWH].[man].[factories] ON  groups.factory_id = factories.id and tb.fac_code = [factories].factory_bu_code collate SQL_Latin1_General_CP1_CI_AS
			) as sour_dept
			on dept.division_id = sour_dept.divisions_id and dept.department_code = sour_dept.dept_code collate SQL_Latin1_General_CP1_CI_AS
			WHEN MATCHED AND  ( 
				ISNULL([dept].[name]COLLATE SQL_Latin1_General_CP1_CI_AS, '') != ISNULL([sour_dept].[Department]COLLATE SQL_Latin1_General_CP1_CI_AS, '')
				OR [dept].[is_active] <> [sour_dept].[is_active] )  
			THEN
				UPDATE SET dept.name = sour_dept.Department, dept.is_active = sour_dept.is_active, dept.updated_at = getdate()
			WHEN NOT MATCHED THEN
				INSERT (name, department_code, division_id, created_at) VALUES (sour_dept.Department, sour_dept.dept_code, sour_dept.divisions_id, getdate());

		END
	ELSE IF (@target_tb = 'sections')
		BEGIN
			MERGE INTO DWH.man.sections AS sect
			USING (
				SELECT  tb.section_name, tb.sect_code, departments.id department_id, tb.is_active
				 FROM 
				 ( 
					SELECT DISTINCT [Section] as section_name
						, SUBSTRING(BusinessUnitCode, 16,3) AS sect_code
						, SUBSTRING(BusinessUnitCode, 13,3) AS dept_code
						, SUBSTRING(BusinessUnitCode, 10,3) AS divion_code
						, SUBSTRING(BusinessUnitCode, 7,3) AS hq_code
						, SUBSTRING(BusinessUnitCode, 4,3) AS grp_code
						, SUBSTRING(BusinessUnitCode, 1,3) AS fac_code
						, iif([Status]='active',1,0) as is_active
					  FROM [10.29.1.88].[HRMSLocal].[dbo].[OneBook_BusinessUnitMaster]
					  WHERE [Section] IS NOT NULL
					  AND LEN(BusinessUnitCode) = 18
				 ) as tb
				 JOIN [DWH].[man].departments ON  tb.dept_code = departments.department_code collate SQL_Latin1_General_CP1_CI_AS
				 JOIN [DWH].[man].divisions ON  departments.division_id = divisions.id and tb.divion_code = divisions.division_code  collate SQL_Latin1_General_CP1_CI_AS
				 JOIN [DWH].[man].headquarters ON  divisions.headquarter_id = headquarters.id and tb.hq_code = headquarters.hq_code collate SQL_Latin1_General_CP1_CI_AS
				 JOIN [DWH].[man].groups ON  headquarters.group_id = groups.id and tb.grp_code = groups.group_code collate SQL_Latin1_General_CP1_CI_AS
				 JOIN [DWH].[man].[factories] ON  groups.factory_id = factories.id and tb.fac_code = [factories].factory_bu_code collate SQL_Latin1_General_CP1_CI_AS
			) as sour_sect
			on sect.department_id = sour_sect.department_id and sect.section_code = sour_sect.sect_code collate SQL_Latin1_General_CP1_CI_AS
			WHEN MATCHED AND  ( 
				ISNULL([sect].[name]COLLATE SQL_Latin1_General_CP1_CI_AS, '') != ISNULL([sour_sect].[section_name]COLLATE SQL_Latin1_General_CP1_CI_AS, '')
				OR [sect].[is_active] <> [sour_sect].[is_active]) 
			THEN 
				UPDATE SET sect.name = sour_sect.section_name, sect.is_active = sour_sect.is_active, sect.updated_at = getdate()
			WHEN NOT MATCHED THEN
				INSERT (name, section_code, department_id, created_at) VALUES (sour_sect.section_name, sour_sect.sect_code, sour_sect.department_id, getdate());

		END

	ELSE IF (@target_tb = 'organizations') 
		BEGIN
			MERGE INTO DWH.man.organizations AS org
			USING (
				SELECT 
					[BusinessUnitId] bu_id
				  ,[BusinessUnitCode] bu_code
				  ,[BusinessUnitLevel] bu_level
				  ,[BusinessUnitNameEH] name_en
				  ,[BusinessUnitNameTH] name_th
				  ,[Group] grp
				  ,[HQ] hq
				  ,[Division] division
				  ,[Department] department
				  ,[Section] section
				  , iif([Status]='active',1,0) as is_active
				FROM [10.29.1.88].[HRMSLocal].[dbo].[OneBook_BusinessUnitMaster]
			) AS sour_org
			ON org.business_unit_id  = sour_org.bu_id collate SQL_Latin1_General_CP1_CI_AS
			WHEN MATCHED AND ( 
			ISNULL([org].[business_unit_level] , '') != ISNULL([sour_org].[bu_level] , '')
			OR ISNULL([org].[business_unit_name_eng]COLLATE SQL_Latin1_General_CP1_CI_AS, '') != ISNULL([sour_org].[name_en]COLLATE SQL_Latin1_General_CP1_CI_AS, '')
			OR ISNULL([org].[business_unit_name_th]COLLATE SQL_Latin1_General_CP1_CI_AS, '') != ISNULL([sour_org].[name_th]COLLATE SQL_Latin1_General_CP1_CI_AS, '')
			OR ISNULL([org].[group]COLLATE SQL_Latin1_General_CP1_CI_AS, '') != ISNULL([sour_org].[grp]COLLATE SQL_Latin1_General_CP1_CI_AS, '')
			OR ISNULL([org].[hq]COLLATE SQL_Latin1_General_CP1_CI_AS, '') != ISNULL([sour_org].[hq]COLLATE SQL_Latin1_General_CP1_CI_AS, '')
			OR ISNULL([org].[division]COLLATE SQL_Latin1_General_CP1_CI_AS, '') != ISNULL([sour_org].[division]COLLATE SQL_Latin1_General_CP1_CI_AS, '')
			OR ISNULL([org].[department]COLLATE SQL_Latin1_General_CP1_CI_AS, '') != ISNULL([sour_org].[department]COLLATE SQL_Latin1_General_CP1_CI_AS, '')
			OR ISNULL([org].[section]COLLATE SQL_Latin1_General_CP1_CI_AS, '') != ISNULL([sour_org].[section]COLLATE SQL_Latin1_General_CP1_CI_AS, '')
			OR ISNULL([org].[is_active], '') != ISNULL([sour_org].[is_active], '')
			
			) THEN
				UPDATE SET	org.business_unit_level = sour_org.bu_level,
							org.business_unit_name_eng = sour_org.name_en, 
							org.business_unit_name_th = sour_org.name_th,
							org.[group] = sour_org.grp, org.hq = sour_org.hq, 
							org.division = sour_org.division,
							org.department = sour_org.department, 
							org.section = sour_org.section, 
							org.is_active = sour_org.is_active,
							org.updated_at = getdate()
			WHEN NOT MATCHED THEN
				INSERT (business_unit_id, business_unit_code, business_unit_level, business_unit_name_eng, business_unit_name_th,
						[group], hq, division, department, section, is_active, created_at) 
						VALUES (sour_org.bu_id, sour_org.bu_code, sour_org.bu_level,
								sour_org.name_en, sour_org.name_th, sour_org.grp, sour_org.hq, 
								sour_org.division, sour_org.department, sour_org.section, sour_org.is_active, getdate());
		END
	ELSE IF (@target_tb = 'employee_organizations') 
		BEGIN
			MERGE INTO DWH.man.employee_organizations AS emp_org
			USING (
					SELECT emp.id as emp_id, org.id as org_id
					FROM [DWH].[man].[employees] emp
					JOIN [10.29.1.88].[HRMSLocal].[dbo].[OneBook_EmployeeInfo] one_emp on emp.emp_code = one_emp.EmployeeCode collate SQL_Latin1_General_CP1_CI_AS
					JOIN [DWH].[man].organizations org on one_emp.BusinessUnitCode = org.business_unit_id collate SQL_Latin1_General_CP1_CI_AS
			) AS sour_emp_org
			ON emp_org.emp_id = sour_emp_org.emp_id
			WHEN MATCHED AND  ( ISNULL([emp_org].[organization_id], '') != ISNULL([sour_emp_org].[org_id], '')) THEN
				UPDATE SET	emp_org.organization_id = sour_emp_org.org_id, emp_org.updated_at = getdate()
			WHEN NOT MATCHED THEN
				INSERT (emp_id, organization_id, created_at) VALUES (sour_emp_org.emp_id, sour_emp_org.org_id, getdate());
		END
	ELSE IF (@target_tb = 'employee_levels')
		BEGIN
		MERGE INTO DWH.man.employee_levels AS emplevel
		USING (
				SELECT  tb.emp_level_name,tb.short_name,tb.level_code,tb.create_date,tb.create_by
				FROM (
					SELECT DISTINCT [EmployeeLevelNameEN] AS emp_level_name 
					,SUBSTRING([EmployeeLevelNameEN],7,3) AS short_name
					,[EmployeeLevel] AS [level_code]
					,GETDATE() AS create_date, 3611 AS create_by
					FROM [10.29.1.88].[HRMSLocal].[dbo].[OneBook_EmployeeInfo]
					WHERE [EmployeeLevelNameEN] IS NOT NULL 
					) AS tb
					JOIN [DWH].[man].[employee_levels] el ON tb.level_code = el.level_code collate SQL_Latin1_General_CP1_CI_AS
			  ) sour_emplevel
					ON emplevel.level_code = sour_emplevel.level_code collate SQL_Latin1_General_CP1_CI_AS
				WHEN MATCHED AND  ( ISNULL([emplevel].[name]COLLATE SQL_Latin1_General_CP1_CI_AS, '') != ISNULL([sour_emplevel].[emp_level_name]COLLATE SQL_Latin1_General_CP1_CI_AS, '')) THEN 
					UPDATE SET emplevel.name = sour_emplevel.emp_level_name, emplevel.updated_at = getdate()
				WHEN NOT MATCHED THEN
					INSERT (name, short_name, level_code, created_at) VALUES (sour_emplevel.emp_level_name, sour_emplevel.short_name, sour_emplevel.level_code, getdate());
	
		END
	ELSE IF (@target_tb = 'positions')
	 BEGIN
		MERGE INTO DWH.man.positions AS posi
		USING (
 				SELECT  p.postion_name,p.short_name,p.positions_code,el.id AS emp_level_id ,p.create_date,p.create_by
				FROM 
					(SELECT distinct PositionNameEN AS postion_name 
					,SUBSTRING(positioncode,5,6) AS short_name
					,positioncode AS positions_code
					,EmployeeLevel AS emp_level
					,GETDATE() AS create_date, 3611 AS create_by
					FROM [10.29.1.88].[HRMSLocal].[dbo].[OneBook_EmployeeInfo]
					WHERE PositionNameEN IS NOT NULL 
					) AS p
				JOIN [DWH].[man].[employee_levels] el ON p.emp_level = el.level_code collate SQL_Latin1_General_CP1_CI_AS
			   ) AS sour_posi
					ON posi.employee_level_id = sour_posi.emp_level_id and posi.positions_code = sour_posi.positions_code collate SQL_Latin1_General_CP1_CI_AS
					WHEN MATCHED AND  ( ISNULL([posi].[name]COLLATE SQL_Latin1_General_CP1_CI_AS, '') != ISNULL([sour_posi].[postion_name]COLLATE SQL_Latin1_General_CP1_CI_AS, '')) THEN 
						UPDATE SET posi.name = sour_posi.postion_name, posi.updated_at = getdate()
					WHEN NOT MATCHED THEN
						INSERT (name, short_name, positions_code,employee_level_id, created_at) VALUES (sour_posi.postion_name, sour_posi.short_name, sour_posi.positions_code,sour_posi.emp_level_id, getdate());
	 END
	ELSE IF (@target_tb = 'shift_calendars')
	BEGIN
		MERGE INTO DWH.man.shift_calendars AS shi
		USING (SELECT tb.shift_name,tb.short_name,tb.shift_code
				FROM (
						SELECT DISTINCT [ShiftCalendarNameEN] as shift_name 
						, SUBSTRING([ShiftCalendar],5,3) as short_name
						, [ShiftCalendar] as shift_code
						, GETDATE() as create_date, 3611 as create_by
						FROM [10.29.1.88].[HRMSLocal].[dbo].[OneBook_EmployeeInfo]
						WHERE [ShiftCalendarNameEN] IS NOT NULL
						) AS tb
						JOIN [DWH].[man].[shift_calendars] sh on tb.shift_code = sh.shift_code collate SQL_Latin1_General_CP1_CI_AS
			   ) AS sour_shift
				ON shi.shift_code = sour_shift.shift_code  collate SQL_Latin1_General_CP1_CI_AS
				WHEN MATCHED AND  ( ISNULL([shi].[name]COLLATE SQL_Latin1_General_CP1_CI_AS, '') != ISNULL([sour_shift].[shift_name]COLLATE SQL_Latin1_General_CP1_CI_AS, '')) THEN 
					UPDATE SET shi.name = sour_shift.shift_name, shi.updated_at = getdate()
				WHEN NOT MATCHED THEN
					INSERT (name, short_name, shift_code , created_at) VALUES (sour_shift.shift_name, sour_shift.short_name, sour_shift.shift_code, getdate());
	END
	ELSE IF (@target_tb = 'flow_approve')
	BEGIN
		MERGE INTO DWH.man.employees_supervisor_span AS emp_sup_span
		USING (
				SELECT emp.id emp_id, s1.id id_step1, s2.id id_step2, s3.id id_step3, s4.id id_step4, s5.id id_step5, s6.id id_step6, [ModifiedDate]
				FROM ( 
						SELECT
						   [EmployeeCode]
						  ,SUBSTRING([SupervisorCodeStep1],5,6) as SupStep1
						  ,SUBSTRING([SupervisorCodeStep2],5,6) as SupStep2
						  ,SUBSTRING([SupervisorCodeStep3],5,6) as SupStep3
						  ,SUBSTRING([SupervisorCodeStep4],5,6) as SupStep4
						  ,SUBSTRING([SupervisorCodeStep5],5,6) as SupStep5
						  ,SUBSTRING([SupervisorCodeStep6],5,6) as SupStep6
						  ,[ModifiedDate]
						FROM [10.29.1.88].[HRMSLocal].[dbo].[OneBook_SupervisorSpan]
					) AS SupSpan
				LEFT JOIN [DWH].[man].[employees] emp ON  SupSpan.EmployeeCode = emp.emp_code collate SQL_Latin1_General_CP1_CI_AS
				LEFT JOIN [DWH].[man].[employees] s1 ON  SupSpan.SupStep1 = s1.emp_code collate SQL_Latin1_General_CP1_CI_AS
				LEFT JOIN [DWH].[man].[employees] s2 ON  SupSpan.SupStep2 = s2.emp_code collate SQL_Latin1_General_CP1_CI_AS
				LEFT JOIN [DWH].[man].[employees] s3 ON  SupSpan.SupStep3 = s3.emp_code collate SQL_Latin1_General_CP1_CI_AS
				LEFT JOIN [DWH].[man].[employees] s4 ON  SupSpan.SupStep4 = s4.emp_code collate SQL_Latin1_General_CP1_CI_AS
				LEFT JOIN [DWH].[man].[employees] s5 ON  SupSpan.SupStep5 = s5.emp_code collate SQL_Latin1_General_CP1_CI_AS
				LEFT JOIN [DWH].[man].[employees] s6 ON  SupSpan.SupStep6 = s6.emp_code collate SQL_Latin1_General_CP1_CI_AS
		) AS sour_sup_span ON emp_sup_span.emp_id = sour_sup_span.emp_id
		WHEN MATCHED AND ( 
			ISNULL([emp_sup_span].[supervisor_id_step1], '') != ISNULL([sour_sup_span].[id_step1], '')
			OR ISNULL([emp_sup_span].[supervisor_id_step2], '') != ISNULL([sour_sup_span].[id_step2], '')
			OR ISNULL([emp_sup_span].[supervisor_id_step3], '') != ISNULL([sour_sup_span].[id_step3], '')
			OR ISNULL([emp_sup_span].[supervisor_id_step4], '') != ISNULL([sour_sup_span].[id_step4], '')
			OR ISNULL([emp_sup_span].[supervisor_id_step5], '') != ISNULL([sour_sup_span].[id_step5], '')
			OR ISNULL([emp_sup_span].[supervisor_id_step6], '') != ISNULL([sour_sup_span].[id_step6], '')
			
			
			)THEN
			UPDATE SET	emp_sup_span.supervisor_id_step1 = sour_sup_span.id_step1,
						emp_sup_span.supervisor_id_step2 = sour_sup_span.id_step2,
						emp_sup_span.supervisor_id_step3 = sour_sup_span.id_step3,
						emp_sup_span.supervisor_id_step4 = sour_sup_span.id_step4,
						emp_sup_span.supervisor_id_step5 = sour_sup_span.id_step5,
						emp_sup_span.supervisor_id_step6 = sour_sup_span.id_step6,
						emp_sup_span.modifieddate = sour_sup_span.[ModifiedDate],
						emp_sup_span.updated_at = GETDATE()
		WHEN NOT MATCHED THEN
			INSERT (emp_id, supervisor_id_step1, supervisor_id_step2, supervisor_id_step3, supervisor_id_step4, supervisor_id_step5, supervisor_id_step6, modifieddate, created_at) 
			VALUES (sour_sup_span.emp_id, sour_sup_span.id_step1 , sour_sup_span.id_step2 ,sour_sup_span.id_step3 ,sour_sup_span.id_step4 ,sour_sup_span.id_step5 ,sour_sup_span.id_step6, sour_sup_span.[ModifiedDate] , getdate());
	END

END TRY
BEGIN CATCH
PRINT  '---> Error <----' +  ERROR_MESSAGE() + '---> Error <----';
ROLLBACK ;
END CATCH
END
