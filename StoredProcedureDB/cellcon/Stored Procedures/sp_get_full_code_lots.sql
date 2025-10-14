-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_full_code_lots]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--SELECT  [lots].[id]					as LotId
	--	 , [lots].[lot_no]				as LotNo
	--	 ,CASE WHEN qr_code252 IS NULL THEN CONVERT(char(252),QR_CODE_2) ELSE qr_code252 END AS qr_code252
	--	 ,CASE WHEN qr_code332 IS NULL THEN CONVERT(char(332), QR_CODE) ELSE qr_code332 END AS qr_code332

	--FROM [APCSProDB].[trans].[lots]										with (NOLOCK)

	--LEFT  JOIN [APCSProDB].[robin].[lot_information_front]				with (NOLOCK) ON [APCSProDB].robin.lot_information_front.lot_id = [APCSProDB].trans.lots.id
	--LEFT  JOIN [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]			with (NOLOCK) ON [APCSProDB].dbo.LCQW_UNION_WORK_DENPYO_PRINT.LOT_NO_2 = [APCSProDB].trans.lots.lot_no	
	--WHERE [lots].[lot_no] = @lot_no

	--ORDER BY [lots].[lot_no]

	IF (@lot_no LIKE '____D____V')
	BEGIN
		SELECT [lots].[id]					AS [LotId]
			, [lots].[lot_no]				AS [LotNo]
			, CAST(ISNULL([packages].[short_name],'') AS CHAR(10)) --as package_name
				+ CAST(ISNULL([device_names].[assy_name],'') AS CHAR(20)) --as ASSY_Model_Name
				+ CAST(ISNULL([lots].[lot_no],'') AS CHAR(10)) --as LotNo
				+ SPACE(42)
				+ CAST(ISNULL([device_names].[tp_rank],'') AS CHAR(2)) --as TPRank
				+ SPACE(62)
				+ CAST(ISNULL([packages].[short_name],'') AS CHAR(20)) --as package_name
				+ CAST(ISNULL([device_names].[ft_name],'') AS CHAR(20)) --as ft_name
				+ CAST('MX' AS CHAR(12)) --AS MNo
				+ CAST(FORMAT([device_names].[pcs_per_pack],'00000') AS CHAR(5)) --as packing_standard
				+ SPACE(2)
				+ CAST(ISNULL([device_names].[rank],'') AS CHAR(7))--as Rank
				+ CASE WHEN [multi_labels].[user_model_name] IS NULL THEN CAST(ISNULL([device_names].[name],'') AS CHAR(20))
					ELSE CAST(ISNULL([multi_labels].[user_model_name],'') AS CHAR(20)) END --as Customer_Device
				+ CAST([device_names].[name] AS CHAR(20)) --as device_name
			AS [qr_code252]
			, NULL AS [qr_code332]
		FROM [APCSProDB].[trans].[lots]
		INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
		INNER JOIN [APCSProDB].[method].[packages] ON [device_names].[package_id] = [packages].[id]
		LEFT JOIN [APCSProDB].[method].[multi_labels] ON [device_names].[name] = [multi_labels].[device_name]
		WHERE [lots].[lot_no] = @lot_no
			AND [lots].[lot_no] LIKE '____D____V';
	END
	ELSE
	BEGIN
		SELECT [lots].[id]					AS [LotId]
			 , [lots].[lot_no]				AS [LotNo]
			 , (CASE WHEN qr_code252 IS NULL THEN CONVERT(CHAR(252), [QR_CODE_2]) ELSE [qr_code252] END) AS [qr_code252]
			 , (CASE WHEN [qr_code332] IS NULL THEN CONVERT(CHAR(332), [QR_CODE]) ELSE [qr_code332] END) AS [qr_code332]
		FROM [APCSProDB].[trans].[lots]										WITH (NOLOCK)
		LEFT JOIN [APCSProDB].[robin].[lot_information_front]				WITH (NOLOCK) ON [lot_information_front].[lot_id] = [lots].[id]
		LEFT JOIN [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]			WITH (NOLOCK) ON [LCQW_UNION_WORK_DENPYO_PRINT].[LOT_NO_2] = [lots].[lot_no] 
		WHERE [lots].[lot_no] = @lot_no;
	END
END
