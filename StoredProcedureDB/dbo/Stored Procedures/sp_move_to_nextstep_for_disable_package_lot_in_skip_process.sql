-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_move_to_nextstep_for_disable_package_lot_in_skip_process]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	update apcsprodb.trans.lots 
	set step_no = t1.next_step_no 
		,act_job_id = t1.next_job_id 
		,act_process_id = t1.next_process_id 
	from apcsprodb.trans.lots as l 
		inner join (
						select 
							p.name,
							l.id,
							l.lot_no,
							l.step_no,
							f.next_step_no,
							l.act_package_id,
							l.act_device_name_id,
							f.job_id,
							j.name as job,
							jn.name as destination_job,
							fn.job_id as next_job_id,
							jn.process_id as next_process_id 

						from apcsprodb.trans.lots as l 
							inner join apcsprodb.method.packages as p 
								on p.id = l.act_package_id 
							inner join apcsprodb.method.device_flows as f 
								on f.device_slip_id = l.device_slip_id 
									and f.step_no = l.step_no
							inner join apcsprodb.method.jobs as j 
								on j.id = f.job_id
							inner join apcsprodb.method.device_flows as fn 
								on fn.device_slip_id = l.device_slip_id 
									and fn.step_no = f.next_step_no
							inner join apcsprodb.method.jobs as jn 
								on jn.id = fn.job_id
						where l.wip_state <=20 and
							--	 p.name in('TO263-3','TO263-5','TO263-7','TO263-9','HSSOP-C16')
						p.id in(71,275,277,279,280)
						and p.is_enabled = 0
						and f.is_skipped = 1
			) as t1 
				on t1.id = l.id 
END
