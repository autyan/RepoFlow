import router from '@ohos.router';

const PRIMARY_TEXT = '#1F2328';
const SECONDARY_TEXT = '#656D76';
const ACCENT = '#0969DA';
const ICON_COLOR = '#57606A';

/**
 * 登录提示组件
 * 用于未登录用户访问需要认证的页面时展示友好引导
 */
@Component
export struct LoginPrompt {
  @Prop title: string = '登录后查看更多';
  @Prop subtitle: string = '登录 GitHub 账号，解锁完整功能';
  @Prop showDismiss: boolean = true;
  onDismiss?: () => void;

  build() {
    Column({ space: 20 }) {
      // 图标
      Column() {
        Image($r('app.media.github_mark'))
          .width(64)
          .height(64)
          .fillColor(ACCENT)
      }
      .width(100)
      .height(100)
      .backgroundColor('#F0F6FC')
      .borderRadius(50)
      .justifyContent(FlexAlign.Center)

      // 标题
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(PRIMARY_TEXT)
        .textAlign(TextAlign.Center)

      // 副标题
      Text(this.subtitle)
        .fontSize(14)
        .fontColor(SECONDARY_TEXT)
        .textAlign(TextAlign.Center)
        .lineHeight(22)

      // 功能亮点
      Column({ space: 8 }) {
        this.FeatureItem($r('app.media.ic_repo'), '查看和管理您的仓库')
        this.FeatureItem($r('app.media.ic_bell'), '接收 Issue 和 PR 通知')
        this.FeatureItem($r('app.media.ic_star'), '访问已加星的项目')
        this.FeatureItem($r('app.media.ic_user'), '查看个人资料和统计')
      }
      .margin({ top: 8, bottom: 8 })

      // 登录按钮
      Button('立即登录')
        .width('80%')
        .height(44)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor(ACCENT)
        .borderRadius(8)
        .onClick(() => {
          router.pushUrl({ url: 'pages/LoginPage' });
        })

      // 稍后再说
      if (this.showDismiss) {
        Text('稍后再说')
          .fontSize(14)
          .fontColor(SECONDARY_TEXT)
          .onClick(() => {
            if (this.onDismiss) {
              this.onDismiss();
            }
          })
      }
    }
    .width('100%')
    .padding(32)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  FeatureItem(icon: Resource, text: string) {
    Row({ space: 12 }) {
      Image(icon)
        .width(16)
        .height(16)
        .fillColor(ICON_COLOR)
      Text(text)
        .fontSize(14)
        .fontColor(SECONDARY_TEXT)
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
    .padding({ left: 32 })
  }
}
