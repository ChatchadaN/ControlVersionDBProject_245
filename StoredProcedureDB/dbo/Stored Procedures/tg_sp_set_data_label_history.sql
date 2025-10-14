-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_data_label_history]
	-- Add the parameters for the stored procedure here
	@lot_no_value varchar(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	 DECLARE @short_name char(20) = ' '
	 DECLARE @reel_num INT = 0;
	 DECLARE @Lotno char(10) = '';
	 DECLARE @Lotno_hasuu char(10)  = '';
	 DECLARE @QTY int = 0;
	 DECLARE @Package char(20)  = '';
	 DECLARE @Device char(20)  = '';
	 DECLARE @AssyName char(20)  = '';
	 DECLARE @Standard int = 0;
	 DECLARE @Total int = 0;
	 DECLARE @qty_hasuu_before int = 0;
	 DECLARE @qty_lot_standard_before int = 0;
	 DECLARE @Mno_Standard char(20)  = '';
	 DECLARE @Mno_Hasuu char(20)  = '';
	 DECLARE @Label_Type int  = 0;
	 DECLARE @Rank char(20)  = '';
	 DECLARE @TPRank char(20)  = '';
	 DECLARE @Customer_Device char(20)  = '';
	 DECLARE @SPEC  char(20)  = '';
	 DECLARE @FLOOR_LIFE   char(20)  = '';
	 DECLARE @PPBT   char(20)  = '';
	 DECLARE @BoxType   char(20)  = '';
	 DECLARE @Tomson_box   char(20)  = '';
	 DECLARE @OPNo   char(10)  = '';
	 DECLARE @OPName   char(20)  = '';
	 DECLARE @Hasuu_qty int = 0;
	 DECLARE @convert_mno_value int = 0;
	 DECLARE @Tomson_Mark_3 char(4) = ' ';
	 DECLARE @Required_ul_logo int = 0;
	 DECLARE @Lot_id int = 0;
    -- Insert statements for procedure here

	select @Lot_id = id from APCSProDB.trans.lots where lot_no = @lot_no_value

	select @Lotno_hasuu = lots.lot_no from APCSProDB.trans.lot_combine as lot_com
	inner join APCSProDB.trans.lots as lots on lot_com.member_lot_id = lots.id
	where lot_id = @Lot_id

	select @Mno_Standard = MNO2 from APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT where LOT_NO_1 = @lot_no_value

	select @Mno_Hasuu = MNO2 from APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT where LOT_NO_1 = @Lotno_hasuu

	--select @Mno_Hasuu = MNo from StoredProcedureDB.dbo.IS_ALLOCAT where LotNo = @Lotno_hasuu

	SELECT top(1)
	 @Lotno = lot.lot_no
	,@QTY = lot.qty_pass 
	,@reel_num = lot.qty_pass/dv.pcs_per_pack
	,@Hasuu_qty = (lot.qty_pass)%([dv].pcs_per_pack) 
	,@Package = pk.name
	,@Device = dv.name
	,@AssyName = dv.assy_name
	,@Customer_Device = multi_label.USER_Model_Name  
	,@Rank = dv.rank
	,@TPRank = dv.tp_rank
	--,@Mno_Standard = allo_cat.MNo
	,@Standard = [dv].pcs_per_pack
	,@Total = lot.qty_pass-(lot.qty_pass)%(dv.pcs_per_pack)  
	,@SPEC = msl.SPEC 
	,@FLOOR_LIFE = msl.FLOOR_LIFE 
	,@PPBT = msl.PPBT 
	,@Tomson_box = packmat.TOMSON_BOX 
	,@BoxType = box.BOX_TYPE 
	,@OPNo = lot_cb.updated_by
	from APCSProDB.trans.lot_combine as lot_cb
	inner join APCSProDB.trans.lots as lot on lot_cb.lot_id = lot.id
	inner join APCSProDB.method.packages as pk on lot.act_package_id = pk.id
	inner join APCSProDB.method.device_names as dv on lot.act_device_name_id = dv.id
	left join StoredProcedureDB.dbo.IS_ALLOCAT as allo_cat on lot.lot_no = allo_cat.LotNo
	LEFT join DBxDW.TGOG.IS_JEDEC_PACKAGE_MASTER as msl on pk.short_name COLLATE Latin1_General_CI_AS = msl.PACKAGE_NAME and lot_cb.created_at >= msl.START_DATE COLLATE Latin1_General_CI_AS
	LEFT join StoredProcedureDB.dbo.IS_PACKING_MAT as packmat on pk.short_name COLLATE Latin1_General_CI_AS = packmat.Type_Name COLLATE Latin1_General_CI_AS 
	and dv.name COLLATE Latin1_General_CI_AS = packmat.ROHM_Model_Name COLLATE Latin1_General_CI_AS
	LEFT join (select * from StoredProcedureDB.dbo.IS_BOX where TP = '1') as box on pk.short_name COLLATE Latin1_General_CI_AS = box.TYPE_NAME COLLATE Latin1_General_CI_AS
	LEFT join StoredProcedureDB.dbo.IS_MULTI_LABEL_M as multi_label on dv.name COLLATE Latin1_General_CI_AS = multi_label.ROHM_Model_Name COLLATE Latin1_General_CI_AS
	where lot_id = @Lot_id

	--check logo UL
	SELECT @Required_ul_logo = required_ul_logo FROM [APCSProDB].[method].[device_names] where name = @Device and assy_name = @AssyName
	select @Tomson_Mark_3 = Tomson3 from StoredProcedureDB.dbo.IS_ALLOCAT where LotNo = @Lotno

	DECLARE @op_no_len varchar(10);
	DECLARE @op_no_len_value varchar(10);

	select @op_no_len = @OPNo

	select  @op_no_len_value =  case when LEN(CAST(@op_no_len as varchar(10))) = 5 then '0' + CAST(@op_no_len as varchar(10))
			when LEN(CAST(@op_no_len as varchar(10))) = 4 then '00' + CAST(@op_no_len as varchar(10))
			when LEN(CAST(@op_no_len as varchar(10))) = 3 then '000' + CAST(@op_no_len as varchar(10))
			when LEN(CAST(@op_no_len as varchar(10))) = 2 then '0000' + CAST(@op_no_len as varchar(10))
			else CAST(@op_no_len as varchar(10)) end 

	--select @OPName = CAST(name as char(20)) from [APCSProDB].[man].[users] where emp_num = @op_no_len_value

	SELECT @OPName =
	CASE
		WHEN SUBSTRING(CAST(name as char(20)),1,3) ='MR.' THEN LEFT(SUBSTRING([users].name, 5,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
		WHEN SUBSTRING(CAST(name as char(20)),1,4) ='MISS' THEN LEFT(SUBSTRING([users].name, 6,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
		WHEN SUBSTRING(CAST(name as char(20)),1,3) ='MRS' THEN LEFT(SUBSTRING([users].name, 6,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
    ELSE SUBSTRING(CAST(name as char(20)), 1,LEN([users].name)) END 
	FROM [APCSProDB].[man].[users]
	WHERE [users].[emp_num] = @op_no_len_value

	DECLARE @check_mno_for_reel float = CAST(@Hasuu_qty as float) / CAST(@Standard as float);
	select @convert_mno_value = CEILING(@check_mno_for_reel) 

	DECLARE @i INT = 0;
	DECLARE @Mno_hasuu_value char(10) = ''

	--create #tempDataByOom
	CREATE TABLE #tempData(
		[type_of_label] [int] NOT NULL,
		[lot_no] [char](10) NOT NULL,
		[Customer_Device] [char](20) NOT NULL,
		[Rohm_Model_Name] [char](20) NOT NULL,
		[qty] [char](20) NOT NULL,
		[barcode_lotno] [char](20) NOT NULL,
		[tomson_box] [char](20) NOT NULL,
		[tomson_3] [char](20) NOT NULL,
		[box_type] [char](20) NOT NULL,
		[barcode_bottom] [char](18) NOT NULL,
		[mno_std] [char](20) NOT NULL,
		[std_qty_before] [char](20) NOT NULL,
		[mno_hasuu] [char](20) NOT NULL,
		[hasuu_qty_before] [char](20) NOT NULL,
		[no_reel] [char](20) NOT NULL,
		[qrcode_detail] [char](90) NOT NULL,
		[type_label_laterat] [char](20) NOT NULL,
		[mno_std_laterat] [char](20) NOT NULL,
		[mno_hasuu_laterat] [char](20) NOT NULL,
		[barcode_device_detail] [char](20) NOT NULL,
		[op_no] [int] NOT NULL,
		[op_name] [char](20) NULL,
		[SEQ] [int] NULL,
		[Mc_Name] [char](15) NULL,
		[MSL_LAVEL] [varchar](15) NULL,
		[FLOOR_LIFE] [varchar](15) NULL,
		[PPBT] [varchar](15) NULL,
		[re_comment] [varchar](60) NOT NULL,
		[VERSION] [int] NULL,
		[is_logo] [int] NULL,
		[create_at] [datetime] NULL,
		[create_by] [int] NULL,
		[update_at] [datetime] NULL,
		[update_by] [int] NULL,
		
	);

	DECLARE @sql varchar(max);
	SET @i = 1;

	SET @sql = 'INSERT INTO #tempData (type_of_label,lot_no,Customer_Device';
	SET @sql = @sql + ',Rohm_Model_Name,qty,barcode_lotno,tomson_box,tomson_3';
	SET @sql = @sql + ',box_type,barcode_bottom,mno_std,std_qty_before,mno_hasuu';
	SET @sql = @sql + ',hasuu_qty_before,no_reel,qrcode_detail,type_label_laterat';
	SET @sql = @sql + ',mno_std_laterat,mno_hasuu_laterat,barcode_device_detail';
	SET @sql = @sql + ',op_no,op_name,SEQ,Mc_Name,MSL_LAVEL,FLOOR_LIFE,PPBT';
	SET @sql = @sql + ',re_comment,VERSION,is_logo,create_at,create_by,update_at,update_by) values ';

	WHILE @i <= @reel_num + 2
	BEGIN
		--#1
		IF @i = 1

		BEGIN	
			SET @sql = @sql + '(''1''';
			SET @sql = @sql + ',''' + Cast((@Lotno) as char(10)) + '''';
			SET @sql = @sql + ',''' + case when Cast((@Customer_Device) as char(20)) is null or Cast((@Customer_Device) as char(20)) = '' then Cast((@Device) as char(20))
			 else Cast((@Customer_Device) as char(20)) end + '''';
			SET @sql = @sql + ',''' + Cast((@Device) as char(20)) + '''';
			SET @sql = @sql + ',''' + Cast((@QTY) as char(20)) + '''';
			SET @sql = @sql + ',''' + Cast(SUBSTRING(@Lotno, 1, 4) as char(4)) + ' ' + Cast(SUBSTRING(@Lotno, 5, 6) as char(6)) + '''';
			SET @sql = @sql + ',''' + Cast((@Tomson_box) as char(20)) + '''';
			SET @sql = @sql + ',''' + Cast((@Tomson_Mark_3) as char(4)) + '''';
			SET @sql = @sql + ',''' + case when Cast((@BoxType) as char(20)) is null or Cast((@BoxType) as char(20)) = '' then ' '
			 else Cast((@BoxType) as char(20)) end + '''';
			SET @sql = @sql + ',''' + Cast((@QTY) as char(20)) + '''';
			SET @sql = @sql + ',''' + Cast((@Mno_Standard) as char(20)) + '''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''' + Cast((@Mno_Hasuu) as char(20)) + '''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''' + '00' + Cast((2 + @reel_num) as char(3)) + '''';
			SET @sql = @sql + ',''' + Cast(@Device as varchar(19)) + case when LEN(CAST(@Standard as varchar(6))) = 5 then '0' + CAST(@Standard as varchar(6))  + CAST(@Lotno as varchar(10)) + '00' + Cast((2 + @reel_num) as char(3))
			  when LEN(CAST(@Standard as varchar(6))) = 4 then '00' + CAST(@Standard as varchar(6))  + CAST(@Lotno as varchar(10)) + '00' + Cast((2 + @reel_num) as char(3))
			  when LEN(CAST(@Standard as varchar(6))) = 3 then '000' + CAST(@Standard as varchar(6))  + CAST(@Lotno as varchar(10)) + '00' + Cast((2 + @reel_num) as char(3))
			  when LEN(CAST(@Standard as varchar(6))) = 2 then '0000' + CAST(@Standard as varchar(6))  + CAST(@Lotno as varchar(10)) + '00' + Cast((2 + @reel_num) as char(3))
			  else CAST(@Standard as varchar(6)) + CAST(@Lotno as varchar(10)) + '00' + Cast((2 + @reel_num) as char(3)) end + '''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''' + @OPNo + '''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''' + Cast((@SPEC) as varchar(15)) + '''';
			SET @sql = @sql + ',''' + Cast((@FLOOR_LIFE) as varchar(15)) + '''';
			SET @sql = @sql + ',''' + Cast((@PPBT) as varchar(15)) + '''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''' + Cast((@Required_ul_logo) as varchar(1)) + '''';
			SET @sql = @sql + ',''' + convert(varchar(max),getdate(),121) + '''';
			SET @sql = @sql + ',''' + @OPNo + '''';
			SET @sql = @sql + ',''' + convert(varchar(max),getdate(),121) + '''';
			SET @sql = @sql + ',''' + @OPNo + ''')';
		END
		--#2
		ELSE IF @i = 2

		BEGIN	
			SET @sql = @sql + ',(''2''';
			SET @sql = @sql + ',''' + Cast((@Lotno) as char(10)) + '''';
			SET @sql = @sql + ',''' + case when Cast((@Customer_Device) as char(20)) is null or Cast((@Customer_Device) as char(20)) = '' then Cast((@Device) as char(20))
			 else Cast((@Customer_Device) as char(20)) end + '''';
			SET @sql = @sql + ',''' + Cast((@Device) as char(20)) + '''';
			SET @sql = @sql + ',''' + Cast((@Hasuu_qty) as char(20)) + '''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''' + case when LEN(CAST(@Standard as varchar(6))) = 5 then '0' + CAST(@Standard as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
			  when LEN(CAST(@Standard as varchar(6))) = 4 then '00' + CAST(@Standard as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
			  when LEN(CAST(@Standard as varchar(6))) = 3 then '000' + CAST(@Standard as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
			  when LEN(CAST(@Standard as varchar(6))) = 2 then '0000' + CAST(@Standard as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
			  else CAST(@Standard as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11)) end
			  + '''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''' + Cast((@Mno_Hasuu) as char(20)) + '''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''' + '00' + Cast((1 + @reel_num) as char(3)) + '''';
			SET @sql = @sql + ',''' + Cast(@Device as varchar(19)) + case when LEN(CAST(@Standard as varchar(6))) = 5 then '0' + CAST(@Standard as varchar(6))  + CAST(@Lotno as varchar(10)) + '00' + Cast((1 + @reel_num) as char(3))
			  when LEN(CAST(@Standard as varchar(6))) = 4 then '00' + CAST(@Standard as varchar(6))  + CAST(@Lotno as varchar(10)) + '00' + Cast((1 + @reel_num) as char(3))
			  when LEN(CAST(@Standard as varchar(6))) = 3 then '000' + CAST(@Standard as varchar(6))  + CAST(@Lotno as varchar(10)) + '00' + Cast((1 + @reel_num) as char(3))
			  when LEN(CAST(@Standard as varchar(6))) = 2 then '0000' + CAST(@Standard as varchar(6))  + CAST(@Lotno as varchar(10)) + '00' + Cast((1 + @reel_num) as char(3))
			  else CAST(@Standard as varchar(6)) + CAST(@Lotno as varchar(10)) + '00' + Cast((1 + @reel_num) as char(20)) end + '''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''' + Cast((@Device) as char(20)) + '''';
			SET @sql = @sql + ',''' + @OPNo + '''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''' + Cast((@SPEC) as varchar(15)) + '''';
			SET @sql = @sql + ',''' + Cast((@FLOOR_LIFE) as varchar(15)) + '''';
			SET @sql = @sql + ',''' + Cast((@PPBT) as varchar(15)) + '''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''' + Cast((@Required_ul_logo) as varchar(1)) + '''';
			SET @sql = @sql + ',''' + convert(varchar(max),getdate(),121) + '''';
			SET @sql = @sql + ',''' + @OPNo + '''';
			SET @sql = @sql + ',''' + convert(varchar(max),getdate(),121) + '''';
			SET @sql = @sql + ',''' + @OPNo + ''')';
		END
		--#more then 3
		ELSE

		BEGIN	
			--SET @sql = @sql + ',(''bass' + Cast((@count) as varchar(max)) + ''',''2222'')';
			SET @sql = @sql + ',(''3''';
			--SET @sql = @sql + ',(''3' + Cast((@i-2) as varchar(max)) + '''';
			SET @sql = @sql + ',''' + Cast((@Lotno) as char(10)) + '''';
			SET @sql = @sql + ',''' + case when Cast((@Customer_Device) as char(20)) is null or Cast((@Customer_Device) as char(20)) = '' then Cast((@Device) as char(20))
			 else Cast((@Customer_Device) as char(20)) end + '''';
			SET @sql = @sql + ',''' + Cast((@Device) as char(20)) + '''';
			SET @sql = @sql + ',''' + Cast((@Standard) as char(20)) + '''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''' + case when LEN(CAST(@Standard as varchar(6))) = 5 then '0' + CAST(@Standard as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
			  when LEN(CAST(@Standard as varchar(6))) = 4 then '00' + CAST(@Standard as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
			  when LEN(CAST(@Standard as varchar(6))) = 3 then '000' + CAST(@Standard as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
			  when LEN(CAST(@Standard as varchar(6))) = 2 then '0000' + CAST(@Standard as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
			  else CAST(@Standard as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11)) end
			  + '''';
			SET @sql = @sql + ',''' + Cast((@Mno_Standard) as char(20)) + '''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''' + case when @i-2 <= @convert_mno_value then Cast((@Mno_Hasuu) as char(20)) else ' ' end + '''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''' + '00' + Cast((@i-2) as char(3)) + '''';
			SET @sql = @sql + ',''' + Cast(@Device as varchar(19)) + case when LEN(CAST(@Standard as varchar(6))) = 5 
			  then '0' + CAST(@Standard as varchar(6))  + CAST(@Lotno as varchar(10)) + '00' + Cast((@i-2) as char(20)) 
			  when LEN(CAST(@Standard as varchar(6))) = 4 then '00' + CAST(@Standard as varchar(6))  + CAST(@Lotno as varchar(10)) + '00' + Cast((@i-2) as char(3)) 
			  when LEN(CAST(@Standard as varchar(6))) = 3 then '000' + CAST(@Standard as varchar(6))  + CAST(@Lotno as varchar(10)) + '00' + Cast((@i-2) as char(3)) 
			  when LEN(CAST(@Standard as varchar(6))) = 2 then '0000' + CAST(@Standard as varchar(6))  + CAST(@Lotno as varchar(10)) + '00' + Cast((@i-2) as char(3)) 
			  else CAST(@Standard as varchar(6)) + CAST(@Lotno as varchar(10)) + '00' + Cast((@i-2) as char(3))  end + '''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''' + Cast((@Device) as char(20)) + '''';
			SET @sql = @sql + ',''' + @OPNo + '''';
			SET @sql = @sql + ',''' + Cast((@OPName) as char(20)) + '''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''' + Cast((@SPEC) as varchar(15)) + '''';
			SET @sql = @sql + ',''' + Cast((@FLOOR_LIFE) as varchar(15)) + '''';
			SET @sql = @sql + ',''' + Cast((@PPBT) as varchar(15)) + '''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''''';
			SET @sql = @sql + ',''' + Cast((@Required_ul_logo) as varchar(1)) + '''';
			SET @sql = @sql + ',''' + convert(varchar(max),getdate(),121) + '''';
			SET @sql = @sql + ',''' + @OPNo + '''';
			SET @sql = @sql + ',''' + convert(varchar(max),getdate(),121) + '''';
			SET @sql = @sql + ',''' + @OPNo + ''')';	
		END
		SET @i = @i + 1;
	END;
	PRINT 'Done FOR LOOP';

	--insert into #tempDataByOom
	EXEC(@sql);

	print @sql
	--select #tempDataByOom
	--- insert select

	BEGIN TRY 
		select * from #tempData;
		INSERT INTO APCSProDB.trans.label_history
		(
		type_of_label
		,lot_no
		,Customer_Device
		,Rohm_Model_Name
		,qty
		,barcode_lotno
		,tomson_box
		,tomson_3
		,box_type
		,barcode_bottom
		,mno_std
		,std_qty_before
		,mno_hasuu
		,hasuu_qty_before
		,no_reel
		,qrcode_detail
		,type_label_laterat
		,mno_std_laterat
		,mno_hasuu_laterat
		,barcode_device_detail
		,op_no
		,op_name
		,SEQ
		,Mc_Name
		,MSL_LAVEL
		,FLOOR_LIFE
		,PPBT
		,re_comment
		,VERSION
		,is_logo
		,create_at
		,create_by
		,update_at
		,update_by
		)
		select 
		type_of_label
		,lot_no
		,Customer_Device
		,Rohm_Model_Name
		,qty
		,barcode_lotno
		,tomson_box
		,tomson_3
		,box_type
		,barcode_bottom
		,mno_std
		,std_qty_before
		,mno_hasuu
		,hasuu_qty_before
		,no_reel
		,qrcode_detail
		,type_label_laterat
		,mno_std_laterat
		,mno_hasuu_laterat
		,barcode_device_detail
		,op_no
		,op_name
		,SEQ
		,Mc_Name
		,MSL_LAVEL
		,FLOOR_LIFE
		,PPBT
		,re_comment
		,VERSION
		,is_logo
		,create_at
		,create_by
		,update_at
		,update_by
		from #tempData;

	--Clear #tempDataByOom
	DROP TABLE #tempData;

	END TRY
	BEGIN CATCH 
			SELECT 'FALSE' AS Status ,'Insert Data error !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
	END CATCH


	
	
	
END
