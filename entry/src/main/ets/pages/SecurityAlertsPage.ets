/**
 * RepoFlow 安全警报列表页面
 * 显示用户所有仓库的安全警报
 */

import { authManager } from '../services/AuthManager';
import { GitHubSecurityAlert } from '../models/GitHubModels';
import {
  ThemeManager,
  ThemeColors,
  Spacing,
  BorderRadius,
  FontSize,
} from '../theme';
import { RFCard } from '../components';
import { UIHelper } from '../common/ui';

@Entry
@Component
struct SecurityAlertsPage {
  @StorageLink('themeMode') themeMode: string = 'system';
  @State colors: ThemeColors = ThemeManager.colors;
  @State isDark: boolean = ThemeManager.isDark;
  @State isLoading: boolean = true;
  @State securityAlerts: GitHubSecurityAlert[] = [];
  @State errorMessage: string = '';
  @State selectedFilter: string = 'all'; // all, critical, high, medium, low

  private t(res: Resource, ...args: Array<string | number>): string {
    try {
      const rm = this.getUIContext()!.getHostContext()!.resourceManager!;
      return rm.getStringSync(res.id, ...args);
    } catch (error) {
      console.error('Resource loading failed:', error);
      return '';
    }
  }

  aboutToAppear(): void {
    // 订阅主题变化
    ThemeManager.subscribe((colors: ThemeColors, isDark: boolean): void => {
      this.colors = colors;
      this.isDark = isDark;
    });

    this.loadSecurityAlerts();
  }

  async loadSecurityAlerts(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';

    try {
      const api = authManager.getGitHubApi();
      if (!api) {
        this.errorMessage = this.t($r('app.string.please_login'));
        this.isLoading = false;
        return;
      }

      // 使用API方法获取所有安全警报（内部已遍历仓库）
      const alerts: GitHubSecurityAlert[] = await api.getSecurityAlerts('open', 1, 100);

      // 按严重程度排序
      this.securityAlerts = alerts.sort((a: GitHubSecurityAlert, b: GitHubSecurityAlert): number => {
        const severityOrder: Record<string, number> = { 'critical': 0, 'high': 1, 'medium': 2, 'low': 3 };
        const aOrder = severityOrder[a.security_advisory.severity] ?? 4;
        const bOrder = severityOrder[b.security_advisory.severity] ?? 4;
        return aOrder - bOrder;
      });

    } catch (error) {
      this.errorMessage = this.t($r('app.string.load_security_failed'));
    } finally {
      this.isLoading = false;
    }
  }

  getFilteredAlerts(): GitHubSecurityAlert[] {
    if (this.selectedFilter === 'all') {
      return this.securityAlerts;
    }
    return this.securityAlerts.filter(alert =>
      alert.security_advisory.severity === this.selectedFilter
    );
  }

  getSeverityColor(severity: string): ResourceColor {
    switch (severity) {
      case 'critical': return this.colors.error;
      case 'high': return '#F97316';
      case 'medium': return this.colors.warning;
      default: return this.colors.textTertiary;
    }
  }

  getSeverityIcon(severity: string): string {
    switch (severity) {
      case 'critical': return '!!';
      case 'high': return '!';
      case 'medium': return '•';
      default: return '·';
    }
  }

  getSeverityLabel(severity: string): string {
    switch (severity) {
      case 'critical': return this.t($r('app.string.security_severity_critical'));
      case 'high': return this.t($r('app.string.security_severity_high'));
      case 'medium': return this.t($r('app.string.security_severity_medium'));
      case 'low': return this.t($r('app.string.security_severity_low'));
      default: return this.t($r('app.string.security_severity_unknown'));
    }
  }

  getCountBySeverity(severity: string): number {
    return this.securityAlerts.filter(a => a.security_advisory.severity === severity).length;
  }

  @Builder
  FilterTabs() {
    Row({ space: Spacing.XS }) {
      this.FilterTab('all', this.t($r('app.string.security_filter_all'), this.securityAlerts.length))
      this.FilterTab('critical', this.t($r('app.string.security_filter_critical'), this.getCountBySeverity('critical')))
      this.FilterTab('high', this.t($r('app.string.security_filter_high'), this.getCountBySeverity('high')))
      this.FilterTab('medium', this.t($r('app.string.security_filter_medium'), this.getCountBySeverity('medium')))
    }
    .width('100%')
    .padding({ left: Spacing.MD, right: Spacing.MD })
  }

