

CREATE PROCEDURE [trans].[sp_rpt_data_interface_20191018NewMAIOFUK5_v15]
@FILE_DATE DATE,
@LOCATION_ID INT,
@USER_ID INT
AS
BEGIN
	IF @FILE_DATE IS NULL
	BEGIN
		SET @FILE_DATE  = GETDATE()
	END

	-- FROM MATERIAL_CONTROL / F_CLARIFICATION.VB / GET_DATA()
	SET NOCOUNT ON
	DECLARE @WRITE_TIME DATETIME
	DECLARE @DATE_FORMAT VARCHAR(255)
	DECLARE @_NO INT
	DECLARE @_BARCODE VARCHAR(12)
	DECLARE @_LOCATION_ID INT
	DECLARE @_PROD_NAME CHAR(20)
	DECLARE @_QUANTITY DECIMAL(18, 6)
	DECLARE @_MAT_LOCATION CHAR(5)

	DECLARE @_SUPPLIER_CD CHAR(5)
	DECLARE @_CATE_CODE CHAR(2)
	DECLARE @_IN_DATE DATETIME
	DECLARE @_RECORD_CLASS INT
	DECLARE @_PO_NO CHAR(10)
	DECLARE @_INV_NO CHAR(10)
	DECLARE @DAY_ID INT
	DECLARE @SEPARATE_HOUR int
	set @SEPARATE_HOUR = 18

	SET @WRITE_TIME = GETDATE()
	SET @DATE_FORMAT = CONVERT(VARCHAR(8), GETDATE(), 112) + REPLACE(CONVERT(VARCHAR(5), GETDATE(), 114), ':', '')
	SET @DAY_ID = [material].fn_GetDayID(@FILE_DATE)
	SET @_NO = 1;
	
	DELETE FROM [APCSPRODWH].[DBO].[ADM00001]

-- ************** FUK5 ************** --
--INSERT [APCSPRODWH].[DBO].[ADM00001] ([WRITETIME] ,[SEQNO6] ,[ROVANSFILE] ,[ROVANSDATA] ,[SENDENDFL] ,[MAKDT] ,[MAKP] ,[MAKC] ,[UPDDT] ,[UPDP] ,[UPDC] ,[DELF] ,[DELDT] ,[DELP] ,[DELC])
select t3.writetime
	,t3.seqno6
	,t3.rovansfile
	,case when t3.record_type = 2 then 'GEE' + FORMAT(t3.seqno6, '000000') + [storedproceduredb].[material].[fn_space_right]('FUK5', 9) + SPACE(62) else t3.rovansdata end as rovansdata
	,t3.sendendfl
	,t3.makdt
	,t3.makp
	,t3.makc
	,t3.upddt
	,t3.updp
	,t3.updc
	,t3.delf
	,t3.deldt
	,t3.delp
	,t3.delc
