-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_system_user]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT host_name,login_name,program_name
	FROM sys.dm_exec_sessions 
	--where login_name not in('LSI\DBSERV$')
	where login_name not in('sa','LSI\DBSERV$')
	--where login_name not in('apcsuser','sa','system','LSI\DBSERV$')
	order by login_name, host_name
END
