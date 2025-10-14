-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [dbo].[tg_sp_update_data_for_lot_resurpluses_and_rework] 
	-- Add the parameters for the stored procedure here
	 @lotno_member varchar(10) = ''
	,@newlot varchar(10) = '' 
	,@count_reel_rollback int = 0
	,@status int = 0 --1 = for re-surpluses, 2 = for cancel
AS
BEGIN

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
	 	,'4'
	 	,ORIGINAL_LOGIN()
	 	,HOST_NAME()
	 	,APP_NAME()
	 	,'EXEC [dbo].[tg_sp_update_data_for_lot_resurpluses_and_rework_call_store] @lotno = ''' + isnull(@lotno_member,'') + ''''
	 	,@lotno_member

	SET NOCOUNT ON; 
	DECLARE @qty_out_lot_member int = 0 
	DECLARE @qty_pass_new_lot int = 0
	DECLARE @pcs_per_pack int = 0
	DECLARE @lot_id_val int = null
	DECLARE @member_lot_id_val int = null
	DECLARE @production_category_val tinyint = null

	IF @status = 1 --(Re-Surpluses and Rework)
	BEGIN
		IF @lotno_member <> ''
		BEGIN
			select @qty_out_lot_member = qty_out
			from APCSProDB.trans.lots where lot_no = @lotno_member
			
			select @qty_pass_new_lot = qty_pass
			from APCSProDB.trans.lots where lot_no = @newlot
			
			--UPDATE TABLE LSI_SHIP_IF of DATA INTERFACE
			UPDATE [APCSProDWH].[dbo].[LSI_SHIP_IF]
			SET Shipment_QTY = @qty_out_lot_member
			,Good_Product_QTY = IIF(@qty_out_lot_member = 0,0,(Good_Product_QTY - @qty_pass_new_lot))  --add condition check qty_out is zero #update date : 2023/09/15 time : 09.47 by aomsin แก้ไขเรื่องจำนวนงานติดลบ #
			where LotNo = @lotno_member

			--UPDATE TABLE WH_UKEBA_IF of DATA INTERFACE
			UPDATE [APCSProDWH].[dbo].[WH_UKEBA_IF]
			SET QTY = IIF(@qty_out_lot_member = 0,0,(QTY - @qty_pass_new_lot))  --add condition check qty_out is zero #update date : 2023/09/15 time : 09.47 by aomsin แก้ไขเรื่องจำนวนงานติดลบ #
			where LotNo = @lotno_member

			--UPDATE TABLE H_STOCK_IF of DATA INTERFACE
			UPDATE [APCSProDWH].[dbo].[H_STOCK_IF]
			SET DMY_OUT_Flag = '1'  --Fix data is 1
			where LotNo = @lotno_member

			SELECT 'TRUE' AS Status ,'Update Success !!' AS Error_Message_ENG
			RETURN
		END
		ELSE
		BEGIN
			INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
			(
				 [record_at]
				,[record_class]
				,[login_name]
				,[hostname]
				,[appname]
				,[command_text]
				,[lot_no]
			)
				SELECT GETDATE()
				,'4'
				,ORIGINAL_LOGIN()
				,HOST_NAME()
				,APP_NAME()
				,'EXEC [dbo].[tg_sp_update_data_for_Is no update data interface for re-surplsues and rework (lot_member is null)] @lotno = ''' + isnull(@lotno_member,'') + ''''
	 			,@lotno_member

			SELECT 'FALSE' AS Status ,'Update Error !!' AS Error_Message_ENG
			RETURN
		END
	END
	ELSE IF @status = 2  --(Cancel lot Re-Surpluses and Rework)
	BEGIN
		BEGIN TRY
			select @lot_id_val = id 
			,@qty_pass_new_lot = qty_pass
			,@production_category_val = production_category
			from APCSProDB.trans.lots where lot_no = @newlot
			
			IF (@production_category_val = 21 or @production_category_val = 22 or @production_category_val = 23)
			BEGIN
				--GET DATA LOT_MEMBER_ID
				select @member_lot_id_val = member_lot_id from APCSProDB.trans.lot_combine where lot_id = @lot_id_val

				--GET DETIAL OF LOT_MEMBER_ID
				select @lotno_member = Trim(lots.lot_no)
				,@qty_out_lot_member = lots.qty_out
				,@pcs_per_pack = dn.pcs_per_pack
				from APCSProDB.trans.lots 
				inner join APCSProDB.method.device_names as dn on lots.act_device_name_id = dn.id
				where lots.id = @member_lot_id_val

				IF @lotno_member <> ''
				BEGIN
					--UPDATE TABLE LSI_SHIP_IF of DATA INTERFACE
					UPDATE [APCSProDWH].[dbo].[LSI_SHIP_IF]
					SET Shipment_QTY = (@pcs_per_pack) * ((Good_Product_QTY + @qty_pass_new_lot)/(@pcs_per_pack))  
					,Good_Product_QTY = (Good_Product_QTY + @qty_pass_new_lot)
					where LotNo = @lotno_member

					--UPDATE TABLE WH_UKEBA_IF of DATA INTERFACE
					UPDATE [APCSProDWH].[dbo].[WH_UKEBA_IF]
					SET QTY = (QTY + @qty_pass_new_lot)
					where LotNo = @lotno_member

					SELECT 'TRUE' AS Status ,'Update Success !!' AS Error_Message_ENG
					RETURN
				END
				ELSE
				BEGIN
					INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
					(
						 [record_at]
						,[record_class]
						,[login_name]
						,[hostname]
						,[appname]
						,[command_text]
						,[lot_no]
					)
						SELECT GETDATE()
						,'4'
						,ORIGINAL_LOGIN()
						,HOST_NAME()
						,APP_NAME()
						,'EXEC [dbo].[tg_sp_update_data_for_Is no update data interface for cancel lot (lot member is null)] @lotno = ''' + isnull(@lotno_member,'') + ''''
	 					,@lotno_member

					SELECT 'FALSE' AS Status ,'Update Error !!' AS Error_Message_ENG
					RETURN
				END
			END
			ELSE
			BEGIN
				INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
				(
					 [record_at]
					,[record_class]
					,[login_name]
					,[hostname]
					,[appname]
					,[command_text]
					,[lot_no]
				)
					SELECT GETDATE()
					,'4'
					,ORIGINAL_LOGIN()
					,HOST_NAME()
					,APP_NAME()
					,'EXEC [dbo].[tg_sp_update_data_for_Is no update data interface for cancel lot (be not lot re-surpluses or rework)] @lotno = ''' + isnull(@lotno_member,'') + ''''
	 				,@lotno_member

				SELECT 'FALSE' AS Status ,'Update Error !!' AS Error_Message_ENG
				RETURN
			END
		END TRY
		BEGIN CATCH 
			INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
			(
				 [record_at]
				,[record_class]
				,[login_name]
				,[hostname]
				,[appname]
				,[command_text]
				,[lot_no]
			)
				SELECT GETDATE()
				,'4'
				,ORIGINAL_LOGIN()
				,HOST_NAME()
				,APP_NAME()
				,'EXEC [dbo].[tg_sp_update_data_for_Is no update data interface for cancel lot (lot_member is null)] @lotno = ''' + isnull(@lotno_member,'') + ''''
	 			,@lotno_member

			SELECT 'FALSE' AS Status ,'Update Error !!' AS Error_Message_ENG
			RETURN
		END CATCH
	END
END
