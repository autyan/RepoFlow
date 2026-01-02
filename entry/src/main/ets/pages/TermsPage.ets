import router from '@ohos.router';

const PRIMARY_TEXT = '#1F2328';
const SECONDARY_TEXT = '#656D76';

@Entry
@Component
struct TermsPage {
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

        Text($r('app.string.terms_of_service'))
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
          Text($r('app.string.terms_repoflow'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(PRIMARY_TEXT)
            .width('100%')

          Text($r('app.string.terms_update_date'))
            .fontSize(12)
            .fontColor(SECONDARY_TEXT)
            .width('100%')

          this.Section('1. 服务说明', 'RepoFlow 是一款个人开发的非盈利第三方 GitHub 客户端应用。本应用通过 GitHub 官方 API 提供服务，旨在为用户提供更便捷的移动端 GitHub 使用体验。')

          this.Section('2. 账户与授权', '使用本应用需要通过 GitHub OAuth 进行授权登录。我们仅请求必要的权限来提供核心功能。您的 GitHub 账户安全由 GitHub 官方保障，我们不会存储您的密码。')

          this.Section('3. 使用限制', '本应用受 GitHub API 速率限制约束。请合理使用，避免频繁刷新等可能触发限制的操作。')

          this.Section('4. 免责声明', '本应用按"现状"提供，不做任何明示或暗示的保证。开发者不对因使用本应用而导致的任何损失承担责任。')

          this.Section('5. 第三方服务', '本应用依赖 GitHub 提供的 API 服务。GitHub 的服务条款和隐私政策同样适用于您对本应用的使用。')

          this.Section('6. 知识产权', 'GitHub 是 GitHub, Inc. 的注册商标。本应用与 GitHub, Inc. 没有隶属关系，也未获得其官方认可。')

          this.Section('7. 条款修改', '我们保留随时修改这些条款的权利。继续使用本应用即表示您接受修改后的条款。')

          this.Section('8. 联系方式', '如有任何问题或建议，欢迎通过 GitHub 项目页面提交 Issue。')
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