from (
	select t2.record_type
		,t2.writetime
		,rank() over (
			order by t2.record_type
				,seqno6
			) as seqno6
		,t2.rovansfile
		,t2.rovansdata
		,t2.sendendfl
		,t2.makdt
		,t2.makp
		,t2.makc
		,t2.upddt
		,t2.updp
		,t2.updc
		,t2.delf
		,t2.deldt
		,t2.delp
		,t2.delc
	from (
		select 0 as record_type
			,@FILE_DATE as writetime
			,0 as seqno6
			,'FUK5' as rovansfile
			,'GESGEIS1.000ZZROHM0024'+ SPACE(7) +'ZZROHM0011'+ SPACE(7) + RIGHT(@DATE_FORMAT, 10) + [StoredProcedureDB].[material].[fn_space_right]('FUK5', 9) + 'JST' + SPACE(12) as rovansdata
			,0 as sendendfl
			,@FILE_DATE as makdt
			,@USER_ID as makp
			,'PC001' as makc
			,@WRITE_TIME as upddt
			,@USER_ID as updp
			,'PC001' as updc
			,0 as delf
			,@WRITE_TIME as deldt
			,SPACE(1) as delp
			,SPACE(1) as delc
		union all
		select 1 as record_type
			,@FILE_DATE as writetime
			,t1.REC_NO as seqno6
			,'FUK5' as rovansfile
			,t1.material_cd + t1.LOC + t1.PROD_NAME + t1.QUANTITY + t1.supplier_cd + t1.seq_no + t1.IN_DATE + t1.margin as rovansdata
			,0 as sendendfl
			,@FILE_DATE as makdt
			,@USER_ID as makp
			,'PC001' as makc
			,@WRITE_TIME as upddt
			,@USER_ID as updp
			,'PC001' as updc
			,0 as delf
			,@WRITE_TIME as deldt
			,SPACE(1) as delp
			,SPACE(1) as delc
		from (
			select 
				ct.short_name as material_cd
				--,case when isnull(mt.qc_state,0) = 0 then 'QI900' else 'QI999' end as LOC
				,case when lc.wh_code <> 'QI999' then 'QI900' else 'QI999' end as LOC
				,left(rtrim(pr.name) + space(20), 20) as PROD_NAME
				,format(mt.quantity, '000000000') + '00' as QUANTITY
				,pr.supplier_cd
				,left(mt.barcode + space(12),12) as seq_no
				,format(ar.recorded_at,'yyyyMMdd') as IN_DATE
				,space(17) as margin
				,rank() over (
					order by mt.barcode
					) as REC_NO
			from [APCSProDB].trans.materials as mt with (nolock)
			inner join [APCSProDB].material.productions as pr with (nolock) on pr.id = mt.material_production_id
			inner join [APCSProDB].material.categories as ct with (nolock) on ct.id = pr.category_id
			inner join [APCSProDB].material.locations as lc with (nolock) on mt.location_id = lc.id
			inner join apcsprodb.trans.material_arrival_records as ar with (NOLOCK) 
				on ar.material_id = mt.id 
				/* add v9 */
					and not exists (select * from APCSProDB.trans.material_arrival_records as ar2 with (NOLOCK) 
										where ar2.material_id = ar.material_id and ar2.recorded_at > ar.recorded_at)
				/* add v9 end */
			where --mt.material_state = 1 and
				 ct.short_name = '03'  /*03:frame*/
				 and lc.wh_code in ('QI900', 'QI999')
				 and mt.quantity <> 0
		) as t1
		union all
		select 2 as record_type
			,@FILE_DATE as writetime
			,0 as seqno6
			,'FUK5' as rovansfile
			,'' as rovansdata
			,0 as sendendfl
			,@FILE_DATE as makdt
			,@USER_ID as makp
			,'PC001' as makc
			,@WRITE_TIME as upddt
			,@USER_ID as updp
			,'PC001' as updc
			,0 as delf
			,@WRITE_TIME as deldt
			,SPACE(1) as delp
			,SPACE(1) as delc
		) as t2
	) as t3


-- ************** FUK5 ************** --
	
-- ************** MAIO ************** --
	DECLARE @_CATE_ID INT
	DECLARE @_SEQ_NO INT
	DECLARE @_QC_STATE INT
	DECLARE @_FROM_LOCATION VARCHAR(5)
	DECLARE @_TO_LOCATION VARCHAR(5)
	DECLARE @_RECORD_USER VARCHAR(5)

--INSERT [APCSPRODWH].[DBO].[ADM00001] ([WRITETIME] ,[SEQNO6] ,[ROVANSFILE] ,[ROVANSDATA] ,[SENDENDFL] ,[MAKDT] ,[MAKP] ,[MAKC] ,[UPDDT] ,[UPDP] ,[UPDC] ,[DELF] ,[DELDT] ,[DELP] ,[DELC])
select t3.writetime
	,t3.seqno6
	,t3.rovansfile
	,case when t3.record_type = 2 then 'GEE' + FORMAT(t3.seqno6-100000, '000000') + [storedproceduredb].[material].[fn_space_right]('MAIO', 9) + SPACE(62) else t3.rovansdata end as rovansdata
	,t3.sendendfl
	,t3.makdt
	,t3.makp
	,t3.makc
	,t3.upddt
	,t3.updp
	,t3.updc
	,t3.delf
	,t3.deldt
	,t3.delp
	,t3.delc
