-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_trans_special_flow_temp]
	-- Add the parameters for the stored procedure here
	@num INT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @flow_pattern_id INT = NULL
		, @link_flow_no INT = NULL
		, @assy_ft_class VARCHAR(2) = 'S'

	IF ( @num IS NOT NULL )
	BEGIN
		IF ( @num = 1 )
		BEGIN
			SET @flow_pattern_id = 1198; --FL 100% INSP
		END
		ELSE IF ( @num = 2 )
		BEGIN
			SET @flow_pattern_id = 1199; --100% X-Ray
		END
		ELSE IF ( @num = 3 )
		BEGIN
			SET @flow_pattern_id = 1267; --FT 100% INSP
		END
		ELSE IF ( @num = 4 )
		BEGIN
			SET @flow_pattern_id = 1499; -- TP Rework
		END
		ELSE IF ( @num = 5 )
		BEGIN
			SET @flow_pattern_id = 1667; -- Aging TP Rework
		END
		ELSE IF ( @num = 6 )
		BEGIN
			SET @flow_pattern_id = 1673; -- TP Aging Rework
		END
		ELSE IF ( @num = 7 )
		BEGIN
			SET @flow_pattern_id = 1726; -- Test Evaluation
		END
		ELSE IF ( @num = 8 )
		BEGIN
			SET @flow_pattern_id = 1798; -- DB Inspection
		END
		ELSE IF ( @num = 9 )
		BEGIN
			SET @flow_pattern_id = 1745; -- WB Inspection
		END
		ELSE IF ( @num = 10 )
		BEGIN
			SET @flow_pattern_id = 696; -- DC 100% INSP.
		END
		ELSE IF ( @num = 11 )
		BEGIN
			SET @flow_pattern_id = 1841; -- Marker
		END
		ELSE IF ( @num = 12 )
		BEGIN
			SET @flow_pattern_id = 1827; -- Wafer AOI
		END
		ELSE IF ( @num = 13 )
		BEGIN
			SET @flow_pattern_id = 1829; -- X-RAY Period Check
		END
		ELSE IF ( @num = 14 )
		BEGIN
			SET @flow_pattern_id = 1830; -- Solder Test
		END
		ELSE IF ( @num = 15 )
		BEGIN
			SET @flow_pattern_id = 1818; -- Sampling SAT
		END
		ELSE IF ( @num = 16 )
		BEGIN
			SET @flow_pattern_id = 1819; -- Keep Good Sample
		END
		ELSE IF ( @num = 17 )
		BEGIN
			SET @flow_pattern_id = 1820; -- Keep NG Sample
		END
		ELSE IF ( @num = 18 )
		BEGIN
			SET @flow_pattern_id = 1832; -- Change Tube
		END
	END

	SELECT TOP 1 @link_flow_no = [flow_patterns].[link_flow_no]
	FROM [APCSProDB].[method].[flow_patterns]
	INNER JOIN [APCSProDB].[method].[flow_details] ON [flow_patterns].[id] = [flow_details].[flow_pattern_id]
	WHERE [flow_patterns].[assy_ft_class] = @assy_ft_class
		AND [flow_details].[flow_pattern_id] = @flow_pattern_id;

	SELECT ISNULL( @flow_pattern_id, 0 ) AS [flow_pattern_id]
		, @link_flow_no AS [link_flow_no];
END
