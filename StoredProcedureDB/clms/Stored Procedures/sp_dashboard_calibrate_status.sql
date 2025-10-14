-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [clms].[sp_dashboard_calibrate_status]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select count(*)as value,display_type,ref_desc from (
SELECT case 
when DATEDIFF(day, GETDATE(), eq.next_chk_date) < 0 then 'Over Time'
when DATEDIFF(day, GETDATE(), eq.next_chk_date) <=60 then 'Must Calibration'
else 'Normal'
end  AS display_type,eq_type
  FROM [APCSProDB].[clms].[cb_equip] eq) as tt left join [APCSProDB].[clms].[cb_ref_value] ref
  on tt.eq_type =ref.ref_id
  where tt.display_type is not null
  group by display_type,ref_desc
END
