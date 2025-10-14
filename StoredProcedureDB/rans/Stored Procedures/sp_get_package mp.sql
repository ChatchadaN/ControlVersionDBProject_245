CREATE PROCEDURE [rans].[sp_get_package mp]
	-- Add the parameters for the stored procedure here
	@type_id INT = 0 --- 0:package group 1:package 2:package by short
	, @package_group VARCHAR(20) = '%'
	, @package_name VARCHAR(255) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF (@type_id = 0)
	BEGIN
		----------------------------------------------------------------------------------
		----- package group
		----------------------------------------------------------------------------------
		SELECT DISTINCT [package_group_name]
		FROM (
			SELECT [package_groups].[name] AS [package_group_name]
			FROM (
				SELECT [act_package_id] FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
				INNER JOIN [APCSProDB].[method].[device_flows] WITH (NOLOCK) ON [lots].[device_slip_id] = [device_flows].[device_slip_id]
				WHERE [wip_state] IN (0,10,20)
					AND [device_flows].[job_id] = 29
				GROUP BY [act_package_id]
			) AS [act_package] 
			INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [act_package].[act_package_id] = [packages].[id]
			INNER JOIN [APCSProDB].[method].[package_groups] WITH (NOLOCK) ON [packages].[package_group_id] = [package_groups].[id]
			WHERE [package_groups].[id] NOT IN (1,35) ---- 1:DIP/SDIP ,35:LAPIS  
				--AND [packages].[id] NOT IN (587,77) ---- 587:HTQFP64BVE ,77:HTQFP64V-HF
		) AS [package]
		ORDER BY [package_group_name]
		----------------------------------------------------------------------------------
	END
	ELSE IF (@type_id = 1)
	BEGIN
		----------------------------------------------------------------------------------
		----- package
		----------------------------------------------------------------------------------
		SELECT DISTINCT [fillter] AS [package_name]
		FROM (
			SELECT [packages].[name] AS [package_name]
				, [package_groups].[name] AS [package_group_name]
				, CASE
					---- GDIC ---- 
					WHEN [package_groups].[name] = 'GDIC'
						THEN 
							(CASE 
								WHEN [packages].[name] = 'SSOP-B20W' THEN 'SSOP-B20W/B20WA/B20WR1'   
								WHEN [packages].[name] = 'SSOP-B20WA' THEN 'SSOP-B20W/B20WA/B20WR1'   
								WHEN [packages].[name] = 'SSOPB20WR1' THEN 'SSOP-B20W/B20WA/B20WR1'           
								ELSE [packages].[name] 
							END)
					---- POWER ---- 
					WHEN [package_groups].[name] = 'POWER'
						THEN 
							(CASE 
								WHEN [packages].[name] = 'HRP5' THEN 'HRP5/7'   
								WHEN [packages].[name] = 'HRP7' THEN 'HRP5/7'   
								WHEN [packages].[name] = 'TO252-3' THEN 'TO252-3/5' 
								WHEN [packages].[name] = 'TO252-5' THEN 'TO252-3/5'
								WHEN [packages].[name] = 'TO252-J3' THEN 'TO252-J3/J5/J5F'            
								WHEN [packages].[name] = 'TO252-J5' THEN 'TO252-J3/J5/J5F'            
								WHEN [packages].[name] = 'TO252-J5F' THEN 'TO252-J3/J5/J5F'           
								WHEN [packages].[name] = 'TO252S-5' THEN 'TO252S-5'            
								WHEN [packages].[name] = 'TO263-3' THEN 'TO263-3/5/5F/7'             
								WHEN [packages].[name] = 'TO263-5' THEN 'TO263-3/5/5F/7'             
								WHEN [packages].[name] = 'TO263-5F' THEN 'TO263-3/5/5F/7'            
								WHEN [packages].[name] = 'TO263-7' THEN 'TO263-3/5/5F/7'             
								ELSE [packages].[name] 
							END)
					---- QFP ---- 
					WHEN [package_groups].[name] = 'QFP'
						THEN 
							(CASE 
								WHEN [packages].[name] = 'HTQFP64AV' THEN 'HTQFP64AV/BV/V/VHF' 
								WHEN [packages].[name] = 'HTQFP64BV' THEN 'HTQFP64AV/BV/V/VHF'  
								WHEN [packages].[name] = 'HTQFP64V' THEN 'HTQFP64AV/BV/V/VHF'
								WHEN [packages].[name] = 'HTQFP64V-HF' THEN 'HTQFP64AV/BV/V/VHF' 
								WHEN [packages].[name] = 'SQFP-T52' THEN 'SQFP-T52/VQFP48C/VQFP64'            
								WHEN [packages].[name] = 'VQFP48C' THEN 'SQFP-T52/VQFP48C/VQFP64'                  
								WHEN [packages].[name] = 'VQFP64' THEN 'SQFP-T52/VQFP48C/VQFP64'                   
								ELSE [packages].[name] 
							END)
					---- SMALL ---- 
					WHEN [package_groups].[name] = 'SMALL'
						THEN 
							(CASE 
								WHEN [packages].[name] = 'HSON8' THEN 'HSON8/HF' 
								WHEN [packages].[name] = 'HSON8-HF ' THEN 'HSON8/HF'  
								WHEN [packages].[name] = 'HVSOF5' THEN 'HVSOF5/6/6HF'  
								WHEN [packages].[name] = 'HVSOF6' THEN 'HVSOF5/6/6HF'            
								WHEN [packages].[name] = 'HVSOF6-HF' THEN 'HVSOF5/6/6HF'                  
								WHEN [packages].[name] = 'MSOP8' THEN 'MSOP8/8HF/10' 
								WHEN [packages].[name] = 'MSOP8-HF' THEN 'MSOP8/8HF/10'  
								WHEN [packages].[name] = 'MSOP10' THEN 'MSOP8/8HF/10'
								WHEN [packages].[name] = 'WSOF5' THEN 'WSOF5/6/6I'    
								WHEN [packages].[name] = 'WSOF6' THEN 'WSOF5/6/6I'     
								WHEN [packages].[name] = 'WSOF6I' THEN 'WSOF5/6/6I'  
								ELSE [packages].[name] 
							END)
					---- SOP ---- 
					WHEN [package_groups].[name] = 'SOP'
						THEN 
							(CASE 
								WHEN [packages].[name] = 'HSOP-M36' THEN 'HSOP-M36/TSSOP-B30' 
								WHEN [packages].[name] = 'TSSOP-B30' THEN 'HSOP-M36/TSSOP-B30' 
								WHEN [packages].[name] = 'HTSSOP-A44' THEN 'HTSSOP-A44/A44R/B54/B54R' 
								WHEN [packages].[name] = 'HTSSOP-A44R' THEN 'HTSSOP-A44/A44R/B54/B54R' 
								WHEN [packages].[name] = 'HTSSOP-B54' THEN 'HTSSOP-A44/A44R/B54/B54R' 
								WHEN [packages].[name] = 'HTSSOP-B54R' THEN 'HTSSOP-A44/A44R/B54/B54R'
								WHEN [packages].[name] = 'HTSSOP-C48R' THEN 'HTSSOP-C48R/C48E'       
								WHEN [packages].[name] = 'HTSSOPC48E' THEN 'HTSSOP-C48R/C48E' 
								WHEN [packages].[name] = 'SSOP-A20' THEN 'SSOP-A20/A24/A32/B40'
								WHEN [packages].[name] = 'SSOP-A24' THEN 'SSOP-A20/A24/A32/B40'
								WHEN [packages].[name] = 'SSOP-A32' THEN 'SSOP-A20/A24/A32/B40'  
								WHEN [packages].[name] = 'SSOP-B40' THEN 'SSOP-A20/A24/A32/B40'  
								WHEN [packages].[name] = 'SSOP-A54_23' THEN 'SSOP-A54_23/36'
								WHEN [packages].[name] = 'SSOP-A54_36' THEN 'SSOP-A54_23/36' 
								ELSE [packages].[name] 
							END)
					---- OTHER ---- 
					ELSE
						[packages].[name]
				END AS [fillter]
			FROM (
				SELECT [act_package_id] FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
				INNER JOIN [APCSProDB].[method].[device_flows] WITH (NOLOCK) ON [lots].[device_slip_id] = [device_flows].[device_slip_id]
				WHERE [wip_state] IN (0,10,20)
					AND [device_flows].[job_id] = 29
				GROUP BY [act_package_id]
			) AS [act_package] 
			INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [act_package].[act_package_id] = [packages].[id]
			INNER JOIN [APCSProDB].[method].[package_groups] WITH (NOLOCK) ON [packages].[package_group_id] = [package_groups].[id]
			WHERE [package_groups].[id] NOT IN (1,35) ---- 1:DIP/SDIP ,35:LAPIS  
				--AND [packages].[id] NOT IN (587,77) ---- 587:HTQFP64BVE ,77:HTQFP64V-HF
		) AS [package]
		WHERE [package_group_name] LIKE @package_group
		ORDER BY [package_name]
		----------------------------------------------------------------------------------
	END
	ELSE IF (@type_id = 2)
	BEGIN
		DECLARE @return VARCHAR(MAX) 
		SELECT @return = COALESCE(@return + ',', '') + TRIM([package_name])
		FROM (
			SELECT [packages].[name] AS [package_name]
				, [package_groups].[name] AS [package_group_name]
				, CASE
					---- GDIC ---- 
					WHEN [package_groups].[name] = 'GDIC'
						THEN 
							(CASE 
								WHEN [packages].[name] = 'SSOP-B20W' THEN 'SSOP-B20W/B20WA/B20WR1'   
								WHEN [packages].[name] = 'SSOP-B20WA' THEN 'SSOP-B20W/B20WA/B20WR1'   
								WHEN [packages].[name] = 'SSOPB20WR1' THEN 'SSOP-B20W/B20WA/B20WR1'           
								ELSE [packages].[name] 
							END)
					---- POWER ---- 
					WHEN [package_groups].[name] = 'POWER'
						THEN 
							(CASE 
								WHEN [packages].[name] = 'HRP5' THEN 'HRP5/7'   
								WHEN [packages].[name] = 'HRP7' THEN 'HRP5/7'   
								WHEN [packages].[name] = 'TO252-3' THEN 'TO252-3/5' 
								WHEN [packages].[name] = 'TO252-5' THEN 'TO252-3/5'
								WHEN [packages].[name] = 'TO252-J3' THEN 'TO252-J3/J5/J5F'            
								WHEN [packages].[name] = 'TO252-J5' THEN 'TO252-J3/J5/J5F'            
								WHEN [packages].[name] = 'TO252-J5F' THEN 'TO252-J3/J5/J5F'           
								WHEN [packages].[name] = 'TO252S-5' THEN 'TO252S-5'            
								WHEN [packages].[name] = 'TO263-3' THEN 'TO263-3/5/5F/7'             
								WHEN [packages].[name] = 'TO263-5' THEN 'TO263-3/5/5F/7'             
								WHEN [packages].[name] = 'TO263-5F' THEN 'TO263-3/5/5F/7'            
								WHEN [packages].[name] = 'TO263-7' THEN 'TO263-3/5/5F/7'             
								ELSE [packages].[name] 
							END)
					---- QFP ---- 
					WHEN [package_groups].[name] = 'QFP'
						THEN 
							(CASE 
								WHEN [packages].[name] = 'HTQFP64AV' THEN 'HTQFP64AV/BV/V/VHF' 
								WHEN [packages].[name] = 'HTQFP64BV' THEN 'HTQFP64AV/BV/V/VHF'  
								WHEN [packages].[name] = 'HTQFP64V' THEN 'HTQFP64AV/BV/V/VHF'
								WHEN [packages].[name] = 'HTQFP64V-HF' THEN 'HTQFP64AV/BV/V/VHF' 
								WHEN [packages].[name] = 'SQFP-T52' THEN 'SQFP-T52/VQFP48C/VQFP64'            
								WHEN [packages].[name] = 'VQFP48C' THEN 'SQFP-T52/VQFP48C/VQFP64'                  
								WHEN [packages].[name] = 'VQFP64' THEN 'SQFP-T52/VQFP48C/VQFP64'                   
								ELSE [packages].[name] 
							END)
					---- SMALL ---- 
					WHEN [package_groups].[name] = 'SMALL'
						THEN 
							(CASE 
								WHEN [packages].[name] = 'HSON8' THEN 'HSON8/HF' 
								WHEN [packages].[name] = 'HSON8-HF ' THEN 'HSON8/HF'  
								WHEN [packages].[name] = 'HVSOF5' THEN 'HVSOF5/6/6HF'  
								WHEN [packages].[name] = 'HVSOF6' THEN 'HVSOF5/6/6HF'            
								WHEN [packages].[name] = 'HVSOF6-HF' THEN 'HVSOF5/6/6HF'                  
								WHEN [packages].[name] = 'MSOP8' THEN 'MSOP8/8HF/10' 
								WHEN [packages].[name] = 'MSOP8-HF' THEN 'MSOP8/8HF/10'  
								WHEN [packages].[name] = 'MSOP10' THEN 'MSOP8/8HF/10'
								WHEN [packages].[name] = 'WSOF5' THEN 'WSOF5/6/6I'    
								WHEN [packages].[name] = 'WSOF6' THEN 'WSOF5/6/6I'     
								WHEN [packages].[name] = 'WSOF6I' THEN 'WSOF5/6/6I'  
								ELSE [packages].[name] 
							END)
					---- SOP ---- 
					WHEN [package_groups].[name] = 'SOP'
						THEN 
							(CASE 
								WHEN [packages].[name] = 'HSOP-M36' THEN 'HSOP-M36/TSSOP-B30' 
								WHEN [packages].[name] = 'TSSOP-B30' THEN 'HSOP-M36/TSSOP-B30' 
								WHEN [packages].[name] = 'HTSSOP-A44' THEN 'HTSSOP-A44/A44R/B54/B54R' 
								WHEN [packages].[name] = 'HTSSOP-A44R' THEN 'HTSSOP-A44/A44R/B54/B54R' 
								WHEN [packages].[name] = 'HTSSOP-B54' THEN 'HTSSOP-A44/A44R/B54/B54R' 
								WHEN [packages].[name] = 'HTSSOP-B54R' THEN 'HTSSOP-A44/A44R/B54/B54R'
								WHEN [packages].[name] = 'HTSSOP-C48R' THEN 'HTSSOP-C48R/C48E'       
								WHEN [packages].[name] = 'HTSSOPC48E' THEN 'HTSSOP-C48R/C48E' 
								WHEN [packages].[name] = 'SSOP-A20' THEN 'SSOP-A20/A24/A32/B40'
								WHEN [packages].[name] = 'SSOP-A24' THEN 'SSOP-A20/A24/A32/B40'
								WHEN [packages].[name] = 'SSOP-A32' THEN 'SSOP-A20/A24/A32/B40'  
								WHEN [packages].[name] = 'SSOP-B40' THEN 'SSOP-A20/A24/A32/B40'  
								WHEN [packages].[name] = 'SSOP-A54_23' THEN 'SSOP-A54_23/36'
								WHEN [packages].[name] = 'SSOP-A54_36' THEN 'SSOP-A54_23/36' 
								ELSE [packages].[name] 
							END)
					---- OTHER ---- 
					ELSE
						[packages].[name]
				END AS [fillter]
			FROM (
				SELECT [act_package_id] FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
				INNER JOIN [APCSProDB].[method].[device_flows] WITH (NOLOCK) ON [lots].[device_slip_id] = [device_flows].[device_slip_id]
				WHERE [wip_state] IN (0,10,20)
					AND [device_flows].[job_id] = 29
				GROUP BY [act_package_id]
			) AS [act_package] 
			INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [act_package].[act_package_id] = [packages].[id]
			INNER JOIN [APCSProDB].[method].[package_groups] WITH (NOLOCK) ON [packages].[package_group_id] = [package_groups].[id]
			WHERE [package_groups].[id] NOT IN (1,35) ---- 1:DIP/SDIP ,35:LAPIS  
				--AND [packages].[id] NOT IN (587,77) ---- 587:HTQFP64BVE ,77:HTQFP64V-HF
		) AS [package]
		WHERE [fillter] LIKE @package_name
		ORDER BY [package_name];

		SELECT @return AS [package_name];
	END
END
