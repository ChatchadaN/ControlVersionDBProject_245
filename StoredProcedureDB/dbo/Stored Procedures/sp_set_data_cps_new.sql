-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_data_cps_new]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @lot_type varchar(1)
	DECLARE @is_incoming int = 0 --is 1 : incoming,is 0 : not incoming
	DECLARE @pc_instr_value int = 0

	--update apcsdb.dbo.denpyo --> apcsprodb.dbo.denpyo  #2024/04/08 time : 13.24 by aomsin

	--add log sql Date : 2021/11/10 Time : 12.56
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
			([record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [command_text]
			, [lot_no])
		SELECT GETDATE()
			, '4'
			, ORIGINAL_LOGIN()
			, HOST_NAME() ---- 'StoredProcedureDB'
			, APP_NAME() ---- 'TGSYSTEM(insertis)'
			--add parameter log value pc_request and is incoming date modify : 2022/03/03 time : 16.48
			, 'EXEC [dbo].[sp_set_data_cps_new insert data mli02] @lotno = ''' + @lotno + ''',@is_PcRequest = ''' + CAST(@pc_instr_value as char(5)) + ''',@is_Incoming = ''' + CAST(ISNULL(@is_incoming,'') as char(5)) + '''' 
			, @lotno


	select @lot_type = SUBSTRING(lot_no,5,1) from APCSProDB.trans.label_issue_records where lot_no = @lotno
    -- Insert statements for procedure here
	
	select @is_incoming = dn.is_incoming from APCSProDB.trans.lots as lot
	inner join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
	where lot_no = @lotno

	select @pc_instr_value = pc_instruction_code from APCSProDB.trans.lots where lot_no = @lotno

	--Change Insert data trans.mli02_lsi Date : 2021/08/25
	--Update insert data type incoming label : 2021/09/10 By Aomsin 
	BEGIN TRY
	    IF @is_incoming = 1
		BEGIN
			INSERT INTO APCSProDB.trans.mli02_lsi(
			   [NYKP]
			  ,[MSGS]
			  ,[BSIJD]
			  ,[SHGM]
			  ,[KEIJ]
			  ,[SOFS]
			  ,[HKNK]
			  ,[LOCT]
			  ,[TOKI]
			  ,[TOKI2]
			  ,[KGSS]
			  ,[KGBS]
			  ,[HASM]
			  ,[SMGS]
			  ,[TKEM]
			  ,[NKYS]
			  ,[TMSS]
			  ,[SZON]
			  ,[LOTN]
			  ,[INVN]
			  ,[NYKD]
			  ,[NYID]
			  ,[BRKC]
			  ,[FG01]
			  ,[FG02]
			  ,[FG03]
			  ,[FG04]
			  ,[FG05]
			  ,[TR_FLG]
			  )
			select 
				lc_master.arrival_packing_no as NYKP 
				,'001' as MAGS
				,CONVERT(varchar,GETDATE(),112)  as BSIJD
				,'10' as SHGM
				,'' as KEIJ
				,lc_master.product_code as SOFS
				,'' as HKNK
				,'' as LOCT
				,pk_cps_lice.cps_license_no as TOKI1
				,lc_master.package_name as TOKI2
				,'0' as KGSS
				,'0' as KGBS
				,'' as HASM
				,'' as SMGH
				,lc_detail.device_name as TKEM
				,lc_detail.arrival_amount as NKYS
				,lc_detail.reel_count as TMSS --'1' as TMSS Change fix 1 is use reel_count per 1 tomson Date 2021/11/17 Time : 13.25
				,lc_detail.order_no as SZON
				,lc_detail.lot_no as LOTN
				,SUBSTRING(lc_detail.lot_no,1,7) as INVN
				,CONVERT(varchar,GETDATE(),112) as NYKD
				,'' as NYID
				,'RIS01' as BRKC
				,'0' as FG01
				,'0' as FG02
				,'0' as FG03
				,'0' as FG04
				,case when lc_master.product_code = 'QI001' then '1' else '2' end as FG05
				,'0' as TR_FLG 
				from APCSProDB.trans.incoming_labels as lc_master
				inner join APCSProDB.trans.incoming_label_details as lc_detail
				on lc_master.id = lc_detail.incoming_id
				inner join APCSProDB.trans.lots as lot 
				on lc_detail.lot_no = Trim(lot.lot_no)
				inner join APCSProDB.method.packages as pk_cps_lice 
				on lot.act_package_id = pk_cps_lice.id
				where lc_detail.lot_no = @lotno
		END
		ELSE
		BEGIN
			IF @pc_instr_value = 13 --add condition date modify : 2022/03/03 time : 15.00
			BEGIN
				INSERT INTO APCSProDB.trans.mli02_lsi(
			   [NYKP]
			  ,[MSGS]
			  ,[BSIJD]
			  ,[SHGM]
			  ,[KEIJ]
			  ,[SOFS]
			  ,[HKNK]
			  ,[LOCT]
			  ,[TOKI]
			  ,[TOKI2]
			  ,[KGSS]
			  ,[KGBS]
			  ,[HASM]
			  ,[SMGS]
			  ,[TKEM]
			  ,[NKYS]
			  ,[TMSS]
			  ,[SZON]
			  ,[LOTN]
			  ,[INVN]
			  ,[NYKD]
			  ,[NYID]
			  ,[BRKC]
			  ,[FG01]
			  ,[FG02]
			  ,[FG03]
			  ,[FG04]
			  ,[FG05]
			  ,[TR_FLG]
			  )
			select 
				SUBSTRING(label_rec.qrcode_detail,26,13) 
				,'001' 
				,CONVERT(varchar,GETDATE(),112)  
				,'10' 
				,'' 
				,case when @lot_type = 'D' then sur.pdcd else den_pyo.PROCESS_POST_CODE end
				,'' 
				,'' 
				--,cps_lice.LINNO --close data 2021/12/24 time : 09.12
				,case when pk.cps_license_no is null then '' else pk.cps_license_no end --add value date : 2021/12/24 time : 09.12
				,pk.short_name 
				,'0' 
				,'0' 
				,'' 
				,'' 
				,dn.name 
				,lot.qty_out --lot.qty_pass  --PC Request  change qty_pass is qty_out 2024/05/02 time : 13.46 by Aomsin
				,'1' 
				,case when @lot_type = 'D' then 'NO'
				else den_pyo.ORDER_NO end 
				,label_rec.lot_no 
				,SUBSTRING(label_rec.lot_no,1,7) 
				,CONVERT(varchar,GETDATE(),112) 
				,'' 
				,'RIS01' 
				,'0' 
				,'0' 
				,'0' 
				,'0' 
				,case when sur.pdcd = 'QI001' then '1' else '2' end 
				,'0' 
				from APCSProDB.trans.label_issue_records as label_rec
				inner join APCSProDB.trans.lots as lot on label_rec.lot_no = lot.lot_no
				inner join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
				inner join APCSProDB.method.packages as pk on lot.act_package_id = pk.id
				left join APCSProDB.trans.surpluses as sur on lot.id = sur.lot_id
				left join APCSProDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as den_pyo on lot.lot_no = den_pyo.LOT_NO_2
				--left join StoredProcedureDB.dbo.IS_CPS_LICENSE as cps_lice on pk.short_name = cps_lice.TYPEX4
				where label_rec.lot_no = @lotno
				--and label_rec.type_of_label = 21 --close condition 2022/15 time : 15.56
				and label_rec.type_of_label in (21,5) --new condition 2022/15 time : 15.56
				order by SUBSTRING(label_rec.qrcode_detail,26,13)  asc
			END
			ELSE IF @pc_instr_value = 11 --add condition date modify : 2022/03/03 time : 16.40
			BEGIN
				INSERT INTO APCSProDB.trans.mli02_lsi(
			   [NYKP]
			  ,[MSGS]
			  ,[BSIJD]
			  ,[SHGM]
			  ,[KEIJ]
			  ,[SOFS]
			  ,[HKNK]
			  ,[LOCT]
			  ,[TOKI]
			  ,[TOKI2]
			  ,[KGSS]
			  ,[KGBS]
			  ,[HASM]
			  ,[SMGS]
			  ,[TKEM]
			  ,[NKYS]
			  ,[TMSS]
			  ,[SZON]
			  ,[LOTN]
			  ,[INVN]
			  ,[NYKD]
			  ,[NYID]
			  ,[BRKC]
			  ,[FG01]
			  ,[FG02]
			  ,[FG03]
			  ,[FG04]
			  ,[FG05]
			  ,[TR_FLG]
			  )
				select 
				 --@lotno + RIGHT('000'+ CONVERT(VARCHAR,ROW_NUMBER() OVER(ORDER BY label_rec.type_of_label DESC)),3)  --close : 2024/05/02 time : 11.32 by Aomsin
				 SUBSTRING(label_rec.qrcode_detail,26,13)  --open : 2024/05/02 time : 11.32 by Aomsin
				,'001' 
				,CONVERT(varchar,GETDATE(),112)  
				,'10' 
				,'' 
				,case when @lot_type = 'D' then sur.pdcd else den_pyo.PROCESS_POST_CODE end
				,'' 
				,'' 
				,case when pk.cps_license_no is null then '' else pk.cps_license_no end --add value date : 2021/12/24 time : 09.12
				,pk.short_name 
				,'0' 
				,'0' 
				,'' 
				,'' 
				,dn.name 
				,case when label_rec.type_of_label = 21 then lot.qty_hasuu else dn.pcs_per_pack end
				,'1' 
				,case when @lot_type = 'D' then 'NO' else den_pyo.ORDER_NO end 
				,label_rec.lot_no 
				,SUBSTRING(label_rec.lot_no,1,7) 
				,CONVERT(varchar,GETDATE(),112) 
				,'' 
				,'RIS01' 
				,'0' 
				,'0' 
				,'0' 
				,'0' 
				,case when sur.pdcd = 'QI001' then '1' else '2' end 
				,'0' 
				from APCSProDB.trans.label_issue_records as label_rec
				inner join APCSProDB.trans.lots as lot on label_rec.lot_no = lot.lot_no
				inner join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
				inner join APCSProDB.method.packages as pk on lot.act_package_id = pk.id
				left join APCSProDB.trans.surpluses as sur on lot.id = sur.lot_id
				left join APCSProDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as den_pyo on lot.lot_no = den_pyo.LOT_NO_2
				where label_rec.lot_no = @lotno
				and label_rec.type_of_label in (5,21)
				--order by label_rec.type_of_label desc  --close : 2024/05/02 time : 11.32 by Aomsin
				order by SUBSTRING(label_rec.qrcode_detail,26,13)  asc --open : 2024/05/02 time : 11.32 by Aomsin
			END
			ELSE
			BEGIN
				INSERT INTO APCSProDB.trans.mli02_lsi(
			   [NYKP]
			  ,[MSGS]
			  ,[BSIJD]
			  ,[SHGM]
			  ,[KEIJ]
			  ,[SOFS]
			  ,[HKNK]
			  ,[LOCT]
			  ,[TOKI]
			  ,[TOKI2]
			  ,[KGSS]
			  ,[KGBS]
			  ,[HASM]
			  ,[SMGS]
			  ,[TKEM]
			  ,[NKYS]
			  ,[TMSS]
			  ,[SZON]
			  ,[LOTN]
			  ,[INVN]
			  ,[NYKD]
			  ,[NYID]
			  ,[BRKC]
			  ,[FG01]
			  ,[FG02]
			  ,[FG03]
			  ,[FG04]
			  ,[FG05]
			  ,[TR_FLG]
			  )
			select 
				SUBSTRING(label_rec.qrcode_detail,26,13) 
				,'001' 
				,CONVERT(varchar,GETDATE(),112)  
				,'10' 
				,'' 
				,case when @lot_type = 'D' then sur.pdcd else den_pyo.PROCESS_POST_CODE end
				,'' 
				,'' 
				--,cps_lice.LINNO --close data 2021/12/24 time : 09.12
				,case when pk.cps_license_no is null then '' else pk.cps_license_no end --add value date : 2021/12/24 time : 09.12
				,pk.short_name 
				,'0' 
				,'0' 
				,'' 
				,'' 
				,dn.name 
				,dn.pcs_per_pack 
				,'1' 
				,case when @lot_type = 'D' then 'NO'
				else den_pyo.ORDER_NO end 
				,label_rec.lot_no 
				,SUBSTRING(label_rec.lot_no,1,7) 
				,CONVERT(varchar,GETDATE(),112) 
				,'' 
				,'RIS01' 
				,'0' 
				,'0' 
				,'0' 
				,'0' 
				,case when sur.pdcd = 'QI001' then '1' else '2' end 
				,'0' 
				from APCSProDB.trans.label_issue_records as label_rec
				inner join APCSProDB.trans.lots as lot on label_rec.lot_no = lot.lot_no
				inner join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
				inner join APCSProDB.method.packages as pk on lot.act_package_id = pk.id
				left join APCSProDB.trans.surpluses as sur on lot.id = sur.lot_id
				left join APCSProDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as den_pyo on lot.lot_no = den_pyo.LOT_NO_2
				--left join StoredProcedureDB.dbo.IS_CPS_LICENSE as cps_lice on pk.short_name = cps_lice.TYPEX4
				where label_rec.lot_no = @lotno
				and label_rec.type_of_label = 5
				order by SUBSTRING(label_rec.qrcode_detail,26,13)  asc
			END
			
		END
		
	END TRY
	BEGIN CATCH 
		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
			([record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [command_text]
			, [lot_no])
		SELECT GETDATE()
			, '4'
			, ORIGINAL_LOGIN()
			, 'StoredProcedureDB'
			, 'TGSYSTEM(insertis)'
			, 'EXEC [dbo].[sp_set_data_cps] @lotno = ''' + @lotno + ''' ERROR INSERT [APCSPRO].[tran].[MLI02_LSI]'
			, @lotno
	END CATCH
END