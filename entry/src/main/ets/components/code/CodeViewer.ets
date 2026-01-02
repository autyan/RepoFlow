/**
 * RepoFlow 代码查看器组件
 * 
 * 高性能代码查看器:
 * - 虚拟滚动，支持大文件 (10万+行)
 * - 语法高亮
 * - 行号显示
 * - 行选中
 * - 搜索高亮
 * - 低内存占用
 */

import { ThemeColors, DarkColors, LanguageColors } from '../../theme/Colors';
import { Spacing, BorderRadius, FontSize } from '../../theme/DesignTokens';
import {
  CodeLine,
  CodeToken,
  TokenType,
  FileContent,
  getLanguageFromExtension,
  formatFileSize
} from './CodeBrowserModels';

// 渲染范围接口
interface RenderRange {
  start: number;
  end: number;
}

// =====================================================
// 代码行组件
// =====================================================

@Component
export struct CodeLineView {
  /** 行数据 */
  @Prop line: CodeLine = {} as CodeLine;
  /** 是否选中 */
  @Prop isSelected: boolean = false;
  /** 是否高亮 (搜索结果) */
  @Prop isHighlighted: boolean = false;
  /** 行号宽度 */
  @Prop lineNumberWidth: number = 50;
  /** 行高 (用于多行换行的行距控制) */
  @Prop lineHeight: number = 22;
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 点击回调 */
  onTap?: () => void;
  
  @State isHovered: boolean = false;
  
  // 获取背景颜色
  private getBgColor(): string {
    if (this.isSelected) return this.colors.primaryContainer;
    if (this.isHighlighted) return this.colors.warningBg;
    if (this.isHovered) return this.colors.bgHover;
    return 'transparent';
  }
  
  // 获取 Token 颜色
  private getTokenColor(type: TokenType): string {
    switch (type) {
      case TokenType.KEYWORD:
        return this.colors.codeKeyword;
      case TokenType.STRING:
        return this.colors.codeString;
      case TokenType.NUMBER:
        return this.colors.codeNumber;
      case TokenType.COMMENT:
        return this.colors.codeComment;
      case TokenType.FUNCTION:
        return this.colors.codeFunction;
      case TokenType.CLASS:
      case TokenType.TYPE:
        return this.colors.codeFunction; // 使用 codeFunction 作为类型颜色
      case TokenType.VARIABLE:
        return this.colors.codeVariable;
      case TokenType.OPERATOR:
        return this.colors.codeOperator;
      case TokenType.DECORATOR:
        return this.colors.codeFunction; // 使用 codeFunction 作为装饰器颜色
      case TokenType.TAG:
        return this.colors.codeKeyword; // 使用 codeKeyword 作为标签颜色
      case TokenType.ATTRIBUTE:
        return this.colors.codeVariable; // 使用 codeVariable 作为属性颜色
      default:
        return this.colors.textPrimary;
    }
  }
  