from (
	select t2.record_type
		,t2.writetime
		,100000 + rank() over (
			order by t2.record_type
				,seqno6
			) as seqno6
		,t2.rovansfile
		,t2.rovansdata
		,t2.sendendfl
		,t2.makdt
		,t2.makp
		,t2.makc
		,t2.upddt
		,t2.updp
		,t2.updc
		,t2.delf
		,t2.deldt
		,t2.delp
		,t2.delc
	from (
		select 0 as record_type
			,@FILE_DATE as writetime
			,0 as seqno6
			,'MAIO' as rovansfile
			,'GESGEIS1.000ZZROHM0024' + SPACE(7) + 'ZZROHM0010' + SPACE(7) + RIGHT(@DATE_FORMAT, 10) + [StoredProcedureDB].[material].[fn_space_right]('MAIO', 9) + 'JST' + SPACE(12) as rovansdata
			,0 as sendendfl
			,@FILE_DATE as makdt
			,@USER_ID as makp
			,'PC001' as makc
			,@WRITE_TIME as upddt
			,@USER_ID as updp
			,'PC001' as updc
			,0 as delf
			,@WRITE_TIME as deldt
			,SPACE(1) as delp
			,SPACE(1) as delc
		union all
		select 1 as record_type
			,@FILE_DATE as writetime
			,t1.REC_NO as seqno6
			,'MAIO' as rovansfile
			,t1.RECORD_CLASS + t1.IN_DATE + t1.IN_LOC + t1.OUT_LOC + t1.PROD_NAME + t1.QUANTITY + t1.QTY2 + t1.is_red + t1.INVOICE_NO + t1.PO_NO + t1.line_no as rovansdata
			,0 as sendendfl
			,@FILE_DATE as makdt
			,@USER_ID as makp
			,'PC001' as makc
			,@WRITE_TIME as upddt
			,@USER_ID as updp
			,'PC001' as updc
			,0 as delf
			,@WRITE_TIME as deldt
			,SPACE(1) as delp
			,SPACE(1) as delc
		from (
			select  case mr.record_class when 0 then '11' else '15' end as RECORD_CLASS
				,case mr.record_class when 0 then format(ar.recorded_at, 'yyMMdd') else format(mr.recorded_at, 'yyMMdd') end as IN_DATE
				,case mr.record_class 
					when 0 then pr.supplier_cd 
					else 
						case l_fm.wh_code 
							when 'QI999' then l_fm.wh_code 
							when 'QI900' then l_fm.wh_code 
							else 'QI000' end
					end as IN_LOC
				,case mr.record_class 
					when 0 then  l_ar.wh_code 
					else
						case l_to.wh_code 
							when 'QI999' then l_to.wh_code 
							when 'QI900' then l_to.wh_code 
							else 'QI000' end
				end as OUT_LOC
				,left(rtrim(pr.name) + space(20), 20) as PROD_NAME
				,format(mt.in_quantity, '000000000') + '00' as QUANTITY
				,'00000' as QTY2
				,'0' as is_red
				,left(ar.invoice_no + space(10), 10) as INVOICE_NO
				,left(ar.po_no + space(13), 13) as PO_NO
				,space(2) as line_no
				,rank() over (
					order by mr.id
					) as REC_NO
			from APCSProDB.trans.material_records as mr with (nolock)
			left outer join [APCSProDB].trans.material_arrival_records as ar with (nolock) on ar.material_id = mr.material_id
			inner join [APCSProDB].trans.materials as mt with (nolock) on mt.id = ar.material_id
			inner join [APCSProDB].material.productions as pr with (nolock) on pr.id = mt.material_production_id
			inner join [APCSProDB].material.categories as ct with (nolock) on ct.id = pr.category_id
			left outer join [APCSProDB].material.locations as l_ar with (nolock) on l_ar.id = ar.location_id
			left outer join [APCSProDB].material.locations as l_fm with (nolock) on l_fm.id = mr.location_id
			left outer join [APCSProDB].material.locations as l_to with (nolock) on l_to.id = mr.to_location_id
			where mr.recorded_at between dateadd(hour,-8,convert(datetime,@FILE_DATE)) and DATEADD(hour,16,convert(datetime,@FILE_DATE))
			--mr.recorded_at between dateadd(hour,-8,convert(datetime,'2019-11-25 00:00:00.700')) and DATEADD(hour,16,convert(datetime,'2019-11-25 23:00:00.700'))
				/*mr.recorded_at > '2019-10-01'*/
				and mr.record_class in (0, 2)
				and ct.short_name = '03'
			) as t1
		union all
		select 2 as record_type
			,@FILE_DATE as writetime
			,0 as seqno6
			,'MAIO' as rovansfile
			,'' as rovansdata
			,0 as sendendfl
			,@FILE_DATE as makdt
			,@USER_ID as makp
			,'PC001' as makc
			,@WRITE_TIME as upddt
			,@USER_ID as updp
			,'PC001' as updc
			,0 as delf
			,@WRITE_TIME as deldt
			,SPACE(1) as delp
			,SPACE(1) as delc
		) as t2
	) as t3

-- ************** MAIO ************** --

	SET NOCOUNT OFF
END;



--	EXEC [trans].[sp_rpt_data_interface_20191018NewMAIOFUK5_v15] '2019-12-06 01:30:40.853', 2, 1

