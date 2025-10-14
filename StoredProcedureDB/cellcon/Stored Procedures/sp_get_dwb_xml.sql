-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_dwb_xml]
	-- Add the parameters for the stored procedure here
	 @job_name varchar(20),@start_date  DateTime ,@end_date DateTime,@lot_no varchar(10),@package varchar(20),@device varchar(20),@item_ng_mode varchar(50),@MCNo varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	--DECLARE @lot_no varchar(10)
	--Set	@lot_no = '2242A3784V' 
		--	@job_name = N'ＷＢ．ＩＮＳ',
		--@start_date = N'2022-10-01 00:00:00',
		--@end_date = N'2023-03-01 00:00:00'


select --_xml.[extend_data],
	 _record.lot_id,_job.[name]
	, _lot.lot_no,_pk.[name] as package
	, _jb.[name] as job 
	, _dv.[assy_name] as device 
	, _xml_convert.* 
from APCSProDB.trans.lot_process_records  as _record
inner join APCSProDB.trans.lot_extend_records as _xml on _xml.id = _record.id
inner join APCSProDB.method.jobs as _job on _job.id = _record.job_id
inner join APCSProDB.trans.lots as _lot on _lot.id = _record.lot_id
inner join APCSProDB.method.packages as _pk on _pk.id = _lot.act_package_id
inner join APCSProDB.method.device_names as _dv on _dv.id = _lot.act_device_name_id
inner join APCSProDB.method.jobs as _jb on _jb.id = _record.job_id
outer apply ( 
	select  LotNo = Node.Data.value('(LotNo)[1]', 'VARCHAR(MAX)'),
       MCNo = Node.Data.value('(MCNo)[1]', 'VARCHAR(MAX)') ,
       StartTime = Node.Data.value('(StartTime)[1]', 'DateTime') ,
       EndTime = Node.Data.value('(CloseTime)[1]', 'DateTime') ,
       OpNo = Node.Data.value('(SetupUserCode)[1]', 'VARCHAR(MAX)') ,
       InputQty = Node.Data.value('(InputQty)[1]', 'INT') ,
       InputAdjustQty = Node.Data.value('(InputAdjustQty)[1]', 'INT') ,
       GoodAdjustQty = Node.Data.value('(GoodAdjustQty)[1]', 'VARCHAR(MAX)') ,
       NgAdjustQty = Node.Data.value('(NgAdjustQty)[1]', 'VARCHAR(MAX)') ,
       MCType = Node.Data.value('(MCType)[1]', 'VARCHAR(MAX)') ,
       FrameGoodAdjust = Node.Data.value('(FrameGoodAdjust)[1]', 'INT') ,
       FrameNgAdjust = Node.Data.value('(FrameNgAdjust)[1]', 'INT') ,
       FrameInputAdjust = Node.Data.value('(FrameInputAdjust)[1]', 'INT') ,
       FrontNg = Node.Data.value('(FrontNg)[1]', 'INT') ,
       FrontNg_Scrap = Node.Data.value('(FrontNg_Scrap)[1]', 'INT') ,
       QtyScrap = Node.Data.value('(QtyScrap)[1]', 'INT') ,
       P_Nashi = Node.Data.value('(P_Nashi)[1]', 'INT') ,
       P_Nashi_Scrap = Node.Data.value('(P_Nashi_Scrap)[1]', 'INT') ,
       Os_Scrap = Node.Data.value('(Os_Scrap)[1]', 'INT') ,
       NgBefore = Node.Data.value('(NgBefore)[1]', 'INT') ,
       InspTime = Node.Data.value('(InspTime)[1]', 'INT') ,
       Remark = Node.Data.value('(Remark)[1]', 'VARCHAR(MAX)') ,
       GlConfrim = Node.Data.value('(GlConfrim)[1]', 'VARCHAR(MAX)') ,
       Lotjustment = Node.Data.value('(Lotjustment)[1]', 'VARCHAR(MAX)') ,
       Macroscope = Node.Data.value('(Macroscope)[1]', 'VARCHAR(MAX)') ,
       Sampling = Node.Data.value('(Sampling)[1]', 'INT') ,
       SamplingTarget = Node.Data.value('(SamplingTarget)[1]', 'INT') ,
	   Yield = Node.Data.value('(Yield)[1]', 'FLOAT') ,
	   xml_ng.ItemNg , 
	   xml_ng.IsItemBefore ,
	   xml_ng.ValueItemm,
	   xml_ng.Val01,
	   xml_ng.Val02,
	   xml_ng.Val03,
	   xml_ng.Val04,
	   xml_ng.Val05,
	   xml_ng.Val06,
	   xml_ng.Val07,
	   xml_ng.Val08,
	   xml_ng.Val09,
	   xml_ng.Val10,
	   xml_ng.Val11,
	   xml_ng.Val12,
	   xml_trc.ProcessRequest,
	   xml_trc.ProcessRequest2,
	   xml_trc.ProcessRequest3,
	   xml_trc.Requestdata
	from _xml.[extend_data].nodes('LotDataCommon') Node(Data)
	outer apply (
		select  XMLdata.value('(ItemNg)[1]', 'varchar(100)') AS [ItemNg]
			, XMLdata.value('(IsItemBefore)[1]', 'varchar(100)') AS [IsItemBefore]
			, XMLdata.value('(ValueItemm)[1]', 'INT') AS [ValueItemm]
			, XMLdata.value('(Val01)[1]', 'INT') AS [Val01]
			, XMLdata.value('(Val02)[1]', 'INT') AS [Val02]
			, XMLdata.value('(Val03)[1]', 'INT') AS [Val03]
			, XMLdata.value('(Val04)[1]', 'INT') AS [Val04]
			, XMLdata.value('(Val05)[1]', 'INT') AS [Val05]
			, XMLdata.value('(Val06)[1]', 'INT') AS [Val06]
			, XMLdata.value('(Val07)[1]', 'INT') AS [Val07]
			, XMLdata.value('(Val08)[1]', 'INT') AS [Val08]
			, XMLdata.value('(Val09)[1]', 'INT') AS [Val09]
			, XMLdata.value('(Val10)[1]', 'INT') AS [Val10]
			, XMLdata.value('(Val11)[1]', 'INT') AS [Val11]
			, XMLdata.value('(Val12)[1]', 'INT') AS [Val12]
       from _xml.[extend_data].nodes('/LotDataCommon/InspectionItemsList/InspectionItem') AS XTbl(XMLdata)
	) as xml_ng
	outer apply ( 
		select top (1)  XMLdata2.value('(Requestmode)[1]', 'varchar(100)') AS [ProcessRequest] 
		               ,XMLdata2.value('(Requestmode2)[1]', 'varchar(100)') AS [ProcessRequest2]
					   ,XMLdata2.value('(Requestmode3)[1]', 'varchar(100)') AS [ProcessRequest3]
					   ,XMLdata2.value('(RequestInspectionTime)[1]', 'DateTime') AS [Requestdata]
		from _xml.[extend_data].nodes('/LotDataCommon/TrcData/TRCData') AS XTbl2(XMLdata2)
	) as xml_trc
) as _xml_convert
where  lot_no like '%' + @lot_no + '%' --lot_no = (case when @lot_no = '' then lot_no else @lot_no end) --
	and record_class = 2
	and _job.[name] = @job_name  
	and _record.recorded_at between @start_date and @end_date
	and _xml_convert.ItemNg like '%' + @item_ng_mode + '%'
	and _pk.[name] like '%' + @package + '%'
	and _dv.[name] like '%' + @device + '%'

