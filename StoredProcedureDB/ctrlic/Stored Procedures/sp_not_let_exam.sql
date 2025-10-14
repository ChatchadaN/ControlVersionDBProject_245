-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [ctrlic].[sp_not_let_exam] 
	@plan_id bigint
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SELECT       ROW_NUMBER() OVER(ORDER BY APCSProDB.ctrlic.exam_plan_detail.plan_id, APCSProDB.man.users.id,APCSProDB.ctrlic.exam_group.ex_id) as let_id ,null let_date,
                         APCSProDB.man.users.full_name, APCSProDB.ctrlic.exam_plan_detail.plan_id, APCSProDB.ctrlic.exam_plan_detail.plan_trn_id, APCSProDB.man.view_user_organizations.division_id, APCSProDB.man.view_user_organizations.department_id, APCSProDB.man.view_user_organizations.section_id, 
                         APCSProDB.man.users.emp_num,APCSProDB.man.users.id as user_id, APCSProDB.man.users.id, APCSProDB.ctrlic.exam_group.ex_id, null let_by
FROM            APCSProDB.man.view_user_organizations INNER JOIN
                         APCSProDB.man.departments ON APCSProDB.man.view_user_organizations.department_id = APCSProDB.man.departments.id AND APCSProDB.man.view_user_organizations.department_id = APCSProDB.man.departments.id AND 
                         APCSProDB.man.view_user_organizations.department_id = APCSProDB.man.departments.id AND APCSProDB.man.view_user_organizations.department_id = APCSProDB.man.departments.id AND APCSProDB.man.view_user_organizations.department_id = APCSProDB.man.departments.id AND 
                         APCSProDB.man.view_user_organizations.department_id = APCSProDB.man.departments.id INNER JOIN
                         APCSProDB.man.divisions ON APCSProDB.man.view_user_organizations.division_id = APCSProDB.man.divisions.id AND APCSProDB.man.view_user_organizations.division_id = APCSProDB.man.divisions.id AND APCSProDB.man.view_user_organizations.division_id = APCSProDB.man.divisions.id AND 
                         APCSProDB.man.view_user_organizations.division_id = APCSProDB.man.divisions.id AND APCSProDB.man.view_user_organizations.division_id = APCSProDB.man.divisions.id AND APCSProDB.man.view_user_organizations.division_id = APCSProDB.man.divisions.id INNER JOIN
                         APCSProDB.man.sections ON APCSProDB.man.view_user_organizations.section_id = APCSProDB.man.sections.id AND APCSProDB.man.view_user_organizations.section_id = APCSProDB.man.sections.id AND APCSProDB.man.view_user_organizations.section_id = APCSProDB.man.sections.id AND 
                         APCSProDB.man.view_user_organizations.section_id = APCSProDB.man.sections.id AND APCSProDB.man.view_user_organizations.section_id = APCSProDB.man.sections.id AND APCSProDB.man.view_user_organizations.section_id = APCSProDB.man.sections.id RIGHT OUTER JOIN
                         APCSProDB.man.user_organizations ON APCSProDB.man.view_user_organizations.id = APCSProDB.man.user_organizations.organization_id AND APCSProDB.man.view_user_organizations.id = APCSProDB.man.user_organizations.organization_id AND 
                         APCSProDB.man.view_user_organizations.id = APCSProDB.man.user_organizations.organization_id AND APCSProDB.man.view_user_organizations.id = APCSProDB.man.user_organizations.organization_id AND 
                         APCSProDB.man.view_user_organizations.id = APCSProDB.man.user_organizations.organization_id AND APCSProDB.man.view_user_organizations.id = APCSProDB.man.user_organizations.organization_id AND 
                         APCSProDB.man.view_user_organizations.id = APCSProDB.man.user_organizations.organization_id RIGHT OUTER JOIN
                         APCSProDB.man.users INNER JOIN
                         APCSProDB.ctrlic.user_exam_group ON APCSProDB.man.users.id = APCSProDB.ctrlic.user_exam_group.user_id INNER JOIN
                         APCSProDB.ctrlic.exam_group INNER JOIN
                         APCSProDB.ctrlic.exam_plan_detail ON APCSProDB.ctrlic.exam_group.ex_group = APCSProDB.ctrlic.exam_plan_detail.ex_group ON APCSProDB.ctrlic.user_exam_group.user_group = APCSProDB.ctrlic.exam_plan_detail.user_group ON APCSProDB.man.user_organizations.user_id = APCSProDB.man.users.id AND 
                         APCSProDB.man.user_organizations.user_id = APCSProDB.man.users.id AND APCSProDB.man.user_organizations.user_id = APCSProDB.man.users.id AND APCSProDB.man.user_organizations.user_id = APCSProDB.man.users.id AND APCSProDB.man.user_organizations.user_id = APCSProDB.man.users.id AND 
                         APCSProDB.man.user_organizations.user_id = APCSProDB.man.users.id
                        WHERE     APCSProDB.ctrlic.exam_plan_detail.plan_id =@plan_id AND   (NOT EXISTS
                             (SELECT        1 AS Expr1
                               FROM            APCSProDB.ctrlic.let_exam_plan AS e
                               WHERE        (plan_id = APCSProDB.ctrlic.exam_plan_detail.plan_id) AND (ex_id = APCSProDB.ctrlic.exam_group.ex_id) AND (user_id = APCSProDB.man.users.id))) 

END
