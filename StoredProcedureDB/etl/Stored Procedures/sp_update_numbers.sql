

CREATE PROCEDURE [etl].[sp_update_numbers] (@servername NVARCHAR(128) = ''
                                       ,@databasename NVARCHAR(128)
                                       ,@schemaname NVARCHAR(128)
                                       ,@name NVARCHAR(128)
                                       ,@count INT
                                       ,@id_used INT OUTPUT
									   ,@id_used_new INT OUTPUT
									   ,@errnum  INT output
									   ,@errline INT output
									   ,@errmsg nvarchar(max) output
									   ) AS
BEGIN
	declare @servername2 NVARCHAR(128) = ''
	declare @databasename2 NVARCHAR(128) = ''
	declare @schemaname2 NVARCHAR(128) = ''
	declare @name2 NVARCHAR(128) = ''
	declare @dot nvarchar(1) = '.'
	declare @objectname NVARCHAR(128) = ''

    ---------------------------------------------------------------------------
	--(1)-- check argument
    ---------------------------------------------------------------------------
	--BEGIN
	--	IF RTRIM(@servername) = ''
	--		RETURN 1;
	--END;
	BEGIN
		IF RTRIM(@databasename) = ''
			RETURN 1;
	END;
	BEGIN
		IF RTRIM(@schemaname) = ''
			RETURN 1;
	END;
	BEGIN
		IF RTRIM(@name) = ''
			RETURN 1;
	END;
	BEGIN
		IF @count = 0
			RETURN 1;
	END;

	set @servername2 = '[' + @servername + ']'
	set @databasename2 = '[' + @databasename + ']'
	set @schemaname2 = '[' + @schemaname + ']'
	IF RTRIM(@servername) = ''
		BEGIN
			set @objectname = @databasename2 + @dot + @schemaname2 + @dot
		END;
	ELSE
		BEGIN
			set @objectname = @servername2 + @dot + @databasename2 + @dot + @schemaname2 + @dot
		END;
	



    ---------------------------------------------------------------------------
	--(2) init variables
    ---------------------------------------------------------------------------
	SET @id_used = -1
	SET @id_used_new = 0

    ---------------------------------------------------------------------------
	--(3) make @sql1
    ---------------------------------------------------------------------------
	DECLARE @sql1 NVARCHAR(max) = '';
	SET @sql1 = ''
	SET @sql1 = @sql1 + ' SELECT @x = id '
	SET @sql1 = @sql1 + ' FROM ' + @objectname + '[numbers] AS numbers WITH (ROWLOCK,XLOCK) '
	SET @sql1 = @sql1 + ' WHERE RTRIM(name) = ''' + RTRIM(@name) + ''''
	--PRINT '@sql1=' + @sql1;

	BEGIN TRY
		BEGIN TRANSACTION;
		EXEC sp_executesql @sql1, N'@x INT OUTPUT', @x=@id_used OUTPUT;
	END TRY

	BEGIN CATCH
		select @errmsg = ERROR_MESSAGE() + '/SQL:' + @sql1
				,@errnum = ERROR_NUMBER() 
				,@errline = ERROR_LINE()

		--IF @@TRANCOUNT <> 0
		--BEGIN
		ROLLBACK TRANSACTION;
			--END;
		RETURN -1;
	END CATCH;
		
    ---------------------------------------------------------------------------
	--(4) update numbers
    ---------------------------------------------------------------------------
	BEGIN TRY
		--BEGIN TRANSACTION;
			IF @id_used IS NULL 
				BEGIN
					SET @id_used = -1
				END
			IF @id_used = -1
				BEGIN
					DECLARE @sqlIns NVARCHAR(max) = ''
					SET @sqlIns = '';
					SET @sqlIns = @sqlIns + ' INSERT INTO ' + @objectname + '[numbers] ';
					SET @sqlIns = @sqlIns + ' (';
					SET @sqlIns = @sqlIns + ' name ';
					SET @sqlIns = @sqlIns + ',id ';
					SET @sqlIns = @sqlIns + ') VALUES (';
					SET @sqlIns = @sqlIns + '''' + RTRIM(@name) + '''';
					SET @sqlIns = @sqlIns + ',' + CONVERT(NVARCHAR(5), @count+1);
					SET @sqlIns = @sqlIns + ')';
					PRINT '@sqlIns=' + @sqlIns;

					EXECUTE (@sqlIns);
					SET @id_used = 0;
				END

			ELSE
				BEGIN
					DECLARE @sqlUpd NVARCHAR(max) = ''
					SET @sqlUpd = '';
					SET @sqlUpd = @sqlUpd + ' UPDATE ' + @objectname + '[numbers] WITH (ROWLOCK) ';
					SET @sqlUpd = @sqlUpd + ' SET id = id + ' + CONVERT(NVARCHAR(5), @count+1);
					SET @sqlUpd = @sqlUpd + ' WHERE RTRIM(name) = ''' + RTRIM(@name) + '''';
					PRINT '@sqlUpd=' + @sqlUpd;

					EXECUTE (@sqlUpd);
				END
 		COMMIT TRANSACTION;

		SET @id_used_new = @id_used + @count;

		set @errmsg = ''
		set @errnum = 0
		set @errline = 0
		RETURN 0;
	END TRY

	BEGIN CATCH
		select @errmsg = ERROR_MESSAGE() + '/SQL:' + @sqlIns + @sqlUpd
				,@errnum = ERROR_NUMBER() 
				,@errline = ERROR_LINE()
		--IF @@TRANCOUNT <> 0
		--	BEGIN
				ROLLBACK TRANSACTION;
		--	END;
		RETURN -1;
	END CATCH;

END ;





