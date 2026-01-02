/**
 * RepoFlow 虚拟列表组件
 * 
 * 高性能虚拟列表实现:
 * - 仅渲染可见区域 + 缓冲区的项目
 * - 固定高度项目优化
 * - 平滑滚动
 * - 低内存占用
 * - 支持大量数据 (10万+行)
 */

import { ThemeColors, DarkColors } from '../../theme/Colors';
import { Spacing, AnimationDuration } from '../../theme/DesignTokens';
import { VirtualListConfig, VirtualListState, calculateVisibleRange } from './CodeBrowserModels';

// Flexible record type without using `any`/`unknown`
type AnyData = Record<string, string | number | boolean | object | null | undefined>;

// =====================================================
// 虚拟列表项目接口
// =====================================================

export interface VirtualListItem<T> {
  /** 索引 */
  index: number;
  /** 数据 */
  data: T;
  /** 偏移量 */
  offset: number;
}

// =====================================================
// 可见范围信息接口
// =====================================================

export interface VisibleRangeInfo {
  start: number;
  end: number;
}

// =====================================================
// 虚拟列表组件
// =====================================================

@Component
export struct RFVirtualList {
  /** 项目高度 */
  @Prop itemHeight: number = 24;
  /** 总项目数 */
  @Prop totalItems: number = 0;
  /** 缓冲区大小 (上下各多渲染的行数) */
  @Prop bufferSize: number = 10;
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 初始滚动位置 */
  @Prop initialScrollIndex: number = 0;
  /** 获取项目数据回调 */
  getItemData?: (index: number) => AnyData;
  /** 滚动回调 */
  onScroll?: (scrollOffset: number, visibleRange: VisibleRangeInfo) => void;
  /** 项目渲染器 */
  @BuilderParam itemRenderer: (item: VirtualListItem<AnyData>) => void;
  
  @State viewportHeight: number = 0;
  @State scrollOffset: number = 0;
  @State listState: VirtualListState = {
    scrollOffset: 0,
    visibleStartIndex: 0,
    visibleEndIndex: 0,
    renderStartIndex: 0,
    renderEndIndex: 0,
  };
  
  private scrollController: Scroller = new Scroller();
  
  // 获取总高度
  private getTotalHeight(): number {
    return this.totalItems * this.itemHeight;
  }
  
  // 更新可见范围
  private updateVisibleRange(): void {
    if (this.viewportHeight <= 0 || this.totalItems <= 0) return;
    
    const config: VirtualListConfig = {
      itemHeight: this.itemHeight,
      viewportHeight: this.viewportHeight,
      bufferSize: this.bufferSize,
      totalItems: this.totalItems,
    };
    
    this.listState = calculateVisibleRange(config, this.scrollOffset);
    
    if (this.onScroll) {
      const visibleRange: VisibleRangeInfo = {
        start: this.listState.visibleStartIndex,
        end: this.listState.visibleEndIndex,
      };
      this.onScroll(this.scrollOffset, visibleRange);
    }
  }
  
  // 获取渲染的项目
  private getRenderItems(): VirtualListItem<AnyData>[] {
    const items: VirtualListItem<AnyData>[] = [];
    
    for (let i = this.listState.renderStartIndex; i <= this.listState.renderEndIndex && i < this.totalItems; i++) {
      const data: AnyData = this.getItemData ? this.getItemData(i) : {};
      items.push({
        index: i,
        data: data,
        offset: i * this.itemHeight,
      });
    }
    
    return items;
  }
  
  // 滚动到指定索引
  scrollToIndex(index: number, animated: boolean = true): void {
    const offset = index * this.itemHeight;
    this.scrollController.scrollTo({
      xOffset: 0,
      yOffset: offset,
      animation: animated ? {
        duration: AnimationDuration.NORMAL,
        curve: Curve.EaseInOut,
      } : undefined,
    });
  }
  
  // 滚动到顶部
  scrollToTop(animated: boolean = true): void {
    this.scrollToIndex(0, animated);
  }
  
  // 滚动到底部
  scrollToBottom(animated: boolean = true): void {
    this.scrollToIndex(this.totalItems - 1, animated);
  }
  