order by _xml_convert.ItemNg;

	--DECLARE @job_name varchar(20),@start_date  DateTime ,@end_date DateTime
--Set	@job_name = 'ＷＢ．ＩＮＳ' 
--Set	 @start_date ='2022-10-01 00:00:00'
--Set	 @end_date ='2023-03-01 00:00:00'
--select --_xml.[extend_data],
--	 _record.lot_id,_job.[name]
--	, _lot.lot_no,_pk.[name] as package
--	, _jb.[name] as job 
--	, _dv.[assy_name] as device 
--	, _xml_convert.* 
--from APCSProDB.trans.lot_process_records  as _record
--inner join APCSProDB.trans.lot_extend_records as _xml on _xml.id = _record.id
--inner join APCSProDB.method.jobs as _job on _job.id = _record.job_id
--inner join APCSProDB.trans.lots as _lot on _lot.id = _record.lot_id
--inner join APCSProDB.method.packages as _pk on _pk.id = _lot.act_package_id
--inner join APCSProDB.method.device_names as _dv on _dv.id = _lot.act_device_name_id
--inner join APCSProDB.method.jobs as _jb on _jb.id = _record.job_id
--outer apply ( 
--	select  LotNo = Node.Data.value('(LotNo)[1]', 'VARCHAR(MAX)'),
--       MCNo = Node.Data.value('(MCNo)[1]', 'VARCHAR(MAX)') ,
--       StartTime = Node.Data.value('(StartTime)[1]', 'DateTime') ,
--       EndTime = Node.Data.value('(CloseTime)[1]', 'DateTime') ,
--       OpNo = Node.Data.value('(SetupUserCode)[1]', 'VARCHAR(MAX)') ,
--       InputQty = Node.Data.value('(InputQty)[1]', 'INT') ,
--       InputAdjustQty = Node.Data.value('(InputAdjustQty)[1]', 'INT') ,
--       GoodAdjustQty = Node.Data.value('(GoodAdjustQty)[1]', 'VARCHAR(MAX)') ,
--       NgAdjustQty = Node.Data.value('(NgAdjustQty)[1]', 'VARCHAR(MAX)') ,
--       MCType = Node.Data.value('(MCType)[1]', 'VARCHAR(MAX)') ,
--       FrameGoodAdjust = Node.Data.value('(FrameGoodAdjust)[1]', 'INT') ,
--       FrameNgAdjust = Node.Data.value('(FrameNgAdjust)[1]', 'INT') ,
--       FrameInputAdjust = Node.Data.value('(FrameInputAdjust)[1]', 'INT') ,
--       FrontNg = Node.Data.value('(FrontNg)[1]', 'INT') ,
--       FrontNg_Scrap = Node.Data.value('(FrontNg_Scrap)[1]', 'INT') ,
--       QtyScrap = Node.Data.value('(QtyScrap)[1]', 'INT') ,
--       P_Nashi = Node.Data.value('(P_Nashi)[1]', 'INT') ,
--       P_Nashi_Scrap = Node.Data.value('(P_Nashi_Scrap)[1]', 'INT') ,
--       Os_Scrap = Node.Data.value('(Os_Scrap)[1]', 'INT'++++++++++++++++) ,
--       NgBefore = Node.Data.value('(NgBefore)[1]', 'INT') ,
--       InspTime = Node.Data.value('(InspTime)[1]', 'INT') ,
--       Remark = Node.Data.value('(Remark)[1]', 'VARCHAR(MAX)') ,
--       GlConfrim = Node.Data.value('(GlConfrim)[1]', 'VARCHAR(MAX)') ,
--       Lotjustment = Node.Data.value('(Lotjustment)[1]', 'VARCHAR(MAX)') ,
--       Macroscope = Node.Data.value('(Macroscope)[1]', 'VARCHAR(MAX)') ,
--       Sampling = Node.Data.value('(Sampling)[1]', 'INT') ,
--       SamplingTarget = Node.Data.value('(SamplingTarget)[1]', 'INT') ,
--	   xml_ng.ItemNg , 
--	   xml_ng.IsItemBefore ,
--	   xml_ng.ValueItemm
--	from _xml.[extend_data].nodes('LotDataCommon') Node(Data)
--	outer apply (
--		select  XMLdata.value('(ItemNg)[1]', 'varchar(100)') AS [ItemNg]
--			, XMLdata.value('(IsItemBefore)[1]', 'varchar(100)') AS [IsItemBefore]
--			, XMLdata.value('(ValueItemm)[1]', 'INT') AS [ValueItemm]
--       from _xml.[extend_data].nodes('/LotDataCommon/InspectionItemsList/InspectionItem') AS XTbl(XMLdata)
--	) as xml_ng
--) as _xml_convert
--where --lot_no = @lot_no	and 
--	record_class = 2
--	and _job.[name] = @job_name  
--	and _record.created_at between @start_date and @end_date
--order by _xml_convert.ItemNg;

END
