CREATE  PROCEDURE [clms].[sp_dashboard_equip_status]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from

SELECT count(1) as count_type,status
  FROM [APCSProDB].[clms].[cb_equip]  
  group by status

END
