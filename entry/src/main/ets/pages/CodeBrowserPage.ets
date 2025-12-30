import router from '@ohos.router';
import { authManager } from '../services/AuthManager';
import { GitHubBranch, GitHubFileContent } from '../models/GitHubModels';

const PRIMARY_TEXT = '#1F2328';
const SECONDARY_TEXT = '#656D76';
const CARD_BG = '#F6F8FA';
const ACCENT = '#F28C28';
const BORDER_COLOR = '#D0D7DE';
const FOLDER_COLOR = '#54AEFF';

// 文件图标颜色映射
class FileIconColors {
  static ts: string = '#3178C6';
  static tsx: string = '#3178C6';
  static js: string = '#F7DF1E';
  static jsx: string = '#61DAFB';
  static py: string = '#3776AB';
  static java: string = '#B07219';
  static kt: string = '#A97BFF';
  static go: string = '#00ADD8';
  static rs: string = '#DEA584';
  static c: string = '#555555';
  static cpp: string = '#F34B7D';
  static h: string = '#555555';
  static swift: string = '#FA7343';
  static rb: string = '#CC342D';
  static php: string = '#777BB4';
  static cs: string = '#239120';
  static json: string = '#292929';
  static yaml: string = '#CB171E';
  static yml: string = '#CB171E';
  static xml: string = '#E34C26';
  static html: string = '#E34C26';
  static css: string = '#563D7C';
  static scss: string = '#C6538C';
  static md: string = '#083FA1';
  static sh: string = '#89E051';
  static bat: string = '#C1F12E';
  static sql: string = '#E38C00';
  static vue: string = '#4FC08D';
  static dart: string = '#00B4AB';
  static ets: string = '#3178C6';

  static getColor(ext: string): string {
    const colorMap: Record<string, string> = {
      'ts': FileIconColors.ts,
      'tsx': FileIconColors.tsx,
      'js': FileIconColors.js,
      'jsx': FileIconColors.jsx,
      'py': FileIconColors.py,
      'java': FileIconColors.java,
      'kt': FileIconColors.kt,
      'go': FileIconColors.go,
      'rs': FileIconColors.rs,
      'c': FileIconColors.c,
      'cpp': FileIconColors.cpp,
      'h': FileIconColors.h,
      'swift': FileIconColors.swift,
      'rb': FileIconColors.rb,
      'php': FileIconColors.php,
      'cs': FileIconColors.cs,
      'json': FileIconColors.json,
      'yaml': FileIconColors.yaml,
      'yml': FileIconColors.yml,
      'xml': FileIconColors.xml,
      'html': FileIconColors.html,
      'css': FileIconColors.css,
      'scss': FileIconColors.scss,
      'md': FileIconColors.md,
      'sh': FileIconColors.sh,
      'bat': FileIconColors.bat,
      'sql': FileIconColors.sql,
      'vue': FileIconColors.vue,
      'dart': FileIconColors.dart,
      'ets': FileIconColors.ets
    };
    return colorMap[ext] || SECONDARY_TEXT;
  }
}

interface RouteParams {
  owner: string;
  repo: string;
  branch?: string;
}

interface FileItem {
  name: string;
  path: string;
  type: 'file' | 'dir';
  sha: string;
  size?: number;
}

@Entry
@Component
struct CodeBrowserPage {
  @State isLoading: boolean = true;
  @State error: string = '';
  @State branches: GitHubBranch[] = [];
  @State currentBranch: string = 'main';
  @State files: FileItem[] = [];
  @State showBranchPicker: boolean = false;
  @State currentPath: string = '';
  @State pathStack: string[] = [];

