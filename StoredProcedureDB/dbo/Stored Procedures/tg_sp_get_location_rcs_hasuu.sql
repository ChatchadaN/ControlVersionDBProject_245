-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_location_rcs_hasuu]
	-- Add the parameters for the stored procedure here
	@location varchar(20) = '' --'HSL-H2-L20-R01'
	, @status int = 0 --0:all location 1:find address
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF (@status = 0)
	BEGIN
		SELECT [loca].[name] AS [LocationName]
		FROM APCSProDB.trans.locations AS loca with (NOLOCK)
		LEFT JOIN DBx.dbo.rcs_current_locations AS curr with (NOLOCK) ON loca.id = curr.location_id
		WHERE loca.wh_code = 2 
			AND (curr.status = 3 OR curr.status IS NULL)  --3 = null and row null ,wh_code = 2 (Hasuu Rack)
			AND (loca.name LIKE 'HSL%' OR loca.name = 'HST-H2-L01-R01')
			--and (loca.name like 'HSL%' OR loca.name like 'HST%')  --add name 'HST for hasuu long' 2023/09/18 time : 14.05
		GROUP BY loca.name
		ORDER BY  loca.name;
	END
	ELSE IF (@status = 1)
	BEGIN
		SELECT TOP 1 
			 [loca].[id] AS [AddressId]  --add value for support SET Data Rack go to API #2024/12/19 Time : 18.04 by Aomsin
			,[loca].[address] AS [LocationName]
		FROM APCSProDB.trans.locations AS loca with (NOLOCK)
		LEFT JOIN DBx.dbo.rcs_current_locations AS curr with (NOLOCK) ON loca.id = curr.location_id
		WHERE loca.wh_code = 2 
			AND (curr.status = 3 or curr.status is null)  --3 = null and row null ,wh_code = 2 (Hasuu Rack)
			AND loca.name = @location
		ORDER BY  loca.name, loca.address;
	END
END

