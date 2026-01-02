/**
 * RepoFlow Markdown 编辑器
 * 
 * 集成编辑和预览功能的富文本编辑器
 */

import { MarkdownNode, MarkdownNodeType, EditorMode, ToolbarAction, EditorState,
  EditorSelection, getMarkdownSyntax, MarkdownParser } from './MarkdownModels';
import { RFMarkdownPreview } from './MarkdownPreview';
import { Spacing, BorderRadius, FontSize, Shadow } from '../../theme/DesignTokens';
import { ThemeManager, ThemeColors } from '../../theme';

/**
 * 工具栏按钮
 */
interface ToolbarButton {
  action: ToolbarAction;
  icon: Resource;
  label: string;
}

/**
 * 工具栏配置
 */
const TOOLBAR_BUTTONS: ToolbarButton[][] = [
  [
    { action: ToolbarAction.HEADING1, icon: $r('sys.symbol.character'), label: 'H1' },
    { action: ToolbarAction.HEADING2, icon: $r('sys.symbol.character'), label: 'H2' },
    { action: ToolbarAction.HEADING3, icon: $r('sys.symbol.character'), label: 'H3' },
  ],
  [
    { action: ToolbarAction.BOLD, icon: $r('sys.symbol.bold'), label: '粗体' },
    { action: ToolbarAction.ITALIC, icon: $r('sys.symbol.italic'), label: '斜体' },
    { action: ToolbarAction.STRIKETHROUGH, icon: $r('sys.symbol.strikethrough'), label: '删除线' },
  ],
  [
    { action: ToolbarAction.CODE, icon: $r('app.media.ic_code'), label: '代码' },
    { action: ToolbarAction.CODE_BLOCK, icon: $r('app.media.ic_code'), label: '代码块' },
    { action: ToolbarAction.LINK, icon: $r('sys.symbol.link'), label: '链接' },
  ],
  [
    { action: ToolbarAction.QUOTE, icon: $r('app.media.ic_comment'), label: '引用' },
    { action: ToolbarAction.UNORDERED_LIST, icon: $r('sys.symbol.list_bullet'), label: '无序列表' },
    { action: ToolbarAction.ORDERED_LIST, icon: $r('sys.symbol.list_number'), label: '有序列表' },
  ],
];

/**
 * 工具栏按钮组件
 */
@Component
struct ToolbarButtonView {
  @Prop button: ToolbarButton = { action: ToolbarAction.BOLD, icon: $r('sys.symbol.bold'), label: '' };
  @Prop isCompact: boolean = false;
  onPress: (action: ToolbarAction) => void = () => {};
  private colors: ThemeColors = ThemeManager.colors;

  build() {
    Button({ type: ButtonType.Normal }) {
      Column() {
        if (this.button.action === ToolbarAction.HEADING1 ||
            this.button.action === ToolbarAction.HEADING2 ||
            this.button.action === ToolbarAction.HEADING3) {
          // 标题用文本显示
          Text(this.button.label)
            .fontSize(this.isCompact ? FontSize.CAPTION : FontSize.BODY)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textPrimary)
        } else {
          SymbolGlyph(this.button.icon)
            .fontSize(this.isCompact ? 16 : 20)
            .fontColor([this.colors.textPrimary])
        }
      }
      .justifyContent(FlexAlign.Center)
      .width(this.isCompact ? 28 : 36)
      .height(this.isCompact ? 28 : 36)
    }
    .backgroundColor(Color.Transparent)
    .borderRadius(BorderRadius.SM)
    .onClick(() => this.onPress(this.button.action))
  }
}

/**
 * 编辑器工具栏
 */
@Component
struct EditorToolbar {
  @Prop mode: EditorMode = EditorMode.EDIT;
  @Prop isCompact: boolean = false;
  onAction: (action: ToolbarAction) => void = () => {};
  onModeChange: (mode: EditorMode) => void = () => {};
  private colors: ThemeColors = ThemeManager.colors;

