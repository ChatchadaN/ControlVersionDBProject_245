-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Condition sum capacity>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_sum_capacity]
	-- Add the parameters for the stored procedure here
	@unit varchar(50) = 'Lots',
	@lbGroup varchar(50) = '%',
	@package varchar(50) = '%'
AS

BEGIN
IF @unit =  'Lots'
	begin
		--select min(Capacity) as Capacity 
		--select 0 as Capacity
		select case when min(Capacity) is null then 0 else min(Capacity) end as Capacity
		from 
		(select sum(Capacity) as Capacity,Process 
		from DBx.dbo.ControlValue 
		inner join DBx.dbo.MasterPackage on ControlValue.Package = MasterPackage.Package 
		where PackageGroup like @lbGroup and ControlValue.Package like @package and SpecialRank = 0 
		group by Process ) a
	end
else
	begin
		--select 0 as Capacity
		select case when min(CapacityKPcs) is null then 0 else min(CapacityKPcs) end as Capacity 
		from 
		(select sum(CapacityKPcs) as CapacityKPcs,Process 
		from DBx.dbo.ControlValue inner join DBx.dbo.MasterPackage on ControlValue.Package = MasterPackage.Package 
		where PackageGroup like @lbGroup and ControlValue.Package like @package and SpecialRank = 0 
		group by Process ) as a
	end
END
