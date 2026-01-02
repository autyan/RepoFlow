import router from '@ohos.router';

const PRIMARY_TEXT = '#1F2328';
const SECONDARY_TEXT = '#656D76';

@Entry
@Component
struct PrivacyPage {
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

        Text($r('app.string.privacy_policy'))
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(PRIMARY_TEXT)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Row().width(40).height(40)
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 8 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column({ space: 16 }) {
          Text($r('app.string.privacy_repoflow'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(PRIMARY_TEXT)
            .width('100%')

          Text($r('app.string.privacy_update_date'))
            .fontSize(12)
            .fontColor(SECONDARY_TEXT)
            .width('100%')

          this.Section('概述', 'RepoFlow 是一款尊重用户隐私的开源应用。我们致力于保护您的个人信息，本隐私政策说明了我们如何收集、使用和保护您的数据。')

          this.Section('1. 信息收集', '我们通过 GitHub OAuth 获取您授权的信息，包括：\n• 基本个人资料（用户名、头像、邮箱）\n• 公开仓库信息\n• 通知数据\n\n我们不会收集任何超出应用功能必要范围的信息。')

          this.Section('2. 信息使用', '收集的信息仅用于：\n• 展示您的 GitHub 数据\n• 提供仓库浏览功能\n• 显示通知提醒\n\n我们不会将您的信息用于广告或出售给第三方。')

          this.Section('3. 数据存储', '• OAuth Token 安全存储在设备本地\n• 我们不会将您的数据上传到我们的服务器\n• 所有 API 请求直接与 GitHub 服务器通信')

          this.Section('4. 数据安全', '我们采取合理的技术措施保护您的数据：\n• 使用 HTTPS 加密传输\n• Token 使用系统安全存储\n• 不在日志中记录敏感信息')

          this.Section('5. 第三方服务', '本应用使用 GitHub API，您的数据受 GitHub 隐私政策保护。我们建议您阅读 GitHub 的隐私政策了解更多信息。')

          this.Section('6. 您的权利', '您可以随时：\n• 在 GitHub 设置中撤销本应用的授权\n• 在应用内退出登录清除本地数据\n• 联系我们删除任何相关数据')

          this.Section('7. 儿童隐私', '本应用不面向 13 岁以下儿童。我们不会故意收集儿童的个人信息。')

          this.Section('8. 政策更新', '我们可能会更新本隐私政策。重大变更时会在应用内通知您。')

          this.Section('9. 联系我们', '如对隐私政策有任何疑问，请通过 GitHub 项目页面联系我们。')
        }
        .padding(16)
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  Section(title: string, content: string) {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(PRIMARY_TEXT)
        .width('100%')
      Text(content)
        .fontSize(14)
        .fontColor(SECONDARY_TEXT)
        .lineHeight(24)
        .width('100%')
    }
    .width('100%')
    .padding({ bottom: 8 })
  }
}
