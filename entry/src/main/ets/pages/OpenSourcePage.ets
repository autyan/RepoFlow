import router from '@ohos.router';
import { Markdown, MarkdownController } from '@luvi/lv-markdown-in';

const PRIMARY_TEXT = '#1F2328';
const SECONDARY_TEXT = '#656D76';
const ACCENT = '#0969DA';

interface OpenSourceLib {
  name: string;
  license: string;
  url: string;
  description: string;
}

@Entry
@Component
struct OpenSourcePage {
  private markdownController: MarkdownController = new MarkdownController();
  
  private libraries: OpenSourceLib[] = [
    {
      name: '@luvi/lv-markdown-in',
      license: 'Apache-2.0',
      url: 'https://gitee.com/petal-component/lv-markdown-in',
      description: 'HarmonyOS 原生 Markdown 渲染组件'
    },
    {
      name: '@ohos/axios',
      license: 'MIT',
      url: 'https://github.com/nicedoc/axios-ohos',
      description: 'HarmonyOS HTTP 请求库'
    }
  ];

  aboutToAppear(): void {
    this.markdownController
      .setTitleColor(PRIMARY_TEXT)
      .setTextColor(SECONDARY_TEXT)
      .setTextSize(14)
      .setHyperlinkTextColor(ACCENT);
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

        Text($r('app.string.open_source_libs'))
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
          Text($r('app.string.open_source_thanks'))
            .fontSize(14)
            .fontColor(SECONDARY_TEXT)
            .width('100%')

          ForEach(this.libraries, (lib: OpenSourceLib) => {
            Column({ space: 8 }) {
              Row() {
                Text(lib.name)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(PRIMARY_TEXT)
                Blank()
                Text(lib.license)
                  .fontSize(12)
                  .fontColor('#FFFFFF')
                  .backgroundColor(ACCENT)
                  .borderRadius(4)
                  .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              }
              .width('100%')

              Text(lib.description)
                .fontSize(14)
                .fontColor(SECONDARY_TEXT)
                .width('100%')

              Text(lib.url)
                .fontSize(12)
                .fontColor(ACCENT)
                .width('100%')
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#F6F8FA')
            .borderRadius(12)
          }, (lib: OpenSourceLib) => lib.name)

          // MIT License 简要说明
          Column({ space: 8 }) {
            Text($r('app.string.open_source_license_title'))
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(PRIMARY_TEXT)
              .width('100%')
            Text($r('app.string.open_source_license_desc'))
              .fontSize(13)
              .fontColor(SECONDARY_TEXT)
              .lineHeight(22)
              .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#F6F8FA')
          .borderRadius(12)
          .margin({ top: 8 })
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