  build() {
    Column() {
      Row() {
        // 工具按钮
        Scroll() {
          Row() {
            ForEach(TOOLBAR_BUTTONS, (group: ToolbarButton[], groupIndex: number) => {
              Row() {
                ForEach(group, (button: ToolbarButton, buttonIndex: number) => {
                  ToolbarButtonView({
                    button: button,
                    isCompact: this.isCompact,
                    onPress: this.onAction
                  })
                }, (btn: ToolbarButton, idx: number) => `btn-${idx}`)
              }
              .margin({ right: Spacing.XS })

              if (groupIndex < TOOLBAR_BUTTONS.length - 1) {
                Divider()
                  .vertical(true)
                  .height(20)
                  .color(this.colors.border)
                  .margin({ right: Spacing.XS })
              }
            }, (group: ToolbarButton[], idx: number) => `group-${idx}`)
          }
          .padding({ left: Spacing.SM, right: Spacing.SM })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .layoutWeight(1)

        // 模式切换
        Row() {
          this.modeButton(EditorMode.EDIT, $r('app.media.ic_settings'), '编辑')
          this.modeButton(EditorMode.SPLIT, $r('sys.symbol.rectangle_split_2x1'), '分屏')
          this.modeButton(EditorMode.PREVIEW, $r('sys.symbol.eye'), '预览')
        }
        .backgroundColor(this.colors.surfaceVariant)
        .borderRadius(BorderRadius.SM)
        .padding(2)
      }
      .width('100%')
      .height(this.isCompact ? 40 : 48)
      .backgroundColor(this.colors.surface)
      .border({
        width: { bottom: 1 },
        color: this.colors.border
      })
    }
    .width('100%')
  }

  @Builder
  private modeButton(targetMode: EditorMode, icon: Resource, label: string) {
    Button({ type: ButtonType.Normal }) {
      SymbolGlyph(icon)
        .fontSize(16)
        .fontColor([this.mode === targetMode ? this.colors.primary : this.colors.textSecondary])
    }
    .width(32)
    .height(28)
    .backgroundColor(this.mode === targetMode ? this.colors.primaryContainer : Color.Transparent)
    .borderRadius(BorderRadius.XS)
    .onClick(() => this.onModeChange(targetMode))
  }
}

/**
 * 文本编辑区域
 */
@Component
struct EditorTextArea {
  @Link content: string;
  @Prop placeholder: string = '开始输入...';
  private colors: ThemeColors = ThemeManager.colors;

  build() {
    TextArea({ text: this.content, placeholder: this.placeholder })
      .fontSize(FontSize.BODY)
      .fontFamily('monospace')
      .fontColor(this.colors.textPrimary)
      .placeholderColor(this.colors.textTertiary)
      .backgroundColor(Color.Transparent)
      .caretColor(this.colors.primary)
      .width('100%')
      .height('100%')
      .padding(Spacing.MD)
      .onChange((value: string) => {
        this.content = value;
      })
  }
}

/**
 * 行号视图
 */
@Component
struct LineNumbers {
  @Prop lineCount: number = 1;
  private colors: ThemeColors = ThemeManager.colors;
  private getLineNumbers(): number[] {
    const result: number[] = [];
    for (let i = 1; i <= this.lineCount; i++) {
      result.push(i);
    }
    return result;
  }
  build() {
    Column() {
      ForEach(this.getLineNumbers(), (lineNum: number) => {
        Text(`${lineNum}`)
          .fontSize(FontSize.CAPTION)
          .fontFamily('monospace')
          .fontColor(this.colors.textTertiary)
          .height(20)
          .textAlign(TextAlign.End)
      }, (num: number) => `line-${num}`)
    }
    .width(40)
    .alignItems(HorizontalAlign.End)
    .padding({ top: Spacing.MD, right: Spacing.XS })
    .backgroundColor(this.colors.surfaceElevated)
    .border({
      width: { right: 1 },
      color: this.colors.border
    })
  }
}

/**
 * 编辑器状态栏
 */
// 编辑器统计信息接口
interface EditorStats {
  lines: number;
  words: number;
  chars: number;
}

@Component
struct EditorStatusBar {
  @Prop content: string = '';
  @Prop isDirty: boolean = false;
  private colors: ThemeColors = ThemeManager.colors;

  private getStats(): EditorStats {
    const lines = this.content.split('\n').length;
    const words = this.content.trim() ? this.content.trim().split(/\s+/).length : 0;
    const chars = this.content.length;
    const stats: EditorStats = { lines: lines, words: words, chars: chars };
    return stats;
  }

