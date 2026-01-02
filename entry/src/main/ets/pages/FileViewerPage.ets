/**
 * 文件查看器页面
 * 
 * 功能:
 * - 显示代码文件内容
 * - 支持语法高亮
 * - 支持响应式布局和主题切换
 */

import router from '@ohos.router';
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
  RFButton,
} from '../components';

// 关键字映射
const KEYWORDS: Record<string, string[]> = {
  'ts': ['import', 'export', 'from', 'const', 'let', 'var', 'function', 'class', 'interface', 'type', 'enum', 'return', 'if', 'else', 'for', 'while', 'switch', 'case', 'break', 'continue', 'try', 'catch', 'throw', 'async', 'await', 'new', 'this', 'extends', 'implements', 'public', 'private', 'protected', 'static', 'readonly', 'abstract', 'as', 'typeof', 'instanceof', 'null', 'undefined', 'true', 'false', 'void', 'never', 'any', 'string', 'number', 'boolean', 'object'],
  'js': ['import', 'export', 'from', 'const', 'let', 'var', 'function', 'class', 'return', 'if', 'else', 'for', 'while', 'switch', 'case', 'break', 'continue', 'try', 'catch', 'throw', 'async', 'await', 'new', 'this', 'extends', 'null', 'undefined', 'true', 'false'],
  'py': ['import', 'from', 'as', 'def', 'class', 'return', 'if', 'elif', 'else', 'for', 'while', 'break', 'continue', 'try', 'except', 'finally', 'raise', 'with', 'async', 'await', 'lambda', 'yield', 'pass', 'None', 'True', 'False', 'and', 'or', 'not', 'in', 'is', 'global', 'nonlocal', 'assert', 'del'],
  'java': ['import', 'package', 'public', 'private', 'protected', 'class', 'interface', 'extends', 'implements', 'return', 'if', 'else', 'for', 'while', 'switch', 'case', 'break', 'continue', 'try', 'catch', 'throw', 'throws', 'finally', 'new', 'this', 'super', 'static', 'final', 'abstract', 'void', 'int', 'long', 'double', 'float', 'boolean', 'char', 'byte', 'short', 'null', 'true', 'false', 'instanceof', 'synchronized'],
  'go': ['package', 'import', 'func', 'type', 'struct', 'interface', 'return', 'if', 'else', 'for', 'range', 'switch', 'case', 'break', 'continue', 'go', 'chan', 'select', 'defer', 'map', 'make', 'new', 'var', 'const', 'nil', 'true', 'false', 'iota'],
};

interface RouteParams {
  owner: string;
  repo: string;
  path: string;
  branch: string;
  fileName: string;
}

interface CodeLine {
  lineNumber: number;
  content: string;
}

// =====================================================
// 文件查看器页面
// =====================================================
@Entry
@Component
struct FileViewerPage {
  // 数据状态
  @State isLoading: boolean = true;
  @State error: string = '';
  @State fileContent: string = '';
  @State codeLines: CodeLine[] = [];
  @State fileName: string = '';

  private owner: string = '';
  private repoName: string = '';
  private filePath: string = '';
  private branch: string = 'main';

