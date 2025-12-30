import router from '@ohos.router';
import { authManager } from '../services/AuthManager';
import { userState } from '../common/state/UserState';
import promptAction from '@ohos.promptAction';

const PRIMARY_TEXT = '#1F2328';
const SECONDARY_TEXT = '#656D76';
const CARD_BG = '#F6F8FA';
const ACCENT = '#0969DA';
const DANGER = '#CF222E';
const ICON_COLOR = '#57606A';

@Entry
@Component
struct SettingsPage {
  @State isLoggedIn: boolean = false;

  aboutToAppear(): void {
    this.isLoggedIn = userState.isLoggedIn;
    userState.addListener(() => {
      this.isLoggedIn = userState.isLoggedIn;
    });
  }

  async handleLogout(): Promise<void> {
    try {
      const result = await promptAction.showDialog({
        title: '退出登录',
        message: '确定要退出登录吗？退出后需要重新授权才能使用完整功能。',
        buttons: [
          { text: '取消', color: SECONDARY_TEXT },
          { text: '退出', color: DANGER }
        ]
      });

      if (result.index === 1) {
        await authManager.logout();
        router.back();
      }
    } catch (error) {
      console.error('Logout dialog failed:', JSON.stringify(error));
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

        Text('设置')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(PRIMARY_TEXT)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 占位保持标题居中
        Row().width(40).height(40)
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 8 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column({ space: 16 }) {
          // 关于应用
          Column({ space: 0 }) {
            Text('关于')
              .fontSize(13)
              .fontColor(SECONDARY_TEXT)
              .width('100%')
              .padding({ left: 16, bottom: 8 })

            Column() {
              // 版本
              Row() {
                Text('版本')
                  .fontSize(15)
                  .fontColor(PRIMARY_TEXT)
                Blank()
                Text('1.0.0')
                  .fontSize(15)
                  .fontColor(SECONDARY_TEXT)
              }
              .width('100%')
              .height(52)
              .padding({ left: 16, right: 16 })

              Divider().color('#E1E4E8').margin({ left: 16 })

              // 开发者
              Row() {
                Text('开发者')
                  .fontSize(15)
                  .fontColor(PRIMARY_TEXT)
                Blank()
                Text("Misaka's fan")
                  .fontSize(15)
                  .fontColor(SECONDARY_TEXT)
              }
              .width('100%')
              .height(52)
              .padding({ left: 16, right: 16 })
            }
            .width('100%')
            .backgroundColor(CARD_BG)
            .borderRadius(12)
          }
          .width('100%')

          // 法律条款
          Column({ space: 0 }) {
            Text('法律与信息')
              .fontSize(13)
              .fontColor(SECONDARY_TEXT)
              .width('100%')
              .padding({ left: 16, bottom: 8 })

            Column() {
              // 开源库
              Row() {
                Text('开源库')
                  .fontSize(15)
                  .fontColor(PRIMARY_TEXT)
                  .layoutWeight(1)
                Image($r('app.media.ic_chevron_right'))
                  .width(16)
                  .height(16)
                  .fillColor(SECONDARY_TEXT)
              }
              .width('100%')
              .height(52)
              .padding({ left: 16, right: 16 })
              .onClick(() => {
                router.pushUrl({ url: 'pages/OpenSourcePage' });
              })

              Divider().color('#E1E4E8').margin({ left: 16 })

              // 服务条款
              Row() {
                Text('服务条款')
                  .fontSize(15)
                  .fontColor(PRIMARY_TEXT)
                  .layoutWeight(1)
                Image($r('app.media.ic_chevron_right'))
                  .width(16)
                  .height(16)
                  .fillColor(SECONDARY_TEXT)
              }
              .width('100%')
              .height(52)
              .padding({ left: 16, right: 16 })
              .onClick(() => {
                router.pushUrl({ url: 'pages/TermsPage' });
              })

              Divider().color('#E1E4E8').margin({ left: 16 })

              // 隐私政策
              Row() {
                Text('隐私政策')
                  .fontSize(15)
                  .fontColor(PRIMARY_TEXT)
                  .layoutWeight(1)
                Image($r('app.media.ic_chevron_right'))
                  .width(16)
                  .height(16)
                  .fillColor(SECONDARY_TEXT)
              }
              .width('100%')
              .height(52)
              .padding({ left: 16, right: 16 })
              .onClick(() => {
                router.pushUrl({ url: 'pages/PrivacyPage' });
              })
            }
            .width('100%')
            .backgroundColor(CARD_BG)
            .borderRadius(12)
          }
          .width('100%')

          // 账户操作（仅登录后显示）
          if (this.isLoggedIn) {
            Column({ space: 0 }) {
              Text('账户')
                .fontSize(13)
                .fontColor(SECONDARY_TEXT)
                .width('100%')
                .padding({ left: 16, bottom: 8 })

              Column() {
                // 退出登录
                Row() {
                  Text('退出登录')
                    .fontSize(15)
                    .fontColor(DANGER)
                    .layoutWeight(1)
                }
                .width('100%')
                .height(52)
                .padding({ left: 16, right: 16 })
                .onClick(() => {
                  this.handleLogout();
                })
              }
              .width('100%')
              .backgroundColor(CARD_BG)
              .borderRadius(12)
            }
            .width('100%')
          }

          // 底部说明
          Column({ space: 8 }) {
            Text('RepoFlow')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(SECONDARY_TEXT)
            Text('一款开源的第三方 GitHub 客户端')
              .fontSize(13)
              .fontColor(SECONDARY_TEXT)
            Text('本应用为个人非盈利项目')
              .fontSize(12)
              .fontColor(SECONDARY_TEXT)
            Text('GitHub 是 GitHub, Inc. 的商标')
              .fontSize(11)
              .fontColor('#8C959F')
              .margin({ top: 4 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 24, bottom: 32 })
        }
        .padding(16)
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
