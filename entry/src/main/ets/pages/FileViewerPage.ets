import router from '@ohos.router';
import { authManager } from '../services/AuthManager';

const PRIMARY_TEXT = '#1F2328';
const SECONDARY_TEXT = '#656D76';
const CARD_BG = '#F6F8FA';
const ACCENT = '#F28C28';
const BORDER_COLOR = '#D0D7DE';
const CODE_BG = '#F6F8FA';

// 语法高亮颜色
class SyntaxColors {
  static keyword: string = '#CF222E';
  static string: string = '#0A3069';
  static comment: string = '#6E7781';
  static number: string = '#0550AE';
  static function: string = '#8250DF';
  static class: string = '#953800';
  static operator: string = '#CF222E';
  static property: string = '#0550AE';
  static builtin: string = '#8250DF';
  static punctuation: string = '#1F2328';
}

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

@Entry
@Component
struct FileViewerPage {
  @State isLoading: boolean = true;
  @State error: string = '';
  @State fileContent: string = '';
  @State codeLines: CodeLine[] = [];
  @State fileName: string = '';

  private owner: string = '';
  private repoName: string = '';
  private filePath: string = '';
  private branch: string = '';

  aboutToAppear(): void {
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

  async loadFile(): Promise<void> {
    this.isLoading = true;
    this.error = '';

    const api = authManager.getGitHubApi();
    if (!api) {
      this.error = '请先登录';
      this.isLoading = false;
      return;
    }

    try {
      const content = await api.getRawFileContent(this.owner, this.repoName, this.filePath, this.branch);
      this.fileContent = content;
      this.parseCodeLines(content);
    } catch (err) {
      this.error = '加载文件失败';
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

  isKeyword(word: string): boolean {
    const ext = this.getFileExtension();
    let lang = ext;
    if (ext === 'tsx' || ext === 'ets') lang = 'ts';
    if (ext === 'jsx') lang = 'js';

    const keywords = KEYWORDS[lang] || KEYWORDS['ts'] || [];
    return keywords.includes(word);
  }

  @Builder
  CodeLineItem(codeLine: CodeLine) {
    Row() {
      // 行号
      Text(codeLine.lineNumber.toString())
        .fontSize(12)
        .fontColor(SECONDARY_TEXT)
        .fontFamily('monospace')
        .textAlign(TextAlign.End)
        .width(40)
        .padding({ right: 12 })
        .backgroundColor('#F0F0F0')

      // 代码内容
      Text(codeLine.content)
        .fontSize(13)
        .fontColor(PRIMARY_TEXT)
        .fontFamily('monospace')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Clip })
    }
    .width('100%')
    .constraintSize({ minHeight: 24 })
    .alignItems(VerticalAlign.Top)
    .padding({ top: 2, bottom: 2 })
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Row() {
          Image($r('app.media.ic_back'))
            .width(24)
            .height(24)
            .fillColor(PRIMARY_TEXT)
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          router.back();
        })

        Column() {
          Text(this.fileName)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(PRIMARY_TEXT)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.filePath)
            .fontSize(12)
            .fontColor(SECONDARY_TEXT)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Blank().width(40)
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 16 })
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 1 }, color: BORDER_COLOR })

      // 文件信息栏
      Row() {
        // 语言标签
        Row() {
          Text(this.getLanguage())
            .fontSize(12)
            .fontColor('#FFFFFF')
        }
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .borderRadius(4)
        .backgroundColor(ACCENT)

        Text(`${this.codeLines.length} 行`)
          .fontSize(12)
          .fontColor(SECONDARY_TEXT)
          .margin({ left: 12 })

        Blank()

        Text(this.branch)
          .fontSize(12)
          .fontColor(SECONDARY_TEXT)
      }
      .width('100%')
      .height(40)
      .padding({ left: 16, right: 16 })
      .backgroundColor(CARD_BG)

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
          Text('加载中...')
            .fontSize(14)
            .fontColor(SECONDARY_TEXT)
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.error) {
        Column() {
          Text(this.error)
            .fontSize(14)
            .fontColor(SECONDARY_TEXT)
          Button('重试')
            .height(36)
            .fontSize(14)
            .margin({ top: 16 })
            .onClick(() => this.loadFile())
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 代码内容
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
        .backgroundColor('#FFFFFF')
        .scrollBar(BarState.Auto)
        .scrollBarColor(SECONDARY_TEXT)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(CARD_BG)
  }
}
