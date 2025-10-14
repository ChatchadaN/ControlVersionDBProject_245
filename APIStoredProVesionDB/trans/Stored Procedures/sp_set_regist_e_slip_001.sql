-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_regist_e_slip_001] 
	-- Add the parameters for the stored procedure here
	@lot_no AS VARCHAR(10),
	@lot_outsource AS VARCHAR(20) = NULL,
	@e_slip_id AS VARCHAR(20),
	@carrier_no AS VARCHAR(20) = NULL,
	@op_no AS VARCHAR(6),
	@mc_no AS VARCHAR(50),
	@app_name AS VARCHAR(255)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
	
	
	--SELECT @lot_no, @lot_outsource, @e_slip_id, @carrier_no, @op_no, @mc_no, @app_name


	IF (SELECT wip_state FROM APCSProDB.trans.lots WHERE e_slip_id = @e_slip_id) = 20 BEGIN
		SELECT 'FALSE' as Is_Pass,
			'This card has been used. !! ('+ TRIM(lots.lot_no) +')' AS Error_Message_ENG,
			N'Card นี้ถูกใช้งานอยู่ !! ('+ TRIM(lots.lot_no) +')' AS Error_Message_THA,
			N'กรุณาเปลี่ยน Card ใหม่ หรือ Clear Card ที่ระบบ ATOM !!' AS Handling 
		FROM APCSProDB.trans.lots WHERE e_slip_id = @e_slip_id
		RETURN 
	END
	ELSE BEGIN
		BEGIN TRY 
			--Clear card
			IF EXISTS (SELECT 1 FROM APCSProDB.trans.lots WHERE e_slip_id = @e_slip_id)
			BEGIN
				DECLARE @s_lot_no varchar(20) = (SELECT lot_no FROM APCSProDB.trans.lots WHERE e_slip_id = @e_slip_id);
				update APCSProDB.trans.lots 
					set carrier_no = NULL,
						e_slip_id = NULL,
						updated_at = GETDATE(),
						updated_by = (SELECT id FROM APCSProDB.man.users WHERE emp_num =  @op_no)
				where lot_no = @s_lot_no and e_slip_id = @e_slip_id
			END

			--update data
			update APCSProDB.trans.lots 
				set --carrier_no = @carrier_no,
					e_slip_id = @e_slip_id,
					external_lot_no = iif(production_category = 70,external_lot_no,@lot_outsource),
					updated_at = GETDATE(),
					updated_by = (SELECT id FROM APCSProDB.man.users WHERE emp_num =  @op_no)
			where lot_no = @lot_no

			--SELECT	 'TRUE' as Is_Pass
			--		, 'Update Successed. !!' AS Error_Message_ENG
			--		, N'อัพเดทข้อมูลเรียบร้อย !!' AS Error_Message_THA
			--		, N'อัพเดทข้อมูลเรียบร้อย !!' AS Handling 
			--		, [lots].[id] as LotId
			--		, TRIM([lots].[lot_no]) as LotNo
			--		, TRIM(lots.carrier_no)  AS Carrier
			--		, TRIM([packages].[name]) as Package 
			--		, TRIM([device_names].[assy_name]) as Device
			--		, TRIM([device_names].[tp_rank])   AS [tp_rank]					
			--		, CASE WHEN lots.is_special_flow =  1 THEN TRIM(jobspecial.name) ELSE TRIM(jobmaster.name) END AS JobName
			--		, [lots].[qty_in] AS qty
			--		, (SELECT COUNT(lot_no)
			--			FROM OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144; User ID=ship;Password=ship;' ).[Half_Product].[dbo].[Half_Product_Order_List] hp
			--			INNER JOIN APCSProDB.trans.lots ON lots.lot_no = TRIM(hp.LotNo)
			--			WHERE  OutSourceLotNo = @lot_outsource  AND lots.e_slip_id IS NULL) AS lot_count
			--FROM [APCSProDB].[trans].[lots]  
			--	INNER JOIN [APCSProDB].[method].[device_names]  ON [lots].[act_device_name_id] = [device_names].[id]
			--	INNER JOIN [APCSProDB].[method].[packages]  ON [device_names].[package_id] = [packages].[id]
			--	LEFT JOIN APCSProDB.trans.special_flows  ON  lots.is_special_flow = 1 AND lots.special_flow_id = special_flows.id
			--	LEFT JOIN APCSProDB.trans.lot_special_flows ON special_flows.id  = lot_special_flows.special_flow_id AND special_flows.step_no = lot_special_flows.step_no
			--	INNER JOIN APCSProDB.method.jobs  AS jobmaster ON lots.act_job_id = jobmaster.id
			--	LEFT JOIN APCSProDB.method.jobs  AS jobspecial ON lot_special_flows.job_id = jobspecial.id
			--WHERE lot_no = @lot_no
			--ORDER BY [lots].[lot_no]

			----------------------------------------------------
			---- NEW 04/07/2022
			----------------------------------------------------
			SELECT 'TRUE' AS [Is_Pass]
				, 'Update Successed. !!' AS [Error_Message_ENG]
				, N'อัพเดทข้อมูลเรียบร้อย !!' AS [Error_Message_THA]
				, N'อัพเดทข้อมูลเรียบร้อย !!' AS [Handling]
				, [lots].[id] AS [LotId]
				, ISNULL(TRIM([lots].[lot_no]),'') AS [LotNo]
				, ISNULL(TRIM(lots.carrier_no),'')  AS [Carrier]
				, ISNULL(TRIM([packages].[name]),'') AS [Package]
				, ISNULL(TRIM([device_names].[name]),'') AS [Device]
				, ISNULL(TRIM([device_names].[tp_rank]),'')  AS [tp_rank]					
				, CASE WHEN [lots].[is_special_flow] =  1 THEN ISNULL(TRIM(jobspecial.name),'') ELSE ISNULL(TRIM(jobmaster.name),'') END AS [JobName]
				, [lots].[qty_in] AS [qty]
				, ISNULL([outsource_count].[lot_count],0) as [lot_count]
				, ISNULL([lots].[e_slip_id],'') AS [e_slip_id]
				, ISNULL([locations].[name],'') AS [rack_location]
				, [days].[date_value] as [shipment_date]
			FROM [APCSProDB].[trans].[lots]  
			INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
			INNER JOIN [APCSProDB].[method].[packages] ON [device_names].[package_id] = [packages].[id]
			LEFT JOIN APCSProDB.trans.special_flows ON [lots].[is_special_flow] = 1 
				AND [lots].[special_flow_id] = [special_flows].[id]
			LEFT JOIN APCSProDB.trans.lot_special_flows ON [special_flows].[id] = [lot_special_flows].[special_flow_id] 
				AND [special_flows].[step_no] = [lot_special_flows].[step_no]
			INNER JOIN APCSProDB.method.jobs AS [jobmaster] ON [lots].[act_job_id] = [jobmaster].[id]
			LEFT JOIN APCSProDB.method.jobs AS [jobspecial] ON [lot_special_flows].[job_id] = [jobspecial].[id]
			LEFT JOIN [APCSProDB].[trans].[locations] ON [lots].[location_id] = [locations].[id]
			LEFT JOIN [APCSProDB].[trans].[days] on [lots].[modify_out_plan_date_id] = [days].[id] 
			outer apply (
					select count([OutSourceLotNo]) as [lot_count] 
					from (
						select [LotNo],[OutSourceLotNo]
						from openrowset ('SQLNCLI', 'Server= 10.28.1.144;Database=Half_Product;Uid=ship;Pwd=ship', 
							'SELECT [LotNo],[OutSourceLotNo]
							FROM [Half_Product].[dbo].[Half_Product_Order_List]
							ORDER BY Qty DESC, LotNo ASC')
					) as [hp]
					inner join [APCSProDB].[trans].[lots] on [lots].[lot_no] = [hp].[LotNo]
					WHERE [hp].[OutSourceLotNo] = @lot_outsource
						and [lots].e_slip_id is null
					group by [OutSourceLotNo]
				) AS [outsource_count]
			WHERE [lots].lot_no = @lot_no
			ORDER BY [lots].[lot_no]
			----------------------------------------------------------------------------------------------
			RETURN 
		END TRY
		BEGIN CATCH
			SELECT 'FALSE' as Is_Pass,
				'Update Faild. !!' AS Error_Message_ENG,
				N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA,
				N'กรุณาติดต่อ System !!' AS Handling 
			RETURN 
		END CATCH
	END

END 
