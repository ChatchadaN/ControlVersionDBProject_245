


CREATE PROCEDURE [trans].[sp_rpt_frame_ledger]
@YEAR_MONTH VARCHAR(8),
@LOCATION_ID INT,
@USER_ID INT
AS
BEGIN
	SELECT 
      [location_id]
      ,[wh_code]
      ,[category_short_name]
      ,[product_name]
      ,[year_month]
      ,IsNull([month_begin_qty], 0) as [month_begin_qty]
      ,IsNull([month_begin_amt], 0) as [month_begin_amt]
      ,IsNull([month_begin_avg_unit_prc], 0) as [month_begin_avg_unit_prc]
      ,IsNull([rec1_qty], 0) as [rec1_qty]
      ,IsNull([rec1_amt], 0) as [rec1_amt]
      ,IsNull([rec2_qty], 0) as [rec2_qty]
      ,IsNull([rec1_avg_unit_prc], 0) as [rec1_avg_unit_prc]
      ,IsNull([rec2_amt], 0) as [rec2_amt]
      ,IsNull([rec3_qty], 0) as [rec3_qty]
      ,IsNull([rec3_amt], 0) as [rec3_amt]
      ,IsNull([serv1_qty], 0) as [serv1_qty]
      ,IsNull([serv1_amt], 0) as [serv1_amt]
      ,IsNull([serv2_qty], 0) as [serv2_qty]
      ,IsNull([serv2_amt], 0) as [serv2_amt]
      ,IsNull([wh_inv_qty], 0) as [wh_inv_qty]
      ,IsNull([wh_inv_amt], 0) as [wh_inv_amt]
      ,IsNull([month_end_qty], 0) as [month_end_qty]
      ,IsNull([month_end_amt], 0) as [month_end_amt]
      ,IsNull([avg_unit_prc], 0) as [avg_unit_prc]
      ,IsNull([diff_qty], 0) as [diff_qty]
      ,IsNull([diff_amt], 0) as [diff_amt]
      ,IsNull([defect_qty], 0) as [defect_qty]
      ,IsNull([defect_amt], 0) as [defect_amt]
	  ,IsNull(in_process_qty, 0) as [inprocess_qty]
      ,[sfill]
      ,[stamp]
	  ,[CATE].[name] as [category]
		   FROM [APCSPRODB].[TRANS].[MATERIAL_LEDGER_PROCESS] [PROCESS]
		   INNER JOIN [APCSPRODB].MATERIAL.CATEGORIES [CATE] ON [CATE].ID =  [PROCESS].[CATEGORY_SHORT_NAME]
		   WHERE [YEAR_MONTH] = @YEAR_MONTH
	ORDER BY [product_name];
END;