  private t(res: Resource, ...args: Array<string | number>): string {
    const rm = getContext(this).resourceManager;
    return rm.getStringSync(res.id, ...args);
  }

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
      this.filePath = params.path;
      this.branch = params.branch;
      this.fileName = params.fileName;
      this.loadFile();
    }
  }

  // =====================================================
  // 数据加载
  // =====================================================

  async loadFile(): Promise<void> {
    this.isLoading = true;
    this.error = '';

    const api = authManager.getGitHubApi();
    if (!api) {
      this.error = this.t($r('app.string.please_login'));
      this.isLoading = false;
      return;
    }

    try {
      const content = await api.getRawFileContent(this.owner, this.repoName, this.filePath, this.branch);
      this.fileContent = content;
      this.parseCodeLines(content);
    } catch (err) {
      this.error = this.t($r('app.string.load_file_failed'));
      console.error('Load file failed:', JSON.stringify(err));
    } finally {
      this.isLoading = false;
    }
  }

  parseCodeLines(content: string): void {
    const lines = content.split('\n');
    const result: CodeLine[] = [];
    for (let index = 0; index < lines.length; index++) {
      const codeLine: CodeLine = { lineNumber: index + 1, content: lines[index] };
      result.push(codeLine);
    }
    this.codeLines = result;
  }

  // =====================================================
  // 工具方法
  // =====================================================

  getFileExtension(): string {
    const parts = this.fileName.split('.');
    return parts.length > 1 ? parts[parts.length - 1].toLowerCase() : '';
  }

  getLanguage(): string {
    const ext = this.getFileExtension();
    const languageMap: Record<string, string> = {
      'ts': 'TypeScript',
      'tsx': 'TypeScript',
      'js': 'JavaScript',
      'jsx': 'JavaScript',
      'py': 'Python',
      'java': 'Java',
      'kt': 'Kotlin',
      'go': 'Go',
      'rs': 'Rust',
      'c': 'C',
      'cpp': 'C++',
      'h': 'C Header',
      'swift': 'Swift',
      'rb': 'Ruby',
      'php': 'PHP',
      'cs': 'C#',
      'json': 'JSON',
      'yaml': 'YAML',
      'yml': 'YAML',
      'xml': 'XML',
      'html': 'HTML',
      'css': 'CSS',
      'scss': 'SCSS',
      'md': 'Markdown',
      'sh': 'Shell',
      'sql': 'SQL',
      'vue': 'Vue',
      'dart': 'Dart',
      'ets': 'ArkTS',
    };
    return languageMap[ext] || ext.toUpperCase() || 'Text';
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

      Column() {
        Text(this.fileName)
          .fontSize(FontSize.LG)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.filePath)
          .fontSize(FontSize.SM)
          .fontColor(this.colors.textSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Blank().width(40)
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.SM, right: Spacing.MD })
    .backgroundColor(this.colors.bgPrimary)
    .border({ width: { bottom: 1 }, color: this.colors.border })
  }

  // 文件信息栏
  @Builder
  FileInfoBar() {
    Row() {
      // 语言标签
      Row() {
        Text(this.getLanguage())
          .fontSize(FontSize.SM)
          .fontColor('#FFFFFF')
      }
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .borderRadius(4)
      .backgroundColor(this.colors.brandPrimary)

      Text($r('app.string.lines_count', this.codeLines.length))
        .fontSize(FontSize.SM)
        .fontColor(this.colors.textSecondary)
        .margin({ left: Spacing.MD })

      Blank()

      Text(this.branch)
        .fontSize(FontSize.SM)
        .fontColor(this.colors.textSecondary)
    }
    .width('100%')
    .height(40)
    .padding({ left: Spacing.MD, right: Spacing.MD })
    .backgroundColor(this.colors.bgSecondary)
  }

  // 代码行
  @Builder
  CodeLineItem(codeLine: CodeLine) {
    Row() {
      // 行号
      Text(codeLine.lineNumber.toString())
        .fontSize(FontSize.SM)
        .fontColor(this.colors.textTertiary)
        .fontFamily('monospace')
        .textAlign(TextAlign.End)
        .width(40)
        .padding({ right: Spacing.MD })
        .backgroundColor(this.colors.bgTertiary)

      // 代码内容
      Text(codeLine.content)
        .fontSize(FontSize.SM)
        .fontColor(this.colors.textPrimary)
        .fontFamily('monospace')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Clip })
    }
    .width('100%')
    .constraintSize({ minHeight: 24 })
    .alignItems(VerticalAlign.Top)
    .padding({ top: 2, bottom: 2 })
  }

  // 加载状态
  @Builder
  LoadingView() {
    Column({ space: Spacing.SM }) {
      LoadingProgress()
        .width(40)
        .height(40)
        .color(this.colors.brandPrimary)
      Text($r('app.string.loading'))
        .fontSize(FontSize.MD)
        .fontColor(this.colors.textSecondary)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  // 错误状态
  @Builder
  ErrorView() {
    Column({ space: Spacing.SM }) {
      Text(this.error)
        .fontSize(FontSize.MD)
        .fontColor(this.colors.textSecondary)
      RFButton({
        text: $r('app.string.retry'),
        variant: 'secondary',
        buttonSize: 'md',
        colors: this.colors,
        onTap: (): void => {
          this.loadFile();
        }
      })
        .margin({ top: Spacing.MD })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  // 代码内容
  @Builder
  CodeContent() {
    Scroll() {
      Column() {
        ForEach(this.codeLines, (line: CodeLine) => {
          this.CodeLineItem(line)
        }, (line: CodeLine) => line.lineNumber.toString())
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor(this.colors.surface)
    .scrollBar(BarState.Auto)
    .scrollBarColor(this.colors.textSecondary)
  }

  // =====================================================
  // 主构建方法
  // =====================================================

  build() {
    Column() {
      // 页面头部
      this.PageHeader()

      // 文件信息
      this.FileInfoBar()

      // 内容区域
      if (this.isLoading) {
        this.LoadingView()
      } else if (this.error) {
        this.ErrorView()
      } else {
        this.CodeContent()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.bgSecondary)
  }
}
