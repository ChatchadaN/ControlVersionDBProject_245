-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_rcs_new_rack] 
	-- Add the parameters for the stored procedure here
	@Name varchar(20), @Column int, @Row int, @Depth int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	

	DECLARE @AL AS AddressList
	DECLARE @i int = 1, @j int = 1, @k int = 1, @x char(1), @y varchar(2), @z varchar(2), @wh_code int = 1, @lastId int
	
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
		,'EXEC [dbo].[sp_set_rcs_new_rack] @Name = ''' + @Name + ''', @Column = ''' + CONVERT (varchar (5), @Column) 
		+''', @Row = ''' + CONVERT (varchar (5), @Row) + ''', @Depth = '''+ CONVERT (varchar (5), @Depth) + ''''


	SELECT @lastId = ISNULL(MAX(id), 0)
	FROM APCSProDB.trans.locations

	WHILE @i <= @Column
	BEGIN
		SELECT @x = CASE
			WHEN @i = 1 THEN 'A'
			WHEN @i = 2 THEN 'B'
			WHEN @i = 3 THEN 'C'
			WHEN @i = 4 THEN 'D'
			WHEN @i = 5 THEN 'E'
			WHEN @i = 6 THEN 'F'
			WHEN @i = 7 THEN 'G'
			WHEN @i = 8 THEN 'H'
			WHEN @i = 9 THEN 'I'
			WHEN @i = 10 THEN 'J'
			WHEN @i = 11 THEN 'K'
			WHEN @i = 12 THEN 'L'
		END

		WHILE @j <= @Row
		BEGIN 
			SELECT @y = CASE
				WHEN @j <= 9 THEN @j--(SELECT CONCAT('0', @j))
				ELSE (SELECT CONCAT('', @j))
			END

			WHILE @k <= @Depth
			BEGIN 
				SELECT @z = CASE
					WHEN @k <= 9 THEN @k--(SELECT CONCAT('0', @k))
					ELSE (SELECT CONCAT('', @k))
				END

				SELECT @wh_code = CASE
					WHEN @Name like 'HS%' THEN 2 --APCsProDB.trans.item_labels locations.wh_code = 2 -> HS
					WHEN @Name like 'HOL%' THEN 3 --APCsProDB.trans.item_labels locations.wh_code = 3 -> HOL
					ELSE 1
				END

				SELECT @lastId += 1

				INSERT INTO @AL
				VALUES (@lastId, @x, @y, @z, @wh_code)

				SELECT @k += 1			
			END

			SELECT @k = 1
			SELECT @j += 1			
		END

		SELECT @j = 1
		SELECT @i += 1

		SELECT * FROM @AL
	END

	BEGIN TRY
		BEGIN TRAN

		INSERT INTO APCSProDB.trans.locations (id, name, address, x, y, z, wh_code)
		SELECT id, @Name AS name, CONCAT(X, 
										(SELECT CASE WHEN Y <= 9 THEN (SELECT CONCAT('0', Y))
												     ELSE Y END),
										(SELECT CASE WHEN Z <= 9 THEN (SELECT CONCAT('0', Z))
												     ELSE Z END)) AS address, 
			   x, y, z, @wh_code AS wh_code
		FROM @AL		

		COMMIT TRAN

		SELECT 1 AS Result

	END TRY
	BEGIN CATCH		

		ROLLBACK TRAN

		SELECT 0 AS Result

	END CATCH
END
