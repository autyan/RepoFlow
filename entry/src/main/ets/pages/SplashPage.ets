import router from '@ohos.router';
import { authManager } from '../services/AuthManager';

// 配色 - 清爽浅色主题
const BG_PRIMARY = '#FFFFFF';
const BG_SECONDARY = '#F8FAFC';
const ACCENT_ORANGE = '#F28C28';
const TEXT_PRIMARY = '#1F2328';
const TEXT_SECONDARY = '#656D76';
const TEXT_TERTIARY = '#8B949E';

@Entry
@Component
struct SplashPage {
  @State logoOpacity: number = 0;
  @State sloganOpacity: number = 0;
  @State decorOpacity: number = 0;
  @State logoScale: number = 0.8;
  @State logoY: number = 20;

  aboutToAppear(): void {
    // 动画序列
    setTimeout(() => {
      animateTo({ duration: 600, curve: Curve.EaseOut }, () => {
        this.logoOpacity = 1;
        this.logoScale = 1;
        this.logoY = 0;
      });
    }, 200);

    setTimeout(() => {
      animateTo({ duration: 500, curve: Curve.EaseOut }, () => {
        this.sloganOpacity = 1;
      });
    }, 600);

    setTimeout(() => {
      animateTo({ duration: 400, curve: Curve.EaseOut }, () => {
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
      Column({ space: 20 }) {
        // App 图标 - 突出显示
        Image($r('app.media.app_icon'))
          .width(100)
          .height(100)
          .borderRadius(24)
          .shadow({
            radius: 24,
            color: '#F28C2840',
            offsetX: 0,
            offsetY: 8
          })
          .opacity(this.logoOpacity)
          .scale({ x: this.logoScale, y: this.logoScale })
          .translate({ y: this.logoY })

        // App 名称
        Text('RepoFlow')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_PRIMARY)
          .opacity(this.logoOpacity)
          .translate({ y: this.logoY })

        // 副标题
        Text('您的 GitHub 移动助手')
          .fontSize(15)
          .fontColor(TEXT_SECONDARY)
          .opacity(this.logoOpacity)
          .translate({ y: this.logoY })
      }
      .opacity(this.logoOpacity)

      // 中间留白
      Blank().height(60)

      // Slogan 区域
      Column({ space: 16 }) {
        // 分隔线
        Row()
          .width(40)
          .height(3)
          .borderRadius(1.5)
          .backgroundColor(ACCENT_ORANGE)
          .opacity(this.sloganOpacity)

        // 中文 Slogan
        Text('通过代码，构建美好世界')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(TEXT_PRIMARY)
          .opacity(this.sloganOpacity)

        // 英文 Slogan
        Text('Building a Better World Through Code')
          .fontSize(13)
          .fontColor(TEXT_TERTIARY)
          .opacity(this.sloganOpacity)
      }

      // 底部留白
      Blank().layoutWeight(1)

      // 底部加载区域
      Column({ space: 12 }) {
        // 加载动画
        Row({ space: 6 }) {
          ForEach([0, 1, 2], (index: number) => {
            Circle({ width: 6, height: 6 })
              .fill(index === 1 ? ACCENT_ORANGE : '#E5E7EB')
          })
        }
        .opacity(this.decorOpacity)

        // 版本信息
        Text('v1.0.0')
          .fontSize(11)
          .fontColor(TEXT_TERTIARY)
          .opacity(this.decorOpacity)
      }
      .margin({ bottom: 50 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(BG_PRIMARY)
    .padding({ left: 24, right: 24 })
  }
}