  build() {
    Row() {
      // 修改状态
      if (this.isDirty) {
        Row() {
          Circle()
            .width(6)
            .height(6)
            .fill(this.colors.warning)

          Text($r('app.string.unsaved'))
            .fontSize(FontSize.CAPTION)
            .fontColor(this.colors.textSecondary)
            .margin({ left: Spacing.XXS })
        }
      }

      Blank()

      // 统计信息
      Text(`${this.getStats().lines} 行 · ${this.getStats().words} 词 · ${this.getStats().chars} 字符`)
        .fontSize(FontSize.CAPTION)
        .fontColor(this.colors.textTertiary)
    }
    .width('100%')
    .height(24)
    .padding({ left: Spacing.SM, right: Spacing.SM })
    .backgroundColor(this.colors.surfaceElevated)
    .border({
      width: { top: 1 },
      color: this.colors.border
    })
  }
}

/**
 * Markdown 编辑器
 */
@Component
export struct RFMarkdownEditor {
  @Link content: string;
  @Prop placeholder: string = '开始输入 Markdown...';
  @Prop showLineNumbers: boolean = true;
  @Prop showStatusBar: boolean = true;
  @Prop initialMode: EditorMode = EditorMode.EDIT;
  @Prop minHeight: number = 300;
  onContentChange: (content: string) => void = () => {};
  onSave: (content: string) => void = () => {};

  @State mode: EditorMode = EditorMode.EDIT;
  @State isDirty: boolean = false;
  @State undoStack: string[] = [];
  @State redoStack: string[] = [];
  private colors: ThemeColors = ThemeManager.colors;
  private originalContent: string = '';

  aboutToAppear() {
    this.mode = this.initialMode;
    this.originalContent = this.content;
  }

  private handleAction(action: ToolbarAction) {
    if (action === ToolbarAction.UNDO) {
      this.undo();
      return;
    }
    if (action === ToolbarAction.REDO) {
      this.redo();
      return;
    }

    // 保存到撤销栈
    this.pushUndo();

    // 应用Markdown语法
    const syntax = getMarkdownSyntax(action);
    // 简化处理：在内容末尾添加语法
    if (this.content) {
      this.content = this.content + '\n' + syntax.prefix + syntax.placeholder + syntax.suffix;
    } else {
      this.content = syntax.prefix + syntax.placeholder + syntax.suffix;
    }

    this.markDirty();
  }

  private pushUndo() {
    this.undoStack.push(this.content);
    if (this.undoStack.length > 50) {
      this.undoStack.shift();
    }
    this.redoStack = [];
  }

  private undo() {
    if (this.undoStack.length > 0) {
      this.redoStack.push(this.content);
      this.content = this.undoStack.pop() || '';
    }
  }

  private redo() {
    if (this.redoStack.length > 0) {
      this.undoStack.push(this.content);
      this.content = this.redoStack.pop() || '';
    }
  }

  private markDirty() {
    this.isDirty = this.content !== this.originalContent;
    this.onContentChange(this.content);
  }

  private handleModeChange(newMode: EditorMode) {
    this.mode = newMode;
  }

  private getLineCount(): number {
    return this.content ? this.content.split('\n').length : 1;
  }

  build() {
    Column() {
      // 工具栏
      EditorToolbar({
        mode: this.mode,
        isCompact: false,
        onAction: (action: ToolbarAction): void => this.handleAction(action),
        onModeChange: (mode: EditorMode): void => this.handleModeChange(mode)
      })

      // 编辑区域
      Row() {
        if (this.mode === EditorMode.EDIT || this.mode === EditorMode.SPLIT) {
          // 编辑面板
          Column() {
            Row() {
              // 行号
              if (this.showLineNumbers) {
                Scroll() {
                  LineNumbers({ lineCount: this.getLineCount() })
                }
                .scrollBar(BarState.Off)
                .height('100%')
              }

              // 编辑区
              EditorTextArea({
                content: $content,
                placeholder: this.placeholder
              })
                .layoutWeight(1)
            }
            .width('100%')
            .layoutWeight(1)
          }
          .layoutWeight(1)
          .height('100%')
          .backgroundColor(this.colors.codeBackground)
        }

        // 分割线
        if (this.mode === EditorMode.SPLIT) {
          Divider()
            .vertical(true)
            .color(this.colors.border)
        }

        if (this.mode === EditorMode.PREVIEW || this.mode === EditorMode.SPLIT) {
          // 预览面板
          Column() {
            RFMarkdownPreview({ content: this.content })
          }
          .layoutWeight(1)
          .height('100%')
          .backgroundColor(this.colors.surface)
        }
      }
      .width('100%')
      .layoutWeight(1)
      .constraintSize({ minHeight: this.minHeight })

      // 状态栏
      if (this.showStatusBar) {
        EditorStatusBar({
          content: this.content,
          isDirty: this.isDirty
        })
      }
    }
    .width('100%')
    .height('100%')
    .borderRadius(BorderRadius.MD)
    .border({
      width: 1,
      color: this.colors.border
    })
    .clip(true)
  }
}

/**
 * 只读 Markdown 查看器
 */
@Component
export struct RFMarkdownViewer {
  @Prop content: string = '';
  @Prop maxHeight: number = 0;
  private colors: ThemeColors = ThemeManager.colors;

