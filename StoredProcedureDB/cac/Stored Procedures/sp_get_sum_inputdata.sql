-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Condition sum inputData>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_sum_inputdata]
	-- Add the parameters for the stored procedure here
	@unit varchar(50) = 'Lots',
	@lbGroup varchar(50) = '%',
	@package varchar(50) = '%'
AS

BEGIN

DECLARE @OperateDate TABLE(
	[Month] [INT]
	,[Date] [FLOAT]
)

INSERT INTO @OperateDate
	(
	[Month]
	,[Date]
	)
VALUES
	(1,'27.5')
	,(2,'28')
	,(3,'31')
	,(4,'30')
	,(5,'31')
	,(6,'30')
	,(7,'31')
	,(8,'31')
	,(9,'30')
	,(10,'31')
	,(11,'30')
	,(12,'31')


IF @unit =  'Lots'
	begin
		select case when round(sum(InputPlan)/OperateDate.[Date],1) is null then 0 else round(sum(InputPlan)/OperateDate.[Date],1) end as InputPlan 
		from DBx.dbo.MasterPackage 
		--left join APCSDB.dbo.OperateDate on [Month] = datepart(month,GETDATE())
		left join @OperateDate as OperateDate on [Month] = datepart(month,GETDATE())
		where PackageGroup like @lbGroup and Package like @package 
		group by OperateDate.[Date]
	end
else
	begin
		select case when round(sum(InputPlanKPcs)/OperateDate.[Date],1) is null then 0 else round(sum(InputPlanKPcs)/OperateDate.[Date],1) end as InputPlan 
		from DBx.dbo.MasterPackage 
		--left join APCSDB.dbo.OperateDate on [Month] = datepart(month,GETDATE()) 
		left join @OperateDate as OperateDate on [Month] = datepart(month,GETDATE())
		where PackageGroup like @lbGroup and Package like @package group by OperateDate.[Date]
	end
END
