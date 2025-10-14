CREATE VIEW dbo.[view_scheduler_operation_record_base_v05old]
AS
SELECT            t1.lot_id, CONVERT(nvarchar, t1.lot_no) AS lot_no, t1.job, CASE WHEN re.recorded_at IS NULL THEN N'MS' ELSE N'MF' END AS REC_STATUS, format(t1.recorded_at, N'yyyy/MM/dd HH:mm:ss') AS STARTTIME, 
                        ISNULL(format(re.recorded_at, N'yyyy/MM/dd HH:mm:ss'), N' ') AS ENDTIME, t1.machine, CASE WHEN re.recorded_at IS NULL THEN t1.qty_progress ELSE t1.input_quantity END AS Quantity, 
                        ISNULL(re.extend_data.value('(/LotDataCommon/SetupRecord/TesterType)[1]', 'nvarchar(50)'), '') AS TesterType, ISNULL(re.extend_data.value('(/LotDataCommon/SetupRecord/TesterChA)[1]', 'nvarchar(50)'), '') AS TesterChA, 
                        ISNULL(REPLACE(re.extend_data.value('(/LotDataCommon/SetupRecord/BoxNamChA)[1]', 'nvarchar(50)'), ' ', ''), '') AS BoxNamChA, ISNULL(re.extend_data.value('(/LotDataCommon/SetupRecord/FtbChA)[1]', 'nvarchar(50)'), '') 
                        AS FtbChA
FROM              (SELECT            l.id AS lot_id, RTRIM(l.lot_no) AS lot_no, RTRIM(p.name) AS package, RTRIM(d.name) AS device, r.record_class, r.job_id, j.name AS job, r.recorded_at, l.qty_last_pass + l.qty_last_fail AS qty_progress, 
                                                 mc.name AS machine, r.qty_pass AS input_quantity
                         FROM              APCSProDB.method.packages AS p WITH (NOLOCK) INNER JOIN
                                                 APCSProDB.method.device_names AS d WITH (NOLOCK) ON d.package_id = p.id AND d.is_assy_only IN (0, 1) AND NOT EXISTS
                                                     (SELECT            alias_package_group_name, package_name, original_package_group_name, target_device, device_name_id
                                                        FROM              dbo.view_alias_package_group_devices AS va WITH (NOLOCK)
                                                        WHERE             (device_name_id = d.id)) INNER JOIN
                                                 APCSProDB.trans.lots AS l WITH (NOLOCK) ON l.wip_state = 20 AND l.act_device_name_id = d.id AND l.quality_state IN (0) AND ISNULL(l.is_special_flow, 0) = 0 INNER JOIN
                                                 APCSProDB.trans.lot_process_records AS r WITH (NOLOCK) ON r.lot_id = l.id AND r.record_class IN (1) AND r.recorded_at > DATEADD(day, - 1, GETDATE()) INNER JOIN
                                                 APCSProDB.method.jobs AS j WITH (NOLOCK) ON j.id = r.job_id AND j.id IN (87, 106, 108, 110, 119, 87, 88, 92, 93, 278) INNER JOIN
                                                 APCSProDB.mc.machines AS mc WITH (NOLOCK) ON mc.id = r.machine_id
                         WHERE             (p.id = 242)) AS t1 LEFT OUTER JOIN
                        APCSProDB.trans.lot_process_records AS re WITH (NOLOCK) ON re.lot_id = t1.lot_id AND re.recorded_at > t1.recorded_at AND re.record_class IN (2) AND re.job_id = t1.job_id AND NOT EXISTS
                            (SELECT            id
                               FROM              APCSProDB.trans.lot_process_records AS r2 WITH (NOLOCK)
                               WHERE             (lot_id = re.lot_id) AND (job_id = re.job_id) AND (record_class = 2) AND (recorded_at > t1.recorded_at) AND (recorded_at < re.recorded_at))

GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPane1', @value = N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "t1"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 211
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "re"
            Begin Extent = 
               Top = 6
               Left = 237
               Bottom = 136
               Right = 453
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 8820
         Alias = 11490
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'view_scheduler_operation_record_base_v05old';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPaneCount', @value = 1, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'view_scheduler_operation_record_base_v05old';

