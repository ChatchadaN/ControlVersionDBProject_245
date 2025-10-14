



Create PROCEDURE [trans].[sp_rpt_data_interface_20191018NewMAIOFUK5_v12]
@FILE_DATE DATE,
@LOCATION_ID INT,
@USER_ID INT
AS
BEGIN
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
INSERT [APCSPRODWH].[DBO].[ADM00001] ([WRITETIME] ,[SEQNO6] ,[ROVANSFILE] ,[ROVANSDATA] ,[SENDENDFL] ,[MAKDT] ,[MAKP] ,[MAKC] ,[UPDDT] ,[UPDP] ,[UPDC] ,[DELF] ,[DELDT] ,[DELP] ,[DELC])
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
				,case when isnull(mt.qc_state,0) = 0 then 'QI900' else 'QI999' end as LOC
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
			inner join apcsprodb.trans.material_arrival_records as ar with (NOLOCK) 
				on ar.material_id = mt.id 
				/* add v9 */
					and not exists (select * from APCSProDB.trans.material_arrival_records as ar2 with (NOLOCK) 
										where ar2.material_id = ar.material_id and ar2.recorded_at > ar.recorded_at)
				/* add v9 end */
			where --mt.material_state = 1 and
				 ct.short_name = '03'  /*03:frame*/
				 and mt.location_id in (select id from [APCSProDB].material.locations where wh_code in ('QI900', 'QI999'))
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

INSERT [APCSPRODWH].[DBO].[ADM00001] ([WRITETIME] ,[SEQNO6] ,[ROVANSFILE] ,[ROVANSDATA] ,[SENDENDFL] ,[MAKDT] ,[MAKP] ,[MAKC] ,[UPDDT] ,[UPDP] ,[UPDC] ,[DELF] ,[DELDT] ,[DELP] ,[DELC])
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
			select case mr.record_class when 0 then '11' else '15' end as RECORD_CLASS
				,case mr.record_class when 0 then format(ar.recorded_at, 'yyMMdd') else format(mr.recorded_at, 'yyMMdd') end as IN_DATE
				,case mr.record_class when 0 then pr.supplier_cd else l.wh_code end as IN_LOC
				,case mr.record_class when 0 then l.wh_code else 'QI000' end as OUT_LOC
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
			left outer join [APCSProDB].material.locations as l with (nolock) on l.id = ar.location_id
			left outer join [APCSProDB].material.locations as lto with (nolock) on lto.id = mr.location_id
			where mr.recorded_at between dateadd(hour,-8,convert(datetime,@FILE_DATE)) and DATEADD(hour,16,convert(datetime,@FILE_DATE))
				/*mr.recorded_at > '2019-10-01'*/
				and mr.record_class in (0, 2)
				and not exists (
					select *
					from APCSProDB.trans.material_records as mr2 with (nolock)
					where mr2.id < mr.id
						and mr2.material_id = mr.material_id
						and mr2.record_class = mr.record_class
					)
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
	
---- ************** FUK4 ************** --

--	DECLARE @_MAT_CREATED_DATE DATE

--	SET @_NO = 1;
--	DECLARE DB_CURSOR_FUK4 CURSOR LOCAL FAST_FORWARD FOR
--		SELECT
--				[MATL].BARCODE, 
--				[LOC].WH_CODE AS ARRIVAL_LOCATION, 
--				[CATE].SHORT_NAME AS CATE_CODE, 
--				[PROD].NAME AS PROD_NAME,
--				[RECORD].QUANTITY,
--				[PROD].SUPPLIER_CD,
--				[RECORD].RECORDED_AT AS IN_DATE,
--				CASE [RECORD].RECORD_CLASS
--					WHEN 1 THEN 11 -- IN
--					WHEN 2 THEN 15 -- OUT
--				END AS RECORD_CLASS,
--				[ARRIVAL].PO_NO,
--				[ARRIVAL].INVOICE_NO,
--				[MATL].[QC_STATE],
--				[IN_LOC].WH_CODE,
--				[OUT_LOC].WH_CODE,
--				[MATL].CREATED_AT
--		FROM [APCSPRODB].[TRANS].[MATERIAL_RECORDS] [RECORD]
--		INNER JOIN [APCSPRODB].[TRANS].[MATERIALS] [MATL] ON [RECORD].MATERIAL_ID = [MATL].ID
--		INNER JOIN [APCSPRODB].MATERIAL.PRODUCTIONS [PROD] ON [MATL].MATERIAL_PRODUCTION_ID = [PROD].ID
--		INNER JOIN [APCSPRODB].MATERIAL.CATEGORIES [CATE] ON [PROD].CATEGORY_ID = [CATE].ID
--		INNER JOIN [APCSPRODB].MATERIAL.MASTER_DATA [MASTER] ON [MASTER].CODE = [CATE].SHORT_NAME
--		INNER JOIN [APCSPRODB].[TRANS].[MATERIAL_ARRIVAL_RECORDS] [ARRIVAL] ON [MATL].ID = [ARRIVAL].MATERIAL_ID
--		INNER JOIN [APCSPRODB].MATERIAL.LOCATIONS [LOC] ON [ARRIVAL].LOCATION_ID = [LOC].ID
--		LEFT JOIN [APCSPRODB].[TRANS].MATERIAL_OUTGOING_ITEMS [OUT_ITEM] ON [RECORD].ID = [OUT_ITEM].RECORD_ID
--		LEFT JOIN [APCSPRODB].[TRANS].MATERIAL_OUTGOINGS [OUT_GOING] ON [OUT_ITEM].MATERIAL_OUTGOINGS_ID = [OUT_GOING].ID
--		LEFT JOIN [APCSPRODB].MATERIAL.LOCATIONS [IN_LOC] ON [OUT_GOING].FROM_LOCATION_ID = [IN_LOC].ID
--		LEFT JOIN [APCSPRODB].MATERIAL.LOCATIONS [OUT_LOC] ON [OUT_GOING].TO_LOCATION_ID = [OUT_LOC].ID
--		WHERE [RECORD].RECORD_CLASS IN (1, 2)
--			AND [LOC].WH_CODE IN ('QI900', 'QI999', 'QI000')
--			AND [RECORD].DAY_ID = @DAY_ID
--		ORDER BY [CATE].SHORT_NAME, [RECORD].LOCATION_ID, [PROD].NAME, [RECORD].BARCODE, [RECORD].RECORD_CLASS

