-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_qrcode_control]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10)
AS
BEGIN 
	-- SET NOCOUNT ON added to prevent extra result sets from
	DECLARE @control bit,@message varchar(50)
	-- interfering with SELECT statements.
	--, lots.lot_no,packages.short_name,packages.name AS package,package_groups.name package_group 
	SET NOCOUNT ON;
	SET @control = '0'
	SELECT @control = '1' FROM APCSProDB.trans.lots 
INNER JOIN APCSProDB.method.packages ON lots.act_package_id = packages.id
INNER JOIN APCSProDB.method.package_groups ON package_groups.id = packages.package_group_id
WHERE package_groups.[name] NOT IN ('LAPIS','DIP/SDIP') AND lot_no = @lot_no


    -- Insert statements for procedure here
	SELECT @control as is_control , '' as reason
END
