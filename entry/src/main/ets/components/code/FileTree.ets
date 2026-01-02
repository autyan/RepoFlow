/**
 * RepoFlow 文件树组件
 * 
 * 高性能文件树组件:
 * - 虚拟滚动，仅渲染可见节点
 * - 懒加载子目录
 * - 无页面跳转，就地展开
 * - 支持大型仓库
 */

import { ThemeColors, DarkColors, getLanguageColor } from '../../theme/Colors';
import { Spacing, BorderRadius, FontSize, AnimationDuration } from '../../theme/DesignTokens';
import { 
  FileTreeNode, 
  FlatFileNode, 
  FileNodeType,
  getFileExtension 
} from './CodeBrowserModels';

// 渲染范围接口
interface RenderRange {
  start: number;
  end: number;
}

// =====================================================
// 文件树项目组件
// =====================================================

@Component
export struct FileTreeItem {
  /** 节点数据 */
  @Prop node: FlatFileNode = {} as FlatFileNode;
  /** 是否选中 */
  @Prop isSelected: boolean = false;
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 点击回调 */
  onTap?: () => void;
  /** 展开/折叠回调 */
  onToggle?: () => void;
  
  @State isHovered: boolean = false;
  @State isPressed: boolean = false;
  
  // 获取缩进
  private getIndent(): number {
    return this.node.depth * 16;
  }
  
  // 获取图标
  private getIcon(): ResourceStr {
    if (this.node.type === FileNodeType.DIRECTORY) {
      // 使用项目资源
      return $r('app.media.ic_folder');
    }
    return $r('app.media.ic_file');
  }
  
  // 获取图标颜色
  private getIconColor(): string {
    if (this.node.type === FileNodeType.DIRECTORY) {
      return this.colors.folderColor; // 文件夹颜色
    }
    
    // 根据文件扩展名获取颜色
    const ext = this.node.extension || getFileExtension(this.node.name);
    return getLanguageColor(ext);
  }
  
  // 获取背景颜色
  private getBgColor(): string {
    if (this.isSelected) return this.colors.primaryContainer;
    if (this.isPressed) return this.colors.bgTertiary;
    if (this.isHovered) return this.colors.bgHover;
    return 'transparent';
  }
  
  // 获取展开箭头
  @Builder
  ExpandArrow() {
    if (this.node.type === FileNodeType.DIRECTORY) {
      Image($r('app.media.ic_chevron_right'))
        .width(12)
        .height(12)
        .fillColor(this.colors.textTertiary)
        .rotate({ angle: this.node.expanded ? 90 : 0 })
        .animation({
          duration: AnimationDuration.FAST,
          curve: Curve.EaseOut
        })
        .onClick(() => {
          if (this.onToggle) {
            this.onToggle();
          }
        })
    } else {
      // 占位符保持对齐
      Blank()
        .width(12)
        .height(12)
    }
  }
  
  build() {
    Row({ space: 4 }) {
      // 缩进
      Blank()
        .width(this.getIndent())
      
      // 展开箭头
      this.ExpandArrow()
      
      // 文件图标
      Image(this.getIcon())
        .width(16)
        .height(16)
        .fillColor(this.getIconColor())
      
      // 文件名
      Text(this.node.name)
        .fontSize(FontSize.SM)
        .fontColor(this.isSelected ? this.colors.brandPrimary : this.colors.textPrimary)
        .fontWeight(this.isSelected ? FontWeight.Medium : FontWeight.Normal)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
      
      // 加载指示器
      if (this.node.isLoading) {
        LoadingProgress()
          .width(14)
          .height(14)
          .color(this.colors.textTertiary)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: Spacing.SM, right: Spacing.SM })
    .backgroundColor(this.getBgColor())
    .animation({
      duration: AnimationDuration.FAST,
      curve: Curve.EaseOut
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isPressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false;
      }
    })
    .onHover((isHover: boolean) => {
      this.isHovered = isHover;
    })
    .onClick(() => {
      if (this.onTap) {
        this.onTap();
      }
    })
  }
}

// =====================================================
// 文件树组件
// =====================================================

@Component
export struct RFFileTree {
  /** 扁平化的节点列表 */
  @Prop nodes: FlatFileNode[] = [];
  /** 选中的路径 */
  @Link selectedPath: string;
  /** 项目高度 */
  @Prop itemHeight: number = 28;
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 节点点击回调 */
  onNodeClick?: (node: FlatFileNode) => void;
  /** 节点展开回调 */
  onNodeToggle?: (node: FlatFileNode) => void;
  /** 加载子节点回调 */
  onLoadChildren?: (node: FlatFileNode) => Promise<void>;
  
  @State viewportHeight: number = 0;
  @State scrollOffset: number = 0;
  @State renderRange: RenderRange = { start: 0, end: 50 } as RenderRange;
  
  private scrollController: Scroller = new Scroller();
  private bufferSize: number = 15;
  
  // 获取可见节点
  private getVisibleNodes(): FlatFileNode[] {
    return this.nodes.filter(node => node.visible);
  }
  
  // 更新渲染范围
  private updateRenderRange(): void {
    const visibleNodes = this.getVisibleNodes();
    if (visibleNodes.length === 0 || this.viewportHeight <= 0) return;
    
    const visibleStart = Math.floor(this.scrollOffset / this.itemHeight);
    const visibleCount = Math.ceil(this.viewportHeight / this.itemHeight);
    const visibleEnd = Math.min(visibleStart + visibleCount, visibleNodes.length - 1);
    
    const newRange: RenderRange = {
      start: Math.max(0, visibleStart - this.bufferSize),
      end: Math.min(visibleNodes.length - 1, visibleEnd + this.bufferSize),
    };
    this.renderRange = newRange;
  }
  
