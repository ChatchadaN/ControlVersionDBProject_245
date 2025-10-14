-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,Update Call Table Interface to Is Server 2023/02/02 time : 11.24 ,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [tg].[sp_get_check_qr_hasuuu_test]
	-- Add the parameters for the stored procedure here
	  @lot_no varchar(10)
	, @qrcode_detail varchar(90)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	insert into [StoredProcedureDB].[dbo].[exec_sp_history]
	(
		[record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no]
	)
	select getdate()
		, '4'
		, original_login()
		, host_name()
		, app_name()
		, 'exec start [tg].[sp_get_check_qr_hasuuu] @lot_no = ''' + isnull(cast(@lot_no as varchar),'NULL') 
			+ ''', @qrcode_detail = ' + isnull(cast(@qrcode_detail as varchar),'NULL')  + '' 
		, isnull(cast(@lot_no as varchar),'NULL');

	--declare @lot_no varchar(10) = '2320A3448V'
	--declare @qrcode_detail char(90) = 'BU4826F-TR         0021302320A3448V007                                                    '

	------------------------------------------------------------------
	-- สร้างตัวแปร
	------------------------------------------------------------------
	declare @qr_lot_no varchar(10)
		, @qr_version varchar(1) 
		, @qr_qty varchar(6)
		, @qr_reel varchar(2)
		, @db_version varchar(1) 
		, @db_qty varchar(6)
		, @db_reel varchar(2)

	------------------------------------------------------------------
	-- อ่าน QR ใส่ตัวแปร
	------------------------------------------------------------------
	set @qr_lot_no = substring(@qrcode_detail,26,10)
	set @qr_version = substring(@qrcode_detail,36,1)
	--set @qr_qty = substring(@qrcode_detail,20,6) -- 2023-06-29
	set @qr_qty = ''
	--set @qr_reel = substring(@qrcode_detail,37,2) -- 2023-06-20
	set @qr_reel = ''

	------------------------------------------------------------------
	-- เช็ค QR
	------------------------------------------------------------------
	if (datalength(@qrcode_detail) != 90) 
	begin
		insert into [StoredProcedureDB].[dbo].[exec_sp_history]
		(
			[record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [command_text]
			, [lot_no]
		)
		select getdate()
			, '4'
			, original_login()
			, host_name()
			, app_name()
			, N'exec result [tg].[sp_get_check_qr_hasuuu] error: ไม่ได้สแกนคิวอาร์โค้ด' 
			, isnull(cast(@lot_no as varchar),'NULL');

		select 'FALSE' as Status 
			, 'please scan the QR code. !!' as Error_Message_ENG
			, N'กรุณาสแกน QRcode !!' as Error_Message_THA 
			, N'กรุณาติดต่อ System' as Handling
			, null as [version]
			, null as [qty]
			, null as [reel]
			, null as [from_qr]
			, null as [from_db]
		return
	end

	------------------------------------------------------------------
	-- เช็ค @qr_lot_no กับ @lot_no
	------------------------------------------------------------------
	if (@qr_lot_no != @lot_no)
	begin
		insert into [StoredProcedureDB].[dbo].[exec_sp_history]
		(
			[record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [command_text]
			, [lot_no]
		)
		select getdate()
			, '4'
			, original_login()
			, host_name()
			, app_name()
			, N'exec result [tg].[sp_get_check_qr_hasuuu] error: lot_no ไม่ตรงกับ label' 
			, isnull(cast(@lot_no as varchar),'NULL');

		select 'FALSE' as Status 
			, 'lot_no do not match label. !!' as Error_Message_ENG
			, N'lot_no ไม่ตรงกับ label !!' as Error_Message_THA 
			, N' กรุณาติดต่อ System' as Handling
			, null as [version]
			, null as [qty]
			, null as [reel]
			, null as [from_qr]
			, null as [from_db]
		return
	end

	------------------------------------------------------------------
	-- เช็คข้อมูลจากฐานข้อมูล
	------------------------------------------------------------------

	if exists (select 1 from APCSProDB.trans.label_issue_records where lot_no = @qr_lot_no and type_of_label = 2)
	begin
		select @db_version = substring(qrcode_detail,36,1)
			--, @db_qty = substring(qrcode_detail,20,6)  -- 2023-06-29
			, @db_qty =  ''
			--, @db_reel = substring(qrcode_detail,37,2)  -- 2023-06-20
			, @db_reel = ''
		from APCSProDB.trans.label_issue_records
		where lot_no = @lot_no
			and type_of_label = 2
		--select @db_qty,@db_version,@db_reel
	end
	else
	begin
		if exists (select 1 from APCSProDB.trans.surpluses where serial_no = @qr_lot_no)
		begin
			set @db_version = substring(@qrcode_detail,36,1)
			--set @db_qty = substring(@qrcode_detail,20,6)  -- 2023-06-29
			set @db_qty =  ''
			--set @db_reel = substring(@qrcode_detail,37,2)  -- 2023-06-20
			set @db_reel =  ''
		end
		else
		begin
			insert into [StoredProcedureDB].[dbo].[exec_sp_history]
			(
				[record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no]
			)
			select getdate()
				, '4'
				, original_login()
				, host_name()
				, app_name()
				, N'exec result [tg].[sp_get_check_qr_hasuuu] error: ไม่พบข้อมูลในฐานข้อมูล' 
				, isnull(cast(@lot_no as varchar),'NULL');

			select 'FALSE' as Status 
				, 'Data not found in database. !!' as Error_Message_ENG
				, N'ไม่พบข้อมูลในฐานข้อมูล !!' as Error_Message_THA 
				, N' กรุณาติดต่อ System' as Handling
				, null as [version]
				, null as [qty]
				, null as [reel]
				, null as [from_qr]
				, null as [from_db]
			return
		end
	end

	------------------------------------------------------------------
	-- เช็คข้อมูลว่าตรงกันไหม ?
	------------------------------------------------------------------
	if (@qr_reel = @db_reel AND @qr_version = @db_version AND @qr_qty = @db_qty)
	begin
		insert into [StoredProcedureDB].[dbo].[exec_sp_history]
		(
			[record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [command_text]
			, [lot_no]
		)
		select getdate()
			, '4'
			, original_login()
			, host_name()
			, app_name()
			, N'exec result [tg].[sp_get_check_qr_hasuuu] success: ข้อมูลถูกต้อง' 
			, isnull(cast(@lot_no as varchar),'NULL');

	    print 'TRUE --> The information is correct.'
		select 'TRUE' as Status 
			, 'The information is correct.' as Error_Message_ENG
			, N'ข้อมูลถูกต้อง' as Error_Message_THA 
			, N'' as Handling
			, @db_version as [version]
			, @db_qty as [qty]
			, @db_reel as [reel]
			, @qr_version + @qr_reel as [from_qr]
			, @db_version + @db_reel as [from_db]
		return
	end
	else
	begin
		if (@qr_reel != @db_reel AND @qr_version != @db_version AND @qr_qty != @db_qty) --reel,version,qty
		begin
			insert into [StoredProcedureDB].[dbo].[exec_sp_history]
			(
				[record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no]
			)
			select getdate()
				, '4'
				, original_login()
				, host_name()
				, app_name()
				, N'exec result [tg].[sp_get_check_qr_hasuuu] error: reel, version และ QTY ไม่ตรง' 
				, isnull(cast(@lot_no as varchar),'NULL');

			print 'FALSE --> @qr_reel != @db_reel AND @qr_version != @db_version AND @qr_qty != @db_qty'
			select 'FALSE' as Status 
				, 'reel ,version and QTY do not match. !!' as Error_Message_ENG
				, N'reel, version และ QTY ไม่ตรง !!' as Error_Message_THA 
				, N'กรุณาติดต่อ System' as Handling
				, @db_version as [version]
				, @db_qty as [qty]
				, @db_reel as [reel]
				, @qr_version + @qr_reel as [from_qr]
				, @db_version + @db_reel as [from_db]
			return
		end
		else if (@qr_reel != @db_reel AND @qr_version != @db_version AND @qr_qty = @db_qty) --reel,version
		begin
			insert into [StoredProcedureDB].[dbo].[exec_sp_history]
			(
				[record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no]
			)
			select getdate()
				, '4'
				, original_login()
				, host_name()
				, app_name()
				, N'exec result [tg].[sp_get_check_qr_hasuuu] error: reel และ version ไม่ตรง' 
				, isnull(cast(@lot_no as varchar),'NULL');

			print 'FALSE --> @qr_reel != @db_reel AND @qr_version != @db_version AND @qr_qty = @db_qty'
			select 'FALSE' as Status 
				, 'reel and label version do not match. !!' as Error_Message_ENG
				, N'reel และ version ไม่ตรง !!' as Error_Message_THA 
				, N'กรุณาติดต่อ System' as Handling
				, @db_version as [version]
				, @db_qty as [qty]
				, @db_reel as [reel]
				, @qr_version + @qr_reel as [from_qr]
				, @db_version + @db_reel as [from_db]
			return
		end
		else if (@qr_reel != @db_reel AND @qr_version = @db_version AND @qr_qty != @db_qty) --reel,qty
		begin
			insert into [StoredProcedureDB].[dbo].[exec_sp_history]
			(
				[record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no]
			)
			select getdate()
				, '4'
				, original_login()
				, host_name()
				, app_name()
				, N'exec result [tg].[sp_get_check_qr_hasuuu] error: reel และ QTY ไม่ตรง' 
				, isnull(cast(@lot_no as varchar),'NULL');

			print 'FALSE --> @qr_reel != @db_reel AND @qr_version = @db_version AND @qr_qty != @db_qty'
			select 'FALSE' as Status 
				, 'reel and QTY do not match. !!' as Error_Message_ENG
				, N'reel และ QTY ไม่ตรง !!' as Error_Message_THA 
				, N'กรุณาติดต่อ System' as Handling
				, @db_version as [version]
				, @db_qty as [qty]
				, @db_reel as [reel]
				, @qr_version + @qr_reel as [from_qr]
				, @db_version + @db_reel as [from_db]
			return
		end
		else if (@qr_reel = @db_reel AND @qr_version != @db_version AND @qr_qty != @db_qty) --version,qty
		begin
			insert into [StoredProcedureDB].[dbo].[exec_sp_history]
			(
				[record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no]
			)
			select getdate()
				, '4'
				, original_login()
				, host_name()
				, app_name()
				, N'exec result [tg].[sp_get_check_qr_hasuuu] error: version และ QTY ไม่ตรง' 
				, isnull(cast(@lot_no as varchar),'NULL');

			print 'FALSE --> @qr_reel = @db_reel AND @qr_version != @db_version AND @qr_qty != @db_qty'
			select 'FALSE' as Status 
				, 'label version and QTY do not match. !!' as Error_Message_ENG
				, N'label version และ QTY ไม่ตรง !!' as Error_Message_THA 
				, N'กรุณาติดต่อ System' as Handling
				, @db_version as [version]
				, @db_qty as [qty]
				, @db_reel as [reel]
				, @qr_version + @qr_reel as [from_qr]
				, @db_version + @db_reel as [from_db]
			return
		end
		else if (@qr_reel != @db_reel AND @qr_version = @db_version AND @qr_qty = @db_qty) --reel
		begin
			insert into [StoredProcedureDB].[dbo].[exec_sp_history]
			(
				[record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no]
			)
			select getdate()
				, '4'
				, original_login()
				, host_name()
				, app_name()
				, N'exec result [tg].[sp_get_check_qr_hasuuu] error: reel ไม่ตรง' 
				, isnull(cast(@lot_no as varchar),'NULL');

			print 'FALSE --> @qr_reel != @db_reel AND @qr_version = @db_version AND @qr_qty = @db_qty'
			select 'FALSE' as Status 
				, 'reel do not match. !!' as Error_Message_ENG
				, N'reel ไม่ตรง !!' as Error_Message_THA 
				, N'กรุณาติดต่อ System' as Handling
				, @db_version as [version]
				, @db_qty as [qty]
				, @db_reel as [reel]
				, @qr_version + @qr_reel as [from_qr]
				, @db_version + @db_reel as [from_db]
			return
		end
		else if (@qr_reel = @db_reel AND @qr_version != @db_version AND @qr_qty = @db_qty) --version 
		begin
			insert into [StoredProcedureDB].[dbo].[exec_sp_history]
			(
				[record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no]
			)
			select getdate()
				, '4'
				, original_login()
				, host_name()
				, app_name()
				, N'exec result [tg].[sp_get_check_qr_hasuuu] error: version ไม่ตรง' 
				, isnull(cast(@lot_no as varchar),'NULL');

			print 'FALSE --> @qr_reel = @db_reel AND @qr_version != @db_version AND @qr_qty = @db_qty'
			select 'FALSE' as Status 
				, 'label version do not match. !!' as Error_Message_ENG
				, N'label version ไม่ตรง !!' as Error_Message_THA 
				, N'กรุณาติดต่อ System' as Handling
				, @db_version as [version]
				, @db_qty as [qty]
				, @db_reel as [reel]
				, @qr_version + @qr_reel as [from_qr]
				, @db_version + @db_reel as [from_db]
			return
		end
		else if (@qr_reel = @db_reel AND @qr_version = @db_version AND @qr_qty != @db_qty) --qty
		begin
			insert into [StoredProcedureDB].[dbo].[exec_sp_history]
			(
				[record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no]
			)
			select getdate()
				, '4'
				, original_login()
				, host_name()
				, app_name()
				, N'exec result [tg].[sp_get_check_qr_hasuuu] error: QTY ไม่ตรง' 
				, isnull(cast(@lot_no as varchar),'NULL');

			print 'FALSE --> @qr_reel = @db_reel AND @qr_version = @db_version AND @qr_qty != @db_qty'
			select 'FALSE' as Status 
				, 'QTY do not match. !!' as Error_Message_ENG
				, N'QTY ไม่ตรง !!' as Error_Message_THA 
				, N'กรุณาติดต่อ System' as Handling
				, @db_version as [version]
				, @db_qty as [qty]
				, @db_reel as [reel]
				, @qr_version + @qr_reel as [from_qr]
				, @db_version + @db_reel as [from_db]
			return
		end
		else
		begin
			insert into [StoredProcedureDB].[dbo].[exec_sp_history]
			(
				[record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no]
			)
			select getdate()
				, '4'
				, original_login()
				, host_name()
				, app_name()
				, N'exec result [tg].[sp_get_check_qr_hasuuu] error: ไม่เข้าเงื่อนไข' 
				, isnull(cast(@lot_no as varchar),'NULL');

			print 'FALSE --> else'
			select 'FALSE' as Status 
				, 'condition not match. !!' as Error_Message_ENG
				, N'ไม่เข้าเงื่อนไข !!' as Error_Message_THA 
				, N'กรุณาติดต่อ System' as Handling
				, @db_version as [version]
				, @db_qty as [qty]
				, @db_reel as [reel]
				, @qr_version + @qr_reel as [from_qr]
				, @db_version + @db_reel as [from_db]
			return
		end
	end
END
