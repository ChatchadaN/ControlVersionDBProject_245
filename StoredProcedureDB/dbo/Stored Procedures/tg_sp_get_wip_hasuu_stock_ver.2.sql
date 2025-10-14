-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_wip_hasuu_stock_ver.2] 
	-- Add the parameters for the stored procedure here
	 @lot_type		VARCHAR(50)		= ''
	,@start_date	DATE			= NULL
	,@end_date		DATE			= NULL
	,@package		NVARCHAR(50)	= ''
	,@device		NVARCHAR(50)	= ''
	,@package_group	NVARCHAR(50)	= ''   --Add Parameter 2024/07/17 Time : 09.42 by Aomsin
	,@in_stock VARCHAR(10) =  '2,3'

AS
BEGIN

	SET NOCOUNT ON;
	DECLARE @datetime DATETIME
	DECLARE @year_now int = 0
	SET @datetime = GETDATE()

	SELECT @year_now = (FORMAT(@datetime,'yy'))
	SET @in_stock = IIF(@in_stock IS NULL OR @in_stock = '','2,3', @in_stock);

	SELECT *
	FROM (
		SELECT sur.serial_no as LotNo
			, sur.in_stock
			, pk_g.name as PackageGroup
			, pk.name as Type_Name
			, dn.name as ASSY_Model_Name
			, sur.pcs as HASU_Stock_QTY
			, dn.pcs_per_pack as Packing_Standerd_QTY
			, ISNULL(dn.tp_rank,'') As Rank  --add condition check null (2025/01/06 time : 10.56)
			, case when (sur.in_stock = 3 or tranlot.quality_state = 3)  then '#E67E22'  --Hold
					when sur.in_stock = 2 and (CAST(@year_now as int) - CAST((SUBSTRING(sur.serial_no,1,2)) as int) > 3) then '#ff6666'  --Wip and Hasuu long > 3 year.
					else '#FFFFFF' end as color 
			, sur.created_at as Derivery_Date
			, YEAR(sur.created_at) as oldyear
			, YEAR(GETDATE()) as Currentyear
			--, cast(YEAR(GETDATE()) as int) - CAST(YEAR(sur.created_at) as int) as Overdueyear
			, CAST(@year_now as int) - CAST((SUBSTRING(sur.serial_no,1,2)) as int) as Overdueyear
			, case when locat.name  is null then 'NoLocation' else locat.name  end As Rack_Location_name
			, case when locat.address  is null then 'NoLocation' else locat.address  end As Rack_Location_address
			, case when (tranlot.quality_state = 3) then 'Hold' else item_labels.label_eng end as status
			, ISNULL(item_comment.label_eng,'') as CommentValue
			, tranlot.quality_state
			, case when (sur.in_stock in (2,3) and tranlot.quality_state = 3)  then 3
				else sur.in_stock end as [state]
			, tranlot.production_category as production_category_id
			, ISNULL(item_productioncatgory.label_eng,'') as production_category_name
		from APCSProDB.trans.surpluses as sur
		left join APCSProDB.trans.lots as tranlot on sur.serial_no  = tranlot.lot_no 
		inner join APCSProDB.method.packages as pk on pk.id = tranlot.act_package_id
		inner join APCSProDB.method.device_names as dn on dn.id = tranlot.act_device_name_id
		inner join APCSProDB.method.package_groups as pk_g on pk.package_group_id = pk_g.id
		left join APCSProDB.trans.locations as locat on locat.id = sur.location_id
		left join APCSProDB.trans.item_labels on sur.in_stock = CAST(item_labels.val as int)
			and item_labels.name = 'surpluse_records.in_stock'
		left join APCSProDB.trans.item_labels as item_comment on sur.comment = CAST(item_comment.val as int)
			and item_comment.name = 'surpluses.comment'
		left join APCSProDB.trans.item_labels as item_productioncatgory on tranlot.production_category = CAST(item_productioncatgory.val as int)
			and item_productioncatgory.name = 'lots.production_category'
		WHERE (@lot_type IS NULL OR @lot_type = '' OR SUBSTRING(sur.serial_no, 5, 1) = @lot_type)
			AND (CONVERT(DATE, sur.created_at) BETWEEN @start_date AND @end_date)
			AND (@package IS NULL OR @package = '' OR pk.name = @package)
			AND (@device IS NULL OR @device = '' OR dn.name = @device)
			AND (TRIM(@package_group) IS NULL OR TRIM(@package_group) = '' OR TRIM(pk_g.name) = TRIM(@package_group))
			--AND tranlot.quality_state <> 0  --3 = Hold
	) AS [data]
	WHERE (@in_stock IS NULL OR @in_stock = '' OR [state] in (SELECT value from STRING_SPLIT (@in_stock, ',')))
	ORDER BY [data].LotNo ASC

END


