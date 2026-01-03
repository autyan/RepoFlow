/**
 * RepoFlow 安全警报详情页面
 * 显示单个安全警报的详细信息
 */

import { GitHubSecurityAlert } from '../models/GitHubModels';
import {
  ThemeManager,
  ThemeColors,
  Spacing,
  BorderRadius,
  FontSize,
} from '../theme';
import { RFCard, RFButton } from '../components';
import { UIHelper } from '../common/ui';

interface PageParams {
  alert: GitHubSecurityAlert;
  owner: string;
  repo: string;
}

@Entry
@Component
struct SecurityAlertDetailPage {
  @StorageLink('themeMode') themeMode: string = 'system';
  @State colors: ThemeColors = ThemeManager.colors;
  @State isDark: boolean = ThemeManager.isDark;
  @State alert: GitHubSecurityAlert | null = null;
  @State owner: string = '';
  @State repo: string = '';

  aboutToAppear(): void {
    // 订阅主题变化
    ThemeManager.subscribe((colors: ThemeColors, isDark: boolean): void => {
      this.colors = colors;
      this.isDark = isDark;
    });

    this.loadParams();
  }

  private loadParams(): void {
    const params = this.getUIContext()!.getRouter()!.getParams() as PageParams;
    if (params) {
      this.alert = params.alert;
      this.owner = params.owner;
      this.repo = params.repo;
    }
  }

  getSeverityColor(severity: string): ResourceColor {
    switch (severity) {
      case 'critical': return this.colors.error;
      case 'high': return '#F97316';
      case 'medium': return this.colors.warning;
      default: return this.colors.textTertiary;
    }
  }

  getSeverityLabel(severity: string): string {
    switch (severity) {
      case 'critical': return '严重';
      case 'high': return '高危';
      case 'medium': return '中危';
      case 'low': return '低危';
      default: return '未知';
    }
  }

  formatDate(dateStr: string): string {
    if (!dateStr) return '';
    const date = new Date(dateStr);
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
  }

  @Builder
  InfoSection(title: string, content: string) {
    Column({ space: Spacing.XS }) {
      Text(title)
        .fontSize(FontSize.SM)
        .fontColor(this.colors.textSecondary)
      Text(content)
        .fontSize(FontSize.MD)
        .fontColor(this.colors.textPrimary)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ top: Spacing.SM, bottom: Spacing.SM })
  }

  @Builder
  SeverityBadge() {
    if (this.alert) {
      Row({ space: Spacing.XS }) {
        Text(this.getSeverityLabel(this.alert.security_advisory.severity))
          .fontSize(FontSize.SM)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
          .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XXS, bottom: Spacing.XXS })
          .backgroundColor(this.getSeverityColor(this.alert.security_advisory.severity))
          .borderRadius(BorderRadius.SM)
      }
    }
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

        Text($r('app.string.alert_details'))
          .fontSize(FontSize.LG)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textPrimary)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Column().width(24)
      }
      .width('100%')
      .height(56)
      .padding({ left: Spacing.MD, right: Spacing.MD })

      if (this.alert) {
        Scroll() {
          Column({ space: Spacing.MD }) {
            // 标题区域
            RFCard({
              variant: 'filled',
              colors: this.colors,
              content: (): void => this.HeaderContent()
            })

            // 漏洞信息
            RFCard({
              variant: 'outlined',
              colors: this.colors,
              content: (): void => this.VulnerabilityContent()
            })

            // 依赖信息
            RFCard({
              variant: 'outlined',
              colors: this.colors,
              content: (): void => this.DependencyContent()
            })

            // 修复建议
            if (this.alert.security_vulnerability?.first_patched_version) {
              RFCard({
                variant: 'outlined',
                colors: this.colors,
                customBgColor: this.colors.successBg,
                content: (): void => this.FixContent()
              })
            }
          }
          .padding(Spacing.MD)
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      } else {
        // 无数据
        Column() {
          Text($r('app.string.cannot_load_alert'))
            .fontSize(FontSize.MD)
            .fontColor(this.colors.textSecondary)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.bgPrimary)
  }

  @Builder
  HeaderContent() {
    Column({ space: Spacing.SM }) {
      Row({ space: Spacing.SM }) {
        this.SeverityBadge()
        Text(`#${this.alert?.number}`)
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textSecondary)
      }
      .width('100%')

      Text(this.alert?.security_advisory.summary || '')
        .fontSize(FontSize.LG)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.colors.textPrimary)

      Row({ space: Spacing.XS }) {
        Text('📁')
          .fontSize(14)
        Text(`${this.owner}/${this.repo}`)
          .fontSize(FontSize.SM)
          .fontColor(this.colors.brandPrimary)
      }

      if (this.alert?.created_at) {
        Row({ space: Spacing.XS }) {
          Text('📅')
            .fontSize(14)
          Text(`发现时间: ${this.formatDate(this.alert.created_at)}`)
            .fontSize(FontSize.SM)
            .fontColor(this.colors.textSecondary)
        }
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  VulnerabilityContent() {
    Column({ space: Spacing.SM }) {
      Text($r('app.string.vulnerability_info'))
        .fontSize(FontSize.MD)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textPrimary)

      Divider()
        .color(this.colors.border)

      this.InfoSection('GHSA ID', this.alert?.security_advisory.ghsa_id || '-')

      if (this.alert?.security_advisory.cve_id) {
        this.InfoSection('CVE ID', this.alert.security_advisory.cve_id)
      }

      if (this.alert?.security_advisory.description) {
        Column({ space: Spacing.XS }) {
          Text($r('app.string.description'))
            .fontSize(FontSize.SM)
            .fontColor(this.colors.textSecondary)
          Text(this.alert.security_advisory.description)
            .fontSize(FontSize.SM)
            .fontColor(this.colors.textPrimary)
            .lineHeight(20)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ top: Spacing.SM, bottom: Spacing.SM })
      }

      if (this.alert?.security_vulnerability?.vulnerable_version_range) {
        this.InfoSection('受影响版本', this.alert.security_vulnerability.vulnerable_version_range)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  DependencyContent() {
    Column({ space: Spacing.SM }) {
      Text($r('app.string.affected_dependency'))
        .fontSize(FontSize.MD)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textPrimary)

      Divider()
        .color(this.colors.border)

      this.InfoSection('包名称', this.alert?.dependency.package.name || '-')

      if (this.alert?.dependency.package.ecosystem) {
        this.InfoSection('生态系统', this.alert.dependency.package.ecosystem)
      }

      if (this.alert?.dependency.manifest_path) {
        this.InfoSection('清单文件', this.alert.dependency.manifest_path)
      }

      if (this.alert?.dependency.scope) {
        this.InfoSection('作用域', this.alert.dependency.scope)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  FixContent() {
    Column({ space: Spacing.SM }) {
      Row({ space: Spacing.SM }) {
        Text('✅')
          .fontSize(20)
        Text($r('app.string.fix_suggestion'))
          .fontSize(FontSize.MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.success)
      }
      .width('100%')

      Divider()
        .color(this.colors.border)

      Column({ space: Spacing.XS }) {
        Text($r('app.string.upgrade_to_fix'))
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textSecondary)
        Text(this.alert?.security_vulnerability?.first_patched_version?.identifier || '-')
          .fontSize(FontSize.LG)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.success)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ top: Spacing.SM })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