  aboutToAppear(): void {
    // 初始滚动位置
    if (this.initialScrollIndex > 0) {
      this.scrollOffset = this.initialScrollIndex * this.itemHeight;
    }
    this.updateVisibleRange();
  }
  
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Scroll(this.scrollController) {
        // 撑开滚动区域的容器
        Column() {
          // 实际渲染的项目
          ForEach(this.getRenderItems(), (item: VirtualListItem<AnyData>) => {
            Column() {
              if (this.itemRenderer) {
                this.itemRenderer(item);
              }
            }
            .width('100%')
            .height(this.itemHeight)
            .position({
              x: 0,
              y: item.offset
            })
          }, (item: VirtualListItem<AnyData>) => `item_${item.index}`)
        }
        .width('100%')
        .height(this.getTotalHeight())
        .position({ x: 0, y: 0 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Auto)
      .scrollBarColor(this.colors.border)
      .edgeEffect(EdgeEffect.None)
      .onScroll((xOffset: number, yOffset: number) => {
        this.scrollOffset = this.scrollController.currentOffset().yOffset;
        this.updateVisibleRange();
      })
      .onAreaChange((oldArea: Area, newArea: Area) => {
        const newHeight = newArea.height as number;
        if (this.viewportHeight !== newHeight) {
          this.viewportHeight = newHeight;
          this.updateVisibleRange();
        }
      })
    }
    .width('100%')
    .height('100%')
    .clip(true)
  }
}

// =====================================================
// 虚拟网格组件 (用于文件树等)
// =====================================================

@Component
export struct RFVirtualTree {
  /** 项目高度 */
  @Prop itemHeight: number = 32;
  /** 扁平化的树节点数据 */
  @Prop items: AnyData[] = [];
  /** 缓冲区大小 */
  @Prop bufferSize: number = 10;
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 节点点击回调 */
  onItemClick?: (item: AnyData, index: number) => void;
  /** 节点展开/折叠回调 */
  onToggle?: (item: AnyData, index: number) => void;
  /** 项目渲染器 */
  @BuilderParam itemRenderer: (item: AnyData, index: number) => void;
  
  @State viewportHeight: number = 0;
  @State scrollOffset: number = 0;
  @State listState: VirtualListState = {
    scrollOffset: 0,
    visibleStartIndex: 0,
    visibleEndIndex: 0,
    renderStartIndex: 0,
    renderEndIndex: 0,
  };
  
  private scrollController: Scroller = new Scroller();
  
  private getTotalHeight(): number {
    return this.items.length * this.itemHeight;
  }
  
  private updateVisibleRange(): void {
    if (this.viewportHeight <= 0 || this.items.length <= 0) return;
    
    const config: VirtualListConfig = {
      itemHeight: this.itemHeight,
      viewportHeight: this.viewportHeight,
      bufferSize: this.bufferSize,
      totalItems: this.items.length,
    };
    
    this.listState = calculateVisibleRange(config, this.scrollOffset);
  }
  
  private getRenderRange(): VisibleRangeInfo {
    const range: VisibleRangeInfo = {
      start: this.listState.renderStartIndex,
      end: Math.min(this.listState.renderEndIndex, this.items.length - 1),
    };
    return range;
  }
  
  aboutToAppear(): void {
    this.updateVisibleRange();
  }
  
  // 获取实际索引
  private getActualIndex(localIndex: number): number {
    return this.getRenderRange().start + localIndex;
  }
  
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Scroll(this.scrollController) {
        Column() {
          // 渲染可见范围内的项目
          ForEach(
            this.items.slice(
              this.getRenderRange().start,
              this.getRenderRange().end + 1
            ),
            (item: AnyData, localIndex: number) => {
              Column() {
                if (this.itemRenderer) {
                  this.itemRenderer(item, this.getActualIndex(localIndex));
                }
              }
              .width('100%')
              .height(this.itemHeight)
              .position({
                x: 0,
                y: this.getActualIndex(localIndex) * this.itemHeight
              })
              .onClick(() => {
                if (this.onItemClick) {
                  this.onItemClick(item, this.getActualIndex(localIndex));
                }
              })
            },
            (item: AnyData, localIndex: number) => {
              return `tree_item_${this.getActualIndex(localIndex)}`;
            }
          )
        }
        .width('100%')
        .height(this.getTotalHeight())
        .position({ x: 0, y: 0 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Auto)
      .scrollBarColor(this.colors.border)
      .edgeEffect(EdgeEffect.None)
      .onScroll(() => {
        this.scrollOffset = this.scrollController.currentOffset().yOffset;
        this.updateVisibleRange();
      })
      .onAreaChange((oldArea: Area, newArea: Area) => {
        const newHeight = newArea.height as number;
        if (this.viewportHeight !== newHeight) {
          this.viewportHeight = newHeight;
          this.updateVisibleRange();
        }
      })
    }
    .width('100%')
    .height('100%')
    .clip(true)
  }
}