  // 处理节点点击
  private handleNodeClick(node: FlatFileNode): void {
    if (node.type === FileNodeType.DIRECTORY) {
      // 目录：切换展开状态
      this.handleNodeToggle(node);
    } else {
      // 文件：选中并通知
      this.selectedPath = node.path;
      if (this.onNodeClick) {
        this.onNodeClick(node);
      }
    }
  }
  
  // 处理节点展开/折叠
  private async handleNodeToggle(node: FlatFileNode): Promise<void> {
    if (node.type !== FileNodeType.DIRECTORY) return;
    
    // 如果子节点未加载，先加载
    if (!node.childrenLoaded && this.onLoadChildren) {
      await this.onLoadChildren(node);
    }
    
    if (this.onNodeToggle) {
      this.onNodeToggle(node);
    }
  }
  
  aboutToAppear(): void {
    this.updateRenderRange();
  }
  
  build() {
    Column() {
      List({ scroller: this.scrollController }) {
        ForEach(
          this.getVisibleNodes(),
          (node: FlatFileNode, index: number) => {
            ListItem() {
              FileTreeItem({
                node: node,
                isSelected: node.path === this.selectedPath,
                colors: this.colors,
                onTap: () => this.handleNodeClick(node),
                onToggle: () => this.handleNodeToggle(node)
              })
            }
            .width('100%')
            .height(this.itemHeight)
          },
          (node: FlatFileNode, index: number) => {
            return `file_${node.path}_${index}`;
          }
        )
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Auto)
      .scrollBarColor(this.colors.border)
      .edgeEffect(EdgeEffect.None)
      .cachedCount(20)
      .onAreaChange((oldArea: Area, newArea: Area) => {
        const newHeight = newArea.height as number;
        if (this.viewportHeight !== newHeight) {
          this.viewportHeight = newHeight;
          this.updateRenderRange();
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.bgPrimary)
  }
}

// =====================================================
// 文件树管理器 (处理树结构和扁平化)
// =====================================================

export class FileTreeManager {
  private roots: FileTreeNode[] = [];
  private expandedPaths: Set<string> = new Set();
  private flatNodes: FlatFileNode[] = [];
  
  /**
   * 设置根节点
   */
  setRoots(nodes: FileTreeNode[]): void {
    this.roots = this.sortNodes(nodes);
    this.updateFlatNodes();
  }
  
  /**
   * 获取扁平化节点列表
   */
  getFlatNodes(): FlatFileNode[] {
    return this.flatNodes;
  }
  
  /**
   * 展开节点
   */
  expandNode(path: string): void {
    this.expandedPaths.add(path);
    this.updateFlatNodes();
  }
  
  /**
   * 折叠节点
   */
  collapseNode(path: string): void {
    this.expandedPaths.delete(path);
    this.updateFlatNodes();
  }
  
  /**
   * 切换节点展开状态
   */
  toggleNode(path: string): boolean {
    if (this.expandedPaths.has(path)) {
      this.collapseNode(path);
      return false;
    } else {
      this.expandNode(path);
      return true;
    }
  }
  
  /**
   * 设置节点子节点
   */
  setNodeChildren(path: string, children: FileTreeNode[]): void {
    const node = this.findNode(path);
    if (node && node.type === FileNodeType.DIRECTORY) {
      node.children = this.sortNodes(children);
      node.childrenLoaded = true;
      node.isLoading = false;
      this.updateFlatNodes();
    }
  }
  
  /**
   * 设置节点加载状态
   */
  setNodeLoading(path: string, isLoading: boolean): void {
    const node = this.findNode(path);
    if (node) {
      node.isLoading = isLoading;
      this.updateFlatNodes();
    }
  }
  
  /**
   * 查找节点
   */
  private findNode(path: string): FileTreeNode | null {
    const findInNodes = (nodes: FileTreeNode[]): FileTreeNode | null => {
      for (const node of nodes) {
        if (node.path === path) return node;
        if (node.children) {
          const found = findInNodes(node.children);
          if (found) return found;
        }
      }
      return null;
    };
    
    return findInNodes(this.roots);
  }
  
  /**
   * 排序节点 (目录在前，按名称排序)
   */
  private sortNodes(nodes: FileTreeNode[]): FileTreeNode[] {
    return [...nodes].sort((a, b) => {
      // 目录优先
      if (a.type === FileNodeType.DIRECTORY && b.type !== FileNodeType.DIRECTORY) {
        return -1;
      }
      if (a.type !== FileNodeType.DIRECTORY && b.type === FileNodeType.DIRECTORY) {
        return 1;
      }
      // 按名称排序
      return a.name.toLowerCase().localeCompare(b.name.toLowerCase());
    });
  }
  
  /**
   * 更新扁平化节点列表
   */
  private updateFlatNodes(): void {
    this.flatNodes = [];
    this.flattenNodes(this.roots, 0, true);
  }
  
  /**
   * 递归扁平化节点
   */
  private flattenNodes(
    nodes: FileTreeNode[],
    depth: number,
    parentVisible: boolean
  ): void {
    for (const node of nodes) {
      const isExpanded = this.expandedPaths.has(node.path);
      
      const flatNode: FlatFileNode = {
        name: node.name,
        path: node.path,
        type: node.type,
        size: node.size,
        extension: node.extension,
        children: node.children,
        childrenLoaded: node.childrenLoaded,
        isLoading: node.isLoading,
        depth: depth,
        expanded: isExpanded,
        visible: parentVisible,
      };
      
      this.flatNodes.push(flatNode);
      
      // 递归处理子节点
      if (node.children && node.children.length > 0) {
        this.flattenNodes(
          node.children,
          depth + 1,
          parentVisible && isExpanded
        );
      }
    }
  }
}
