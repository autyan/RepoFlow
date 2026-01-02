import router from '@ohos.router';
import { authManager } from '../services/AuthManager';
import { ThemeManager, ThemeColors } from '../theme';
import { Spacing, BorderRadius, FontSize, AnimationDuration } from '../theme/DesignTokens';

@Entry
@Component
struct SplashPage {
  @State logoOpacity: number = 0;
  @State sloganOpacity: number = 0;
  @State decorOpacity: number = 0;
  @State logoScale: number = 0.8;
  @State logoY: number = 20;
  @State private colors: ThemeColors = ThemeManager.colors;

  aboutToAppear(): void {
    // 订阅主题变化
    ThemeManager.subscribe((colors: ThemeColors, isDark: boolean) => {
      this.colors = colors;
    });

    // 动画序列
    setTimeout(() => {
      animateTo({ duration: AnimationDuration.NORMAL, curve: Curve.EaseOut }, () => {
        this.logoOpacity = 1;
        this.logoScale = 1;
        this.logoY = 0;
      });
    }, 200);

    setTimeout(() => {
      animateTo({ duration: AnimationDuration.FAST, curve: Curve.EaseOut }, () => {
        this.sloganOpacity = 1;
      });
    }, 600);

    setTimeout(() => {
      animateTo({ duration: AnimationDuration.FAST, curve: Curve.EaseOut }, () => {
        this.decorOpacity = 1;
      });
    }, 900);

    // 2.5秒后跳转到主页
    setTimeout(() => {
      router.replaceUrl({ url: 'pages/Index' });
    }, 2500);
  }

  build() {
    Column() {
      // 顶部留白
      Blank().layoutWeight(1)

      // Logo 区域
      Column({ space: Spacing.MD }) {
        // App 图标 - 突出显示
        Image($r('app.media.app_icon'))
          .width(100)
          .height(100)
          .borderRadius(BorderRadius.XL)
          .shadow({
            radius: 24,
            color: this.colors.primaryContainer as string,
            offsetX: 0,
            offsetY: 8
          })
          .opacity(this.logoOpacity)
          .scale({ x: this.logoScale, y: this.logoScale })
          .translate({ y: this.logoY })

        // App 名称
        Text($r('app.string.settings_brand'))
          .fontSize(FontSize.DISPLAY)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textPrimary)
          .opacity(this.logoOpacity)
          .translate({ y: this.logoY })

        // 副标题
        Text($r('app.string.app_description'))
          .fontSize(FontSize.BODY)
          .fontColor(this.colors.textSecondary)
          .opacity(this.logoOpacity)
          .translate({ y: this.logoY })
      }
      .opacity(this.logoOpacity)

      // 中间留白
      Blank().height(60)

      // Slogan 区域
      Column({ space: Spacing.MD }) {
        // 分隔线
        Row()
          .width(40)
          .height(3)
          .borderRadius(1.5)
          .backgroundColor(this.colors.primary)
          .opacity(this.sloganOpacity)

        // 中文 Slogan
        Text($r('app.string.slogan'))
          .fontSize(FontSize.SUBTITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textPrimary)
          .opacity(this.sloganOpacity)

        // 英文 Slogan
        Text($r('app.string.app_tagline'))
          .fontSize(FontSize.CAPTION)
          .fontColor(this.colors.textTertiary)
          .opacity(this.sloganOpacity)
      }

      // 底部留白
      Blank().layoutWeight(1)

      // 底部加载区域
      Column({ space: Spacing.SM }) {
        // 加载动画
        Row({ space: Spacing.XS }) {
          ForEach([0, 1, 2], (index: number) => {
            Circle({ width: 6, height: 6 })
              .fill(index === 1 ? this.colors.primary : this.colors.border)
          })
        }
        .opacity(this.decorOpacity)

        // 版本信息
        Text($r('app.string.app_version_value'))
          .fontSize(FontSize.TINY)
          .fontColor(this.colors.textTertiary)
          .opacity(this.decorOpacity)
      }
      .margin({ bottom: 50 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.background)
    .padding({ left: Spacing.LG, right: Spacing.LG })
  }
}
