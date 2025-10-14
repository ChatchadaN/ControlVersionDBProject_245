-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_wiprate]
	-- Add the parameters for the stored procedure here
	@year varchar(10) = '%'
	,@type int 
	-- 1 = LeadTime
	-- 2 = Wip Rate
	-- 3 = LeadTimeHour
	-- 4 = Processing Time Hour
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF(@type = '1')
	BEGIN
		select *
		from
		(
			select PackageGroup,RohmWeek,AVGDAY
			from DBxDW.dbo.[LeadTime_Test]
			where [LeadTime_Test].[RohmYear] = @year
		) temp
		pivot
		(
			max(AVGDAY)
			for RohmWeek IN([1],[2],[3],[4],[5],[6],[7],[8],[9],[10]
			,[11],[12],[13],[14],[15],[16],[17],[18],[19],[20]
			,[21],[22],[23],[24],[25],[26],[27],[28],[29],[30]
			,[31],[32],[33],[34],[35],[36],[37],[38],[39],[40]
			,[41],[42],[43],[44],[45],[46],[47],[48],[49],[50]
			,[51],[52],[53])
		) as O
	END

	IF(@type = '2')
	BEGIN
		select *
		from
		(
			select PackageGroup,RohmWeek,AVGWipDay
			from DBxDW.dbo.[LeadTime_Test]
			where [LeadTime_Test].[RohmYear] = @year
		) temp
		pivot
		(
			max(AVGWipDay)
			for RohmWeek IN([1],[2],[3],[4],[5],[6],[7],[8],[9],[10]
			,[11],[12],[13],[14],[15],[16],[17],[18],[19],[20]
			,[21],[22],[23],[24],[25],[26],[27],[28],[29],[30]
			,[31],[32],[33],[34],[35],[36],[37],[38],[39],[40]
			,[41],[42],[43],[44],[45],[46],[47],[48],[49],[50]
			,[51],[52],[53])
		) as O
	END

	IF(@type = '3')
	BEGIN
		select *
		from
		(
			select PackageGroup,RohmWeek,AVGHour
			from DBxDW.dbo.[LeadTime_Test]
			where [LeadTime_Test].[RohmYear] = @year
		) temp
		pivot
		(
			max(AVGHour)
			for RohmWeek IN([1],[2],[3],[4],[5],[6],[7],[8],[9],[10]
			,[11],[12],[13],[14],[15],[16],[17],[18],[19],[20]
			,[21],[22],[23],[24],[25],[26],[27],[28],[29],[30]
			,[31],[32],[33],[34],[35],[36],[37],[38],[39],[40]
			,[41],[42],[43],[44],[45],[46],[47],[48],[49],[50]
			,[51],[52],[53])
		) as O
	END

	IF(@type = '4')
	BEGIN
		select *
		from
		(
			select PackageGroup,RohmWeek,AVGProcessHour
			from DBxDW.dbo.[LeadTime_Test]
			where [LeadTime_Test].[RohmYear] = @year
		) temp
		pivot
		(
			max(AVGProcessHour)
			for RohmWeek IN([1],[2],[3],[4],[5],[6],[7],[8],[9],[10]
			,[11],[12],[13],[14],[15],[16],[17],[18],[19],[20]
			,[21],[22],[23],[24],[25],[26],[27],[28],[29],[30]
			,[31],[32],[33],[34],[35],[36],[37],[38],[39],[40]
			,[41],[42],[43],[44],[45],[46],[47],[48],[49],[50]
			,[51],[52],[53])
		) as O
	END
	
END
