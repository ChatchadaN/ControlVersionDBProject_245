-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_set_register_carrier]
	-- Add the parameters for the stored procedure here
	--@status 1 = load ,2 = unload
	@lot_no varchar(10),@carrier_no varchar(11),@status int,@mcno varchar(20)
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	DECLARE @is_update bit,@is_start_step bit
	-- interfering with SELECT statements.
		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
      , [record_class]
      , [login_name]
      , [hostname]
      , [appname]
      , [command_text])
	SELECT GETDATE()
		,'4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
		,ORIGINAL_LOGIN()
		,@mcno
		,APP_NAME()
		,'EXEC [cellcon].[sp_set_register_carrier] @lot_no =''' + @lot_no + '''' + ' @carrier_no =''' + @carrier_no + '''' + ' @status =''' + Convert(varchar(5) ,@status)  + '''' + ' @mcno =''' + @mcno + ''''
	
    -- Insert statements for procedure here
	--case ISNULL(next_carrier_no,'') is null or empty
	SET @is_start_step ='0';
	SET @is_update = '0';
	SELECT @is_start_step = CASE WHEN start_step_no = step_no THEN '1' ELSE '0' END   FROM APCSProDB.trans.lots WHERE lot_no = @lot_no
	IF (@is_start_step = '1')
	BEGIN 
		UPDATE APCSProDB.trans.lots set carrier_no = @carrier_no where lot_no = @lot_no AND ISNULL(carrier_no,'') = ''
	 if	(@@ROWCOUNT > 0)
	 BEGIN	
		SELECT @IS_UPDATE = '1'
	 END

	END 
	ELSE 
	BEGIN 
		if @mcno like '%FT%' OR @mcno like '%TP%'OR @mcno like '%MAP%'
		begin
			if (@status = 1) 
			begin
				--SELECT carrier_no,next_carrier_no,case ISNULL(carrier_no,'') when '' then '0' else '1' end from APCSProDB.trans.lots where lot_no = '1951A5080V'			
				SELECT @is_update = case ISNULL(carrier_no,'') when '' then 1 when '-' then 1 else 0 end from APCSProDB.trans.lots where lot_no = @lot_no	
				if (@is_update = 1)
				begin
					update APCSProDB.trans.lots set carrier_no = @carrier_no where lot_no = @lot_no
				end			
			end
			else if (@status = 2)
			begin
				SELECT @is_update = case ISNULL(next_carrier_no,'') when '' then 1 when '-' then 1  else 0 end from APCSProDB.trans.lots where lot_no = @lot_no	
				if (@is_update = 1)
				begin
					update APCSProDB.trans.lots set next_carrier_no = @carrier_no where lot_no = @lot_no
				end		
			end
		end
	END
	select @status as status_carrier,@is_update as is_update
	
	--	--case ISNULL(next_carrier_no,'') is null or empty
	--SET @is_update = '0';
	--if @mcno like '%FT%' OR @mcno like '%TP%'OR @mcno like '%MAP%'
	--begin
	--	if (@status = 1)
	--	begin
	--		--SELECT carrier_no,next_carrier_no,case ISNULL(carrier_no,'') when '' then '0' else '1' end from APCSProDB.trans.lots where lot_no = '1951A5080V'			
	--		SELECT @is_update = case ISNULL(carrier_no,'') when '' then 1 when '-' then 1 else 0 end from APCSProDB.trans.lots where lot_no = @lot_no	
	--		if (@is_update = 1)
	--		begin
	--			update APCSProDB.trans.lots set carrier_no = @carrier_no where lot_no = @lot_no
	--		end			
	--	end
	--	else if (@status = 2)
	--	begin
	--		SELECT @is_update = case ISNULL(next_carrier_no,'') when '' then 1 when '-' then 1  else 0 end from APCSProDB.trans.lots where lot_no = @lot_no	
	--		if (@is_update = 1)
	--		begin
	--			update APCSProDB.trans.lots set next_carrier_no = @carrier_no where lot_no = @lot_no
	--		end		
	--	end
	--end
	
	--select @status as status_carrier,@is_update as is_update
END
