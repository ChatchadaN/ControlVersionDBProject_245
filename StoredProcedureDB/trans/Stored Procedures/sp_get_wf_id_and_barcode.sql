
CREATE PROCEDURE [trans].[sp_get_wf_id_and_barcode]
	-- Add the parameters for the stored procedure here
	@material_id INT OUTPUT,
	@material_barcode VARCHAR(255) OUTPUT,
	@material_arrival_id INT OUTPUT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	------------------------------------------------------------------------------------------
	-- # Get material_id
	------------------------------------------------------------------------------------------
	SET @material_id = (SELECT [id] FROM [APCSProDB].[trans].[numbers] WITH (ROWLOCK) WHERE [name] = 'materials.id');
	IF (@material_id IS NULL)
	BEGIN
		SET @material_id = 1;
		INSERT INTO [APCSProDB].[trans].[numbers] ([name], [id]) VALUES ('materials.id', @material_id);
	END
	ELSE
	BEGIN
		SET @material_id = @material_id + 1;
		IF EXISTS(SELECT [id] FROM [APCSProDB].[trans].[numbers] WHERE [name] = 'materials.id' AND [id] = @material_id)
		BEGIN
			SELECT @material_id = [id] + 1 
			FROM [APCSProDB].[trans].[numbers] 
			WHERE [name] = 'materials.id';
		END
		UPDATE [APCSProDB].[trans].[numbers] SET [id] = @material_id WHERE [name] = 'materials.id';
	END
	------------------------------------------------------------------------------------------
	-- # Get material_barcode
	------------------------------------------------------------------------------------------
	DECLARE @day_id INT,
		@seq_code INT,
		@seq_id INT;

	SET @day_id = (SELECT [id] FROM [APCSProDB].[trans].[days] WHERE [date_value] = CAST(GETDATE() AS DATE));
	SET @seq_id = (SELECT [id] FROM [APCSProDB].[trans].[sequences] WITH (ROWLOCK) WHERE [day_id] =  @day_id);

	IF (@seq_id IS NULL)
	BEGIN
		SET @seq_id = 1;
		INSERT INTO [APCSProDB].[trans].[sequences] ([day_id], [id]) VALUES (@day_id, @seq_id);
	END
	ELSE
	BEGIN
		SET @seq_id = @seq_id + 1;
		UPDATE [APCSProDB].[trans].[sequences] SET [id] = @seq_id WHERE [day_id] = @day_id;
	END

	SET @seq_code = (SELECT [seq_code] FROM [APCSProDB].[material].[master_data] WHERE [name] = 'CHIP');
	SET @material_barcode = FORMAT(@seq_code, '00') + FORMAT(GETDATE(), 'yyMMdd') + FORMAT(@seq_id, '0000');
	------------------------------------------------------------------------------------------
	-- # Get material_arrival_id
	------------------------------------------------------------------------------------------
	SET @material_arrival_id = (SELECT [id] FROM [APCSProDB].[trans].[numbers] WITH (ROWLOCK) WHERE [name] = 'material_arrival_records.id');
	IF (@material_arrival_id IS NULL)
	BEGIN
		SET @material_arrival_id = 1;
		INSERT INTO [APCSProDB].[trans].[numbers] ([name], [id]) VALUES ('material_arrival_records.id', @material_arrival_id);
	END
	ELSE
	BEGIN
		SET @material_arrival_id = @material_arrival_id + 1;
		IF EXISTS(SELECT [id] FROM [APCSProDB].[trans].[numbers] WHERE [name] = 'material_arrival_records.id' AND [id] = @material_arrival_id)
		BEGIN
			SELECT @material_arrival_id = [id] + 1 
			FROM [APCSProDB].[trans].[numbers] 
			WHERE [name] = 'material_arrival_records.id';
		END
		UPDATE [APCSProDB].[trans].[numbers] SET [id] = @material_arrival_id WHERE [name] = 'material_arrival_records.id';
	END
END