--	OPEN DB_CURSOR_FUK4  
--	FETCH NEXT FROM DB_CURSOR_FUK4 INTO @_BARCODE, @_MAT_LOCATION, @_CATE_CODE, @_PROD_NAME, @_QUANTITY, @_SUPPLIER_CD, @_IN_DATE, @_RECORD_CLASS, @_PO_NO, @_INV_NO, @_QC_STATE, @_FROM_LOCATION, @_TO_LOCATION, @_MAT_CREATED_DATE;
--	WHILE @@FETCH_STATUS = 0
--		BEGIN
--			IF @_NO = 1
--			BEGIN
--				-- FUK4 HEADER
--				INSERT [APCSPRODWH].[DBO].[ADM00001] ([WRITETIME] ,[SEQNO6] ,[ROVANSFILE] ,[ROVANSDATA] ,[SENDENDFL] ,[MAKDT] ,[MAKP] ,[MAKC] ,[UPDDT] ,[UPDP] ,[UPDC] ,[DELF] ,[DELDT] ,[DELP] ,[DELC])
--				VALUES(
--					@FILE_DATE
--					,@_NO
--					,'FUK4'
--					,'GESGEIS1.000ZZROHM0024'+ SPACE(7) +'ZZROHM0011'+ SPACE(7) + RIGHT(@DATE_FORMAT, 10) + [material].[fn_space_right]('FUK4', 9) + 'JST' + SPACE(12)
--					,0
--					,@FILE_DATE
--					,@USER_ID
--					,'PC001'
--					,@WRITE_TIME
--					,@USER_ID
--					,'PC001'
--					,0
--					,@WRITE_TIME
--					,SPACE(1)
--					,SPACE(1)
--				);
--				SET @_NO = @_NO + 1;
--			END;
			
--			IF @_RECORD_CLASS = 11 -- IN
--			BEGIN
--				IF @_QC_STATE = 3 -- HOLD STATE
--				BEGIN
--					IF @_MAT_LOCATION = 'QI999'
--						SET @_FROM_LOCATION = 'QI900';
--					ELSE
--						SET @_FROM_LOCATION = 'QI999';
--				END
--				ELSE
--					SET @_FROM_LOCATION = @_SUPPLIER_CD;
--			END
--			ELSE
--				IF @_FROM_LOCATION IS NULL
--					SET @_FROM_LOCATION = @_MAT_LOCATION;
					
--			IF @_RECORD_CLASS = 15 -- OUT
--			BEGIN
--				IF @_QC_STATE = 3 -- HOLD STATE
--				BEGIN
--					IF @_MAT_LOCATION = 'QI999'
--						SET @_TO_LOCATION = 'QI900';
--					ELSE
--						SET @_TO_LOCATION = 'QI999';
--				END
--				ELSE
--					IF @_TO_LOCATION IS NULL
--						SET @_TO_LOCATION = 'PC000'; -- DIRECT TO PROCESS
--			END
--			ELSE
--				SET @_TO_LOCATION = @_MAT_LOCATION;

--			IF @_RECORD_CLASS <> 11
--			BEGIN
--				SET @_INV_NO = SPACE(10)
--				SET @_PO_NO = SPACE(10)
--			END

