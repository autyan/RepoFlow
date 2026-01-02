/**
 * 创建 Issue 页面
 * 
 * 功能:
 * - 创建新的 GitHub Issue
 * - 支持标题和描述输入
 * - 支持响应式布局和主题切换
 */

import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { authManager } from '../services/AuthManager';
import {
  ThemeManager,
  ThemeColors,
  ResponsiveManager,
  ResponsiveState,
  Spacing,
  BorderRadius,
  FontSize,
  LayoutMode,
  DeviceType,
} from '../theme';
import {
  RFCard,
  RFButton,
} from '../components';

interface RouteParams {
  owner: string;
  repo: string;
}

// =====================================================
// 创建 Issue 页面
// =====================================================
@Entry
@Component
struct CreateIssuePage {
  // 数据状态
  @State title: string = '';
  @State body: string = '';
  @State isSubmitting: boolean = false;

  private owner: string = '';
  private repoName: string = '';

  // 主题状态
  @State colors: ThemeColors = ThemeManager.colors;
  @State isDark: boolean = ThemeManager.isDark;

  // 响应式状态
  @State layoutMode: LayoutMode = ResponsiveManager.state.layoutMode;
  @State deviceType: DeviceType = ResponsiveManager.state.deviceType;

  // =====================================================
  // 生命周期
  // =====================================================

  aboutToAppear(): void {
    // 订阅主题变化
    ThemeManager.subscribe((colors: ThemeColors, isDark: boolean): void => {
      this.colors = colors;
      this.isDark = isDark;
    });

    // 订阅响应式变化
    ResponsiveManager.subscribe((state: ResponsiveState): void => {
      this.layoutMode = state.layoutMode;
      this.deviceType = state.deviceType;
    });

    const params = router.getParams() as RouteParams | undefined;
    if (params) {
      this.owner = params.owner;
      this.repoName = params.repo;
    }
  }

  // =====================================================
  // 数据提交
  // =====================================================

  async submitIssue(): Promise<void> {
    if (!this.title.trim()) {
      promptAction.showToast({ message: getContext(this).resourceManager.getStringSync($r('app.string.please_input_title').id) });
      return;
    }

    this.isSubmitting = true;
    const api = authManager.getGitHubApi();
    if (!api) {
      promptAction.showToast({ message: getContext(this).resourceManager.getStringSync($r('app.string.please_login').id) });
      this.isSubmitting = false;
      return;
    }

    try {
      const issue = await api.createIssue(this.owner, this.repoName, this.title.trim(), this.body.trim() || undefined);
      promptAction.showToast({ message: getContext(this).resourceManager.getStringSync($r('app.string.issue_created').id) });
      router.back();
    } catch (err) {
      promptAction.showToast({ message: getContext(this).resourceManager.getStringSync($r('app.string.create_failed').id) });
      console.error('Create issue failed:', JSON.stringify(err));
    } finally {
      this.isSubmitting = false;
    }
  }

  // =====================================================
  // UI 构建器
  // =====================================================

  // 页面头部
  @Builder
  PageHeader() {
    Row() {
      Row() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .fillColor(this.colors.textPrimary)
      }
      .width(40)
      .height(40)
      .justifyContent(FlexAlign.Center)
      .onClick((): void => {
        router.back();
      })

      Text($r('app.string.new_issue'))
        .fontSize(FontSize.XL)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textPrimary)
        .layoutWeight(1)

      // 提交按钮
      if (this.isSubmitting) {
        LoadingProgress()
          .width(24)
          .height(24)
          .margin({ right: Spacing.SM })
      } else {
        Text($r('app.string.submit'))
          .fontSize(FontSize.LG)
          .fontColor(this.title.trim() ? this.colors.brandPrimary : this.colors.textSecondary)
          .margin({ right: Spacing.SM })
          .onClick((): void => {
            if (this.title.trim()) {
              this.submitIssue();
            }
          })
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.SM, right: Spacing.SM })
    .backgroundColor(this.colors.bgPrimary)
    .border({ width: { bottom: 1 }, color: this.colors.border })
  }

  // 仓库信息
  @Builder
  RepoInfo() {
    Row({ space: Spacing.SM }) {
      Image($r('app.media.ic_repo'))
        .width(16)
        .height(16)
        .fillColor(this.colors.textSecondary)

      Text(`${this.owner}/${this.repoName}`)
        .fontSize(FontSize.MD)
        .fontColor(this.colors.textSecondary)
    }
    .width('100%')
    .padding({ left: Spacing.MD, right: Spacing.MD, top: Spacing.MD, bottom: Spacing.MD })
    .backgroundColor(this.colors.bgSecondary)
  }

  // 表单内容
  @Builder
  FormContent() {
    Column({ space: Spacing.LG }) {
      // 标题输入
      Column({ space: Spacing.SM }) {
        Text($r('app.string.title_required'))
          .fontSize(FontSize.MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textPrimary)

        TextInput({ placeholder: $r('app.string.input_issue_title'), text: this.title })
          .width('100%')
          .height(44)
          .backgroundColor(this.colors.surface)
          .borderRadius(BorderRadius.MD)
          .border({ width: 1, color: this.colors.border })
          .onChange((value: string): void => {
            this.title = value;
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 描述输入
      Column({ space: Spacing.SM }) {
        Text($r('app.string.description_optional_markdown'))
          .fontSize(FontSize.MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textPrimary)

        TextArea({ placeholder: $r('app.string.describe_issue'), text: this.body })
          .width('100%')
          .height(200)
          .backgroundColor(this.colors.surface)
          .borderRadius(BorderRadius.MD)
          .border({ width: 1, color: this.colors.border })
          .onChange((value: string): void => {
            this.body = value;
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 提示
      Column({ space: Spacing.SM }) {
        Text($r('app.string.tips_title'))
          .fontSize(FontSize.SM)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textSecondary)

        Text($r('app.string.tips_clear_title'))
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textSecondary)

        Text($r('app.string.tips_detail_desc'))
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textSecondary)

        Text($r('app.string.tips_markdown_support'))
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textSecondary)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(Spacing.MD)
      .backgroundColor(this.colors.bgSecondary)
      .borderRadius(BorderRadius.MD)
    }
    .width('100%')
    .padding(Spacing.MD)
    .layoutWeight(1)
  }

  // =====================================================
  // 主构建方法
  // =====================================================

  build() {
    Column() {
      // 页面头部
      this.PageHeader()

      // 仓库信息
      this.RepoInfo()

      // 表单内容 - 在大屏设备上限制最大宽度
      if (this.layoutMode !== LayoutMode.SINGLE) {
        Row() {
          Blank()
          Column() {
            this.FormContent()
          }
          .width(600)
          Blank()
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        this.FormContent()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.bgPrimary)
  }
}
