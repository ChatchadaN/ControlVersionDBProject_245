-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [clms].[_sp_dashboard_calibrator]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT u.name,u.emp_num, cb.regis_date,cb.renew_date,cb.end_date
	from APCSProDB.clms.calibrator as cb inner join APCSProDB.man.users as u
	on cb.user_id = u.id
END
