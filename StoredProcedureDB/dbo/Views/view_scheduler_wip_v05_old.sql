CREATE VIEW dbo.[view_scheduler_wip_v05_old]
AS
SELECT            RTRIM(l.lot_no) AS LOTNO, RTRIM(p.name) AS PACKAGE, RTRIM(d.name) AS DEVICE, l.qty_pass AS QTY, format(dy.date_value, N'yyyy/MM/dd') AS DELIVERY, 100 - ISNULL(l.priority, 50) AS PRIORITY
FROM              APCSProDB.method.packages AS p WITH (NOLOCK) INNER JOIN
                        APCSProDB.method.device_names AS d WITH (NOLOCK) ON d.package_id = p.id AND d.is_assy_only IN (0, 1) AND NOT EXISTS
                            (SELECT            alias_package_group_name, package_name, original_package_group_name, target_device, device_name_id
                               FROM              dbo.view_alias_package_group_devices AS va WITH (NOLOCK)
                               WHERE             (device_name_id = d.id)) INNER JOIN
                        APCSProDB.trans.lots AS l WITH (NOLOCK) ON l.wip_state = 20 AND l.act_device_name_id = d.id AND l.quality_state IN (0) AND ISNULL(l.is_special_flow, 0) = 0 INNER JOIN
                        APCSProDB.trans.days AS dy WITH (NOLOCK) ON dy.id = l.out_plan_date_id INNER JOIN
                        APCSProDB.method.jobs AS j WITH (NOLOCK) ON j.id = l.act_job_id
WHERE             (p.id = 242) AND (j.id IN (87, 106, 108, 110, 119, 87, 88, 92, 93, 278)) AND (l.process_state IN (0, 1)) OR
                        (l.id IN
                            (SELECT            lot_id
                               FROM              dbo.view_scheduler_wip_from_result_v05))

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
         Begin Table = "p"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 284
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "d"
            Begin Extent = 
               Top = 6
               Left = 322
               Bottom = 136
               Right = 549
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "l"
            Begin Extent = 
               Top = 6
               Left = 587
               Bottom = 136
               Right = 823
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "dy"
            Begin Extent = 
               Top = 138
               Left = 38
               Bottom = 268
               Right = 199
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "j"
            Begin Extent = 
               Top = 138
               Left = 237
               Bottom = 268
               Right = 433
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
         Column = 2610
         Alias = 1110
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
', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'view_scheduler_wip_v05_old';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPaneCount', @value = 1, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'view_scheduler_wip_v05_old';

