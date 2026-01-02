/**
 * RepoFlow Markdown 预览渲染器
 * 
 * 将Markdown节点树渲染为ArkUI组件
 */

import { MarkdownNode, MarkdownNodeType, MarkdownParser } from './MarkdownModels';
import { Spacing, BorderRadius, FontSize } from '../../theme/DesignTokens';
import { ThemeManager, ThemeColors, getLanguageColor } from '../../theme';

/**
 * 文本节点渲染
 */
@Component
struct TextNodeView {
  @Prop content: string = '';
  @Prop fontSize: number = FontSize.BODY;
  @Prop fontWeight: FontWeight = FontWeight.Normal;
  @Prop fontStyle: FontStyle = FontStyle.Normal;
  @Prop textDecoration: TextDecorationType = TextDecorationType.None;
  @Prop textColor: ResourceColor = '';

  build() {
    Text(this.content)
      .fontSize(this.fontSize)
      .fontWeight(this.fontWeight)
      .fontStyle(this.fontStyle)
      .decoration({ type: this.textDecoration })
      .fontColor(this.textColor || ThemeManager.colors.textPrimary)
  }
}

/**
 * 行内元素渲染
 */
@Component
struct InlineNodeView {
  @Prop node: MarkdownNode = { type: MarkdownNodeType.TEXT } as MarkdownNode;
  private colors: ThemeColors = ThemeManager.colors;

  build() {
    if (this.node.type === MarkdownNodeType.TEXT) {
      Text(this.node.content || '')
        .fontSize(FontSize.BODY)
        .fontColor(this.colors.textPrimary)
    } else if (this.node.type === MarkdownNodeType.BOLD) {
      Text(this.node.content || '')
        .fontSize(FontSize.BODY)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.colors.textPrimary)
    } else if (this.node.type === MarkdownNodeType.ITALIC) {
      Text(this.node.content || '')
        .fontSize(FontSize.BODY)
        .fontStyle(FontStyle.Italic)
        .fontColor(this.colors.textPrimary)
    } else if (this.node.type === MarkdownNodeType.STRIKETHROUGH) {
      Text(this.node.content || '')
        .fontSize(FontSize.BODY)
        .decoration({ type: TextDecorationType.LineThrough })
        .fontColor(this.colors.textSecondary)
    } else if (this.node.type === MarkdownNodeType.CODE) {
      Text(this.node.content || '')
        .fontSize(FontSize.CAPTION)
        .fontFamily('monospace')
        .fontColor(this.colors.syntaxKeyword)
        .backgroundColor(this.colors.surfaceVariant)
        .padding({ left: Spacing.XXS, right: Spacing.XXS })
        .borderRadius(BorderRadius.XS)
    } else if (this.node.type === MarkdownNodeType.LINK) {
      Text(this.node.content || '')
        .fontSize(FontSize.BODY)
        .fontColor(this.colors.brandPrimary)
        .decoration({ type: TextDecorationType.Underline })
    } else {
      Text(this.node.content || '')
        .fontSize(FontSize.BODY)
        .fontColor(this.colors.textPrimary)
    }
  }
}

/**
 * 标题样式接口
 */
interface HeadingStyle {
  fontSize: number;
  fontWeight: FontWeight;
}

/**
 * 标题渲染
 */
@Component
struct HeadingView {
  @Prop node: MarkdownNode = { type: MarkdownNodeType.HEADING1 } as MarkdownNode;
  private colors: ThemeColors = ThemeManager.colors;

