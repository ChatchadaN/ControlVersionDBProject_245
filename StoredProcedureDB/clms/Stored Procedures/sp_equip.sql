-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [clms].[sp_equip]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT ref.ref_desc as eq_type,count(*) as [count]
	 FROM [APCSProDB].[clms].[cb_equip] eq  left join [APCSProDB].[clms].[cb_ref_value] ref
  on eq.eq_type =ref.ref_id 
  
  group by ref.ref_desc
 
END