  build() {
    Column() {
      RFMarkdownPreview({ content: this.content })
    }
    .width('100%')
    .constraintSize({ maxHeight: this.maxHeight > 0 ? this.maxHeight : undefined })
    .backgroundColor(this.colors.surface)
    .borderRadius(BorderRadius.MD)
    .border({
      width: 1,
      color: this.colors.border
    })
    .clip(true)
  }
}

/**
 * 评论编辑器工具栏按钮接口
 */
interface CommentToolbarItem {
  action: ToolbarAction;
  icon: Resource;
}

/**
 * 评论编辑器（简化版）
 */
@Component
export struct RFCommentEditor {
  @Link content: string;
  @Prop placeholder: string = '写下你的评论...';
  @Prop minHeight: number = 100;
  onSubmit: (content: string) => void = () => {};
  onCancel: () => void = () => {};

  @State showPreview: boolean = false;
  private colors: ThemeColors = ThemeManager.colors;

  private getQuickToolbarButtons(): CommentToolbarItem[] {
    return [
      { action: ToolbarAction.BOLD, icon: $r('sys.symbol.bold') },
      { action: ToolbarAction.ITALIC, icon: $r('sys.symbol.italic') },
      { action: ToolbarAction.CODE, icon: $r('app.media.ic_code') },
      { action: ToolbarAction.LINK, icon: $r('sys.symbol.link') },
    ];
  }

  build() {
    Column() {
      // 简化工具栏
      Row() {
        Row() {
          ForEach(this.getQuickToolbarButtons(), (item: CommentToolbarItem) => {
            Button({ type: ButtonType.Normal }) {
              SymbolGlyph(item.icon)
                .fontSize(16)
                .fontColor([this.colors.textSecondary])
            }
            .width(28)
            .height(28)
            .backgroundColor(Color.Transparent)
            .borderRadius(BorderRadius.XS)
            .onClick(() => this.handleAction(item.action))
          }, (item: CommentToolbarItem) => item.action)
        }

        Blank()

        // 预览切换
        Button({ type: ButtonType.Normal }) {
          SymbolGlyph(this.showPreview ? $r('app.media.ic_settings') : $r('sys.symbol.eye'))
            .fontSize(16)
            .fontColor([this.colors.textSecondary])
        }
        .width(28)
        .height(28)
        .backgroundColor(Color.Transparent)
        .borderRadius(BorderRadius.XS)
        .onClick(() => {
          this.showPreview = !this.showPreview;
        })
      }
      .width('100%')
      .height(36)
      .padding({ left: Spacing.SM, right: Spacing.SM })
      .backgroundColor(this.colors.surfaceVariant)

      // 内容区域
      if (this.showPreview) {
        Scroll() {
          RFMarkdownPreview({ content: this.content })
        }
        .width('100%')
        .constraintSize({ minHeight: this.minHeight, maxHeight: 200 })
        .backgroundColor(this.colors.surface)
      } else {
        TextArea({ text: this.content, placeholder: this.placeholder })
          .fontSize(FontSize.BODY)
          .fontColor(this.colors.textPrimary)
          .placeholderColor(this.colors.textTertiary)
          .backgroundColor(this.colors.surface)
          .caretColor(this.colors.primary)
          .width('100%')
          .constraintSize({ minHeight: this.minHeight })
          .padding(Spacing.SM)
          .onChange((value: string) => {
            this.content = value;
          })
      }

      // 操作按钮
      Row() {
        Button($r('app.string.cancel'))
          .fontSize(FontSize.BODY)
          .fontColor(this.colors.textSecondary)
          .backgroundColor(Color.Transparent)
          .onClick(() => this.onCancel())

        Blank()

        Button($r('app.string.submit'))
          .fontSize(FontSize.BODY)
          .fontColor(this.colors.onPrimary)
          .backgroundColor(this.colors.primary)
          .borderRadius(BorderRadius.SM)
          .onClick(() => {
            if (this.content.trim()) {
              this.onSubmit(this.content);
            }
          })
      }
      .width('100%')
      .padding(Spacing.SM)
    }
    .width('100%')
    .borderRadius(BorderRadius.MD)
    .border({
      width: 1,
      color: this.colors.border
    })
    .clip(true)
  }

  private handleAction(action: ToolbarAction) {
    const syntax = getMarkdownSyntax(action);
    this.content = this.content + syntax.prefix + syntax.placeholder + syntax.suffix;
  }
}
