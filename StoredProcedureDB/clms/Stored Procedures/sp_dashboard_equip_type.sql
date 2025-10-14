-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [clms].[sp_dashboard_equip_type]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from

SELECT count(1) as count_type,ref.ref_desc
  FROM [APCSProDB].[clms].[cb_equip] eq left join [APCSProDB].[clms].[cb_ref_value] ref
  on eq.eq_type =ref.ref_id
  group by ref.ref_desc
  having count(1) > 1
END
