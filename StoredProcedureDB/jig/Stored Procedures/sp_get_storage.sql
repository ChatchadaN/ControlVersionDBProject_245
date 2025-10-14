------------------------------ Creater Rule ------------------------------
-- Project Name				: jig
-- Author Name              : Sadanun.B
-- Written Date             : 2022/12/07
-- Procedure Name 	 		: [jig].[sp_get_storage]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.locations
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [jig].[sp_get_storage]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		@process_id  INT  = NULL
)
AS
BEGIN
	SET NOCOUNT ON;

  
			SELECT locations.id
					, y AS Col
					, x AS Row
					, locations.name  AS locations
					, processes.name AS processes
			FROM APCSProDB.jig.locations 
			INNER JOIN APCSProDB.method.processes
			ON locations.lsi_process_id =  processes.id 
			WHERE (lsi_process_id = @process_id ) 
			GROUP BY   processes.name  , locations.name, processes.id,  y  , x, locations.id
			ORDER BY  locations.id
			


END
