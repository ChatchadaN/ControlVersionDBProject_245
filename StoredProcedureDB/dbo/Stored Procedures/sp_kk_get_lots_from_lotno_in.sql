-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_kk_get_lots_from_lotno_in]
	-- Add the parameters for the stored procedure here
	@lot_no_in varchar(4000)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @tsql varchar(4000)

	print @lot_no_in;
    -- Insert statements for procedure here
	set @tsql = 'select p.name as package,d.name as device_name,d.assy_name,d.rank,d.tp_rank,d.ft_name,j.name as job,l.* '
	set @tsql = @tsql + 'from [APCSProDB].[trans].[lots] as l with (NOLOCK) '
	set @tsql = @tsql + '	inner join apcsprodb.method.packages as p with (NOLOCK) '
	set @tsql = @tsql + '		on p.id = l.act_package_id '
	set @tsql = @tsql + '	inner join apcsprodb.method.device_names as d with (NOLOCK) '
	set @tsql = @tsql + '		on d.id = l.act_device_name_id '
	set @tsql = @tsql + '	inner join apcsprodb.method.device_flows as f with (NOLOCK) '
	set @tsql = @tsql + '		on f.device_slip_id = l.device_slip_id and f.step_no = l.step_no '
	set @tsql = @tsql + '	inner join apcsprodb.method.jobs as j with (NOLOCK) '
	set @tsql = @tsql + '		on j.id = f.job_id '
	set @tsql = @tsql + 'where l.lot_no in(' + @lot_no_in + ') '

	print @tsql;

	execute (@tsql)

END
