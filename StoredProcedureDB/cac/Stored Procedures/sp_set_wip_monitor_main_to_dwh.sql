-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_set_wip_monitor_main_to_dwh]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @date_value varchar(10)
	--SET @date_value = convert(varchar(10), GETDATE() - 2, 120)
	SET @date_value = convert(varchar(10), GETDATE() - 1, 120)

 DELETE t1
 FROM [10.29.1.230].[DWH].[cac].[wip_monitor_main] AS t1
 WHERE EXISTS (
     SELECT 1
     FROM [APCSProDWH].[cac].[wip_monitor_main] AS t2
     WHERE t1.[date_value] = t2.[date_value]
       AND t1.[package_group] = t2.[package_group]
       AND t1.[package] = t2.[package]
       AND t1.[process] = t2.[process]
       AND t1.[job] = t2.[job]
       AND t1.[lot_type] = t2.[lot_type]
       AND t1.[date_value] BETWEEN @date_value AND GETDATE()
 );

 INSERT INTO [10.29.1.230].[DWH].[cac].[wip_monitor_main]

 SELECT[date_value]
      ,[package_group]
      ,[package]
      ,[process]
      ,[job]
      ,[lot_type]
      ,[normal]
      ,[normal_pcs]
      ,[delay]
      ,[delay_pcs]
      ,[order_delay]
      ,[order_delay_pcs]
      ,[order_delay_hold]
      ,[order_delay_hold_pcs]
      ,[hold]
      ,[hold_pcs]
      ,[total]
      ,[total_pcs]
      ,[machine]
      ,[machine_pcs]
      ,[actual_result]
      ,[actual_result_pcs]
      ,[yesterday_result]
      ,[yesterday_result_pcs]
      ,[seq_no]
      ,[processing_time]
      ,[wip_time]
      ,[today_input]
      ,[today_input_pcs]
      ,[today_output]
      ,[today_output_pcs]
      ,[specialflow]
      ,[specialflow_pcs]
      ,[order_delay_special]
      ,[order_delay_special_pcs]
      ,[device]
		, 'RIST' AS [factory]
		, 'LSI' AS [HQ]
		, 'LSI Production' as [division]	
		, 'LSI IC' as [product_family]
		, 20 AS [partition_no]
  FROM [APCSProDWH].[cac].[wip_monitor_main]
  where date_value BETWEEN @date_value AND GETDATE();








--DELETE FROM [10.29.1.230].[DWH].[cac].[wip_monitor_main]

--INSERT INTO [10.29.1.230].[DWH].[cac].[wip_monitor_main] 

--SELECT [date_value]
--      ,[package_group]
--      ,[package]
--      ,[process]
--      ,[job]
--      ,[lot_type]
--      ,[normal]
--      ,[normal_pcs]
--      ,[delay]
--      ,[delay_pcs]
--      ,[order_delay]
--      ,[order_delay_pcs]
--      ,[order_delay_hold]
--      ,[order_delay_hold_pcs]
--      ,[hold]
--      ,[hold_pcs]
--      ,[total]
--      ,[total_pcs]
--      ,[machine]
--      ,[machine_pcs]
--      ,[actual_result]
--      ,[actual_result_pcs]
--      ,[yesterday_result]
--      ,[yesterday_result_pcs]
--      ,[seq_no]
--      ,[processing_time]
--      ,[wip_time]
--      ,[today_input]
--      ,[today_input_pcs]
--      ,[today_output]
--      ,[today_output_pcs]
--      ,[specialflow]
--      ,[specialflow_pcs]
--      ,[order_delay_special]
--      ,[order_delay_special_pcs]
--      ,[device]
--		, 'RIST' AS [factory]
--		, 'LSI' AS [HQ]
--		, 'LSI Production' as [division]	
--		, 'LSI IC' as [product_family]
--		, 20 AS [partition_no]
--  FROM [APCSProDWH].[cac].[wip_monitor_main]
--  where date_value BETWEEN @date_value AND GETDATE();

END
