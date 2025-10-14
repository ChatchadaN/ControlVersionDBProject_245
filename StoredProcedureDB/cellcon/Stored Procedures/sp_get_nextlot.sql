-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_nextlot]
	-- Add the parameters for the stored procedure here
	@mc_name varchar(30)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select mc_state.machine_id , machine.name as machine_name,  mc_state.next_lot_id ,lots.lot_no as lot_no,SUBSTRING(loca.[name],7,7)+'-'+ SUBSTRING( loca.[address],1,3) as [location],pkg.[name] as PackageName,dev.[assy_name] as DeviceName
	from APCSProDB.trans.machine_states as mc_state
		LEFT JOIN APCSProDB.trans.lots as lots on lots.id = mc_state.next_lot_id
		LEFT JOIN APCSProDB.trans.locations as loca on loca.id = lots.location_id
		LEFT JOIN [APCSProDB].[method].[packages] as pkg on pkg.id = lots.act_package_id
		LEFT JOIN [APCSProDB].[method].[device_names] as dev on dev.id = lots.act_device_name_id
		INNER JOIN APCSProDB.mc.machines as machine on machine.id = mc_state.machine_id		
	where machine.name = @mc_name
END
