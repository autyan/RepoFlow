import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { authManager } from '../services/AuthManager';

const PRIMARY_TEXT = '#1F2328';
const SECONDARY_TEXT = '#656D76';
const CARD_BG = '#F6F8FA';
const ACCENT = '#F28C28';
const BORDER_COLOR = '#D0D7DE';

interface RouteParams {
  owner: string;
  repo: string;
}

@Entry
@Component
struct CreateIssuePage {
  @State title: string = '';
  @State body: string = '';
  @State isSubmitting: boolean = false;

  private owner: string = '';
  private repoName: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as RouteParams | undefined;
    if (params) {
      this.owner = params.owner;
      this.repoName = params.repo;
    }
  }

  async submitIssue(): Promise<void> {
    if (!this.title.trim()) {
      promptAction.showToast({ message: '请输入标题' });
      return;
    }

    this.isSubmitting = true;
    const api = authManager.getGitHubApi();
    if (!api) {
      promptAction.showToast({ message: '请先登录' });
      this.isSubmitting = false;
      return;
    }

    try {
      const issue = await api.createIssue(this.owner, this.repoName, this.title.trim(), this.body.trim() || undefined);
      promptAction.showToast({ message: 'Issue 创建成功' });

      // 返回并刷新列表
      router.back();
    } catch (err) {
      promptAction.showToast({ message: '创建失败，请重试' });
      console.error('Create issue failed:', JSON.stringify(err));
    } finally {
      this.isSubmitting = false;
    }
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

        Text('新建 Issue')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(PRIMARY_TEXT)
          .layoutWeight(1)

        // 提交按钮
        if (this.isSubmitting) {
          LoadingProgress()
            .width(24)
            .height(24)
            .margin({ right: 8 })
        } else {
          Text('提交')
            .fontSize(16)
            .fontColor(this.title.trim() ? ACCENT : SECONDARY_TEXT)
            .margin({ right: 8 })
            .onClick(() => {
              if (this.title.trim()) {
                this.submitIssue();
              }
            })
        }
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 8 })
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 1 }, color: BORDER_COLOR })

      // 仓库信息
      Row({ space: 8 }) {
        Image($r('app.media.ic_repo'))
          .width(16)
          .height(16)
          .fillColor(SECONDARY_TEXT)

        Text(`${this.owner}/${this.repoName}`)
          .fontSize(14)
          .fontColor(SECONDARY_TEXT)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(CARD_BG)

      // 表单
      Column({ space: 16 }) {
        // 标题输入
        Column({ space: 8 }) {
          Text('标题 *')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(PRIMARY_TEXT)

          TextInput({ placeholder: '请输入 Issue 标题', text: this.title })
            .width('100%')
            .height(44)
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .border({ width: 1, color: BORDER_COLOR })
            .onChange((value: string) => {
              this.title = value;
            })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // 描述输入
        Column({ space: 8 }) {
          Text('描述（可选，支持 Markdown）')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(PRIMARY_TEXT)

          TextArea({ placeholder: '请描述您的问题或建议...', text: this.body })
            .width('100%')
            .height(200)
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .border({ width: 1, color: BORDER_COLOR })
            .onChange((value: string) => {
              this.body = value;
            })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // 提示
        Column({ space: 8 }) {
          Text('💡 小提示')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(SECONDARY_TEXT)

          Text('• 使用清晰的标题描述问题')
            .fontSize(12)
            .fontColor(SECONDARY_TEXT)

          Text('• 在描述中提供详细信息')
            .fontSize(12)
            .fontColor(SECONDARY_TEXT)

          Text('• 支持 Markdown 语法')
            .fontSize(12)
            .fontColor(SECONDARY_TEXT)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(16)
        .backgroundColor(CARD_BG)
        .borderRadius(8)
      }
      .width('100%')
      .padding(16)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
