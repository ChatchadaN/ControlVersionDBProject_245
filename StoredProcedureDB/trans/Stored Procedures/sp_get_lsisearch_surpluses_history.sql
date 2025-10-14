-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [trans].[sp_get_lsisearch_surpluses_history]
	-- Add the parameters for the stored procedure here
		  @LotNo      NVARCHAR(100)	= NULL
		, @Device     NVARCHAR(100) = NULL
		, @Package    NVARCHAR(100) = NULL
		, @Time1	  DATETIME
		, @Time2	  DATETIME

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	
	 
		SELECT    pack.name					AS Package
				, device.ft_name			AS Device
				, lot.lot_no				AS Lot
				, ser.pcs					AS QTY
				, device.assy_name			AS Assy_name
				, device.name				AS Name
				, ser.created_at			AS [Surpluses_Date]
		FROM APCSProDB.trans.surpluses ser 
		INNER JOIN APCSProDB.trans.lots lot 
		ON ser.lot_id				= lot.id ​
		INNER JOIN APCSProDB.method.packages pack 
		ON lot.act_package_id		= pack.id​
		INNER JOIN APCSProDB.method.device_names device 
		ON lot.act_device_name_id	= device.id
		--WHERE (lot.lot_no			= @LotNo	OR @LotNo	IS NULL ) 
		--AND (lot.act_device_name_id = @Device	OR @Device	IS NULL) 
		--AND (lot.act_package_id		= @Package	OR @Package IS NULL )​
		--AND (ser.created_at BETWEEN @Time1 AND @Time2) 
		--ORDER BY ser.created_at DESC
		WHERE (lot.lot_no = @LotNo OR @LotNo IS NULL) AND
		    (pack.name LIKE CONCAT('%', @Package, '%') OR @Package IS NULL) AND
			(device.ft_name LIKE CONCAT('%', @Device, '%') OR @Device IS NULL) AND
			(ser.created_at BETWEEN @Time1 AND @Time2)
		ORDER BY ser.created_at DESC

END
