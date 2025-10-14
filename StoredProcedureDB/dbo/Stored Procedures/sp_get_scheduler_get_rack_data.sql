-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_get_rack_data] 
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
		, RackLocation.name as rackName 
		from APCSProDB.trans.lots as Trans 
		inner join APCSProDB.trans.locations as RackLocation on Racklocation.id = Trans.location_id
			AND (SUBSTRING(RackLocation.name,1,2) ='FT' OR SUBSTRING(RackLocation.name,1,2) = 'QA' OR SUBSTRING(RackLocation.name,1,2) = 'QC')
		inner join APCSProDB.method.device_names as Device on Trans.act_device_name_id = Device.id 
			AND Device.name = @device
		where Trans.location_id is not null order by rackName
	END
	ELSE IF (@state = 2) --TP
	BEGIN
		select lot_no
		,RackLocation.name as rackName 
		from APCSProDB.trans.lots as Trans
		inner join APCSProDB.trans.locations as RackLocation on Racklocation.id = Trans.location_id 
			AND (SUBSTRING(RackLocation.name,1,2) = 'TP' OR SUBSTRING(RackLocation.name,1,2) = 'QA' OR SUBSTRING(RackLocation.name,1,2) = 'QC') 
		inner join APCSProDB.method.device_names as Device on Trans.act_device_name_id = Device.id
			AND Device.name = @device
		where Trans.location_id is not null order by rackName
	END
	ELSE IF (@state = 3) --MP
	BEGIN
		SELECT [location].[name]
		FROM (SELECT[locations].[name] FROM[APCSProDB].[trans].[locations]
		WHERE[locations].[name] LIKE 'MP%'
		GROUP BY[locations].[name] ) AS[location]
		LEFT JOIN(SELECT[locations].[name] FROM [APCSProDWH].[rans].[machine_location_settings]
		INNER JOIN [APCSProDB].[trans].[locations] ON[machine_location_settings].[location_id] = [locations].[id]
		GROUP BY [locations].[name]) AS[location_used] ON[location].[name] = [location_used].[name]
		WHERE[location_used].[name] IS NULL;
	END
END
