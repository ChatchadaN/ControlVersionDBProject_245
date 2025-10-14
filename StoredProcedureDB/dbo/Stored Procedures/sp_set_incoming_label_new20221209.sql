-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_incoming_label_new20221209]
	-- Add the parameters for the stored procedure here
	@lotno VARCHAR(10)
	, @empNo CHAR(6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--Add Log Date : 2021/11/10 Time : 08.35
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	(
		[record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no]
	)
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [dbo].[sp_set_incoming_label_new20221209] @Lotno = ''' + @lotno + ''', @Empno = ''' + @empNo  + ''''
		, @lotno

	DECLARE @empno_id int = 0
	DECLARE @incom_id int = 0
	DECLARE @count_reel int = 0
	DECLARE @Reel_of_Carton int = 0
	DECLARE @qty_shipment int = 0

	--seach op_record_id
	select @empno_id = id from APCSProDB.man.users where emp_num = @empNo

	select @count_reel = (lots.qty_out / dn.pcs_per_pack) 
		, @qty_shipment = qty_out
	from APCSProDB.trans.lots 
	inner join APCSProDB.method.device_slips as ds on lots.device_slip_id = ds.device_slip_id --version มี matset id
	inner join APCSProDB.method.device_names as dn on lots.act_device_name_id = dn.id
	where lot_no = @lotno

	SELECT @Reel_of_Carton = MAX(ib.reel_count)
	FROM APCSProDB.trans.lots 
	INNER JOIN [APCSProDB].method.device_slips ds ON ds.device_slip_id = lots.device_slip_id
	INNER JOIN [APCSProDB].method.device_versions dv ON dv.device_id = ds.device_id 
		AND ds.is_released = 1
	INNER JOIN [APCSProDB].method.device_names dn ON dn.id = dv.device_name_id 
	INNER JOIN [APCSProDB].method.packages pk ON dn.package_id = pk.id 				   
	INNER JOIN [APCSProDB].method.device_flows df ON ds.device_slip_id = df.device_slip_id
	LEFT JOIN [APCSProDB].[method].[jobs] ON jobs.[id] = df.[job_id] AND df.job_id = 317 --///
	LEFT JOIN [APCSProDB].method.material_sets ms ON ms.id = df.material_set_id
	INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id 
	INNER JOIN [APCSProDB].material.productions p ON ml.material_group_id = p.id 
		AND p.details = 'TOMSON'--///
	LEFT JOIN [APCSProDB].method.incoming_boxs ib ON ib.tomson_code = ml.tomson_code
	WHERE lot_no = @lotno

	--Add New Condition Check reel_count is null ??  Create Date : 2022/11/24 Time : 16.40
	IF @Reel_of_Carton is null 
	BEGIN
		SELECT 'FALSE' AS Status 
			, 'Reel_count of Material is Null !!' AS Error_Message_ENG
			, N' Reel_count เป็นค่าว่าง กรุณาตรวจสอบข้อมูลการเซต Material ให้ครบด้วยคะ !!' AS Error_Message_THA 
			, N' กรุณาตรวจสอบข้อมูล Material' AS Handling;
		RETURN;
	END

	--Incoming master
	DECLARE @shipment_data char(6)  = ''
	DECLARE @product_family char(5) = ''
	DECLARE @package_name char(20) = ''
	DECLARE @destination char(15) = ''
	DECLARE @storage_division char(3) = ''
	DECLARE @location_no char(6) = ''
	DECLARE @arrival_packing_no char(13) = ''
	DECLARE @special_column char(15) = ''
	DECLARE @special_column2 char(15) = ''
	DECLARE @caton_qty smallint = 0
	DECLARE @total_of_box smallint = 0
	DECLARE @fraction char(2) = ''
	DECLARE @total_seq_no char(3) = ''
	DECLARE @invoice_no char(10) = ''
	DECLARE @product_code varchar(5) = ''
	DECLARE @created_by char(6) = ''
	DECLARE @updated_by char(6) = ''
	--Incoming Detail
	DECLARE @device_name char(19) = ''
	DECLARE @arrival_amount char(9) = '' --int
	DECLARE @reel_count_of_carton char(2) = '' --smallint
	DECLARE @order_no char(15) = ''
	--ใช้คำนวณสูตร
	DECLARE @full_reel_of_carton char(2) = '' --full reel จำนวนของ reel ที่เต็มกล่องที่ 1
	DECLARE @reel_at_exceeded int = 0  --reel hasuu เศษที่เหลือจากกล่องที่ 1
	DECLARE @pcs_per_pack int = 0

	select
		--Incoming Master
		 @shipment_data = CONVERT(varchar, GETDATE(), 12)
		,@product_family = '10' 
		,@package_name = pk.short_name
		,@destination = SPACE(15)
		,@storage_division = SPACE(3)
		,@location_no = SPACE(6)
		,@arrival_packing_no = TRIM(lots.lot_no) --ค่า I01 ใช้เลขวน for ใน sql temp
		,@special_column = SPACE(15)
		,@special_column2 =SPACE(15)
		,@caton_qty = 1 --fix
		,@total_of_box = 1 --fix
		,@fraction = SPACE(2)
		,@total_seq_no = SPACE(3)
		,@invoice_no = SUBSTRING(lots.lot_no,1,7) 
		,@product_code = sur.pdcd 
		,@created_by = @empno_id 
		,@updated_by = @empno_id 
		--Incoming Detail
		,@device_name = dn.name
		--add condition check work shipment all --> Date Modify : 2022/07/26 Time : 13.42
		,@arrival_amount = case when pc_instruction_code = 11 then (lots.qty_out + lots.qty_hasuu) else qty_out end
		,@reel_count_of_carton = case when pc_instruction_code = 13 then CAST('1' as char(2))
									  when pc_instruction_code = 11 then CAST ((lots.qty_out / dn.pcs_per_pack) + 1  as char(2))
									  else (lots.qty_out / dn.pcs_per_pack) end --Add Condition Support work PC Request date 2022/03/17 time : 14.29
		--Add Condition 2021/10/11 Time : 15.03
		,@order_no = case when denpyo.ORDER_NO = '' or denpyo.ORDER_NO is null then 'NO' else denpyo.ORDER_NO end
		,@pcs_per_pack = dn.pcs_per_pack
	from APCSProDB.trans.lots 
	inner join APCSProDB.method.packages as pk on lots.act_package_id = pk.id
	inner join APCSProDB.method.device_names as dn on lots.act_device_name_id = dn.id
	left join APCSProDB.trans.surpluses as sur on lots.lot_no = sur.serial_no
	left join APCSProDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as denpyo on lots.lot_no = denpyo.LOT_NO_1  -- Modify from APCSDB is APCSDBPro #2025/04/23 Time 16.42 by Aomsin
	where lot_no = @lotno
	
	--Add New Condition Check pc_code is null ??  Create Date : 2022/11/21 Time : 11.14
	IF @product_code is null or @product_code = ''
	BEGIN
		SELECT 'FALSE' AS Status 
			, 'PC Instruction Code is Null !!' AS Error_Message_ENG
			, N' PC Instruction Code เป็นค่าว่าง กรุณาติดต่อ System !!' AS Error_Message_THA 
			, N' กรุณาติดต่อ System' AS Handling;
		RETURN;
	END

	--create @tempIncomingMaster
	DECLARE @tempIncomingMaster TABLE(
	   [ship_date][char](6) NOT NULL
      ,[product_family][char](5) NOT NULL
      ,[package_name][char](20) NOT NULL
      ,[destination][char](15) NOT NULL
      ,[storage_division][char](3) NOT NULL
      ,[location_no][char](6) NOT NULL
      ,[arrival_packing_no][char](13) NOT NULL
      ,[special_column][char](15) NOT NULL
      ,[special_column2][char](15) NOT NULL
      ,[caton_qty][smallint] NOT NULL
      ,[total_of_box][smallint] NOT NULL
      ,[fraction][char](2) NOT NULL
      ,[total_seq_no][char](3) NOT NULL
      ,[invoice_no][char](10) NOT NULL
      ,[product_code][varchar](5) NULL
      ,[created_at][datetime] NULL
      ,[created_by][int] NULL
      ,[updated_at][datetime] NULL
	  ,[updated_by][int] NULL
	);

	---- Table Master 2
	--create @tempIncomingMaster2
	DECLARE @tempIncomingMaster2 TABLE (
	   [ship_date][char](6) NOT NULL
      ,[product_family][char](5) NOT NULL
      ,[package_name][char](20) NOT NULL
      ,[destination][char](15) NOT NULL
      ,[storage_division][char](3) NOT NULL
      ,[location_no][char](6) NOT NULL
      ,[arrival_packing_no][char](13) NOT NULL
      ,[special_column][char](15) NOT NULL
      ,[special_column2][char](15) NOT NULL
      ,[caton_qty][smallint] NOT NULL
      ,[total_of_box][smallint] NOT NULL
      ,[fraction][char](2) NOT NULL
      ,[total_seq_no][char](3) NOT NULL
      ,[invoice_no][char](10) NOT NULL
      ,[product_code][varchar](5) NULL
      ,[created_at][datetime] NULL
      ,[created_by][int] NULL
      ,[updated_at][datetime] NULL
	  ,[updated_by][int] NULL
	);

	DECLARE @sql varchar(max);
	DECLARE @i INT = 0;
	DECLARE @iii INT = 0;
	SET @i = 1;
	SET @iii = 1;
	
	IF @count_reel < @Reel_of_Carton or @count_reel = @Reel_of_Carton
	BEGIN
			INSERT INTO @tempIncomingMaster 
			(
				ship_date
				, product_family
				, package_name
				, destination
				, storage_division
				, location_no
				, arrival_packing_no
				, special_column
				, special_column2
				, caton_qty
				, total_of_box
				, fraction
				, total_seq_no
				, invoice_no
				, product_code
				, created_at
				, created_by
				, updated_at
				, updated_by
			)
			SELECT @shipment_data
				, @product_family
				, @package_name
				, @destination
				, @storage_division
				, @location_no
				, Trim(@arrival_packing_no) + 'I0' + CAST(@i as char(1))
				, @special_column
				, @special_column2
				, 1
				, 1
				, @fraction
				, @total_seq_no
				, @invoice_no
				, @product_code
				, convert(varchar(max),getdate(),121)
				, @created_by
				, convert(varchar(max),getdate(),121)
				, @updated_by;
	END
	ELSE IF @count_reel > @Reel_of_Carton
	BEGIN
		------------------- Incoming Master ----------------
		WHILE @iii <= 2
		BEGIN
			INSERT INTO @tempIncomingMaster2
			(
				ship_date
				, product_family
				, package_name
				, destination
				, storage_division
				, location_no
				, arrival_packing_no
				, special_column
				, special_column2
				, caton_qty
				, total_of_box
				, fraction
				, total_seq_no
				, invoice_no
				, product_code
				, created_at
				, created_by
				, updated_at
				, updated_by
			)
			SELECT @shipment_data
				, @product_family
				, @package_name
				, @destination
				, @storage_division
				, @location_no 
				, Trim(@arrival_packing_no) + 'I0' + CAST(@iii as char(1))
				, @special_column
				, @special_column2
				, 1
				, 1
				, @fraction
				, @total_seq_no
				, @invoice_no
				, @product_code
				, convert(varchar(max),getdate(),121)
				, @created_by
				, convert(varchar(max),getdate(),121)
				, @updated_by;

			SET @iii = @iii + 1;

		END;
		PRINT 'Done FOR LOOP';
	END
	
	BEGIN TRANSACTION;
	BEGIN TRY
		IF @count_reel < @Reel_of_Carton or @count_reel = @Reel_of_Carton
		BEGIN
			------------------- Incoming Master 2 ----------------
			INSERT INTO APCSProDB.trans.incoming_labels
			(
			   [ship_date]
			  , [product_family]
			  , [package_name]
			  , [destination]
			  , [storage_division]
			  , [location_no]
			  , [arrival_packing_no]
			  , [special_column]
			  , [special_column2]
			  , [caton_qty]
			  , [total_of_box]
			  , [fraction]
			  , [total_seq_no]
			  , [invoice_no]
			  , [product_code]
			  , [created_at]
			  , [created_by]
			  , [updated_at]
			  , [updated_by]
			)
			SELECT ship_date
			   , product_family
			   , package_name
			   , destination
			   , storage_division
			   , location_no
			   , arrival_packing_no
			   , special_column
			   , special_column2
			   , caton_qty
			   , total_of_box
			   , fraction
			   , total_seq_no
			   , invoice_no
			   , product_code
			   , created_at
			   , created_by
			   , updated_at
			   , updated_by
			from @tempIncomingMaster;

			select top(1) @incom_id = id from APCSProDB.trans.incoming_labels where SUBSTRING(arrival_packing_no,1,10) = @lotno;
			------------------- Insert data to Incoming Detail ----------------
			IF @incom_id != 0
			BEGIN
				------------------- Incoming Detail ----------------
				INSERT INTO [APCSProDB].[trans].[incoming_label_details]
				(
				   [incoming_id]
				  , [line_no]
				  , [device_name]
				  , [arrival_amount]
				  , [reel_count]
				  , [order_no]
				  , [lot_no]
				  , [created_at]
				  , [created_by]
				  , [updated_at]
				  , [updated_by]
				)
				SELECT id
					, 1
					, @device_name
					, @arrival_amount
					, @reel_count_of_carton
					, @order_no
					, @lotno
					, convert(varchar(max),getdate(),121)
					, @created_by
					, convert(varchar(max),getdate(),121)
					, @updated_by
				from APCSProDB.trans.incoming_labels 
				where SUBSTRING(arrival_packing_no,1,10) = @lotno
				order by id ASC;
			END
		END
		ELSE IF @count_reel > @Reel_of_Carton
		BEGIN
			------------------- Incoming Master 2 ----------------
			INSERT INTO APCSProDB.trans.incoming_labels
			(
			   [ship_date]
			  , [product_family]
			  , [package_name]
			  , [destination]
			  , [storage_division]
			  , [location_no]
			  , [arrival_packing_no]
			  , [special_column]
			  , [special_column2]
			  , [caton_qty]
			  , [total_of_box]
			  , [fraction]
			  , [total_seq_no]
			  , [invoice_no]
			  , [product_code]
			  , [created_at]
			  , [created_by]
			  , [updated_at]
			  , [updated_by]
			)
			SELECT ship_date
			   , product_family
			   , package_name
			   , destination
			   , storage_division
			   , location_no
			   , arrival_packing_no
			   , special_column
			   , special_column2
			   , caton_qty
			   , total_of_box
			   , fraction
			   , total_seq_no
			   , invoice_no
			   , product_code
			   , created_at
			   , created_by
			   , updated_at
			   , updated_by
			FROM @tempIncomingMaster2;

		   SELECT top(1) @incom_id = id FROM APCSProDB.trans.incoming_labels WHERE SUBSTRING(arrival_packing_no,1,10) = @lotno;
		   --select @incom_id
			------------------- Insert data to Incoming Detail ----------------
			IF @incom_id != 0
			BEGIN
				------------------- Incoming Detail ----------------
				INSERT INTO [APCSProDB].[trans].[incoming_label_details]
				(
				   [incoming_id]
				  , [line_no]
				  , [device_name]
				  , [arrival_amount]
				  , [reel_count]
				  , [order_no]
				  , [lot_no]
				  , [created_at]
				  , [created_by]
				  , [updated_at]
				  , [updated_by]
				)
				select id
					, 1
					, @device_name
					, case when ROW_NUMBER() OVER (ORDER BY id) = 1 then CAST((@pcs_per_pack) * ((@count_reel - (@count_reel - @Reel_of_Carton))) AS char(9)) 
				 		  when ROW_NUMBER() OVER (ORDER BY id) > 1 then CAST((@pcs_per_pack) * (@count_reel - @Reel_of_Carton) AS char(9)) else '' end 
					, case when ROW_NUMBER() OVER (ORDER BY id) = 1 then CAST((@count_reel - (@count_reel - @Reel_of_Carton)) as char(2))
				 		  when ROW_NUMBER() OVER (ORDER BY id) > 1 then CAST((@count_reel - @Reel_of_Carton) as char(2)) else '' end 
					, @order_no
					, @lotno
					, convert(varchar(max),getdate(),121)
					, @created_by
					, convert(varchar(max),getdate(),121)
					, @updated_by
				from APCSProDB.trans.incoming_labels 
				where SUBSTRING(arrival_packing_no,1,10) = @lotno
				order by id ASC;
			END
		END
		COMMIT;
	END TRY
	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Status 
			, ERROR_MESSAGE() AS Error_Message_ENG
			, N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA 
			, N'กรุณาติดต่อ System' AS Handling;
		RETURN;
	END CATCH;

	--PASS = SEND TRUE -->Date Modify : 2022/12/01 Time: 15.36
	SELECT 'TRUE' AS Status 
		, '' AS Error_Message_ENG
		, N'' AS Error_Message_THA 
		, N'' AS Handling;
	RETURN;	
END
