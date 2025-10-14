ALTER ROLE [db_owner] ADD MEMBER [apiuser];


GO
ALTER ROLE [db_owner] ADD MEMBER [owneruser];


GO
ALTER ROLE [db_owner] ADD MEMBER [ApplicationUser];


GO
ALTER ROLE [db_owner] ADD MEMBER [SysAdminUser];


GO
ALTER ROLE [db_accessadmin] ADD MEMBER [RIST\ICT DatabaseAdminsGroup];


GO
ALTER ROLE [db_accessadmin] ADD MEMBER [RIST\ICT APIDevGroup];


GO
ALTER ROLE [db_securityadmin] ADD MEMBER [RIST\ICT DatabaseAdminsGroup];


GO
ALTER ROLE [db_securityadmin] ADD MEMBER [RIST\ICT APIDevGroup];


GO
ALTER ROLE [db_ddladmin] ADD MEMBER [RIST\ICT DatabaseAdminsGroup];


GO
ALTER ROLE [db_ddladmin] ADD MEMBER [RIST\ICT APIDevGroup];


GO
ALTER ROLE [db_backupoperator] ADD MEMBER [apcsuser];


GO
ALTER ROLE [db_backupoperator] ADD MEMBER [RIST\ICT DatabaseAdminsGroup];


GO
ALTER ROLE [db_backupoperator] ADD MEMBER [RIST\ICT APIDevGroup];


GO
ALTER ROLE [db_datareader] ADD MEMBER [system];


GO
ALTER ROLE [db_datareader] ADD MEMBER [apcsuser];


GO
ALTER ROLE [db_datareader] ADD MEMBER [DBxUser];


GO
ALTER ROLE [db_datareader] ADD MEMBER [ApplicationUser];


GO
ALTER ROLE [db_datareader] ADD MEMBER [RIST\ICT DatabaseAdminsGroup];


GO
ALTER ROLE [db_datareader] ADD MEMBER [RIST\ICT APIDevGroup];


GO
ALTER ROLE [db_datawriter] ADD MEMBER [apcsuser];


GO
ALTER ROLE [db_datawriter] ADD MEMBER [ApplicationUser];


GO
ALTER ROLE [db_datawriter] ADD MEMBER [RIST\ICT DatabaseAdminsGroup];


GO
ALTER ROLE [db_datawriter] ADD MEMBER [RIST\ICT APIDevGroup];

