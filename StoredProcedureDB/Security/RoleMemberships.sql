ALTER ROLE [db_owner] ADD MEMBER [system];


GO
ALTER ROLE [db_owner] ADD MEMBER [owneruser];


GO
ALTER ROLE [db_owner] ADD MEMBER [SysAdminUser];


GO
ALTER ROLE [db_owner] ADD MEMBER [RIST\ICT DB Admins];


GO
ALTER ROLE [db_accessadmin] ADD MEMBER [RIST\ICT DatabaseAdminsGroup];


GO
ALTER ROLE [db_accessadmin] ADD MEMBER [RIST\ICT APIDevGroup];


GO
ALTER ROLE [db_securityadmin] ADD MEMBER [RIST\ICT DatabaseAdminsGroup];


GO
ALTER ROLE [db_securityadmin] ADD MEMBER [RIST\ICT APIDevGroup];


GO
ALTER ROLE [db_ddladmin] ADD MEMBER [apcsuser];


GO
ALTER ROLE [db_ddladmin] ADD MEMBER [ykuser];


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
ALTER ROLE [db_datareader] ADD MEMBER [apcsuser];


GO
ALTER ROLE [db_datareader] ADD MEMBER [system];


GO
ALTER ROLE [db_datareader] ADD MEMBER [apiuser];


GO
ALTER ROLE [db_datareader] ADD MEMBER [ykuser];


GO
ALTER ROLE [db_datareader] ADD MEMBER [ApplicationUser];


GO
ALTER ROLE [db_datareader] ADD MEMBER [RIST\ICT DatabaseAdminsGroup];


GO
ALTER ROLE [db_datareader] ADD MEMBER [RIST\ICT APIDevGroup];


GO
ALTER ROLE [db_datareader] ADD MEMBER [AppReaderUser];


GO
ALTER ROLE [db_datareader] ADD MEMBER [RIST\ICT AdminSysGroup];


GO
ALTER ROLE [db_datareader] ADD MEMBER [RIST\ICT BusinessSysGroup];


GO
ALTER ROLE [db_datareader] ADD MEMBER [RIST\ICT DataInterfaceGroup];


GO
ALTER ROLE [db_datareader] ADD MEMBER [RIST\ICT EDSSysGroup];


GO
ALTER ROLE [db_datareader] ADD MEMBER [RIST\ICT EquipmentOnlineGroup1];


GO
ALTER ROLE [db_datareader] ADD MEMBER [RIST\ICT EquipmentOnlineGroup2];


GO
ALTER ROLE [db_datareader] ADD MEMBER [RIST\ICT IoTSysGroup];


GO
ALTER ROLE [db_datareader] ADD MEMBER [RIST\ICT ProductivitySysGroup];


GO
ALTER ROLE [db_datareader] ADD MEMBER [RIST\ICT QualitySysGroup];


GO
ALTER ROLE [db_datareader] ADD MEMBER [RIST\ICT ReaderGroup];


GO
ALTER ROLE [db_datareader] ADD MEMBER [RIST\ICT SupportAppGroup];


GO
ALTER ROLE [db_datareader] ADD MEMBER [RIST\ICT SystemMaintenanceGroup];


GO
ALTER ROLE [db_datawriter] ADD MEMBER [apcsuser];


GO
ALTER ROLE [db_datawriter] ADD MEMBER [system];


GO
ALTER ROLE [db_datawriter] ADD MEMBER [apiuser];


GO
ALTER ROLE [db_datawriter] ADD MEMBER [ykuser];


GO
ALTER ROLE [db_datawriter] ADD MEMBER [ApplicationUser];


GO
ALTER ROLE [db_datawriter] ADD MEMBER [RIST\ICT DatabaseAdminsGroup];


GO
ALTER ROLE [db_datawriter] ADD MEMBER [RIST\ICT APIDevGroup];


GO
ALTER ROLE [db_datawriter] ADD MEMBER [RIST\ICT AdminSysGroup];


GO
ALTER ROLE [db_datawriter] ADD MEMBER [RIST\ICT BusinessSysGroup];


GO
ALTER ROLE [db_datawriter] ADD MEMBER [RIST\ICT DataInterfaceGroup];


GO
ALTER ROLE [db_datawriter] ADD MEMBER [RIST\ICT EDSSysGroup];


GO
ALTER ROLE [db_datawriter] ADD MEMBER [RIST\ICT EquipmentOnlineGroup1];


GO
ALTER ROLE [db_datawriter] ADD MEMBER [RIST\ICT EquipmentOnlineGroup2];


GO
ALTER ROLE [db_datawriter] ADD MEMBER [RIST\ICT IoTSysGroup];


GO
ALTER ROLE [db_datawriter] ADD MEMBER [RIST\ICT ProductivitySysGroup];


GO
ALTER ROLE [db_datawriter] ADD MEMBER [RIST\ICT QualitySysGroup];


GO
ALTER ROLE [db_datawriter] ADD MEMBER [RIST\ICT SupportAppGroup];


GO
ALTER ROLE [db_datawriter] ADD MEMBER [RIST\ICT SystemMaintenanceGroup];

