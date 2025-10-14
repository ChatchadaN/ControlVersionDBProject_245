-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [clms].[sp_equip_expire60]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @SQLQuery AS NVARCHAR(1000)
	
    -- Insert statements for procedure here
	set @SQLQuery ='SELECT        eq.eq_name, eq.eq_num, eq.eq_num_old, eq.mc_no, eq.location_use, APCSProDB.clms.cb_ref_value.ref_desc AS model, eq.prod_no, eq.next_chk_date, eq.last_chk_date,
 DATEDIFF(day, GETDATE(), eq.next_chk_date) AS remain_days, eq.chk_locate, sec.name AS use_section, sections_1.name AS chk_section
FROM            APCSProDB.clms.cb_equip AS eq LEFT OUTER JOIN
                         APCSProDB.man.sections AS sections_1 ON eq.chk_sec_id = sections_1.id LEFT OUTER JOIN
                         APCSProDB.man.sections AS sec ON eq.use_sec_id = sec.id LEFT OUTER JOIN
                         APCSProDB.clms.cb_ref_value ON eq.qe_model_id = APCSProDB.clms.cb_ref_value.ref_id
WHERE  (DATEDIFF(day, GETDATE(), eq.next_chk_date) <=90 or DATEDIFF(day, GETDATE(), eq.next_chk_date) <0)'

EXECUTE sp_Executesql @SQLQuery

IF @@ERROR <> 0
	GOTO ErrorHandler

SET NOCOUNT OFF

RETURN (0)

ErrorHandler:

RETURN (@@ERROR)
end