  @Builder
  FilterTab(filter: string, label: string) {
    Text(label)
      .fontSize(FontSize.SM)
      .fontColor(this.selectedFilter === filter ? this.colors.brandPrimary : this.colors.textSecondary)
      .fontWeight(this.selectedFilter === filter ? FontWeight.Medium : FontWeight.Normal)
      .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XS, bottom: Spacing.XS })
      .backgroundColor(this.selectedFilter === filter ? this.colors.primaryContainer : 'transparent')
      .borderRadius(BorderRadius.FULL)
      .onClick(() => {
        this.selectedFilter = filter;
      })
  }

  @Builder
  AlertItem(alert: GitHubSecurityAlert) {
    Column({ space: Spacing.SM }) {
      Row({ space: Spacing.SM }) {
        // 严重程度标记
        Column() {
          Text(this.getSeverityIcon(alert.security_advisory.severity))
            .fontSize(12)
            .fontColor(Color.White)
        }
        .width(28)
        .height(28)
        .borderRadius(14)
        .backgroundColor(this.getSeverityColor(alert.security_advisory.severity))
        .justifyContent(FlexAlign.Center)

        Column({ space: 2 }) {
          Text(alert.security_advisory.summary)
            .fontSize(FontSize.MD)
            .fontColor(this.colors.textPrimary)
            .fontWeight(FontWeight.Medium)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Row({ space: Spacing.XS }) {
            Text(this.getSeverityLabel(alert.security_advisory.severity))
              .fontSize(FontSize.XS)
              .fontColor(this.getSeverityColor(alert.security_advisory.severity))
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .backgroundColor(this.getSeverityColor(alert.security_advisory.severity))
              .opacity(0.1)
              .borderRadius(4)

            Text(`${alert.repository?.full_name || ''}`)
              .fontSize(FontSize.XS)
              .fontColor(this.colors.textSecondary)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Image($r('app.media.ic_chevron_right'))
          .width(16)
          .height(16)
          .fillColor(this.colors.textTertiary)
      }
      .width('100%')

      // 依赖信息
      Row({ space: Spacing.XS }) {
        Text('📦')
          .fontSize(12)
        Text(`${alert.dependency.package.name}`)
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textSecondary)
        if (alert.dependency.package.ecosystem) {
          Text(`(${alert.dependency.package.ecosystem})`)
            .fontSize(FontSize.XS)
            .fontColor(this.colors.textTertiary)
        }
      }
    }
    .width('100%')
    .padding(Spacing.MD)
    .backgroundColor(this.colors.bgSecondary)
    .borderRadius(BorderRadius.MD)
    .onClick(() => {
      UIHelper.pushUrl(this, 'pages/SecurityAlertDetailPage', {
        alert: alert,
        owner: alert.repository?.owner?.login || '',
        repo: alert.repository?.name || ''
      });
    })
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .fillColor(this.colors.textPrimary)
          .onClick(() => {
            UIHelper.goBack(this);
          })

        Text($r('app.string.security_alerts'))
          .fontSize(FontSize.LG)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textPrimary)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 占位保持居中
        Column().width(24)
      }
      .width('100%')
      .height(56)
      .padding({ left: Spacing.MD, right: Spacing.MD })

      if (this.isLoading) {
        // 加载中
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color(this.colors.brandPrimary)
          Text($r('app.string.loading_security_alerts'))
            .fontSize(FontSize.SM)
            .fontColor(this.colors.textSecondary)
            .margin({ top: Spacing.MD })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.errorMessage) {
        // 错误提示
        Column() {
          Text('⚠️')
            .fontSize(48)
          Text(this.errorMessage)
            .fontSize(FontSize.MD)
            .fontColor(this.colors.textSecondary)
            .margin({ top: Spacing.MD })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.securityAlerts.length === 0) {
        // 无警报
        Column() {
          Text('✅')
            .fontSize(48)
          Text($r('app.string.no_security_alerts'))
            .fontSize(FontSize.MD)
            .fontColor(this.colors.textSecondary)
            .margin({ top: Spacing.MD })
          Text($r('app.string.all_repos_safe'))
            .fontSize(FontSize.SM)
            .fontColor(this.colors.textTertiary)
            .margin({ top: Spacing.XS })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 过滤标签
        this.FilterTabs()

        // 警报列表
        List({ space: Spacing.SM }) {
          ForEach(this.getFilteredAlerts(), (alert: GitHubSecurityAlert) => {
            ListItem() {
              this.AlertItem(alert)
            }
          }, (alert: GitHubSecurityAlert) => `${alert.number}_${alert.security_advisory.ghsa_id}`)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: Spacing.MD, right: Spacing.MD, top: Spacing.MD })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.bgPrimary)
  }
}
