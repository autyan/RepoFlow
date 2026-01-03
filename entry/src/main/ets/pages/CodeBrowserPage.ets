/**
 * 代码浏览页面
 *
 * 使用 RFCodeBrowser 组件提供完整的代码浏览体验:
 * - 文件树浏览
 * - 代码查看
 * - 分支切换
 * - 响应式布局
 */

import { util } from '@kit.ArkTS';
import { authManager } from '../services/AuthManager';
import { GitHubBranch } from '../models/GitHubModels';
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
  RFCodeBrowser,
  RFButton,
  RFPageHeader,
  FileTreeNode,
  FileNodeType,
  getFileExtension,
} from '../components';
import { UIHelper } from '../common/ui';

// =====================================================
// 路由参数
// =====================================================
interface RouteParams {
  owner: string;
  repo: string;
  branch?: string;
}

// =====================================================
// 代码浏览页面
// =====================================================
@Entry
@Component
struct CodeBrowserPage {
  // 主题状态
  @State colors: ThemeColors = ThemeManager.colors;
  @State isDark: boolean = ThemeManager.isDark;

  // 响应式状态
  @State layoutMode: LayoutMode = ResponsiveManager.state.layoutMode;
  @State deviceType: DeviceType = ResponsiveManager.state.deviceType;

  // 页面状态
  @State branches: GitHubBranch[] = [];
  @State currentBranch: string = 'main';
  @State showBranchPicker: boolean = false;
  @State isLoadingBranches: boolean = false;
  @State branchPage: number = 1;
  @State hasMoreBranches: boolean = true;
  @State branchSearchQuery: string = '';

  private owner: string = '';
  private repoName: string = '';

  private t(res: Resource, ...args: Array<string | number>): string {
    try {
      const rm = this.getUIContext()!.getHostContext()!.resourceManager!;
      return rm.getStringSync(res.id, ...args);
    } catch (error) {
      console.error('Resource loading failed:', error);
      return '';
    }
  }

  // =====================================================
  // 生命周期
  // =====================================================