--			-- FUK4 CONTENT / 1
--			INSERT [APCSPRODWH].[DBO].[ADM00001] ([WRITETIME] ,[SEQNO6] ,[ROVANSFILE] ,[ROVANSDATA] ,[SENDENDFL] ,[MAKDT] ,[MAKP] ,[MAKC] ,[UPDDT] ,[UPDP] ,[UPDC] ,[DELF] ,[DELDT] ,[DELP] ,[DELC])
--			VALUES(
--				@FILE_DATE
--				,@_NO
--				,'FUK4'
--				,'01' + 
--					CAST(@_RECORD_CLASS AS CHAR(2)) + 
--					@_CATE_CODE + 
--					[material].[fn_space_right](@_MAT_LOCATION, 5) + -- IN DEP
--					[material].[fn_space_right](@_FROM_LOCATION, 5) + -- ISSUE
--					[material].[fn_space_right](@_TO_LOCATION, 5) + -- REC DEP
--					[material].[fn_space_right](@_PROD_NAME, 20) + 
--					FORMAT(@_QUANTITY * 100, '00000000000') + 
--					'0' +  -- RED_BLK_CLS
--					'1' + -- COM VALUE
--					'G' + 
--					ISNULL(@_PO_NO, SPACE(10)) + 
--					ISNULL(@_INV_NO, SPACE(10)) +
--					SPACE(3) + -- PROD_CTL_CLS
--					SPACE(1) + -- ISSUE_CLS
--					SPACE(1)
--				,0
--				,@FILE_DATE
--				,@USER_ID
--				,'PC001'
--				,@FILE_DATE
--				,@USER_ID
--				,'PC001'
--				,0
--				,@FILE_DATE
--				,SPACE(1)
--				,SPACE(1)
--			);
--			SET @_NO = @_NO + 1;

--			-- FUK4 CONTENT / 2
--			--INSERT [APCSPRODWH].[DBO].[ADM00001] ([WRITETIME] ,[SEQNO6] ,[ROVANSFILE] ,[ROVANSDATA] ,[SENDENDFL] ,[MAKDT] ,[MAKP] ,[MAKC] ,[UPDDT] ,[UPDP] ,[UPDC] ,[DELF] ,[DELDT] ,[DELP] ,[DELC])
--			--VALUES(
--			--	@FILE_DATE
--			--	,@_NO
--			--	,'FUK4'
--			--	,CAST('02' + 
--			--		CONVERT(VARCHAR(8), @_IN_DATE, 112) + 
--			--		CASE @_RECORD_CLASS
--			--			WHEN 15 THEN CONVERT(VARCHAR(8), @_MAT_CREATED_DATE, 112)
--			--			ELSE '00000000'
--			--		END +
--			--		SPACE(62) AS CHAR(80))
--			--	,0
--			--	,@FILE_DATE
--			--	,@USER_ID
--			--	,'PC001'
--			--	,@WRITE_TIME
--			--	,@USER_ID
--			--	,'PC001'
--			--	,0
--			--	,@WRITE_TIME
--			--	,SPACE(1)
--			--	,SPACE(1)
--			--);
--			--SET @_NO = @_NO + 1;
--			FETCH NEXT FROM DB_CURSOR_FUK4 INTO @_BARCODE, @_MAT_LOCATION, @_CATE_CODE, @_PROD_NAME, @_QUANTITY, @_SUPPLIER_CD, @_IN_DATE, @_RECORD_CLASS, @_PO_NO, @_INV_NO, @_QC_STATE, @_FROM_LOCATION, @_TO_LOCATION, @_MAT_CREATED_DATE;
--		END
--	CLOSE DB_CURSOR_FUK4  
--	DEALLOCATE DB_CURSOR_FUK4;

--	-- FUK4 FOOTER
--	INSERT [APCSPRODWH].[DBO].[ADM00001] ([WRITETIME] ,[SEQNO6] ,[ROVANSFILE] ,[ROVANSDATA] ,[SENDENDFL] ,[MAKDT] ,[MAKP] ,[MAKC] ,[UPDDT] ,[UPDP] ,[UPDC] ,[DELF] ,[DELDT] ,[DELP] ,[DELC])
--	VALUES(
--		@FILE_DATE
--		,@_NO
--		,'FUK4'
--		,'GEE'+ FORMAT(@_NO, '000000') +'FUK4'
--		,0
--		,@FILE_DATE
--		,@USER_ID
--		,'PC001'
--		,@WRITE_TIME
--		,@USER_ID
--		,'PC001'
--		,0
--		,@WRITE_TIME
--		,SPACE(1)
--		,SPACE(1)
--	);
---- ************** FUK4 ************** --

	SET NOCOUNT OFF
END;



--	EXEC [trans].[sp_rpt_data_interface_2] '2019-10-03 01:30:40.853', 2, 1
--  SELECT * FROM [APCSPRODWH].[DBO].[ADM00001] WHERE rovansfile = 'MAIO' ORDER BY UPDDT DESC