  private getHeadingStyle(): HeadingStyle {
    switch (this.node.type) {
      case MarkdownNodeType.HEADING1:
        return { fontSize: FontSize.DISPLAY, fontWeight: FontWeight.Bold } as HeadingStyle;
      case MarkdownNodeType.HEADING2:
        return { fontSize: FontSize.HEADLINE, fontWeight: FontWeight.Bold } as HeadingStyle;
      case MarkdownNodeType.HEADING3:
        return { fontSize: FontSize.TITLE, fontWeight: FontWeight.Medium } as HeadingStyle;
      case MarkdownNodeType.HEADING4:
        return { fontSize: FontSize.SUBTITLE, fontWeight: FontWeight.Medium } as HeadingStyle;
      case MarkdownNodeType.HEADING5:
        return { fontSize: FontSize.BODY, fontWeight: FontWeight.Medium } as HeadingStyle;
      case MarkdownNodeType.HEADING6:
        return { fontSize: FontSize.CAPTION, fontWeight: FontWeight.Medium } as HeadingStyle;
      default:
        return { fontSize: FontSize.BODY, fontWeight: FontWeight.Normal } as HeadingStyle;
    }
  }

  build() {
    Column() {
      Text(this.node.content || '')
        .fontSize(this.getHeadingStyle().fontSize)
        .fontWeight(this.getHeadingStyle().fontWeight)
        .fontColor(this.colors.textPrimary)
        .width('100%')

      if (this.node.type === MarkdownNodeType.HEADING1 ||
        this.node.type === MarkdownNodeType.HEADING2) {
        Divider()
          .color(this.colors.border)
          .margin({ top: Spacing.XS })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}

/**
 * 代码块渲染
 */
@Component
struct CodeBlockView {
  @Prop node: MarkdownNode = { type: MarkdownNodeType.CODE_BLOCK };
  private colors: ThemeColors = ThemeManager.colors;

  build() {
    Column() {
      // 语言标签
      if (this.node.language) {
        Row() {
          Circle()
            .width(8)
            .height(8)
            .fill(getLanguageColor(this.node.language))

          Text(this.node.language)
            .fontSize(FontSize.CAPTION)
            .fontColor(this.colors.textSecondary)
            .margin({ left: Spacing.XXS })
        }
        .padding({ left: Spacing.SM, top: Spacing.XS, bottom: Spacing.XS })
        .width('100%')
        .backgroundColor(this.colors.surfaceElevated)
        .borderRadius({
          topLeft: BorderRadius.SM,
          topRight: BorderRadius.SM
        })
      }

      // 代码内容
      Scroll() {
        Text(this.node.content || '')
          .fontSize(FontSize.CAPTION)
          .fontFamily('monospace')
          .fontColor(this.colors.textPrimary)
          .width('100%')
          .lineHeight(20)
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Auto)
      .padding(Spacing.SM)
      .backgroundColor(this.colors.codeBackground)
      .borderRadius(this.node.language ? {
        bottomLeft: BorderRadius.SM,
        bottomRight: BorderRadius.SM
      } : BorderRadius.SM)
      .width('100%')
    }
    .width('100%')
  }
}

/**
 * 引用块渲染
 */
@Component
struct BlockquoteView {
  @Prop node: MarkdownNode = { type: MarkdownNodeType.BLOCKQUOTE };
  private colors: ThemeColors = ThemeManager.colors;

  build() {
    Row() {
      // 左边框
      Column()
        .width(4)
        .height('100%')
        .backgroundColor(this.colors.primary)
        .borderRadius(2)

      // 内容
      Column() {
        if (this.node.children && this.node.children.length > 0) {
          ForEach(this.node.children, (child: MarkdownNode, index: number) => {
            MarkdownNodeView({ node: child })
          }, (node: MarkdownNode, index: number) => `quote-child-${index}`)
        } else {
          Text(this.node.content || '')
            .fontSize(FontSize.BODY)
            .fontColor(this.colors.textSecondary)
            .fontStyle(FontStyle.Italic)
        }
      }
      .padding({ left: Spacing.SM })
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ left: Spacing.SM })
  }
}

/**
 * 列表渲染
 */
@Component
struct ListViewComponent {
  @Prop node: MarkdownNode = { type: MarkdownNodeType.UNORDERED_LIST };
  private colors: ThemeColors = ThemeManager.colors;

  build() {
    Column() {
      ForEach(this.node.children || [], (item: MarkdownNode, index: number) => {
        Row() {
          // 列表标记
          if (this.node.type === MarkdownNodeType.UNORDERED_LIST) {
            Text('•')
              .fontSize(FontSize.BODY)
              .fontColor(this.colors.textSecondary)
              .width(20)
              .textAlign(TextAlign.Center)
          } else {
            Text(`${(this.node.start || 1) + index}.`)
              .fontSize(FontSize.BODY)
              .fontColor(this.colors.textSecondary)
              .width(24)
              .textAlign(TextAlign.End)
              .margin({ right: Spacing.XXS })
          }

          // 列表内容
          Column() {
            if (item.children && item.children.length > 0) {
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(item.children, (child: MarkdownNode, childIndex: number) => {
                  InlineNodeView({ node: child })
                }, (node: MarkdownNode, idx: number) => `list-inline-${idx}`)
              }
            } else {
              Text(item.content || '')
                .fontSize(FontSize.BODY)
                .fontColor(this.colors.textPrimary)
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
        .margin({ bottom: Spacing.XXS })
      }, (item: MarkdownNode, index: number) => `list-item-${index}`)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: Spacing.SM })
  }
}

/**
 * 表格渲染
 */
@Component
struct TableView {
  @Prop node: MarkdownNode = { type: MarkdownNodeType.TABLE };
  private colors: ThemeColors = ThemeManager.colors;

  build() {
    Column() {
      ForEach(this.node.children || [], (row: MarkdownNode, rowIndex: number) => {
        Row() {
          ForEach(row.children || [], (cell: MarkdownNode, cellIndex: number) => {
            Column() {
              Text(cell.content || '')
                .fontSize(FontSize.CAPTION)
                .fontWeight(row.isHeader ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.colors.textPrimary)
                .maxLines(3)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .padding(Spacing.XS)
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            .backgroundColor(row.isHeader ? this.colors.surfaceElevated : Color.Transparent)
            .border({
              width: { right: 1, bottom: 1 },
              color: this.colors.border
            })
          }, (cell: MarkdownNode, idx: number) => `cell-${idx}`)
        }
        .width('100%')
      }, (row: MarkdownNode, index: number) => `row-${index}`)
    }
    .width('100%')
    .border({
      width: { left: 1, top: 1 },
      color: this.colors.border
    })
    .borderRadius(BorderRadius.SM)
    .clip(true)
  }
}

/**
 * 水平分割线
 */
@Component
struct HorizontalRuleView {
  private colors: ThemeColors = ThemeManager.colors;

  build() {
    Divider()
      .color(this.colors.border)
      .strokeWidth(2)
      .margin({ top: Spacing.MD, bottom: Spacing.MD })
  }
}

/**
 * 图片渲染
 */
@Component
struct ImageView {
  @Prop node: MarkdownNode = { type: MarkdownNodeType.IMAGE };
  @State loadError: boolean = false;
  private colors: ThemeColors = ThemeManager.colors;

  build() {
    Column() {
      if (this.loadError) {
        Column() {
          SymbolGlyph($r('app.media.ic_file'))
            .fontSize(32)
            .fontColor([this.colors.textTertiary])

          Text(this.node.alt || '图片加载失败')
            .fontSize(FontSize.CAPTION)
            .fontColor(this.colors.textSecondary)
            .margin({ top: Spacing.XS })
        }
        .width('100%')
        .height(120)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.colors.surfaceVariant)
        .borderRadius(BorderRadius.SM)
      } else {
        Image(this.node.url || '')
          .width('100%')
          .objectFit(ImageFit.Contain)
          .borderRadius(BorderRadius.SM)
          .onError(() => {
            this.loadError = true;
          })
      }

      // 图片描述
      if (this.node.alt && !this.loadError) {
        Text(this.node.alt)
          .fontSize(FontSize.CAPTION)
          .fontColor(this.colors.textSecondary)
          .margin({ top: Spacing.XXS })
          .width('100%')
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
}

/**
 * 段落渲染
 */
@Component
struct ParagraphView {
  @Prop node: MarkdownNode = { type: MarkdownNodeType.PARAGRAPH };
  private colors: ThemeColors = ThemeManager.colors;

  build() {
    Flex({ wrap: FlexWrap.Wrap }) {
      if (this.node.children && this.node.children.length > 0) {
        ForEach(this.node.children, (child: MarkdownNode, index: number) => {
          InlineNodeView({ node: child })
        }, (node: MarkdownNode, idx: number) => `para-inline-${idx}`)
      } else {
        Text(this.node.content || '')
          .fontSize(FontSize.BODY)
          .fontColor(this.colors.textPrimary)
          .lineHeight(24)
      }
    }
    .width('100%')
  }
}

/**
 * Markdown节点视图
 */
@Component
export struct MarkdownNodeView {
  @Prop node: MarkdownNode = { type: MarkdownNodeType.TEXT };

  build() {
    Column() {
      if (this.isHeading()) {
        HeadingView({ node: this.node })
      } else if (this.node.type === MarkdownNodeType.CODE_BLOCK) {
        CodeBlockView({ node: this.node })
      } else if (this.node.type === MarkdownNodeType.BLOCKQUOTE) {
        BlockquoteView({ node: this.node })
      } else if (this.node.type === MarkdownNodeType.UNORDERED_LIST ||
        this.node.type === MarkdownNodeType.ORDERED_LIST) {
        ListViewComponent({ node: this.node })
      } else if (this.node.type === MarkdownNodeType.TABLE) {
        TableView({ node: this.node })
      } else if (this.node.type === MarkdownNodeType.HORIZONTAL_RULE) {
        HorizontalRuleView()
      } else if (this.node.type === MarkdownNodeType.IMAGE) {
        ImageView({ node: this.node })
      } else if (this.node.type === MarkdownNodeType.PARAGRAPH) {
        ParagraphView({ node: this.node })
      } else {
        // 其他类型使用行内渲染
        InlineNodeView({ node: this.node })
      }
    }
    .width('100%')
    .margin({ bottom: Spacing.SM })
  }

  private isHeading(): boolean {
    return [
      MarkdownNodeType.HEADING1,
      MarkdownNodeType.HEADING2,
      MarkdownNodeType.HEADING3,
      MarkdownNodeType.HEADING4,
      MarkdownNodeType.HEADING5,
      MarkdownNodeType.HEADING6,
    ].includes(this.node.type);
  }
}

/**
 * Markdown 预览组件
 */
@Component
export struct RFMarkdownPreview {
  @Prop content: string = '';
  @State nodes: MarkdownNode[] = [];
  private colors: ThemeColors = ThemeManager.colors;

  aboutToAppear() {
    this.parseContent();
  }

  private parseContent() {
    if (this.content) {
      this.nodes = MarkdownParser.parse(this.content);
    } else {
      this.nodes = [];
    }
  }

  build() {
    Scroll() {
      Column() {
        if (this.nodes.length > 0) {
          ForEach(this.nodes, (node: MarkdownNode, index: number) => {
            MarkdownNodeView({ node: node })
          }, (node: MarkdownNode, idx: number) => `md-node-${idx}`)
        } else {
          Column() {
            SymbolGlyph($r('sys.symbol.doc_text'))
              .fontSize(48)
              .fontColor([this.colors.textTertiary])

            Text($r('app.string.no_content'))
              .fontSize(FontSize.BODY)
              .fontColor(this.colors.textSecondary)
              .margin({ top: Spacing.SM })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .padding(Spacing.MD)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Auto)
  }
}