  aboutToAppear(): void {
    // 获取路由参数
    const params = this.getUIContext()!.getRouter()!.getParams() as RouteParams | undefined;
    if (params) {
      this.owner = params.owner;
      this.repoName = params.repo;
      if (params.branch) {
        this.currentBranch = params.branch;
      }
      this.loadBranches();
    }

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

  // =====================================================
  // 数据加载
  // =====================================================

  async loadBranches(page: number = 1): Promise<void> {
    const api = authManager.getGitHubApi();
    if (!api) return;

    this.isLoadingBranches = true;

    try {
      const newBranches = await api.getRepoBranches(this.owner, this.repoName, page, 20);
      
      if (page === 1) {
        this.branches = newBranches;
      } else {
        this.branches = [...this.branches, ...newBranches];
      }
      
      this.branchPage = page;
      this.hasMoreBranches = newBranches.length >= 20;

      // 使用第一个分支作为默认分支 (仅在首次加载且当前为默认 main 时)
      if (page === 1 && this.branches.length > 0 && this.currentBranch === 'main') {
        const mainBranch = this.branches.find(b => b.name === 'main' || b.name === 'master');
        if (mainBranch) {
          this.currentBranch = mainBranch.name;
        } else {
          this.currentBranch = this.branches[0].name;
        }
      }
    } catch (err) {
      console.error('Load branches failed:', JSON.stringify(err));
    } finally {
      this.isLoadingBranches = false;
    }
  }

  loadMoreBranches(): void {
    if (!this.isLoadingBranches && this.hasMoreBranches) {
      this.loadBranches(this.branchPage + 1);
    }
  }

  // 获取目录树
  async fetchTree(path: string): Promise<FileTreeNode[]> {
    const api = authManager.getGitHubApi();
    if (!api) return [];

    try {
      const contents = await api.getRepoContents(this.owner, this.repoName, path, this.currentBranch);
      const depth = path ? path.split('/').length : 0;

      // 转换为 FileTreeNode
      const nodes: FileTreeNode[] = contents.map((item): FileTreeNode => {
        const node: FileTreeNode = {
          name: item.name,
          path: item.path,
          type: item.type === 'dir' ? FileNodeType.DIRECTORY : FileNodeType.FILE,
          size: item.size,
          extension: item.type === 'file' ? getFileExtension(item.name) : undefined,
          depth: depth,
          parentPath: path || undefined,
          expanded: false,
          isLoading: false,
          childrenLoaded: false,
        };
        return node;
      });

      // 排序：目录在前，文件在后，按名称排序
      return nodes.sort((a, b) => {
        if (a.type !== b.type) {
          return a.type === FileNodeType.DIRECTORY ? -1 : 1;
        }
        return a.name.localeCompare(b.name);
      });
    } catch (err) {
      console.error('Fetch tree failed:', JSON.stringify(err));
      return [];
    }
  }

  // 获取文件内容
  async fetchContent(path: string): Promise<string> {
    const api = authManager.getGitHubApi();
    if (!api) return '';

    try {
      const content = await api.getFileContent(this.owner, this.repoName, path, this.currentBranch);
      // GitHub API 返回 base64 编码的内容
      if (content.encoding === 'base64' && content.content) {
        // 使用 ArkTS 的 Base64Helper 解码
        const base64Helper = new util.Base64Helper();
        const base64Content = content.content.replace(/\n/g, '');
        const decodedArray = base64Helper.decodeSync(base64Content);
        const textDecoder = util.TextDecoder.create('utf-8');
        return textDecoder.decodeToString(decodedArray);
      }
      return content.content || '';
    } catch (err) {
      console.error('Fetch content failed:', JSON.stringify(err));
      throw new Error(this.t($r('app.string.load_failed')));
    }
  }

  // 切换分支
  switchBranch(branch: string): void {
    if (branch !== this.currentBranch) {
      this.currentBranch = branch;
      UIHelper.replaceUrl(this, 'pages/CodeBrowserPage', {
        owner: this.owner,
        repo: this.repoName,
        branch: branch
      });
    }
    this.showBranchPicker = false;
  }

  // 返回导航
  navigateBack(): void {
    UIHelper.goBack(this);
  }

  // =====================================================
  // UI 构建
  // =====================================================

  @Builder
  BranchButton() {
    Row({ space: Spacing.XS }) {
      Image($r('app.media.ic_branch'))
        .width(16)
        .height(16)
        .fillColor(this.colors.textSecondary)

      Text(this.currentBranch)
        .fontSize(FontSize.SM)
        .fontColor(this.colors.textPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Image($r('app.media.ic_chevron_right'))
        .width(12)
        .height(12)
        .fillColor(this.colors.textTertiary)
        .rotate({ angle: 90 })
    }
    .height(32)
    .padding({ left: Spacing.SM, right: Spacing.SM })
    .backgroundColor(this.colors.bgSecondary)
    .borderRadius(BorderRadius.SM)
    .border({ width: 1, color: this.colors.border })
    .onClick(() => {
      this.showBranchPicker = true;
    })
  }

  @Builder
  BranchPicker() {
    Column() {
      // 遮罩层
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000060')
        .onClick(() => {
          this.showBranchPicker = false;
        })

      // 分支选择面板
      Column() {
        // 标题栏
        Row() {
          Text($r('app.string.select_branch'))
            .fontSize(FontSize.LG)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.colors.textPrimary)

          Blank()

          Image($r('app.media.ic_close'))
            .width(24)
            .height(24)
            .fillColor(this.colors.textSecondary)
            .onClick(() => {
              this.showBranchPicker = false;
            })
        }
        .width('100%')
        .padding(Spacing.MD)
        .border({
          width: { bottom: 1 },
          color: this.colors.border
        })

        // 分支列表
        Column() {
          // 搜索框
          Search({ placeholder: $r('app.string.search_branches') })
            .width('100%')
            .height(36)
            .margin({ bottom: Spacing.SM })
            .backgroundColor(this.colors.bgSecondary)
            .placeholderColor(this.colors.textTertiary)
            .onChange((value: string) => {
              this.branchSearchQuery = value;
            })

          if (this.isLoadingBranches && this.branches.length === 0) {
            Column() {
              LoadingProgress()
                .width(32)
                .height(32)
                .color(this.colors.brandPrimary)
            }
            .width('100%')
            .height(200)
            .justifyContent(FlexAlign.Center)
          } else {
            List() {
              ForEach(this.branches.filter(b => b.name.toLowerCase().includes(this.branchSearchQuery.toLowerCase())), (branch: GitHubBranch) => {
                ListItem() {
                  Row() {
                    Image($r('app.media.ic_branch'))
                      .width(18)
                      .height(18)
                      .fillColor(this.colors.textSecondary)

                    Text(branch.name)
                      .fontSize(FontSize.MD)
                      .fontColor(this.colors.textPrimary)
                      .margin({ left: Spacing.SM })
                      .layoutWeight(1)

                    if (branch.name === this.currentBranch) {
                      Image($r('app.media.ic_check_circle'))
                        .width(20)
                        .height(20)
                        .fillColor(this.colors.success)
                    }
                  }
                  .width('100%')
                  .height(52)
                  .padding({ left: Spacing.MD, right: Spacing.MD })
                  .onClick(() => {
                    this.switchBranch(branch.name);
                  })
                }
              }, (branch: GitHubBranch) => branch.name)

              // 加载更多
              if (this.hasMoreBranches) {
                ListItem() {
                  Row() {
                    if (this.isLoadingBranches) {
                      LoadingProgress()
                        .width(20)
                        .height(20)
                        .color(this.colors.brandPrimary)
                        .margin({ right: 8 })
                      Text($r('app.string.loading'))
                        .fontSize(FontSize.SM)
                        .fontColor(this.colors.textSecondary)
                    } else {
                      Text($r('app.string.load_more'))
                        .fontSize(FontSize.SM)
                        .fontColor(this.colors.brandPrimary)
                    }
                  }
                  .width('100%')
                  .height(48)
                  .justifyContent(FlexAlign.Center)
                  .onClick(() => {
                    this.loadMoreBranches();
                  })
                }
              } else if (this.branches.length > 0) {
                ListItem() {
                  Text($r('app.string.no_more_branches'))
                    .fontSize(FontSize.XS)
                    .fontColor(this.colors.textTertiary)
                    .width('100%')
                    .textAlign(TextAlign.Center)
                    .padding({ top: Spacing.SM, bottom: Spacing.SM })
                }
              }
            }
            .width('100%')
            .layoutWeight(1)
            .divider({
              strokeWidth: 1,
              color: this.colors.border,
              startMargin: Spacing.MD + 18 + Spacing.SM,
              endMargin: Spacing.MD
            })
          }
        }
        .padding({ left: Spacing.MD, right: Spacing.MD, bottom: Spacing.MD })
        .layoutWeight(1)
      }
      .width('100%')
      .height('60%')
      .backgroundColor(this.colors.bgPrimary)
      .borderRadius({
        topLeft: BorderRadius.LG,
        topRight: BorderRadius.LG
      })
      .position({ y: '40%' })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  HeaderActions() {
    Row({ space: Spacing.SM }) {
      this.BranchButton()
    }
  }

  build() {
    Stack() {
      Column() {
        // 页面头部
        RFPageHeader({
          title: `${this.owner}/${this.repoName}`,
          subtitle: $r('app.string.code_browser'),
          colors: this.colors,
          showBack: true,
          onBack: (): void => this.navigateBack(),
          actions: (): void => this.HeaderActions()
        })

        // 代码浏览器
        RFCodeBrowser({
          owner: this.owner,
          repo: this.repoName,
          branch: this.currentBranch,
          layoutMode: this.layoutMode,
          deviceType: this.deviceType,
          colors: this.colors,
          onFetchTree: async (path: string): Promise<FileTreeNode[]> => {
            return await this.fetchTree(path);
          },
          onFetchContent: async (path: string): Promise<string> => {
            return await this.fetchContent(path);
          }
        })
          .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.colors.bgPrimary)

      // 分支选择弹窗
      if (this.showBranchPicker) {
        this.BranchPicker()
      }
    }
    .width('100%')
    .height('100%')
  }
}
