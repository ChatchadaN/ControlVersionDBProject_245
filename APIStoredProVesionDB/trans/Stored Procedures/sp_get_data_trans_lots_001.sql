-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_data_trans_lots_001] 
	-- Add the parameters for the stored procedure here
	@lot_no AS VARCHAR(10),
	@e_slip_id AS VARCHAR(20) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	----------------------------------------------------
	---- NEW 04/07/2022
	----------------------------------------------------
	select TRIM(ISNULL(lots.lot_no,'')) as LotNo
		 , TRIM(ISNULL(packages.name,'')) as Package
		 , TRIM(ISNULL(device_names.name,'')) as Device
		 , TRIM(ISNULL(device_names.tp_rank,'')) as tp_rank
		 , ISNULL(lots.carrier_no,'') as Carrier
		 , case when lots.is_special_flow = 1 then job_special.name else job_master.name end as JobName
	from APCSProDB.trans.lots
	left join APCSProDB.method.device_names on lots.act_device_name_id = device_names.id
	left join APCSProDB.method.packages on device_names.package_id = packages.id
	left join APCSProDB.method.jobs as job_master on lots.act_job_id = job_master.id
	left join APCSProDB.trans.special_flows on lots.id = special_flows.lot_id
		and lots.is_special_flow = 1
		and lots.special_flow_id = special_flows.id
	left join APCSProDB.trans.lot_special_flows on special_flows.id = lot_special_flows.special_flow_id
		and special_flows.step_no = lot_special_flows.step_no
	left join APCSProDB.method.jobs as job_special on lot_special_flows.job_id = job_special.id
	where lots.lot_no = @lot_no
	----------------------------------------------------------------------------------------------
END 