  private owner: string = '';
  private repoName: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as RouteParams | undefined;
    if (params) {
      this.owner = params.owner;
      this.repoName = params.repo;
      if (params.branch) {
        this.currentBranch = params.branch;
      }
      this.loadBranches();
      this.loadDirectory('');
    }
  }

  async loadBranches(): Promise<void> {
    const api = authManager.getGitHubApi();
    if (!api) return;

    try {
      this.branches = await api.getRepoBranches(this.owner, this.repoName);
      // 如果有分支列表，使用第一个作为默认分支（通常是默认分支）
      if (this.branches.length > 0 && this.currentBranch === 'main') {
        // 检查是否有 main 或 master 分支
        const mainBranch = this.branches.find(b => b.name === 'main' || b.name === 'master');
        if (mainBranch) {
          this.currentBranch = mainBranch.name;
        } else {
          this.currentBranch = this.branches[0].name;
        }
      }
    } catch (err) {
      console.error('Load branches failed:', JSON.stringify(err));
    }
  }

  async loadDirectory(path: string): Promise<void> {
    this.isLoading = true;
    this.error = '';

    const api = authManager.getGitHubApi();
    if (!api) {
      this.error = '请先登录';
      this.isLoading = false;
      return;
    }

    try {
      const contents = await api.getRepoContents(this.owner, this.repoName, path, this.currentBranch);

      // 转换为 FileItem 并排序
      const items: FileItem[] = [];
      for (const item of contents) {
        const fileItem: FileItem = {
          name: item.name,
          path: item.path,
          type: item.type,
          sha: item.sha,
          size: item.size
        };
        items.push(fileItem);
      }

      // 排序：文件夹在前，按名称排序
      this.files = items.sort((a, b) => {
        if (a.type !== b.type) {
          return a.type === 'dir' ? -1 : 1;
        }
        return a.name.localeCompare(b.name);
      });

      this.currentPath = path;
    } catch (err) {
      this.error = '加载目录失败';
      console.error('Load directory failed:', JSON.stringify(err));
    } finally {
      this.isLoading = false;
    }
  }

  navigateToFolder(path: string): void {
    this.pathStack.push(this.currentPath);
    this.loadDirectory(path);
  }

  navigateBack(): void {
    if (this.pathStack.length > 0) {
      const previousPath = this.pathStack.pop() || '';
      this.loadDirectory(previousPath);
    } else {
      router.back();
    }
  }

  openFile(file: FileItem): void {
    router.pushUrl({
      url: 'pages/FileViewerPage',
      params: {
        owner: this.owner,
        repo: this.repoName,
        path: file.path,
        branch: this.currentBranch,
        fileName: file.name
      }
    });
  }

  getFileExtension(filename: string): string {
    const parts = filename.split('.');
    return parts.length > 1 ? parts[parts.length - 1].toLowerCase() : '';
  }

  getFileIconColor(filename: string): string {
    const ext = this.getFileExtension(filename);
    return FileIconColors.getColor(ext);
  }

  formatFileSize(bytes: number | undefined): string {
    if (bytes === undefined) return '';
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  }

  getDisplayPath(): string {
    if (!this.currentPath) return '/';
    return '/' + this.currentPath;
  }

  @Builder
  FileRow(file: FileItem) {
    Row() {
      // 文件夹/文件图标
      if (file.type === 'dir') {
        Image($r('app.media.ic_folder'))
          .width(20)
          .height(20)
          .fillColor(FOLDER_COLOR)
      } else {
        Image($r('app.media.ic_file'))
          .width(20)
          .height(20)
          .fillColor(this.getFileIconColor(file.name))
      }

      // 文件名
      Text(file.name)
        .fontSize(14)
        .fontColor(PRIMARY_TEXT)
        .margin({ left: 12 })
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 文件大小
      if (file.type === 'file' && file.size !== undefined) {
        Text(this.formatFileSize(file.size))
          .fontSize(12)
          .fontColor(SECONDARY_TEXT)
      }

      // 文件夹箭头
      if (file.type === 'dir') {
        Image($r('app.media.ic_chevron_right'))
          .width(16)
          .height(16)
          .fillColor(SECONDARY_TEXT)
          .margin({ left: 8 })
      }
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      if (file.type === 'dir') {
        this.navigateToFolder(file.path);
      } else {
        this.openFile(file);
      }
    })
  }

  @Builder
  BranchPicker() {
    Column() {
      // 遮罩层
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000040')
        .onClick(() => {
          this.showBranchPicker = false;
        })

      // 分支选择面板
      Column() {
        Row() {
          Text('选择分支')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(PRIMARY_TEXT)
          Blank()
          Image($r('app.media.ic_close'))
            .width(20)
            .height(20)
            .fillColor(SECONDARY_TEXT)
            .onClick(() => {
              this.showBranchPicker = false;
            })
        }
        .width('100%')
        .padding(16)
        .border({ width: { bottom: 1 }, color: BORDER_COLOR })

        List() {
          ForEach(this.branches, (branch: GitHubBranch) => {
            ListItem() {
              Row() {
                Image($r('app.media.ic_branch'))
                  .width(16)
                  .height(16)
                  .fillColor(SECONDARY_TEXT)

                Text(branch.name)
                  .fontSize(14)
                  .fontColor(PRIMARY_TEXT)
                  .margin({ left: 12 })
                  .layoutWeight(1)

                if (branch.name === this.currentBranch) {
                  Image($r('app.media.ic_check_circle'))
                    .width(20)
                    .height(20)
                    .fillColor(ACCENT)
                }
              }
              .width('100%')
              .height(48)
              .padding({ left: 16, right: 16 })
              .onClick(() => {
                if (branch.name !== this.currentBranch) {
                  this.currentBranch = branch.name;
                  this.pathStack = [];
                  this.loadDirectory('');
                }
                this.showBranchPicker = false;
              })
            }
          }, (branch: GitHubBranch) => branch.name)
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('60%')
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 16, topRight: 16 })
      .position({ y: '40%' })
    }
    .width('100%')
    .height('100%')
  }

  build() {
    Stack() {
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
            this.navigateBack();
          })

          Text('代码')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(PRIMARY_TEXT)
            .layoutWeight(1)

          Blank().width(40)
        }
        .width('100%')
        .height(56)
        .padding({ left: 8, right: 16 })
        .backgroundColor('#FFFFFF')
        .border({ width: { bottom: 1 }, color: BORDER_COLOR })

        // 分支选择器
        Row() {
          Image($r('app.media.ic_branch'))
            .width(16)
            .height(16)
            .fillColor(SECONDARY_TEXT)

          Text(this.currentBranch)
            .fontSize(14)
            .fontColor(PRIMARY_TEXT)
            .margin({ left: 8 })

          Image($r('app.media.ic_chevron_right'))
            .width(14)
            .height(14)
            .fillColor(SECONDARY_TEXT)
            .rotate({ angle: 90 })
            .margin({ left: 4 })

          Blank()

          // 当前路径
          Text(this.getDisplayPath())
            .fontSize(12)
            .fontColor(SECONDARY_TEXT)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .height(44)
        .padding({ left: 16, right: 16 })
        .backgroundColor(CARD_BG)
        .onClick(() => {
          this.showBranchPicker = true;
        })

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
              .onClick(() => this.loadDirectory(this.currentPath))
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.files.length === 0) {
          Column() {
            Text('此目录为空')
              .fontSize(14)
              .fontColor(SECONDARY_TEXT)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          // 文件列表
          List() {
            ForEach(this.files, (file: FileItem) => {
              ListItem() {
                this.FileRow(file)
              }
            }, (file: FileItem) => file.path)
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor('#FFFFFF')
          .divider({ strokeWidth: 1, color: BORDER_COLOR, startMargin: 48, endMargin: 0 })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(CARD_BG)

      // 分支选择弹窗
      if (this.showBranchPicker) {
        this.BranchPicker()
      }
    }
    .width('100%')
    .height('100%')
  }
}
