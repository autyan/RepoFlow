/**
 * RepoFlow 代码浏览器集成组件
 * 
 * 完整的代码浏览体验:
 * - 左侧文件树
 * - 右侧代码查看器
 * - 面包屑导航
 * - 无页面跳转
 * - 响应式布局
 */

import { ThemeColors, DarkColors } from '../../theme/Colors';
import { Spacing, BorderRadius, FontSize, LayoutMode, DeviceType } from '../../theme/DesignTokens';
import { RFSplitView } from '../layout/RFLayout';
import { RFFileTree, FileTreeManager } from './FileTree';
import { RFCodeViewer, CodeViewerHeader, CodeParser } from './CodeViewer';
import {
  FileTreeNode,
  FlatFileNode,
  FileNodeType,
  CodeLine,
  FileContent,
  LineRange,
  getFileExtension,
  getLanguageFromExtension,
  isBinaryExtension
} from './CodeBrowserModels';

// =====================================================
// 面包屑组件
// =====================================================

@Component
export struct Breadcrumbs {
  /** 路径片段 */
  @Prop pathSegments: string[] = [];
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 路径点击回调 */
  onPathClick?: (path: string, index: number) => void;
  
  build() {
    Row({ space: 4 }) {
      // 根目录
      Text('/')
        .fontSize(FontSize.SM)
        .fontColor(this.colors.brandPrimary)
        .onClick(() => {
          if (this.onPathClick) {
            this.onPathClick('', -1);
          }
        })
      
      ForEach(this.pathSegments, (segment: string, index: number) => {
        // 分隔符
        Text('/')
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textTertiary)
        
        // 路径片段
        Text(segment)
          .fontSize(FontSize.SM)
          .fontColor(index === this.pathSegments.length - 1
            ? this.colors.textPrimary
            : this.colors.brandPrimary)
          .fontWeight(index === this.pathSegments.length - 1
            ? FontWeight.Medium
            : FontWeight.Normal)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .onClick(() => {
            if (this.onPathClick) {
              const path = this.pathSegments.slice(0, index + 1).join('/');
              this.onPathClick(path, index);
            }
          })
      })
    }
    .width('100%')
    .height(40)
    .padding({ left: Spacing.MD, right: Spacing.MD })
    .backgroundColor(this.colors.bgSecondary)
    .border({
      width: { bottom: 1 },
      color: this.colors.border
    })
  }
}

// =====================================================
// 空状态组件
// =====================================================

@Component
struct EmptyState {
  /** 图标 */
  @Prop icon: ResourceStr = $r('app.media.ic_folder');
  /** 标题 */
  @Prop title: string | Resource = '';
  /** 描述 */
  @Prop description: string | Resource = '';
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  
  build() {
    Column({ space: Spacing.MD }) {
      Image(this.icon)
        .width(64)
        .height(64)
        .fillColor(this.colors.textTertiary)
        .opacity(0.5)
      
      Text(this.title)
        .fontSize(FontSize.LG)
        .fontColor(this.colors.textSecondary)
      
      if (this.description) {
        Text(this.description)
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textTertiary)
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(Spacing.LG)
  }
}

// =====================================================
// 代码浏览器主组件
// =====================================================

@Component
export struct RFCodeBrowser {
  /** 仓库所有者 */
  @Prop owner: string = '';
  /** 仓库名称 */
  @Prop repo: string = '';
  /** 分支名称 */
  @Prop branch: string = 'main';
  /** 布局模式 */
  @Prop layoutMode: LayoutMode = LayoutMode.SINGLE;
  /** 设备类型 */
  @Prop deviceType: DeviceType = DeviceType.PHONE;
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 获取文件树回调 */
  onFetchTree?: (path: string) => Promise<FileTreeNode[]>;
  /** 获取文件内容回调 */
  onFetchContent?: (path: string) => Promise<string>;
  
  // 状态
  @State fileTreeNodes: FlatFileNode[] = [];
  @State selectedPath: string = '';
  @State currentFile: FileContent | null = null;
  @State codeLines: CodeLine[] = [];
  @State selectedLine: number = 0;
  @State isLoadingTree: boolean = false;
  @State isLoadingFile: boolean = false;
  @State showDetail: boolean = false;
  @State error: string = '';
  @State breadcrumbs: string[] = [];
  
  private fileTreeManager: FileTreeManager = new FileTreeManager();
  
  // 初始化加载根目录
  async aboutToAppear(): Promise<void> {
    await this.loadRootTree();
  }
  
