-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

CREATE PROCEDURE [bms].[sp_get_ft_user]
	-- Add the parameters for the stored procedure here
	@typepm varchar(50) = '%'
	--,@lbGroup varchar(50) = '%'
	--, @package varchar(50) = '%'
	--, @lotType varchar(50) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	 IF(@typepm = 'EE')
	 Begin
	 select ID from DBx.dbo.BMEmployee where (DepartmentID = 'PM13') and ID !='1333' order By ID
	 End
	 IF(@typepm = 'EDS')
	 Begin
	 select ID from DBx.dbo.BMEmployee where DepartmentID = 'PM10' order By ID
	 End
	 ELSE
	 Begin
	 select ID from DBx.dbo.BMEmployee where (DepartmentID = 'PM8') and ID != '642' and ID != '5600' and ID != '3693' and ID != '5755' order By DepartmentID desc,ID
	 End

END
