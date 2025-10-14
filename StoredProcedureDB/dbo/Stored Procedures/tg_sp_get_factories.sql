
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_factories]
	-- Add the parameters for the stored procedure here
	@emp_no char(6) = ''
AS
BEGIN

	SELECT factories.name as factories_name
	,case when factories.factory_code = '64646' then 'MADE IN THAILAND' --RIST
		  when factories.factory_code = '62300' then 'MADE IN PHILIPPINES' --REPI
		  when factories.factory_code = '61300' then 'MADE IN MALAYSIA' --RWEM
		  else 'MADE IN THAILAND' end as country
	, factories.factory_code
	FROM APCSProDB.man.users
	INNER JOIN APCSProDB.man.user_organizations 
		on users.id = user_organizations.user_id
	INNER JOIN APCSProDB.man.organizations 
		on user_organizations.organization_id = organizations.id
	INNER JOIN APCSProDB.man.headquarters 
		on organizations.headquarter_id = headquarters.id
	INNER JOIN APCSProDB.man.factories 
		on headquarters.factory_id = factories.id
	where emp_num = @emp_no
	
END
