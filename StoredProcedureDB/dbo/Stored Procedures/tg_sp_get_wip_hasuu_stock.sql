-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_wip_hasuu_stock] 
	-- Add the parameters for the stored procedure here
	 @lot_type		VARCHAR(50)		= ''
	,@start_date	DATE			= NULL
	,@end_date		DATE			= NULL
	,@package		NVARCHAR(50)	= NULL
	,@device		NVARCHAR(50)	= NULL
	,@package_group	NVARCHAR(50)	= '%'   --Add Parameter 2024/07/17 Time : 09.42 by Aomsin
	,@in_stock VARCHAR(10) =  '2,3'

AS
BEGIN
	
	SET NOCOUNT ON;
	--Update Query 2024/07/18 Time : 08.30 by Aomsin
	--SELECT sur.serial_no as LotNo
	--	, sur.in_stock
	--	, pk_g.name as PackageGroup
	--	, pk.name as Type_Name
	--	, dn.name as ASSY_Model_Name
	--	, sur.pcs as HASU_Stock_QTY
	--	, dn.pcs_per_pack as Packing_Standerd_QTY
	--	, dn.tp_rank As Rank
	--	--, IIF(DATEDIFF(YEAR,CONVERT(DATE, sur.created_at), CONVERT(DATE, GETDATE())) > 3, '#ff6666', '') as color  --edit condition : 2023/09/08 time : 15.05
	--	, case when sur.in_stock = 3 then '#E67E22'  --Hold
	--			when sur.in_stock = 2 and (CAST(YEAR(GETDATE()) as int) - CAST(YEAR(sur.created_at) as int) > 3) then '#ff6666'  --Wip and Hasuu long > 3 year.
	--			else '#FFFFFF' end as color  --edit condition : 2024/07/15 time : 17.17 by Aomsin
	--	, sur.created_at as Derivery_Date
	--	, YEAR(sur.created_at) as oldyear
	--	, YEAR(GETDATE()) as Currentyear
	--	, cast(YEAR(GETDATE()) as int) - CAST(YEAR(sur.created_at) as int) as Overdueyear
	--	, case when locat.name  is null then 'NoLocation' else locat.name  end As Rack_Location_name
	--	, case when locat.address  is null then 'NoLocation' else locat.address  end As Rack_Location_address
	--	, item_labels.label_eng as status
	--	, ISNULL(item_comment.label_eng,'') as CommentValue
	--from APCSProDB.trans.surpluses as sur
	--left join APCSProDB.trans.lots as tranlot on sur.serial_no  = tranlot.lot_no 
	--inner join APCSProDB.method.packages as pk on pk.id = tranlot.act_package_id
	--inner join APCSProDB.method.device_names as dn on dn.id = tranlot.act_device_name_id
	--inner join APCSProDB.method.package_groups as pk_g on pk.package_group_id = pk_g.id
	--left join APCSProDB.trans.locations as locat on locat.id = sur.location_id
	--left join APCSProDB.trans.item_labels on sur.in_stock = CAST(item_labels.val as int)
	--	and item_labels.name = 'surpluse_records.in_stock'
	--left join APCSProDB.trans.item_labels as item_comment on sur.comment = CAST(item_comment.val as int)
	--	and item_comment.name = 'surpluses.comment'
	--WHERE (sur.in_stock in (
	--		SELECT value 
	--		from STRING_SPLIT (ISNULL(IIF(@in_stock = '', '%', @in_stock), '%'), ',' )
	--	))
	--	AND (SUBSTRING(sur.serial_no,5,1) like ISNULL(IIF(@lot_type ='', '%', @lot_type), '%'))
	--	AND (CONVERT(DATE, sur.created_at) BETWEEN @start_date AND @end_date)
	--	AND (pk.name LIKE ISNULL(@package, '%'))
	--	AND (dn.name LIKE ISNULL(@device, '%'))
	--	AND (TRIM(pk_g.name) LIKE ISNULL(TRIM(@package_group), '%'))
	--	--and (sur.created_at >= '2021-10-05' or '2021-10-05' = '') and (sur.created_at <= '2021-10-05' or '2021-10-05' = '') 
	--ORDER BY sur.serial_no ASC
	

	IF(@lot_type = null or @lot_type = '')
			BEGIN
			--Update 2021/10/05
				SELECT 
				  sur.serial_no as LotNo
				, pk_g.name as PackageGroup
				, pk.name as Type_Name
				, dn.name as ASSY_Model_Name
				, sur.pcs as HASU_Stock_QTY
				, dn.pcs_per_pack as Packing_Standerd_QTY
				, dn.tp_rank As Rank
				--, IIF(DATEDIFF(YEAR,CONVERT(DATE, sur.created_at), CONVERT(DATE, GETDATE())) > 3, '#ff6666', '') as color  --edit condition : 2023/09/08 time : 15.05
				, case when sur.in_stock = 3 then '#E67E22'  --Hold
						when sur.in_stock = 2 and (CAST(YEAR(GETDATE()) as int) - CAST(YEAR(sur.created_at) as int) > 3) then '#ff6666'  --Wip and Hasuu long > 3 year.
						else '#FFFFFF' end as color  --edit condition : 2024/07/15 time : 17.17 by Aomsin
				, sur.created_at as Derivery_Date
				, YEAR(sur.created_at) as oldyear
				, YEAR(GETDATE()) as Currentyear
				, cast(YEAR(GETDATE()) as int) - CAST(YEAR(sur.created_at) as int) as Overdueyear
				, case when locat.name  is null then 'NoLocation' else locat.name  end As Rack_Location_name
				, case when locat.address  is null then 'NoLocation' else locat.address  end As Rack_Location_address
				, item_labels.label_eng as status
				, ISNULL(item_comment.label_eng,'') as CommentValue
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
				where sur.in_stock in ('2','3')
				and SUBSTRING(sur.serial_no,5,1) like '%'
				and convert(date,sur.created_at) between @start_date and @end_date
				AND (pk.name  = @package OR ISNULL(@package,'') = ''  )
				AND (dn.name  = @device OR ISNULL(@device,'') = '' )
				AND TRIM(pk_g.name) like TRIM(@package_group)
				--and (sur.created_at >= '2021-10-05' or '2021-10-05' = '') and (sur.created_at <= '2021-10-05' or '2021-10-05' = '') 
				ORDER BY sur.serial_no ASC
			END
		ELSE
			BEGIN
				--Update 2021/10/05
				SELECT 
				  sur.serial_no as LotNo
				, pk_g.name as PackageGroup
				, pk.name as Type_Name
				, dn.name as ASSY_Model_Name
				, sur.pcs as HASU_Stock_QTY
				, dn.pcs_per_pack as Packing_Standerd_QTY
				, dn.tp_rank As Rank
				--, IIF(DATEDIFF(YEAR,CONVERT(DATE, sur.created_at), CONVERT(DATE, GETDATE())) > 3, '#ff6666', '') as color  --edit condition : 2023/09/08 time : 15.05
				, case when sur.in_stock = 3 then '#E67E22'  --Hold
						when sur.in_stock = 2 and (CAST(YEAR(GETDATE()) as int) - CAST(YEAR(sur.created_at) as int) > 3) then '#ff6666'  --Wip and Hasuu long > 3 year.
						else '#FFFFFF' end as color  --edit condition : 2024/07/15 time : 17.17 by Aomsin
				, sur.created_at as Derivery_Date
				, YEAR(sur.created_at) as oldyear
				, YEAR(GETDATE()) as Currentyear
				, cast(YEAR(GETDATE()) as int) - CAST(YEAR(sur.created_at) as int) as Overdueyear
				, case when locat.name  is null then 'NoLocation' else locat.name  end As Rack_Location_name
				, case when locat.address  is null then 'NoLocation' else locat.address  end As Rack_Location_address
				, item_labels.label_eng as status
				, ISNULL(item_comment.label_eng,'') as CommentValue
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
				where sur.in_stock in ('2','3')
				and SUBSTRING(sur.serial_no,5,1) like @lot_type
				and convert(date,sur.created_at) between @start_date and @end_date
				AND (pk.name  = @package OR ISNULL(@package,'') = ''  )
				AND (dn.name  = @device OR ISNULL(@device,'') = '' )
				AND TRIM(pk_g.name) like @package_group
				--and (sur.created_at >= '2021-10-05' or '2021-10-05' = '') and (sur.created_at <= '2021-10-05' or '2021-10-05' = '') 
				ORDER BY sur.serial_no ASC

			END

END
