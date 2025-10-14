-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [clms].[sp_grr_result_detail]
@grr_id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select g.*,u.name ,u.emp_num  from [APCSProDB].[clms].[cb_grr_detail] g inner join [APCSProDB].[man].[users] u 
	on g.chk_user_id = u.id
	where grr_id =@grr_id and g.seq_title <> 'AVGTOTAL'
	  order by u.emp_num,seq
END


