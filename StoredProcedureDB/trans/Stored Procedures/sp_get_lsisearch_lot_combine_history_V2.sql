-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_lsisearch_lot_combine_history_V2]
	-- Add the parameters for the stored procedure here
		  @LotNo      NVARCHAR(100)		= NULL
		, @Device     NVARCHAR(100)		= NULL
		, @Package    NVARCHAR(100)		= NULL
		, @ReSur	  NVARCHAR(10)		= NULL
		, @Surpluses  NVARCHAR(100)		= NULL
		, @Time1	  DATETIME
		, @Time2	  DATETIME
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT * FROM (
		SELECT pk.name AS Package
			,dn.ft_name   AS Device
			,dn.name		AS [Device_Name]
			,dn.assy_name AS [Assy_Name]
			,pk.name  AS [Package_Name]
			,TRIM(l.lot_no) AS Lot
			,TRIM(lm.lot_no) AS HasuuLot
			,l.qty_in AS qty_good	  
			,IIF((lc.lot_id = lc.member_lot_id OR SER.original_lot_id IS NOT NULL OR l.production_category IN (21,22,23,70) ),0,IIF(l.pc_instruction_code <> 1,l.qty_pass,MSER.pcs)) AS hasuu_lot_before
			,0  AS qty_combine
			,l.qty_out 
			,lc.created_at
			,CASE WHEN  l.pc_instruction_code > 1 THEN il_pc.label_eng
			 WHEN  l.production_category IN (21,22,23,70) THEN il_pd.label_eng
			 ELSE 'MIX' END  AS original_lot_id
			,il.label_eng   AS wip_state
		FROM [APCSProDB].[trans].[lot_combine] lc
		INNER JOIN [APCSProDB].trans.lots l on l.id = lc.lot_id and l.wip_state <> 200 
		INNER JOIN [APCSProDB].trans.lots lm on lm.id = lc.member_lot_id 
		INNER JOIN [APCSProDB].method.device_names dn on dn.id = l.act_device_name_id
		INNER JOIN [APCSProDB].method.packages pk on pk.id = dn.package_id
		LEFT JOIN APCSProDB.trans.surpluses SER ON  l.id = SER.lot_id
		LEFT JOIN APCSProDB.trans.surpluses MSER ON  lm.id = MSER.lot_id
		LEFT JOIN  APCSProDB.trans.item_labels il ON l.wip_state =  il.val AND il.name = 'lots.wip_state'
		LEFT JOIN  APCSProDB.trans.item_labels il_pc ON l.pc_instruction_code =  il_pc.val AND il_pc.name = 'lots.pc_instruction_code'
		LEFT JOIN  APCSProDB.trans.item_labels il_pd ON l.production_category =  il_pd.val AND il_pd.name = 'lots.production_category'

		WHERE l.id > 10 

		UNION -- Master lot

		SELECT DISTINCT pk.name AS Package
			,dn.ft_name   AS Device
			,dn.name		AS [Device_Name]
			,dn.assy_name AS [Assy_Name]
			,pk.name  AS [Package_Name]
			,TRIM(l.lot_no) AS Lot
			,TRIM(l.lot_no) AS HasuuLot
			,l.qty_in AS qty_good	  
			,0 AS hasuu_lot_before
			,0 AS qty_combine
			,l.qty_out 
			,lc.created_at
			,CASE WHEN  l.pc_instruction_code > 1 THEN il_pc.label_eng
				WHEN  l.production_category IN (21,22,23,70) THEN il_pd.label_eng
				ELSE 'MIX' END  AS original_lot_id
			,il.label_eng   AS wip_state
		FROM [APCSProDB].[trans].[lot_combine] lc
		INNER JOIN APCSProDB.trans.lots l on l.id = lc.lot_id and l.wip_state <> 200 
		INNER JOIN APCSProDB.method.device_names dn on dn.id = l.act_device_name_id
		INNER JOIN APCSProDB.method.packages pk on pk.id = l.act_package_id
		INNER JOIN APCSProDB.trans.surpluses SER ON  l.id = SER.lot_id
		LEFT JOIN  APCSProDB.trans.item_labels il ON l.wip_state =  il.val AND il.name = 'lots.wip_state'
		LEFT JOIN  APCSProDB.trans.item_labels il_pc ON l.pc_instruction_code =  il_pc.val AND il_pc.name = 'lots.pc_instruction_code'
		LEFT JOIN  APCSProDB.trans.item_labels il_pd ON l.production_category =  il_pd.val AND il_pd.name = 'lots.production_category'
		WHERE l.id > 10 
		) AS data_combine 	 		
	WHERE (data_combine.Lot = @LotNo	OR @LotNo	IS NULL) 
	AND (data_combine.HasuuLot = @Surpluses OR @Surpluses IS NULL)
	--AND (data_combine.original_lot_id = @ReSur OR @ReSur IS NULL)
	AND (data_combine.original_lot_id LIKE '%' + @ReSur + '%' OR @ReSur IS NULL)
	--AND (data_combine.Device = @Device	OR @Device	IS NULL)
	AND (data_combine.Device_Name = @Device	OR @Device	IS NULL)
	AND (data_combine.Package = @Package	OR @Package IS NULL)
	AND (data_combine.created_at BETWEEN @Time1 AND @Time2)
	ORDER BY Lot DESC,hasuu_lot_before ASC

END
