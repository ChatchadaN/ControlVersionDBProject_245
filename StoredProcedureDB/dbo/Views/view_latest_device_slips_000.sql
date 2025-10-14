CREATE VIEW dbo.view_latest_device_slips_000
AS
SELECT            p.name AS package, s.device_slip_id, RTRIM(d.name) AS device_name, d.id AS device_name_id, d.official_number
FROM              APCSProDB.method.packages AS p WITH (NOLOCK) INNER JOIN
                        APCSProDB.method.device_names AS d WITH (NOLOCK) ON d.package_id = p.id INNER JOIN
                        APCSProDB.method.device_versions AS v WITH (NOLOCK) ON v.device_name_id = d.id INNER JOIN
                        APCSProDB.method.device_slips AS s WITH (NOLOCK) ON s.device_id = v.device_id AND s.is_released = 1 AND NOT EXISTS
                            (SELECT            device_slip_id, device_id, version_num, package_slip_id, tp_code, os_program_name, sub_rank, temporary_char, comments, is_released, normal_leadtime_minutes, lead_time_sum, created_at, created_by, 
                                                       updated_at, updated_by, is_inherited
                               FROM              APCSProDB.method.device_slips AS s2 WITH (NOLOCK)
                               WHERE             (device_id = s.device_id) AND (is_released = 1) AND (version_num > s.version_num))
WHERE             (p.id = 242)
GROUP BY      p.name, s.device_slip_id, d.name, d.id, d.official_number

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
               Right = 300
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "d"
            Begin Extent = 
               Top = 6
               Left = 338
               Bottom = 136
               Right = 581
            End
            DisplayFlags = 280
            TopColumn = 12
         End
         Begin Table = "v"
            Begin Extent = 
               Top = 6
               Left = 619
               Bottom = 136
               Right = 873
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "s"
            Begin Extent = 
               Top = 6
               Left = 911
               Bottom = 136
               Right = 1169
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
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
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
', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'view_latest_device_slips_000';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPaneCount', @value = 1, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'view_latest_device_slips_000';

