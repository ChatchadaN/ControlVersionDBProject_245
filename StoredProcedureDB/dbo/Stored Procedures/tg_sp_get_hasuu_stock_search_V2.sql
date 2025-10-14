-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_hasuu_stock_search_V2]
	-- Add the parameters for the stored procedure here
	 @lotno varchar(17) = ''
	,@ProcessName varchar(10) = ''  --TP,FLFTTP,MAP and Blank
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Package_Name char(20) = ''
	DECLARE @Instock int = 0
	DECLARE @Production_Category tinyint = 0
	DECLARE @get_lot_by_eslno varchar(10) = ''
    -- Insert statements for procedure here
	-- Search Hasuu Stock is APCS Pro

	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		([record_at]
		  , [record_class]
		  , [login_name]
		  , [hostname]
		  , [appname]
		  , [command_text]
		  , [lot_no])
		SELECT GETDATE()
			,'4'
			,ORIGINAL_LOGIN()
			,HOST_NAME()
			,APP_NAME()
			,'EXEC [dbo].[tg_sp_get_hasuu_stock_search_V2 --> Get Data] @lotno = ''' + @lotno + ''''
			,@lotno

	--Add condition 2025/02/10 time : 14.56 by Aomsin
	IF EXISTS (SELECT 1 FROM APCSProDB.trans.lots WHERE e_slip_id = @lotno)
	BEGIN
		SELECT @get_lot_by_eslno = lot_no FROM APCSProDB.trans.lots WHERE e_slip_id = @lotno
		SET @lotno = @get_lot_by_eslno
	END

	SELECT @lotno = TRIM(@lotno)

	SELECT @Package_Name = pk.name
		,@Instock = sur.in_stock
		,@Production_Category = lot.production_category
	FROM APCSProDB.trans.surpluses as sur
	inner join APCSProDB.trans.lots as lot on sur.lot_id = lot.id
	inner join APCSProDB.method.packages as pk on lot.act_package_id = pk.id
	where serial_no = @lotno

	--process name is blank = web , process name is nort blank = cellcon
	IF @ProcessName = 'TP' or @ProcessName = 'MAP'  --add condition 2023/04/18 time : 13.01
	BEGIN
		IF @lotno != ''  --add condition date : 2022/05/21 time : 09.03
		BEGIN
			IF @Instock = 2
			BEGIN
				SELECT 
					 serial_no as LotNo
					,pcs as HASU_Stock_QTY
					,'TRUE' AS Status 
					,'Hasuu is a wip !!' AS Error_Message_ENG
					, N'Hasuu lot นี้ สามารถใช้งานได้ !!' AS Error_Message_THA 
					, N'กรุณาติดต่อ System' AS Handling
				FROM APCSProDB.trans.surpluses as sur
				left join APCSProDB.trans.lots as lot on sur.lot_id = lot.id 
				left join APCSProDB.method.packages as pk on lot.act_package_id = pk.id
				left join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
				where sur.serial_no = @lotno
			END
			ELSE
			BEGIN
				SELECT 
				 '' as LotNo
				,0 as HASU_Stock_QTY
				,'FALSE' AS Status 
				,'Hasuu is not a wip !!' AS Error_Message_ENG
				,N'Hasuu lot นี้ไม่สามารถใช้งานได้ เนื่องจาก Hasuu ไม่ใช่ Wip !!' AS Error_Message_THA 
				,N' กรุณาติดต่อ System' AS Handling
				RETURN
			END
			
		END
	END
	ELSE IF @ProcessName = ''
	BEGIN
		IF @lotno != ''  --add condition date : 2022/05/21 time : 09.03
		BEGIN
			select 
				 lot_id --add value 2022/06/29  time : 18.14
				,serial_no as LotNo
				,pcs as HASU_Stock_QTY
				,sur.updated_at as Timestamp_Date
				,pk.name as package_name
				,dn.name as device_name
				,dn.pcs_per_pack as standard_qty
				,dn.tp_rank 
				,case when @Production_Category = 70 then IIF(sur.pcs = 0,0,sur.in_stock)  --add condition for recall work support by aomsin #2023/10/30 time : 15.45
					  else sur.in_stock end as in_stock
				,case when dn.rank is null then '' else dn.rank end  as rank_value
				--,lot.qty_pass as qty_good  --close 2024/03/26  time : 09.29
				,(lot.qty_pass + qty_combined) as qty_good  --update 2024/03/26 edit for support map process time : 09.29 by aomsin
				,sur.transfer_pcs   --add value 2023/04/04  time : 10.37
				,sur.is_ability
				,lot.pc_instruction_code  --add value 2023/11/24  time : 13.25 by Aomsin
				,lot.qty_out as qty_shipment  --add value 2024/06/19  time : 14.26 by Aomsin
				,lot.production_category  --add value 2024/06/19  time : 14.26 by Aomsin
			from APCSProDB.trans.surpluses as sur
			left join APCSProDB.trans.lots as lot on sur.lot_id = lot.id 
			left join APCSProDB.method.packages as pk on lot.act_package_id = pk.id
			left join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
			where sur.serial_no = @lotno
		END
	END
END
