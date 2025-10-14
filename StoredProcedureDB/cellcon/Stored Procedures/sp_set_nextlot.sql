-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_set_nextlot] 
	-- Add the parameters for the stored procedure here
	@mc_name varchar(30),
	@lot_no varchar(10),
	@program_name varchar(MAX) ='%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @mc_id int = (SELECT TOP 1 mc.id FROM APCSProDB.mc.machines as mc WHERE mc.name = @mc_name) 
	DECLARE @nextlot_id int = (SELECT TOP 1 next_lot_id FROM APCSProDB.trans.machine_states WHERE machine_id = @mc_id)
	DECLARE @lot_id int = (SELECT TOP 1 id FROM APCSProDB.trans.lots WHERE lot_no = @lot_no)
	
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
      , [record_class]
      , [login_name]
      , [hostname]
      , [appname]
      , [command_text])
	SELECT GETDATE()
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [cellcon].[sp_set_nextlot] @lot_no = ''' + @lot_no + ''', @mc_name = ''' + @mc_name + ''', @program_name = ''' + @program_name + ''''

		--select @mc_id ,@nextlot_id,@lot_id as lotid

			IF (@nextlot_id is null)
				BEGIN
					UPDATE [APCSProDB].[trans].[machine_states]
					 SET [next_lot_id] = @lot_id
					 WHERE machine_id = @mc_id
				END
			ELSE -- next lot is not null
				BEGIN

					IF((SELECT process_state FROM APCSProDB.trans.lots WHERE id = @nextlot_id) in (0,100))
					BEGIN
						UPDATE [APCSProDB].[trans].[machine_states]
						SET [next_lot_id] = @lot_id
						WHERE machine_id = @mc_id
					END
					ELSE IF(@program_name = 'setupchecksheet' OR @program_name = 'special' OR @program_name = 'CellController')
					BEGIN
						UPDATE [APCSProDB].[trans].[machine_states]
						SET [next_lot_id] = @lot_id
						WHERE machine_id = @mc_id
					END
				END
END