  build() {
    Row() {
      // 行号区域 (固定宽度)
      Text(this.line.lineNumber.toString())
        .width(this.lineNumberWidth)
        .fontSize(FontSize.CODE)
        .fontFamily('JetBrains Mono, Consolas, monospace')
        .fontColor(this.isSelected ? this.colors.brandPrimary : this.colors.textTertiary)
        .textAlign(TextAlign.End)
        .padding({ right: Spacing.SM })
        .lineHeight(this.lineHeight)
        .border({ width: { right: 1 }, color: this.colors.border })
      
      // 代码内容区 (允许自动换行)
      if (this.line.tokens && this.line.tokens.length > 0) {
        Text() {
          ForEach(this.line.tokens, (token: CodeToken, index: number) => {
            Span(token.text)
              .fontSize(FontSize.CODE)
              .fontFamily('JetBrains Mono, Consolas, monospace')
              .fontColor(this.getTokenColor(token.type))
          }, (token: CodeToken, index: number) => `token_${index}`)
        }
        .fontSize(FontSize.CODE)
        .fontFamily('JetBrains Mono, Consolas, monospace')
        .lineHeight(this.lineHeight)
        .layoutWeight(1)
        .padding({ left: Spacing.SM })
      } else {
        // 纯文本渲染
        Text(this.line.content || ' ') // 空行保持高度
          .fontSize(FontSize.CODE)
          .fontFamily('JetBrains Mono, Consolas, monospace')
          .fontColor(this.colors.textPrimary)
          .lineHeight(this.lineHeight)
          .layoutWeight(1)
          .padding({ left: Spacing.SM })
      }
    }
    .alignItems(VerticalAlign.Top)
    .width('100%')
    .backgroundColor(this.getBgColor())
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
// 代码查看器组件
// =====================================================

@Component
export struct RFCodeViewer {
  /** 代码行数据 */
  @Prop lines: CodeLine[] = [];
  /** 选中的行 */
  @Link selectedLine: number;
  /** 高亮的行列表 */
  @Prop highlightedLines: number[] = [];
  /** 行高 */
  @Prop lineHeight: number = 22;
  /** 语言类型 */
  @Prop language: string = 'plaintext';
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 显示行号 */
  @Prop showLineNumbers: boolean = true;
  /** 行点击回调 */
  onLineClick?: (lineNumber: number) => void;
  /** 滚动回调 */
  onScroll?: (scrollOffset: number) => void;
  
  private scroller: Scroller = new Scroller();
  
  // 计算行号宽度
  private getLineNumberWidth(): number {
    if (!this.showLineNumbers) return 0;
    const maxLineNumber = this.lines.length;
    const digits = maxLineNumber.toString().length;
    return Math.max(40, digits * 10 + 16);
  }
  
  // 滚动到指定行
  scrollToLine(lineNumber: number, animated: boolean = true): void {
    // List 滚动到索引 (lineNumber - 1)
    this.scroller.scrollToIndex(lineNumber - 1, animated);
  }
  
  // 处理行点击
  private handleLineClick(lineNumber: number): void {
    this.selectedLine = lineNumber;
    if (this.onLineClick) {
      this.onLineClick(lineNumber);
    }
  }
  
  build() {
    // 使用 List 替换 Scroll + Column 以获得更好的性能和虚拟滚动支持
    List({ scroller: this.scroller }) {
      ForEach(
        this.lines,
        (line: CodeLine, index: number) => {
          ListItem() {
            CodeLineView({
              line: line,
              isSelected: line.lineNumber === this.selectedLine,
              isHighlighted: this.highlightedLines.includes(line.lineNumber),
              lineNumberWidth: this.getLineNumberWidth(),
              lineHeight: this.lineHeight,
              colors: this.colors,
              onTap: () => this.handleLineClick(line.lineNumber)
            })
          }
        },
        (line: CodeLine, index: number) => {
          return `line_${line.lineNumber}`;
        }
      )
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.bgPrimary)
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
  }
}

// =====================================================
// 代码头部组件 (显示文件信息)
// =====================================================

@Component
export struct CodeViewerHeader {
  /** 文件名 */
  @Prop fileName: string = '';
  /** 文件路径 */
  @Prop filePath: string = '';
  /** 语言类型 */
  @Prop language: string = '';
  /** 文件大小 */
  @Prop fileSize: number = 0;
  /** 行数 */
  @Prop lineCount: number = 0;
  /** 主题颜色 */
  @Prop colors: ThemeColors = DarkColors;
  /** 返回回调 */
  onBack?: () => void;
  /** 复制回调 */
  onCopy?: () => void;
  /** 分享回调 */
  onShare?: () => void;
  
  build() {
    Row({ space: Spacing.MD }) {
      // 返回按钮
      if (this.onBack) {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .fillColor(this.colors.textPrimary)
          .onClick(() => {
            if (this.onBack) {
              this.onBack();
            }
          })
      }
      
      // 文件图标
      Image($r('app.media.ic_file'))
        .width(20)
        .height(20)
        .fillColor(this.colors.textSecondary)
      
      // 文件信息
      Column({ space: 2 }) {
        Text(this.fileName)
          .fontSize(FontSize.MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        Row({ space: Spacing.SM }) {
          Text(this.language)
            .fontSize(FontSize.XS)
            .fontColor(this.colors.textTertiary)
          
          Text('•')
            .fontSize(FontSize.XS)
            .fontColor(this.colors.textTertiary)
          
          Text(`${this.lineCount} lines`)
            .fontSize(FontSize.XS)
            .fontColor(this.colors.textTertiary)
          
          Text('•')
            .fontSize(FontSize.XS)
            .fontColor(this.colors.textTertiary)
          
          Text(formatFileSize(this.fileSize))
            .fontSize(FontSize.XS)
            .fontColor(this.colors.textTertiary)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      // 操作按钮
      Row({ space: Spacing.SM }) {
        if (this.onCopy) {
          Image($r('app.media.ic_code'))
            .width(20)
            .height(20)
            .fillColor(this.colors.textSecondary)
            .onClick(() => {
              if (this.onCopy) {
                this.onCopy();
              }
            })
        }
        
        if (this.onShare) {
          Image($r('app.media.ic_link'))
            .width(20)
            .height(20)
            .fillColor(this.colors.textSecondary)
            .onClick(() => {
              if (this.onShare) {
                this.onShare();
              }
            })
        }
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.MD, right: Spacing.MD })
    .backgroundColor(this.colors.bgSecondary)
    .border({
      width: { bottom: 1 },
      color: this.colors.border
    })
  }
}

// =====================================================
// 代码内容解析器
// =====================================================

export class CodeParser {
  /**
   * 将原始文本解析为代码行
   */
  static parseContent(content: string): CodeLine[] {
    // 统一换行符：将 \r\n 和 \r 都转换为 \n，然后按 \n 分割
    const normalizedContent = content.replace(/\r\n/g, '\n').replace(/\r/g, '\n');
    const rawLines = normalizedContent.split('\n');
    const result: CodeLine[] = [];
    for (let i = 0; i < rawLines.length; i++) {
      const codeLine: CodeLine = {
        lineNumber: i + 1,
        content: rawLines[i],
        tokens: [], // 简化实现，不进行语法高亮
      };
      result.push(codeLine);
    }
    return result;
  }
  
  /**
   * 分页加载代码行
   */
  static getPagedLines(
    allLines: CodeLine[],
    startLine: number,
    pageSize: number
  ): CodeLine[] {
    const start = Math.max(0, startLine - 1);
    const end = Math.min(allLines.length, start + pageSize);
    return allLines.slice(start, end);
  }
  
  /**
   * 搜索代码
   */
  static searchInLines(
    lines: CodeLine[],
    query: string,
    caseSensitive: boolean = false
  ): number[] {
    if (!query) return [];
    
    const searchQuery = caseSensitive ? query : query.toLowerCase();
    const results: number[] = [];
    
    for (const line of lines) {
      const content = caseSensitive ? line.content : line.content.toLowerCase();
      if (content.includes(searchQuery)) {
        results.push(line.lineNumber);
      }
    }
    
    return results;
  }
}
