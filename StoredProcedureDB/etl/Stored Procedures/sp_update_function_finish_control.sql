

CREATE PROCEDURE [etl].[sp_update_function_finish_control] (@function_name_ NVARCHAR(128) 
														,@to_fact_table_ varchar(50) 
                                                       ,@finished_at_ DATETIME
													   ,@errnum  INT output
													   ,@errline INT output
													   ,@errmsg nvarchar(max) output
													   ) AS
BEGIN

    ---------------------------------------------------------------------------
	--(1)-- check argument
    ---------------------------------------------------------------------------
	BEGIN
		IF RTRIM(@function_name_) = ''
			RETURN 1;
	END;

    ---------------------------------------------------------------------------
	--(2)-- declare
    ---------------------------------------------------------------------------
	DECLARE @update_flg INT = 0;
	DECLARE @dwh_count INT = 0;
	DECLARE @finished_day_id INT = 0;
	DECLARE @finished_hour_code TINYINT = 0;
	DECLARE @sql nvarchar(max) = N'';


	SELECT @dwh_count = COUNT(*) 
	FROM [APCSProDWH].[dwh].[function_finish_control] AS dwh_ffc 
	WHERE RTRIM(dwh_ffc.function_name) = RTRIM(@function_name_);

	SELECT @finished_day_id = id 
	FROM [APCSProDWH].[dwh].[dim_days] 
	WHERE date_value = (SELECT CONVERT(date, @finished_at_) AS date_value);

	SELECT @finished_hour_code = code 
	FROM [APCSProDWH].[dwh].[dim_hours] 
	WHERE h = (SELECT DATEPART(hour, @finished_at_) AS h);

	/*
    ---------------------------------------------------------------------------
	--(3)select function_finish_control
    ---------------------------------------------------------------------------
	--SELECT @dwh_count = COUNT(*)	
	--FROM [apcsprodwh].[dwh].[function_finish_control] AS dwh_ffc 
	--WHERE RTRIM(dwh_ffc.function_name) = RTRIM(@function_name_);

	SET @sql = N''
	SET @sql = @sql + N' SELECT @x = COUNT(*) '
	SET @sql = @sql + N' FROM [apcsprodwh].[dwh].[function_finish_control] AS dwh_ffc with (NOLOCK) '
	SET @sql = @sql + N' WHERE RTRIM(dwh_ffc.function_name) = ''' + RTRIM(@function_name_) + ''''
	--PRINT '@sql1=' + @sql1;

	BEGIN TRY
		EXEC sp_executesql @sql, N'@x INT OUTPUT', @x=@dwh_count OUTPUT;
	END TRY
	BEGIN CATCH
		select @errmsg = ERROR_MESSAGE()
				,@errnum = ERROR_NUMBER() 
		RETURN -1;
	END CATCH

	--SELECT @finished_day_id = id 
	--FROM [apcsprodwh].[dwh].[dim_days] 
	--WHERE date_value = (SELECT CONVERT(date, @finished_at_) AS date_value);

	SET @sql = ''
	SET @sql = @sql + N' SELECT @x = id '
	SET @sql = @sql + N' FROM [apcsprodwh].[dwh].[dim_days] AS d with (NOLOCK) '
	SET @sql = @sql + N' WHERE date_value = (SELECT CONVERT(date, @finishedat) AS date_value) '
	--PRINT '@sql1=' + @sql1;

	BEGIN TRY
		EXEC sp_executesql @sql, N'@x INT OUTPUT,@finishedat DATETIME', @x=@finished_day_id OUTPUT, @finishedat=@finished_at_;
	END TRY
	BEGIN CATCH
		select @errmsg = ERROR_MESSAGE() + '/SQL:' + @sql
				,@errnum = ERROR_NUMBER() 
		RETURN -1;
	END CATCH


	--SELECT @finished_hour_code = code 
	--FROM [apcsprodwh].[dwh].[dim_hours] 
	--WHERE h = (SELECT DATEPART(hour, @finished_at_) AS h);

	SET @sql = ''
	SET @sql = @sql + N' SELECT @x = code '
	SET @sql = @sql + N' FROM [apcsprodwh].[dwh].[dim_hours] AS d with (NOLOCK) '
	SET @sql = @sql + N' WHERE h = (SELECT DATEPART(hour, @finished_at_) AS h) '
	--PRINT '@sql1=' + @sql1;

	BEGIN TRY
		EXEC sp_executesql @sql, N'@x INT OUTPUT', @x=@finished_hour_code OUTPUT;
	END TRY
	BEGIN CATCH
		select @errmsg = ERROR_MESSAGE() + '/SQL:' + @sql
				,@errnum = ERROR_NUMBER() 
		RETURN -1;
	END CATCH
	*/

    ---------------------------------------------------------------------------
	--(4) update function_finish_control
    ---------------------------------------------------------------------------
	BEGIN TRY
		--BEGIN TRANSACTION;
			IF @dwh_count = 0
				BEGIN
					SET @sql = ''
					SET @sql = @sql + N'INSERT INTO [APCSProDWH].[dwh].function_finish_control ( ' ;
					SET @sql = @sql + N'function_name,finished_at,finished_day_id,finished_hour_code,to_fact_table ' ;
					SET @sql = @sql + N') VALUES ( ' ;
					set @sql = @sql + N'''' + @function_name_ + '''' + ',''' + convert(varchar,@finished_at_,21) + ''',' + convert(varchar,@finished_day_id) + ',' + convert(varchar,@finished_hour_code) ;
					SET @sql = @sql + N',''' + @to_fact_table_ + N'''' ;
					SET @sql = @sql + N') ' ;
					print @sql;
					EXECUTE (@sql);
					print '@sql:OK';
				END
			ELSE
				BEGIN
					SET @sql = ''
					SET @sql = @sql + N'UPDATE [APCSProDWH].[dwh].function_finish_control ' ;
					SET @sql = @sql + N'SET ' ;
					SET @sql = @sql + N'finished_at = ''' + convert(varchar,@finished_at_,21) + ''' ' ;
					SET @sql = @sql + N',finished_day_id = ' + convert(varchar,@finished_day_id) + ' ' ;
					SET @sql = @sql + N',finished_hour_code = ' + convert(varchar,@finished_hour_code) + ' ' ;
					SET @sql = @sql + N',to_fact_table = ''' + @to_fact_table_ + N''' ' ;
					set @sql = @sql +  'WHERE function_name = ''' + @function_name_ + ''' ' ;
					print @sql;
					EXECUTE (@sql);
					print '@sql:OK';
				END
 		--COMMIT TRANSACTION;

		RETURN 0;
	END TRY

	BEGIN CATCH
		--IF @@TRANCOUNT <> 0
		--	BEGIN
		--		ROLLBACK TRANSACTION;
		--	END;
		select @errmsg = ERROR_MESSAGE() + '/SQL:' + @sql
				,@errnum = ERROR_NUMBER() 
				,@errline = ERROR_LINE()
		RETURN -1;
	END CATCH;

END ;

