-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [ctrlic].[sp_let_exam] 
	@plan_id bigint
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SELECT   APCSProDB.ctrlic.let_exam_plan.let_id, APCSProDB.ctrlic.let_exam_plan.let_date, APCSProDB.man.users.full_name, APCSProDB.ctrlic.let_exam_plan.plan_id, CAST(0 AS bigint) AS plan_trn_id, APCSProDB.man.view_user_organizations.division_id, 
                         APCSProDB.man.view_user_organizations.department_id, APCSProDB.man.view_user_organizations.section_id, APCSProDB.man.users.emp_num, APCSProDB.ctrlic.let_exam_plan.user_id, APCSProDB.ctrlic.let_exam_plan.ex_id, APCSProDB.ctrlic.let_exam_plan.let_by
FROM            APCSProDB.man.user_organizations RIGHT OUTER JOIN
                         APCSProDB.man.users INNER JOIN
                         APCSProDB.ctrlic.let_exam_plan ON APCSProDB.man.users.id = APCSProDB.ctrlic.let_exam_plan.user_id ON APCSProDB.man.user_organizations.user_id = APCSProDB.man.users.id AND APCSProDB.man.user_organizations.user_id = APCSProDB.man.users.id AND 
                         APCSProDB.man.user_organizations.user_id = APCSProDB.man.users.id AND APCSProDB.man.user_organizations.user_id = APCSProDB.man.users.id AND APCSProDB.man.user_organizations.user_id = APCSProDB.man.users.id AND APCSProDB.man.user_organizations.user_id = APCSProDB.man.users.id LEFT OUTER JOIN
                         APCSProDB.man.view_user_organizations INNER JOIN
                         APCSProDB.man.departments ON APCSProDB.man.view_user_organizations.department_id = APCSProDB.man.departments.id AND APCSProDB.man.view_user_organizations.department_id = APCSProDB.man.departments.id AND 
                         APCSProDB.man.view_user_organizations.department_id = APCSProDB.man.departments.id AND APCSProDB.man.view_user_organizations.department_id = APCSProDB.man.departments.id AND APCSProDB.man.view_user_organizations.department_id = APCSProDB.man.departments.id AND 
                         APCSProDB.man.view_user_organizations.department_id = APCSProDB.man.departments.id INNER JOIN
                         APCSProDB.man.divisions ON APCSProDB.man.view_user_organizations.division_id = APCSProDB.man.divisions.id AND APCSProDB.man.view_user_organizations.division_id = APCSProDB.man.divisions.id AND APCSProDB.man.view_user_organizations.division_id = APCSProDB.man.divisions.id AND 
                         APCSProDB.man.view_user_organizations.division_id = APCSProDB.man.divisions.id AND APCSProDB.man.view_user_organizations.division_id = APCSProDB.man.divisions.id AND APCSProDB.man.view_user_organizations.division_id = APCSProDB.man.divisions.id INNER JOIN
                         APCSProDB.man.sections ON APCSProDB.man.view_user_organizations.section_id = APCSProDB.man.sections.id AND APCSProDB.man.view_user_organizations.section_id = APCSProDB.man.sections.id AND APCSProDB.man.view_user_organizations.section_id = APCSProDB.man.sections.id AND 
                         APCSProDB.man.view_user_organizations.section_id = APCSProDB.man.sections.id AND APCSProDB.man.view_user_organizations.section_id = APCSProDB.man.sections.id AND APCSProDB.man.view_user_organizations.section_id = APCSProDB.man.sections.id ON 
                         APCSProDB.man.user_organizations.organization_id = APCSProDB.man.view_user_organizations.id AND APCSProDB.man.user_organizations.organization_id = APCSProDB.man.view_user_organizations.id AND 
                         APCSProDB.man.user_organizations.organization_id = APCSProDB.man.view_user_organizations.id AND APCSProDB.man.user_organizations.organization_id = APCSProDB.man.view_user_organizations.id AND 
                         APCSProDB.man.user_organizations.organization_id = APCSProDB.man.view_user_organizations.id AND APCSProDB.man.user_organizations.organization_id = APCSProDB.man.view_user_organizations.id AND 
                         APCSProDB.man.user_organizations.organization_id = APCSProDB.man.view_user_organizations.id
                         Where APCSProDB.ctrlic.let_exam_plan.plan_id = @plan_id

END
