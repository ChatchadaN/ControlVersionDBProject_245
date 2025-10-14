-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_qfp_flow_xray]
	
	@PKG AS VARCHAR(5) = '1'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@PKG = '1')
		BEGIN
			select DISTINCT dvname.name as DeviceName 
				, dvname.ft_name as FTDeviceName
				, jobs.name
			from APCSProDB.method.device_flows as dvflows
				inner join APCSProDB.method.jobs as jobs on dvflows.job_id = jobs.id 
				inner join APCSProDB.trans.lots as lots on lots.device_slip_id = dvflows.device_slip_id
				inner join APCSProDB.method.device_names as dvname on dvname.id = lots.act_device_name_id
				inner join APCSProDB.method.packages as pk on lots.act_package_id = pk.id
			where dvflows.job_id in (12,267) and pk.id in (74,75,76,77)
		END
	ELSE IF(@PKG = '2')
		BEGIN
			select DISTINCT dvname.name as DeviceName 
				, dvname.ft_name as FTDeviceName
				, jobs.name
			from APCSProDB.method.device_flows as dvflows
				inner join APCSProDB.method.jobs as jobs on dvflows.job_id = jobs.id 
				inner join APCSProDB.trans.lots as lots on lots.device_slip_id = dvflows.device_slip_id
				inner join APCSProDB.method.device_names as dvname on dvname.id = lots.act_device_name_id
				inner join APCSProDB.method.packages as pk on lots.act_package_id = pk.id
			where dvflows.job_id in (12,267) and pk.id in (505,508,509,121,122,346,347)
		END
	ELSE IF(@PKG = '4')
		BEGIN
			select DISTINCT dvname.name as DeviceName 
				, dvname.ft_name as FTDeviceName
				, jobs.name
			from APCSProDB.method.device_flows as dvflows
				inner join APCSProDB.method.jobs as jobs on dvflows.job_id = jobs.id 
				inner join APCSProDB.trans.lots as lots on lots.device_slip_id = dvflows.device_slip_id
				inner join APCSProDB.method.device_names as dvname on dvname.id = lots.act_device_name_id
				inner join APCSProDB.method.packages as pk on lots.act_package_id = pk.id
			where dvflows.job_id in (12,267) and pk.id in (510,511,512)
		END
END
