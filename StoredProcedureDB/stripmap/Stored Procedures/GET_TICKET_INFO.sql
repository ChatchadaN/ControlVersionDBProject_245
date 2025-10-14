-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[GET_TICKET_INFO]
	-- Add the parameters for the stored procedure here
	@TICKET_ID INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select DS.device_slip_id as TICKET_ID, DN.assy_name + ' Version.' + CAST(DS.version_num as varchar(3)) as TICKET_NAME, '' as PRD_TYPE, PK.name as TYPE_NAME
	from APCSProDB.method.device_slips as DS with(nolock)
	inner join APCSProDB.method.device_versions as DV with(nolock) on DV.device_id = DS.device_id
	inner join APCSProDB.method.device_names as DN with(nolock) on DN.id = DV.device_name_id
	inner join APCSProDB.method.packages as PK with(nolock) on PK.id = DN.package_id
	where DS.device_slip_id = @TICKET_ID
	
	return @@ROWCOUNT
END
