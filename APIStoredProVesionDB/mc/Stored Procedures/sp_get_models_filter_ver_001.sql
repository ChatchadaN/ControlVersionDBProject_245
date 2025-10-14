-- =============================================
-- Author:		<Author,,Nutchanat K.>
-- Create date: <15/09/2025>
-- Description:	<Get get_location List>
-- =============================================
CREATE PROCEDURE [mc].[sp_get_models_filter_ver_001]
@item AS INT = 0, 
@val AS VARCHAR(15) = NULL

AS
BEGIN
    SET NOCOUNT ON;



		IF (@item = 0  ) --all
	BEGIN

    SELECT [name]
          ,[val]
          ,[label_eng]
          ,ISNULL(CONVERT(VARCHAR,[item_labels].[created_at],120),'') AS [created_at]
          ,ISNULL(UserCreate.emp_code,'') AS created_by
          ,ISNULL(CONVERT(VARCHAR,[item_labels].[updated_at],120), '') AS [updated_at]
          ,ISNULL(UserUpdate.emp_code, '') AS updated_by
    FROM [DWH].[mc].[item_labels]
    LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserCreate 
        ON UserCreate.id = item_labels.created_by
    LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserUpdate 
        ON UserUpdate.id = item_labels.updated_by
    WHERE [name] like 'models%'
      AND (@val IS NULL OR item_labels.[val] = @val)
END
ELSE
	
	IF (@item =  1) --models.process_type
	BEGIN

    SELECT [name]
          ,[val]
          ,[label_eng]
          ,ISNULL(CONVERT(VARCHAR,[item_labels].[created_at],120),'') AS [created_at]
          ,ISNULL(UserCreate.emp_code,'') AS created_by
          ,ISNULL(CONVERT(VARCHAR,[item_labels].[updated_at],120), '') AS [updated_at]
          ,ISNULL(UserUpdate.emp_code, '') AS updated_by
    FROM [DWH].[mc].[item_labels]
    LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserCreate 
        ON UserCreate.id = item_labels.created_by
    LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserUpdate 
        ON UserUpdate.id = item_labels.updated_by
    WHERE [name] = 'models.process_type'
      AND (@val IS NULL OR item_labels.[val] = @val)
END
ELSE


	IF (@item =  2) --models.map_using'
	BEGIN

    SELECT [name]
          ,[val]
          ,[label_eng]
          ,ISNULL(CONVERT(VARCHAR,[item_labels].[created_at],120),'') AS [created_at]
          ,ISNULL(UserCreate.emp_code,'') AS created_by
          ,ISNULL(CONVERT(VARCHAR,[item_labels].[updated_at],120), '') AS [updated_at]
          ,ISNULL(UserUpdate.emp_code, '') AS updated_by
    FROM [DWH].[mc].[item_labels]
    LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserCreate 
        ON UserCreate.id = item_labels.created_by
    LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserUpdate 
        ON UserUpdate.id = item_labels.updated_by
    WHERE [name] = 'models.map_using'
      AND (@val IS NULL OR item_labels.[val] = @val)
END
ELSE

	IF (@item =  3) --models.map_type
	BEGIN

    SELECT [name]
          ,[val]
          ,[label_eng]
          ,ISNULL(CONVERT(VARCHAR,[item_labels].[created_at],120),'') AS [created_at]
          ,ISNULL(UserCreate.emp_code,'') AS created_by
          ,ISNULL(CONVERT(VARCHAR,[item_labels].[updated_at],120), '') AS [updated_at]
          ,ISNULL(UserUpdate.emp_code, '') AS updated_by
    FROM [DWH].[mc].[item_labels]
    LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserCreate 
        ON UserCreate.id = item_labels.created_by
    LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserUpdate 
        ON UserUpdate.id = item_labels.updated_by
    WHERE [name] = 'models.map_type'
      AND (@val IS NULL OR item_labels.[val] = @val)
END
ELSE

	IF (@item =  4) --models.bin_type
	BEGIN

    SELECT [name]
          ,[val]
          ,[label_eng]
          ,ISNULL(CONVERT(VARCHAR,[item_labels].[created_at],120),'') AS [created_at]
          ,ISNULL(UserCreate.emp_code,'') AS created_by
          ,ISNULL(CONVERT(VARCHAR,[item_labels].[updated_at],120), '') AS [updated_at]
          ,ISNULL(UserUpdate.emp_code, '') AS updated_by
    FROM [DWH].[mc].[item_labels]
    LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserCreate 
        ON UserCreate.id = item_labels.created_by
    LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserUpdate 
        ON UserUpdate.id = item_labels.updated_by
    WHERE [name] = 'models.bin_type'
      AND (@val IS NULL OR item_labels.[val] = @val)
END
ELSE

	IF (@item =  5) --models.is_linked_with_work
	BEGIN

    SELECT [name]
          ,[val]
          ,[label_eng]
          ,ISNULL(CONVERT(VARCHAR,[item_labels].[created_at],120),'') AS [created_at]
          ,ISNULL(UserCreate.emp_code,'') AS created_by
          ,ISNULL(CONVERT(VARCHAR,[item_labels].[updated_at],120), '') AS [updated_at]
          ,ISNULL(UserUpdate.emp_code, '') AS updated_by
    FROM [DWH].[mc].[item_labels]
    LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserCreate 
        ON UserCreate.id = item_labels.created_by
    LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserUpdate 
        ON UserUpdate.id = item_labels.updated_by
    WHERE [name] = 'models.is_linked_with_work'
      AND (@val IS NULL OR item_labels.[val] = @val)
