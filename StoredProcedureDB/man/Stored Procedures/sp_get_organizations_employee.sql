
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [man].[sp_get_organizations_employee]
	-- Add the parameters for the stored procedure here
	@state INT ,
	@OrgID INT = NULL ,
	@userID INT = NULL,
	@emp_num nvarchar(10) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF @state = 0 --FindOrganizeGroupName 
	BEGIN
		SELECT divisions.name as div 
          ,departments.name as dep
          ,sections.name as sec 
		FROM [APCSProDB].[man].[organizations] 
		LEFT JOIN [APCSProDB].[man].sections    ON [APCSProDB].[man].organizations.section_id = [APCSProDB].[man].sections.id
		LEFT JOIN [APCSProDB].[man].departments ON [APCSProDB].[man].sections.department_id =   [APCSProDB].[man].departments.id OR [APCSProDB].[man].organizations.department_id = [APCSProDB].[man].departments.id
		LEFT JOIN [APCSProDB].[man].divisions   ON [APCSProDB].[man].departments.division_id =  [APCSProDB].[man].divisions.id OR   [APCSProDB].[man].organizations.division_id =   [APCSProDB].[man].divisions.id
		WHERE organizations.id = @OrgID
	END
	
	ELSE IF @state = 1 	--FindOrgIDEdit
	BEGIN
		SELECT organization_id 
		FROM [APCSProDB].[man].[users] 
		LEFT JOIN [APCSProDB].[man].user_organizations ON [APCSProDB].[man].users.id = [APCSProDB].[man].user_organizations.user_id 
		WHERE users.id = @userID
	END

	ELSE IF @state = 2 	-- FindID
BEGIN
	SELECT [id] FROM [APCSProDB].[man].[users] WHERE emp_num = @emp_num

	END
END;
