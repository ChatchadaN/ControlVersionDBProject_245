-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_get_rack_data_ver_temp] 
	-- Add the parameters for the stored procedure here
	@device VARCHAR(MAX) = NULL ,
	@state INT = 1
	--(1: Rack FT  2: Rack TP 3: Rack MP)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	IF(@state = 1) --FT
	BEGIN

		select lot_no
		,rack_controls.name as rackName 
		from APCSProDB.trans.lots as Trans

		INNER JOIN APCSProDB.rcs.rack_addresses ON Trans.lot_no = rack_addresses.item
		INNER JOIN APCSProDB.rcs.rack_controls ON  rack_addresses.rack_control_id = rack_controls.id
		AND (SUBSTRING(rack_controls.name,1,2) ='FT' OR SUBSTRING(rack_controls.name,1,2) = 'QA' OR SUBSTRING(rack_controls.name,1,2) = 'QC')

		inner join APCSProDB.method.device_names as Device on Trans.act_device_name_id = Device.id
		AND Device.name = @device
		where Trans.location_id is not null order by rackName

	END
	ELSE IF (@state = 2) --TP
	BEGIN

		select lot_no
		,rack_controls.name as rackName 
		from APCSProDB.trans.lots as Trans

		INNER JOIN APCSProDB.rcs.rack_addresses ON Trans.lot_no = rack_addresses.item
		INNER JOIN APCSProDB.rcs.rack_controls ON  rack_addresses.rack_control_id = rack_controls.id
		AND (SUBSTRING(rack_controls.name,1,2) = 'TP' OR SUBSTRING(rack_controls.name,1,2) = 'QA' OR SUBSTRING(rack_controls.name,1,2) = 'QC') 

		inner join APCSProDB.method.device_names as Device on Trans.act_device_name_id = Device.id
		AND Device.name = @device
		where Trans.location_id is not null order by rackName

	END
	ELSE IF (@state = 3) --MP
	BEGIN

		SELECT [location].[name]
		FROM (
			SELECT [rack_controls].[name] FROM APCSProDB.rcs.rack_controls
			WHERE [rack_controls].[name] LIKE 'MP%'
			GROUP BY [rack_controls].[name] 
			) AS[location]
		LEFT JOIN (SELECT rack_controls.[name] FROM [APCSProDWH].[rans].[machine_location_settings]
		INNER JOIN [APCSProDB].rcs.rack_addresses as [locations] ON [machine_location_settings].[location_id] = [locations].[id]
		INNER JOIN APCSProDB.rcs.rack_controls ON [locations].rack_control_id = rack_controls.id
		GROUP BY rack_controls.[name]) AS [location_used] ON [location].[name] = [location_used].[name]
		WHERE[location_used].[name] IS NULL;

	END
END
