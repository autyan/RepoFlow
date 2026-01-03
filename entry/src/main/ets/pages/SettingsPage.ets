import { authManager } from '../services/AuthManager';
import { userState } from '../common/state/UserState';
import { ThemeManager, ThemeMode, ThemeColors } from '../theme';
import { Spacing, BorderRadius, FontSize } from '../theme/DesignTokens';
import { UIHelper } from '../common/ui';

@Entry
@Component
struct SettingsPage {
  @State isLoggedIn: boolean = false;
  @State themeMode: ThemeMode = ThemeMode.SYSTEM;
  @State isDarkTheme: boolean = false;
  private colors: ThemeColors = ThemeManager.colors;

  aboutToAppear(): void {
    this.isLoggedIn = userState.isLoggedIn;
    this.themeMode = ThemeManager.currentMode;
    this.isDarkTheme = ThemeManager.isDark;

    userState.addListener(() => {
      this.isLoggedIn = userState.isLoggedIn;
    });

    // 订阅主题变化
    ThemeManager.subscribe((colors: ThemeColors, isDark: boolean) => {
      this.isDarkTheme = isDark;
      this.colors = colors;
    });
  }

  async handleLogout(): Promise<void> {
    try {
      const result = await this.getUIContext()!.getPromptAction()!.showDialog({
        title: $r('app.string.logout'),
        message: $r('app.string.logout_confirm'),
        buttons: [
          { text: $r('app.string.cancel'), color: this.colors.textSecondary as string },
          { text: $r('app.string.logout'), color: this.colors.error as string }
        ]
      });

      if (result.index === 1) {
        await authManager.logout();
        UIHelper.goBack(this);
      }
    } catch (error) {
      console.error('Logout dialog failed:', JSON.stringify(error));
    }
  }

  async handleThemeChange(): Promise<void> {
    try {
      const result = await this.getUIContext()!.getPromptAction()!.showActionMenu({
        title: $r('app.string.theme_mode'),
        buttons: [
          { text: $r('app.string.theme_system'), color: this.colors.textPrimary as string },
          { text: $r('app.string.theme_light'), color: this.colors.textPrimary as string },
          { text: $r('app.string.theme_dark'), color: this.colors.textPrimary as string }
        ]
      });

      const modes: ThemeMode[] = [ThemeMode.SYSTEM, ThemeMode.LIGHT, ThemeMode.DARK];
      if (result.index >= 0 && result.index < modes.length) {
        await ThemeManager.setThemeMode(modes[result.index]);
        this.themeMode = modes[result.index];
        this.colors = ThemeManager.colors;
      }
    } catch (error) {
      console.error('Theme change failed:', JSON.stringify(error));
    }
  }

  private getThemeModeText(): Resource {
    switch (this.themeMode) {
      case ThemeMode.LIGHT:
        return $r('app.string.theme_light');
      case ThemeMode.DARK:
        return $r('app.string.theme_dark');
      default:
        return $r('app.string.theme_system');
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
            .fillColor(this.colors.textPrimary)
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          UIHelper.goBack(this);
        })