  // 加载根目录
  private async loadRootTree(): Promise<void> {
    if (!this.onFetchTree) return;
    
    this.isLoadingTree = true;
    this.error = '';
    
    try {
      const nodes = await this.onFetchTree('');
      this.fileTreeManager.setRoots(nodes);
      this.fileTreeNodes = this.fileTreeManager.getFlatNodes();
    } catch (err) {
      this.error = 'Failed to load repository';
      console.error('Load tree error:', JSON.stringify(err));
    } finally {
      this.isLoadingTree = false;
    }
  }
  
  // 加载目录子节点
  private async loadChildren(node: FlatFileNode): Promise<void> {
    if (!this.onFetchTree || node.childrenLoaded) return;
    
    this.fileTreeManager.setNodeLoading(node.path, true);
    this.fileTreeNodes = this.fileTreeManager.getFlatNodes();
    
    try {
      const children = await this.onFetchTree(node.path);
      // 转换为 FileTreeNode 并设置深度
      const childNodes: FileTreeNode[] = children.map((child: FileTreeNode): FileTreeNode => {
        const childNode: FileTreeNode = {
          name: child.name,
          path: child.path,
          type: child.type,
          size: child.size,
          extension: child.extension,
          children: child.children,
          childrenLoaded: child.childrenLoaded,
          isLoading: child.isLoading,
          depth: node.depth + 1,
          parentPath: node.path,
        };
        return childNode;
      });
      this.fileTreeManager.setNodeChildren(node.path, childNodes);
    } catch (err) {
      console.error('Load children error:', JSON.stringify(err));
    } finally {
      this.fileTreeManager.setNodeLoading(node.path, false);
      this.fileTreeNodes = this.fileTreeManager.getFlatNodes();
    }
  }
  
  // 处理节点切换
  private handleNodeToggle(node: FlatFileNode): void {
    this.fileTreeManager.toggleNode(node.path);
    this.fileTreeNodes = this.fileTreeManager.getFlatNodes();
  }
  
  // 处理文件点击
  private async handleFileClick(node: FlatFileNode): Promise<void> {
    if (node.type !== FileNodeType.FILE) return;
    
    // 更新面包屑
    this.breadcrumbs = node.path.split('/');
    this.selectedPath = node.path;
    
    // 检查是否为二进制文件
    const ext = node.extension || getFileExtension(node.name);
    if (isBinaryExtension(ext)) {
      const binaryRange: LineRange = { start: 0, end: 0 };
      const binaryFile: FileContent = {
        path: node.path,
        name: node.name,
        extension: ext,
        size: node.size || 0,
        lineCount: 0,
        encoding: 'binary',
        isBinary: true,
        language: 'binary',
        lines: [],
        loadedRange: binaryRange,
      };
      this.currentFile = binaryFile;
      this.codeLines = [];
      this.showDetail = true;
      return;
    }
    
    // 加载文件内容
    await this.loadFileContent(node);
  }
  
  // 加载文件内容
  private async loadFileContent(node: FlatFileNode): Promise<void> {
    if (!this.onFetchContent) return;
    
    this.isLoadingFile = true;
    this.error = '';
    
    try {
      const content = await this.onFetchContent(node.path);
      const lines = CodeParser.parseContent(content);
      const ext = node.extension || getFileExtension(node.name);
      
      const fileRange: LineRange = { start: 1, end: lines.length };
      const fileContent: FileContent = {
        path: node.path,
        name: node.name,
        extension: ext,
        size: content.length,
        lineCount: lines.length,
        encoding: 'utf-8',
        isBinary: false,
        language: getLanguageFromExtension(ext),
        lines: lines,
        loadedRange: fileRange,
        rawContent: content,
      };
      this.currentFile = fileContent;
      
      this.codeLines = lines;
      this.selectedLine = 0;
      this.showDetail = true;
    } catch (err) {
      this.error = 'Failed to load file';
      console.error('Load file error:', JSON.stringify(err));
    } finally {
      this.isLoadingFile = false;
    }
  }
  
  // 处理面包屑点击
  private handleBreadcrumbClick(path: string, index: number): void {
    if (index === -1) {
      // 点击根目录
      this.selectedPath = '';
      this.showDetail = false;
      this.currentFile = null;
      this.breadcrumbs = [];
    } else {
      // 点击中间路径
      this.breadcrumbs = this.breadcrumbs.slice(0, index + 1);
      // 可以扩展为导航到对应目录
    }
  }
  
  // 处理返回
  private handleBack(): void {
    if (this.layoutMode === LayoutMode.SINGLE) {
      this.showDetail = false;
    }
    this.currentFile = null;
    this.codeLines = [];
    this.selectedLine = 0;
  }
  
