import PrizeData from '../viewmodel/PrizeData';
import CommonConstants from '../common/constants/CommonConstants';
import StyleConstants from '../common/constants/StyleConstants';

@CustomDialog
export default struct PrizeDialog {
  @Link prizeData: PrizeData;
  @Link enableFlag: boolean;
  private controller?: CustomDialogController;
  onClose?: () => void;  // 新增：关闭弹窗后的回调

  build() {
    Column() {
      if (this.prizeData.emoji) {
        Text(this.prizeData.emoji)
          .fontSize(80)
          .margin({ top: $r('app.float.dialog_image_top'), bottom: 10 })
      } else {
        Image(this.prizeData.imageSrc !== undefined ? this.prizeData.imageSrc : '')
          .width($r('app.float.dialog_image_size'))
          .height($r('app.float.dialog_image_size'))
          .margin({
            top: $r('app.float.dialog_image_top'),
            bottom: $r('app.float.dialog_image_bottom')
          })
          .rotate({
            x: 0,
            y: 0,
            z: 1,
            angle: CommonConstants.TRANSFORM_ANGLE
          })
      }

      Text(this.prizeData.message)
        .fontSize($r('app.float.dialog_font_size'))
        .textAlign(TextAlign.Center)
        .margin({ bottom: $r('app.float.dialog_message_bottom') })

      Text($r('app.string.text_confirm'))
        .fontColor($r('app.color.text_font_color'))
        .fontWeight(StyleConstants.FONT_WEIGHT)
        .fontSize($r('app.float.dialog_font_size'))
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.controller?.close();
          this.enableFlag = !this.enableFlag;
          if (this.onClose) {
            this.onClose();  // 调用回调
          }
        })
    }
    .backgroundColor($r('app.color.dialog_background'))
    .width(StyleConstants.FULL_PERCENT)
    .height($r('app.float.dialog_height'))
  }
}