END
ELSE

	IF (@item =  6) --models.ppid_type1,2
	BEGIN

    SELECT [name]
          ,[val]
          ,[label_eng]
          ,ISNULL(CONVERT(VARCHAR,[item_labels].[created_at],120),'') AS [created_at]
          ,ISNULL(UserCreate.emp_code,'') AS created_by
          ,ISNULL(CONVERT(VARCHAR,[item_labels].[updated_at],120), '') AS [updated_at]
          ,ISNULL(UserUpdate.emp_code, '') AS updated_by
    FROM [DWH].[mc].[item_labels]
    LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserCreate 
        ON UserCreate.id = item_labels.created_by
    LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserUpdate 
        ON UserUpdate.id = item_labels.updated_by
    WHERE [name] = 'models.ppid_type1'
      AND (@val IS NULL OR item_labels.[val] = @val)
END
ELSE

	IF (@item =  7) --models.is_carrier_register
	BEGIN

    SELECT [name]
          ,[val]
          ,[label_eng]
          ,ISNULL(CONVERT(VARCHAR,[item_labels].[created_at],120),'') AS [created_at]
          ,ISNULL(UserCreate.emp_code,'') AS created_by
          ,ISNULL(CONVERT(VARCHAR,[item_labels].[updated_at],120), '') AS [updated_at]
          ,ISNULL(UserUpdate.emp_code, '') AS updated_by
    FROM [DWH].[mc].[item_labels]
    LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserCreate 
        ON UserCreate.id = item_labels.created_by
    LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserUpdate 
        ON UserUpdate.id = item_labels.updated_by
    WHERE [name] = 'models.is_carrier_register'
      AND (@val IS NULL OR item_labels.[val] = @val)
END
ELSE

	IF (@item =  8) --models.is_carrier_transfer
	BEGIN

    SELECT [name]
          ,[val]
          ,[label_eng]
          ,ISNULL(CONVERT(VARCHAR,[item_labels].[created_at],120),'') AS [created_at]
          ,ISNULL(UserCreate.emp_code,'') AS created_by
          ,ISNULL(CONVERT(VARCHAR,[item_labels].[updated_at],120), '') AS [updated_at]
          ,ISNULL(UserUpdate.emp_code, '') AS updated_by
    FROM [DWH].[mc].[item_labels]
    LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserCreate 
        ON UserCreate.id = item_labels.created_by
    LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserUpdate 
        ON UserUpdate.id = item_labels.updated_by
    WHERE [name] = 'models.is_carrier_transfer'
      AND (@val IS NULL OR item_labels.[val] = @val)
END
ELSE

	IF (@item =  9) --models.is_carrier_verification_setup
	BEGIN

    SELECT [name]
          ,[val]
          ,[label_eng]
          ,ISNULL(CONVERT(VARCHAR,[item_labels].[created_at],120),'') AS [created_at]
          ,ISNULL(UserCreate.emp_code,'') AS created_by
          ,ISNULL(CONVERT(VARCHAR,[item_labels].[updated_at],120), '') AS [updated_at]
          ,ISNULL(UserUpdate.emp_code, '') AS updated_by
    FROM [DWH].[mc].[item_labels]
    LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserCreate 
        ON UserCreate.id = item_labels.created_by
    LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserUpdate 
        ON UserUpdate.id = item_labels.updated_by
    WHERE [name] = 'models.is_carrier_verification_setup'
      AND (@val IS NULL OR item_labels.[val] = @val)
END
ELSE

	IF (@item =  10) --models.is_carrier_verification_end
	BEGIN

    SELECT [name]
          ,[val]
          ,[label_eng]
          ,ISNULL(CONVERT(VARCHAR,[item_labels].[created_at],120),'') AS [created_at]
          ,ISNULL(UserCreate.emp_code,'') AS created_by
          ,ISNULL(CONVERT(VARCHAR,[item_labels].[updated_at],120), '') AS [updated_at]
          ,ISNULL(UserUpdate.emp_code, '') AS updated_by
    FROM [DWH].[mc].[item_labels]
    LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserCreate 
        ON UserCreate.id = item_labels.created_by
    LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserUpdate 
        ON UserUpdate.id = item_labels.updated_by
    WHERE [name] = 'models.is_carrier_verification_end'
      AND (@val IS NULL OR item_labels.[val] = @val)
END
ELSE

	IF (@item =  11) --machine.machine_level
	BEGIN

    SELECT [name]
          ,[val]
          ,[label_eng]
          ,ISNULL(CONVERT(VARCHAR,[item_labels].[created_at],120),'') AS [created_at]
          ,ISNULL(UserCreate.emp_code,'') AS created_by
          ,ISNULL(CONVERT(VARCHAR,[item_labels].[updated_at],120), '') AS [updated_at]
          ,ISNULL(UserUpdate.emp_code, '') AS updated_by
    FROM [DWH].[mc].[item_labels]
    LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserCreate 
        ON UserCreate.id = item_labels.created_by
    LEFT JOIN [10.29.1.230].[DWH].[man].[employees] AS UserUpdate 
        ON UserUpdate.id = item_labels.updated_by
    WHERE [name] = 'machine.machine_level'
      AND (@val IS NULL OR item_labels.[val] = @val)

	END
END