  // 文件树面板
  @Builder
  FileTreePanel() {
    Column() {
      // 仓库信息头部
      Row({ space: Spacing.SM }) {
        Image($r('app.media.ic_folder'))
          .width(20)
          .height(20)
          .fillColor(this.colors.folderColor)
        
        Text(`${this.owner}/${this.repo}`)
          .fontSize(FontSize.MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textPrimary)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        // 刷新按钮
        Image($r('app.media.ic_search'))
          .width(20)
          .height(20)
          .fillColor(this.colors.textSecondary)
          .onClick(async () => {
            await this.loadRootTree();
          })
      }
      .width('100%')
      .height(48)
      .padding({ left: Spacing.MD, right: Spacing.MD })
      .backgroundColor(this.colors.bgSecondary)
      .border({
        width: { bottom: 1 },
        color: this.colors.border
      })
      
      // 文件树
      if (this.isLoadingTree) {
        Column() {
          LoadingProgress()
            .width(32)
            .height(32)
            .color(this.colors.brandPrimary)
          Text($r('app.string.loading'))
            .fontSize(FontSize.SM)
            .fontColor(this.colors.textSecondary)
            .margin({ top: Spacing.SM })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.error && this.fileTreeNodes.length === 0) {
        EmptyState({
          icon: $r('app.media.ic_error'),
          title: $r('app.string.error'),
          description: this.error,
          colors: this.colors
        })
      } else {
        RFFileTree({
          nodes: this.fileTreeNodes,
          selectedPath: this.selectedPath,
          itemHeight: 28,
          colors: this.colors,
          onNodeClick: (node) => this.handleFileClick(node),
          onNodeToggle: (node) => this.handleNodeToggle(node),
          onLoadChildren: async (node) => await this.loadChildren(node)
        })
          .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.bgPrimary)
  }
  
  // 代码查看面板
  @Builder
  CodeViewerPanel() {
    Column() {
      if (this.currentFile) {
        // 文件头部
        CodeViewerHeader({
          fileName: this.currentFile.name,
          filePath: this.currentFile.path,
          language: this.currentFile.language,
          fileSize: this.currentFile.size,
          lineCount: this.currentFile.lineCount,
          colors: this.colors,
          onBack: this.layoutMode === LayoutMode.SINGLE
            ? () => this.handleBack()
            : undefined,
          onCopy: () => {
            // TODO: 复制到剪贴板
          },
          onShare: () => {
            // TODO: 分享
          }
        })
        
        // 代码内容
        if (this.currentFile.isBinary) {
          EmptyState({
            icon: $r('app.media.ic_file'),
            title: 'Binary File',
            description: 'This file cannot be displayed',
            colors: this.colors
          })
        } else if (this.isLoadingFile) {
          Column() {
            LoadingProgress()
              .width(32)
              .height(32)
              .color(this.colors.brandPrimary)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else {
          RFCodeViewer({
            lines: this.codeLines,
            selectedLine: this.selectedLine,
            lineHeight: 22,
            language: this.currentFile.language,
            colors: this.colors,
            showLineNumbers: true
          })
            .layoutWeight(1)
        }
      } else {
        // 空状态
        EmptyState({
          icon: $r('app.media.ic_file'),
          title: $r('app.string.select_file'),
          description: $r('app.string.select_file_hint'),
          colors: this.colors
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.bgPrimary)
  }
  
  build() {
    Column() {
      // 面包屑导航
      if (this.breadcrumbs.length > 0) {
        Breadcrumbs({
          pathSegments: this.breadcrumbs,
          colors: this.colors,
          onPathClick: (path, index) => this.handleBreadcrumbClick(path, index)
        })
      }
      
      // 主内容区域
      if (this.layoutMode === LayoutMode.SINGLE) {
        // 单栏模式
        Stack() {
          // 文件树
          Column() {
            this.FileTreePanel()
          }
          .width('100%')
          .height('100%')
          .visibility(this.showDetail ? Visibility.Hidden : Visibility.Visible)
          
          // 代码查看器
          Column() {
            this.CodeViewerPanel()
          }
          .width('100%')
          .height('100%')
          .visibility(this.showDetail ? Visibility.Visible : Visibility.Hidden)
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        // 多栏模式
        RFSplitView({
          layoutMode: this.layoutMode,
          primaryWidth: this.layoutMode === LayoutMode.TRIPLE ? 280 : 320,
          colors: this.colors,
          showDivider: true,
          primaryContent: () => {
            this.FileTreePanel()
          },
          detailContent: () => {
            this.CodeViewerPanel()
          }
        })
          .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.bgPrimary)
  }
}
