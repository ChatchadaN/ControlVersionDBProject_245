-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_mli02_lsi_ogistate]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here

	--update dbx.dbo.OGIData
	--	set CPS_State = (case when [IS_Table].LotNo is null  then 
	--		case 
	--			when dbdata.CPS_State = 0  then
	--		   		case when MCNo = 'WEBTG'  then 0 else 3 end 
	--			else dbdata.CPS_State
	--		end
	--	 else 
	--		case 
	--			when dbdata.CPS_State = 3  then 0 
	--			else dbdata.CPS_State
	--		end
	--	end )
	--from dbx.dbo.OGIData as dbdata
	--left join (SELECT [LOTN] as LotNo
	--	FROM OPENROWSET('SQLNCLI', 'Server= 10.28.1.144;Database=DBLSISHT;Uid=ship;Pwd=ship', 
	--	'SELECT [LOTN] FROM [DBLSISHT].[dbo].[MLI02_LSI] with (NOLOCK) GROUP BY LOTN')) as [IS_Table] on [dbdata].[LotNo] = [IS_Table].[LotNo]
	--where dbdata.LotEndTime is not null and ([IS_Table].[LotNo] is null or dbdata.CPS_State = 3)
	
	
	---------------edit 26/02/2022 15.40

	DECLARE @table_mli02_is table ( 
		[LOTN] [char](10) NULL
	)

	DECLARE @table_ogi table ( 
		[LotNo] [varchar](10) NOT NULL,
		[CPS_State] [int] NULL
	)

	DECLARE @lotno VARCHAR(MAX)
	DECLARE @sql NVARCHAR(MAX)

	insert into @table_ogi ([LotNo],[CPS_State])
	select [dbdata].[LotNo]
		,dbdata.CPS_State
	from dbx.dbo.OGIData as dbdata
	where (dbdata.CPS_State = 3 or dbdata.CPS_State = 0)
		and dbdata.LotEndTime between (convert(varchar, getdate() - 1, 111) + ' 00:00:00') and (convert(varchar, getdate(), 111) + ' 23:59:59')
		and dbdata.MCNo != 'WEBTG'

	SELECT @lotno = COALESCE(@lotno + ''''',''''','''''', '') + [LotNo]
	FROM @table_ogi as [OGIData]
	GROUP BY [LotNo]

	SET @sql = 'SELECT [LOTN] FROM OPENROWSET(''SQLNCLI'', ''Server= 10.28.1.144;Database=DBLSISHT;Uid=ship;Pwd=ship'',' + 
				'''SELECT [LOTN] FROM [DBLSISHT].[dbo].[MLI02_LSI] '+ 
				'WHERE [LOTN] in (' + @lotno + ''''')'')';

	INSERT INTO @table_mli02_is EXEC sp_executesql @sql

	--select [OGIData].[LotNo] 
	--	, case when [mli02_lsi].[LOTN] is null then 3 else 0 end as [CPS_State_now]
	--	, [OGIData].[CPS_State]
	UPDATE [OGIData1]
		set [OGIData1].[CPS_State] = (case when [mli02_lsi].[LOTN] is null then 3 else 0 end)
	from @table_ogi as [OGIData1]
	left join (
		select [LOTN] from @table_mli02_is
		group by [LOTN]
	) as [mli02_lsi] on [OGIData1].[LotNo] = [mli02_lsi].[LOTN]


	update [OGIData]
		set [OGIData].[CPS_State] = [OGIData1].[CPS_State]
	from dbx.dbo.OGIData as [OGIData]
	inner join @table_ogi as [OGIData1] on [OGIData].[LotNo] = [OGIData1].[LotNo]

	---------------edit 26/02/2022 15.40

END
