/**
 * 首页 - 开发者工作流
 * 
 * 功能:
 * - 显示待办事项 (指派给我的 Issues/PRs)
 * - 显示我的活动历史
 * - 安全警报提醒
 * - 快速访问常用功能
 * 支持响应式布局和主题切换
 */

import router from '@ohos.router';
import { userState } from '../common/state/UserState';
import { authManager } from '../services/AuthManager';
import { GitHubUser, GitHubIssue, GitHubEvent, GitHubSecurityAlert } from '../models/GitHubModels';
import { tabState } from '../common/state/TabState';
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
  RFAvatar,
  RFSplitView,
} from '../components';

// =====================================================
// 首页组件
// =====================================================
@Component
export default struct HomePage {
  // 数据状态
  @State user: GitHubUser | null = null;
  @State isLoggedIn: boolean = false;
  @State assignedIssues: GitHubIssue[] = [];
  @State myEvents: GitHubEvent[] = [];
  @State securityAlerts: GitHubSecurityAlert[] = [];
  @State isLoading: boolean = false;
  @State activeTab: 'assigned' | 'created' | 'mentioned' = 'assigned';

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
    this.syncState();

    // 订阅用户状态变化
    userState.addListener((): void => {
      this.syncState();
    });

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
  }

  syncState(): void {
    this.user = userState.user;
    this.isLoggedIn = userState.isLoggedIn;
    if (this.isLoggedIn && this.assignedIssues.length === 0) {
      this.loadWorkflowData();
    }
  }

  async loadWorkflowData(): Promise<void> {
    const api = authManager.getGitHubApi();
    if (!api || !this.user) return;

    this.isLoading = true;
    try {
      // 加载待办事项
      this.assignedIssues = await api.getAssignedIssues('open', 1, 10);
      // 加载用户活动
      this.myEvents = await api.getUserEvents(this.user.login, 1, 15);
      
      // 异步加载安全警报 (可能较慢)
      this.loadSecurityAlerts();
    } catch (error) {
      console.error('Failed to load workflow data:', JSON.stringify(error));
    } finally {
      this.isLoading = false;
    }
  }

  async loadSecurityAlerts(): Promise<void> {
    const api = authManager.getGitHubApi();
    if (!api) return;

    try {
      this.securityAlerts = await api.getSecurityAlerts('open', 1, 5);
    } catch (error) {
      console.error('Failed to load security alerts:', JSON.stringify(error));
    }
  }

  async loadIssuesByFilter(): Promise<void> {
    const api = authManager.getGitHubApi();
    if (!api) return;

    this.isLoading = true;
    try {
      switch (this.activeTab) {
        case 'assigned':
          this.assignedIssues = await api.getAssignedIssues('open', 1, 10);
          break;
        case 'created':
          this.assignedIssues = await api.getCreatedIssues('open', 1, 10);
          break;
        case 'mentioned':
          this.assignedIssues = await api.getMentionedIssues('open', 1, 10);
          break;
      }
    } catch (error) {
      console.error('Failed to load issues:', JSON.stringify(error));
    } finally {
      this.isLoading = false;
    }
  }

  // =====================================================
  // UI 构建器
  // =====================================================

  // 欢迎区 (简化版)
  @Builder
  WelcomeHeader() {
    Row({ space: Spacing.MD }) {
      if (this.isLoggedIn && this.user) {
        RFAvatar({
          src: this.user.avatar_url,
          avatarSize: 'lg',
          colors: this.colors
        })

        Column({ space: Spacing.XXS }) {
          Text($r('app.string.welcome_user', this.user.name || this.user.login))
            .fontSize(FontSize.LG)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textPrimary)
          Text(this.getGreeting())
            .fontSize(FontSize.SM)
            .fontColor(this.colors.textSecondary)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      } else {
        Column() {
          Image($r('app.media.github_mark'))
            .width(28)
            .height(28)
            .fillColor(this.colors.textSecondary)
        }
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor(this.colors.surfaceVariant)
        .justifyContent(FlexAlign.Center)

        Column({ space: Spacing.XXS }) {
          Text($r('app.string.settings_brand'))
            .fontSize(FontSize.LG)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textPrimary)
          Text($r('app.string.app_description'))
            .fontSize(FontSize.SM)
            .fontColor(this.colors.textSecondary)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
    }
    .width('100%')
  }

  getGreeting(): Resource {
    const hour = new Date().getHours();
    if (hour < 12) return $r('app.string.greeting_morning');
    if (hour < 18) return $r('app.string.greeting_afternoon');
    return $r('app.string.greeting_evening');
  }

  // 登录引导
  @Builder
  LoginPrompt() {
    RFCard({
      variant: 'filled',
      colors: this.colors,
      customBgColor: this.colors.primaryContainer,
      content: (): void => this.LoginPromptContent()
    })
  }

  @Builder
  LoginPromptContent() {
    Column({ space: Spacing.SM }) {
      Text($r('app.string.get_started'))
        .fontSize(FontSize.LG)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.brandPrimary)

      Text($r('app.string.login_description'))
        .fontSize(FontSize.MD)
        .fontColor(this.colors.textSecondary)
        .lineHeight(22)

      RFButton({
        text: $r('app.string.login_github'),
        variant: 'primary',
        buttonSize: 'md',
        fullWidth: true,
        colors: this.colors,
        onTap: (): void => {
          router.pushUrl({ url: 'pages/LoginPage' });
        }
      })
        .margin({ top: Spacing.XS })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // 安全警报卡片
  @Builder
  SecurityAlertsCard() {
    if (this.securityAlerts.length > 0) {
      RFCard({
        variant: 'outlined',
        colors: this.colors,
        content: (): void => this.SecurityAlertsContent()
      })
    }
  }

  @Builder
  SecurityAlertsContent() {
    Column({ space: Spacing.SM }) {
      Row({ space: Spacing.SM }) {
        Image($r('app.media.ic_warning'))
          .width(20)
          .height(20)
          .fillColor(this.colors.error)

        Text($r('app.string.security_alerts'))
          .fontSize(FontSize.MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.error)

        Blank()

        Row({ space: Spacing.XS }) {
          Text(`${this.securityAlerts.length}`)
            .fontSize(FontSize.SM)
            .fontColor(this.colors.error)
            .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XXS, bottom: Spacing.XXS })
            .backgroundColor('#FFEBEE')
            .borderRadius(BorderRadius.FULL)

          Text($r('app.string.view_all_alerts'))
            .fontSize(FontSize.SM)
            .fontColor(this.colors.brandPrimary)
        }
        .onClick(() => {
          router.pushUrl({
            url: 'pages/SecurityAlertsPage'
          });
        })
      }
      .width('100%')

      ForEach(this.securityAlerts.slice(0, 3), (alert: GitHubSecurityAlert) => {
        this.SecurityAlertItem(alert)
      }, (alert: GitHubSecurityAlert) => `${alert.security_advisory.ghsa_id}`)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  SecurityAlertItem(alert: GitHubSecurityAlert) {
    Row({ space: Spacing.SM }) {
      Column() {
        Text(this.getSeverityIcon(alert.security_advisory.severity))
          .fontSize(12)
      }
      .width(24)
      .height(24)
      .borderRadius(12)
      .backgroundColor(this.getSeverityColor(alert.security_advisory.severity))
      .justifyContent(FlexAlign.Center)

      Column({ space: 2 }) {
        Text(alert.security_advisory.summary)
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${alert.repository?.full_name || ''} · ${alert.dependency.package.name}`)
          .fontSize(FontSize.XS)
          .fontColor(this.colors.textSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Image($r('app.media.ic_chevron_right'))
        .width(16)
        .height(16)
        .fillColor(this.colors.textTertiary)
    }
    .width('100%')
    .padding({ top: Spacing.XS, bottom: Spacing.XS })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/SecurityAlertDetailPage',
        params: {
          alert: alert,
          owner: alert.repository?.owner?.login || '',
          repo: alert.repository?.name || ''
        }
      });
    })
  }

  getSeverityIcon(severity: string): string {
    switch (severity) {
      case 'critical': return '!!'
      case 'high': return '!'
      case 'medium': return '•'
      default: return '·'
    }
  }

  getSeverityColor(severity: string): ResourceColor {
    switch (severity) {
      case 'critical': return this.colors.error;
      case 'high': return '#F97316'; // orange
      case 'medium': return this.colors.warning;
      default: return this.colors.textTertiary;
    }
  }

  // 待办事项卡片 (指派给我的 Issues)
  @Builder
  TodoCard() {
    RFCard({
      variant: 'elevated',
      colors: this.colors,
      content: (): void => this.TodoContent()
    })
  }

  @Builder
  TodoContent() {
    Column({ space: Spacing.SM }) {
      // 标题行
      Row() {
        Text($r('app.string.todo_items'))
          .fontSize(FontSize.LG)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textPrimary)

        Blank()

        if (this.assignedIssues.length > 0) {
          Text(getContext(this).resourceManager.getStringSync($r('app.string.items_count').id)
            .replace('%d', this.assignedIssues.length.toString()))
            .fontSize(FontSize.SM)
            .fontColor(this.colors.textSecondary)
        }
      }
      .width('100%')

      // 筛选标签
      Row({ space: Spacing.SM }) {
        this.FilterTab('assigned', $r('app.string.assigned'))
        this.FilterTab('created', $r('app.string.created_by_me'))
        this.FilterTab('mentioned', $r('app.string.mentioned_me'))
      }
      .width('100%')

      // 内容
      if (!this.isLoggedIn) {
        Text($r('app.string.login_to_see_todos'))
          .fontSize(FontSize.MD)
          .fontColor(this.colors.textSecondary)
          .padding({ top: Spacing.SM, bottom: Spacing.SM })
      } else if (this.isLoading) {
        Row({ space: Spacing.SM }) {
          LoadingProgress()
            .width(20)
            .height(20)
            .color(this.colors.brandPrimary)
          Text($r('app.string.loading'))
            .fontSize(FontSize.MD)
            .fontColor(this.colors.textSecondary)
        }
        .padding({ top: Spacing.SM, bottom: Spacing.SM })
      } else if (this.assignedIssues.length === 0) {
        Column({ space: Spacing.XS }) {
          Image($r('app.media.ic_check_circle'))
            .width(32)
            .height(32)
            .fillColor(this.colors.success)
          Text($r('app.string.no_todo_items'))
            .fontSize(FontSize.MD)
            .fontColor(this.colors.textSecondary)
        }
        .width('100%')
        .padding({ top: Spacing.MD, bottom: Spacing.MD })
        .alignItems(HorizontalAlign.Center)
      } else {
        ForEach(this.assignedIssues.slice(0, 5), (issue: GitHubIssue) => {
          this.IssueItem(issue)
        }, (issue: GitHubIssue) => issue.id.toString())

        if (this.assignedIssues.length > 5) {
          Text(getContext(this).resourceManager.getStringSync($r('app.string.more_items').id)
            .replace('%d', (this.assignedIssues.length - 5).toString()))
            .fontSize(FontSize.SM)
            .fontColor(this.colors.brandPrimary)
            .padding({ top: Spacing.XS })
        }
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  FilterTab(tab: 'assigned' | 'created' | 'mentioned', label: string | Resource) {
    Text(label)
      .fontSize(FontSize.SM)
      .fontColor(this.activeTab === tab ? this.colors.brandPrimary : this.colors.textSecondary)
      .fontWeight(this.activeTab === tab ? FontWeight.Medium : FontWeight.Normal)
      .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XS, bottom: Spacing.XS })
      .backgroundColor(this.activeTab === tab ? this.colors.primaryContainer : Color.Transparent)
      .borderRadius(BorderRadius.FULL)
      .onClick(() => {
        if (this.activeTab !== tab) {
          this.activeTab = tab;
          this.loadIssuesByFilter();
        }
      })
  }

  @Builder
  IssueItem(issue: GitHubIssue) {
    Row({ space: Spacing.SM }) {
      // Issue/PR 图标
      Image(issue.pull_request ? $r('app.media.ic_git_pull_request') : $r('app.media.ic_issue'))
        .width(16)
        .height(16)
        .fillColor(issue.state === 'open' ? this.colors.success : this.colors.error)

      Column({ space: 2 }) {
        Text(issue.title)
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: Spacing.XS }) {
          // 标签
          if (issue.labels && issue.labels.length > 0) {
            Text(issue.labels[0].name)
              .fontSize(FontSize.XS)
              .fontColor('#' + issue.labels[0].color)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .backgroundColor(Color.Transparent)
              .border({ width: 1, color: '#' + issue.labels[0].color, radius: 4 })
          }

          Text(`#${issue.number}`)
            .fontSize(FontSize.XS)
            .fontColor(this.colors.textTertiary)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 评论数
      if (issue.comments > 0) {
        Row({ space: 2 }) {
          Image($r('app.media.ic_comment'))
            .width(12)
            .height(12)
            .fillColor(this.colors.textTertiary)
          Text(issue.comments.toString())
            .fontSize(FontSize.XS)
            .fontColor(this.colors.textTertiary)
        }
      }

      Image($r('app.media.ic_chevron_right'))
        .width(16)
        .height(16)
        .fillColor(this.colors.textTertiary)
    }
    .width('100%')
    .height(48)
    .padding({ top: Spacing.XS, bottom: Spacing.XS })
    .onClick((): void => {
      // 从 html_url 解析出 owner/repo
      const urlParts = issue.html_url.split('/');
      const repoIndex = urlParts.indexOf('github.com') + 1;
      if (repoIndex > 0 && urlParts.length > repoIndex + 1) {
        router.pushUrl({
          url: 'pages/IssueDetailPage',
          params: {
            owner: urlParts[repoIndex],
            repo: urlParts[repoIndex + 1],
            issueNumber: issue.number
          }
        });
      }
    })
  }

  // 最近活动卡片
  @Builder
  ActivityCard() {
    RFCard({
      variant: 'elevated',
      colors: this.colors,
      content: (): void => this.ActivityContent()
    })
  }

  @Builder
  ActivityContent() {
    Column({ space: Spacing.SM }) {
      // 标题行
      Row() {
        Text($r('app.string.my_activity'))
          .fontSize(FontSize.LG)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textPrimary)

        Blank()

        Text($r('app.string.recent_activity'))
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textSecondary)
      }
      .width('100%')

      // 内容
      if (!this.isLoggedIn) {
        Text($r('app.string.login_to_see_activity'))
          .fontSize(FontSize.MD)
          .fontColor(this.colors.textSecondary)
          .padding({ top: Spacing.SM, bottom: Spacing.SM })
      } else if (this.myEvents.length === 0) {
        Text($r('app.string.no_activity_records'))
          .fontSize(FontSize.MD)
          .fontColor(this.colors.textSecondary)
          .padding({ top: Spacing.SM, bottom: Spacing.SM })
      } else {
        ForEach(this.myEvents.slice(0, 8), (event: GitHubEvent) => {
          this.EventItem(event)
        }, (event: GitHubEvent) => event.id)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  EventItem(event: GitHubEvent) {
    Row({ space: Spacing.SM }) {
      // 事件图标
      Image(this.getEventIcon(event.type))
        .width(16)
        .height(16)
        .fillColor(this.colors.textSecondary)

      Column({ space: 2 }) {
        Text(this.getEventDescription(event))
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.formatEventTime(event.created_at))
          .fontSize(FontSize.XS)
          .fontColor(this.colors.textTertiary)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: Spacing.XS, bottom: Spacing.XS })
    .onClick(() => {
      // 点击跳转到对应仓库
      const repoParts = event.repo.name.split('/');
      if (repoParts.length === 2) {
        router.pushUrl({
          url: 'pages/RepoDetailPage',
          params: { owner: repoParts[0], repo: repoParts[1] }
        });
      }
    })
  }

  getEventIcon(type: string): Resource {
    switch (type) {
      case 'PushEvent':
        return $r('app.media.ic_git_commit');
      case 'CreateEvent':
        return $r('app.media.ic_git_branch');
      case 'PullRequestEvent':
        return $r('app.media.ic_git_pull_request');
      case 'IssuesEvent':
        return $r('app.media.ic_issue');
      case 'WatchEvent':
        return $r('app.media.ic_star');
      case 'ForkEvent':
        return $r('app.media.ic_git_fork');
      case 'IssueCommentEvent':
        return $r('app.media.ic_comment');
      default:
        return $r('app.media.ic_activity');
    }
  }

  getEventDescription(event: GitHubEvent): ResourceStr {
    const repoName = event.repo.name.split('/')[1] || event.repo.name;
    switch (event.type) {
      case 'PushEvent':
        const commits = event.payload.size || 1;
        return getContext(this).resourceManager.getStringSync($r('app.string.push_commits').id)
          .replace('%d', commits.toString()).replace('%s', repoName);
      case 'CreateEvent':
        return getContext(this).resourceManager.getStringSync($r('app.string.create_ref').id)
          .replace('%s', event.payload.ref_type || 'branch').replace('%s', repoName);
      case 'PullRequestEvent':
        return getContext(this).resourceManager.getStringSync($r('app.string.action_pr').id)
          .replace('%s', event.payload.action || 'action').replace('%s', repoName);
      case 'IssuesEvent':
        return getContext(this).resourceManager.getStringSync($r('app.string.action_issue').id)
          .replace('%s', event.payload.action || 'action').replace('%s', repoName);
      case 'WatchEvent':
        return getContext(this).resourceManager.getStringSync($r('app.string.starred_repo').id)
          .replace('%s', repoName);
      case 'ForkEvent':
        return getContext(this).resourceManager.getStringSync($r('app.string.forked_repo').id)
          .replace('%s', repoName);
      case 'IssueCommentEvent':
        return getContext(this).resourceManager.getStringSync($r('app.string.commented_repo').id)
          .replace('%s', repoName);
      default:
        return getContext(this).resourceManager.getStringSync($r('app.string.event_in_repo').id)
          .replace('%s', event.type.replace('Event', '')).replace('%s', repoName);
    }
  }

  formatEventTime(dateStr: string): ResourceStr {
    const date = new Date(dateStr);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);

    if (minutes < 60) {
      return getContext(this).resourceManager.getStringSync($r('app.string.minutes_ago').id)
        .replace('%d', minutes.toString());
    }
    if (hours < 24) {
      return getContext(this).resourceManager.getStringSync($r('app.string.hours_ago').id)
        .replace('%d', hours.toString());
    }
    if (days < 7) {
      return getContext(this).resourceManager.getStringSync($r('app.string.days_ago').id)
        .replace('%d', days.toString());
    }
    return date.toLocaleDateString();
  }

  // 主内容区域 (单栏)
  @Builder
  MainContent() {
    Scroll() {
      Column({ space: Spacing.MD }) {
        // 欢迎区
        this.WelcomeHeader()

        // 未登录引导
        if (!this.isLoggedIn) {
          this.LoginPrompt()
        } else {
          // 安全警报 (如果有)
          this.SecurityAlertsCard()

          // 待办事项
          this.TodoCard()

          // 最近活动
          this.ActivityCard()
        }
      }
      .padding(Spacing.LG)
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
  }

  // 侧边栏 (折叠屏/平板) - 显示主要内容列表
  @Builder
  SideContent() {
    Scroll() {
      Column({ space: Spacing.MD }) {
        // 欢迎区
        this.WelcomeHeader()

        // 安全警报
        this.SecurityAlertsCard()

        // 待办事项
        this.TodoCard()

        // 最近活动
        this.ActivityCard()
      }
      .width('100%')
      .padding(Spacing.MD)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
  }

  // 详情区域 (折叠屏/平板) - 显示选中项的详情
  @Builder
  DetailContent() {
    Column() {
      // 当没有选中内容时显示欢迎信息
      Column({ space: Spacing.MD }) {
        Image($r('app.media.github_mark'))
          .width(64)
          .height(64)
          .fillColor(this.colors.textTertiary)
          .opacity(0.5)

        Text($r('app.string.select_item_to_view'))
          .fontSize(FontSize.MD)
          .fontColor(this.colors.textSecondary)

        Text($r('app.string.select_from_list'))
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textTertiary)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.surfaceVariant)
  }

  // =====================================================
  // 主构建方法
  // =====================================================

  build() {
    Column() {
      if (this.layoutMode === LayoutMode.SINGLE) {
        // 手机单栏布局
        this.MainContent()
      } else {
        // 折叠屏/平板多栏布局
        RFSplitView({
          layoutMode: this.layoutMode,
          primaryWidth: this.layoutMode === LayoutMode.TRIPLE ? 320 : 360,
          colors: this.colors,
          showDivider: true,
          primaryContent: (): void => this.SideContent(),
          detailContent: (): void => this.DetailContent()
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.bgPrimary)
  }
}
