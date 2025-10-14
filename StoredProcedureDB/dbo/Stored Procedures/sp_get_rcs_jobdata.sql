-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_rcs_jobdata] -- Ver002
	-- Add the parameters for the stored procedure here
	@JobName1 varchar(20), @JobName2 varchar(20) = '', @JobName3 varchar(20) = '', @JobName4 varchar(20) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	DECLARE @TableRackJob AS TABLE (Rack VARCHAR(20),Job VARCHAR(20))

	INSERT INTO @TableRackJob
	VALUES 
			('QA'	,'qcANALYSIS%'),
			('QA'	,'TP'),
			('QA'	,'AGING IN'),
			('QA'	,'%FT-TP%'),

			('FT'	,'FT'),
			('FT'	,'AUTO(%'),
			('FT'	,'OS%'),

			('OV'	,'TP'),

			('TCY'	,'TCY%'),

			('HS'	,'TSUGITASHI%'),
			('HSM'	,'TSUGITASHI%'),
			('HSL'	,'TSUGITASHI%'),

			('HST'	,'TP-TP%'),

			('HSO'	,'OUT GOING%'),

			('QYI'	,'Low Yield')

	DECLARE @CountList INT

	SELECT	@CountList = COUNT([Rack])
	FROM	@TableRackJob AS [RackJob]
	WHERE	[RackJob].[Rack] LIKE @JobName1 

	IF(@CountList = 0)
			BEGIN
					SELECT	[id], [name]
					FROM	[APCSProDB].[method].[jobs]
					WHERE	[jobs].[name] LIKE @JobName1 + '%' AND [jobs].[name] NOT LIKE '%Lapis%'
					ORDER BY [id]
			END

	ELSE IF(@JobName1 != '%' AND @JobName2 != '%' AND @JobName3 != '%' AND @JobName4 != '%' )
			BEGIN
					SELECT	[id], [name]
					FROM	[APCSProDB].[method].[jobs]
					INNER JOIN @TableRackJob AS [RackJob] ON [jobs].[name] LIKE [RackJob].[Job]
					WHERE	[RackJob].[Rack] = @JobName1 AND [jobs].[name] NOT LIKE '%Lapis%'
					ORDER BY [id]
			END
	ELSE
			BEGIN
					SELECT id, name
					FROM APCSProDB.method.jobs
					ORDER BY id
			END

END