        Text($r('app.string.settings'))
          .fontSize(FontSize.SUBTITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textPrimary)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 占位保持标题居中
        Row().width(40).height(40)
      }
      .width('100%')
      .height(56)
      .padding({ left: Spacing.XS, right: Spacing.XS })
      .backgroundColor(this.colors.surface)

      Scroll() {
        Column({ space: Spacing.MD }) {
          // 外观设置
          Column({ space: 0 }) {
            Text($r('app.string.appearance'))
              .fontSize(FontSize.CAPTION)
              .fontColor(this.colors.textSecondary)
              .width('100%')
              .padding({ left: Spacing.MD, bottom: Spacing.XS })

            Column() {
              // 主题模式
              Row() {
                Text($r('app.string.theme_mode'))
                  .fontSize(FontSize.BODY)
                  .fontColor(this.colors.textPrimary)
                Blank()
                Text(this.getThemeModeText())
                  .fontSize(FontSize.BODY)
                  .fontColor(this.colors.textSecondary)
                Image($r('app.media.ic_chevron_right'))
                  .width(16)
                  .height(16)
                  .fillColor(this.colors.textTertiary)
                  .margin({ left: Spacing.XXS })
              }
              .width('100%')
              .height(52)
              .padding({ left: Spacing.MD, right: Spacing.MD })
              .onClick(() => {
                this.handleThemeChange();
              })
            }
            .width('100%')
            .backgroundColor(this.colors.surfaceVariant)
            .borderRadius(BorderRadius.MD)
          }
          .width('100%')

          // 关于应用
          Column({ space: 0 }) {
            Text($r('app.string.about'))
              .fontSize(FontSize.CAPTION)
              .fontColor(this.colors.textSecondary)
              .width('100%')
              .padding({ left: Spacing.MD, bottom: Spacing.XS })

            Column() {
              // 版本
              Row() {
                Text($r('app.string.version'))
                  .fontSize(FontSize.BODY)
                  .fontColor(this.colors.textPrimary)
                Blank()
                Text($r('app.string.app_version_value'))
                  .fontSize(FontSize.BODY)
                  .fontColor(this.colors.textSecondary)
              }
              .width('100%')
              .height(52)
              .padding({ left: Spacing.MD, right: Spacing.MD })

              Divider().color(this.colors.border).margin({ left: Spacing.MD })

              // 开发者
              Row() {
                Text($r('app.string.developer'))
                  .fontSize(FontSize.BODY)
                  .fontColor(this.colors.textPrimary)
                Blank()
                Text($r('app.string.settings_author'))
                  .fontSize(FontSize.BODY)
                  .fontColor(this.colors.textSecondary)
              }
              .width('100%')
              .height(52)
              .padding({ left: Spacing.MD, right: Spacing.MD })
            }
            .width('100%')
            .backgroundColor(this.colors.surfaceVariant)
            .borderRadius(BorderRadius.MD)
          }
          .width('100%')

          // 法律条款
          Column({ space: 0 }) {
            Text($r('app.string.legal'))
              .fontSize(FontSize.CAPTION)
              .fontColor(this.colors.textSecondary)
              .width('100%')
              .padding({ left: Spacing.MD, bottom: Spacing.XS })

            Column() {
              // 开源库
              Row() {
                Text($r('app.string.open_source_libraries'))
                  .fontSize(FontSize.BODY)
                  .fontColor(this.colors.textPrimary)
                  .layoutWeight(1)
                Image($r('app.media.ic_chevron_right'))
                  .width(16)
                  .height(16)
                  .fillColor(this.colors.textTertiary)
              }
              .width('100%')
              .height(52)
              .padding({ left: Spacing.MD, right: Spacing.MD })
              .onClick(() => {
                UIHelper.pushUrl(this, 'pages/OpenSourcePage');
              })

              Divider().color(this.colors.border).margin({ left: Spacing.MD })

              // 服务条款
              Row() {
                Text($r('app.string.terms_of_service'))
                  .fontSize(FontSize.BODY)
                  .fontColor(this.colors.textPrimary)
                  .layoutWeight(1)
                Image($r('app.media.ic_chevron_right'))
                  .width(16)
                  .height(16)
                  .fillColor(this.colors.textTertiary)
              }
              .width('100%')
              .height(52)
              .padding({ left: Spacing.MD, right: Spacing.MD })
              .onClick(() => {
                UIHelper.pushUrl(this, 'pages/TermsPage');
              })

              Divider().color(this.colors.border).margin({ left: Spacing.MD })

              // 隐私政策
              Row() {
                Text($r('app.string.privacy_policy'))
                  .fontSize(FontSize.BODY)
                  .fontColor(this.colors.textPrimary)
                  .layoutWeight(1)
                Image($r('app.media.ic_chevron_right'))
                  .width(16)
                  .height(16)
                  .fillColor(this.colors.textTertiary)
              }
              .width('100%')
              .height(52)
              .padding({ left: Spacing.MD, right: Spacing.MD })
              .onClick(() => {
                UIHelper.pushUrl(this, 'pages/PrivacyPage');
              })
            }
            .width('100%')
            .backgroundColor(this.colors.surfaceVariant)
            .borderRadius(BorderRadius.MD)
          }
          .width('100%')

          // 账户操作（仅登录后显示）
          if (this.isLoggedIn) {
            Column({ space: 0 }) {
              Text($r('app.string.account'))
                .fontSize(FontSize.CAPTION)
                .fontColor(this.colors.textSecondary)
                .width('100%')
                .padding({ left: Spacing.MD, bottom: Spacing.XS })

              Column() {
                // 退出登录
                Row() {
                  Text($r('app.string.logout'))
                    .fontSize(FontSize.BODY)
                    .fontColor(this.colors.error)
                    .layoutWeight(1)
                }
                .width('100%')
                .height(52)
                .padding({ left: Spacing.MD, right: Spacing.MD })
                .onClick(() => {
                  this.handleLogout();
                })
              }
              .width('100%')
              .backgroundColor(this.colors.surfaceVariant)
              .borderRadius(BorderRadius.MD)
            }
            .width('100%')
          }

          // 底部说明
          Column({ space: Spacing.XS }) {
            Text($r('app.string.settings_brand'))
              .fontSize(FontSize.SUBTITLE)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.colors.textSecondary)
            Text($r('app.string.app_tagline'))
              .fontSize(FontSize.CAPTION)
              .fontColor(this.colors.textSecondary)
            Text($r('app.string.non_profit_project'))
              .fontSize(FontSize.CAPTION)
              .fontColor(this.colors.textSecondary)
            Text($r('app.string.settings_legal_note'))
              .fontSize(FontSize.TINY)
              .fontColor(this.colors.textTertiary)
              .margin({ top: Spacing.XXS })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .padding({ top: Spacing.LG, bottom: Spacing.XL })
        }
        .padding(Spacing.MD)
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.background)
  }
}
