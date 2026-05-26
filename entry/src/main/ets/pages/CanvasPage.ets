/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { window } from '@kit.ArkUI';
import Logger from '../common/utils/Logger';
import DrawModel from '../viewmodel/DrawModel';
import PrizeDialog from '../view/PrizeDialog';
import PrizeData from '../viewmodel/PrizeData';
import StyleConstants from '../common/constants/StyleConstants';
import CommonConstants from '../common/constants/CommonConstants';
import { Context } from '@kit.AbilityKit';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

// Get context.
const uiContext: UIContext | undefined = AppStorage.get('uiContext');
let context: Context = uiContext!.getHostContext()!;

@Entry
@Component
struct CanvasPage {
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  @State drawModel: DrawModel = new DrawModel();
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;
  @State rotateDegree: number = 0;
  @State enableFlag: boolean = true;
  @State prizeData: PrizeData = new PrizeData();
  dialogController: CustomDialogController = new CustomDialogController({
    builder: PrizeDialog({
      prizeData: $prizeData,
      enableFlag: $enableFlag,
      onClose: () => {
        // 检查是否抽中“再抽一次”
        if (this.prizeData.message === '再抽一次') {
          // 自动重新抽奖
          this.enableFlag = false;
          this.startAnimator();
        }
      }
    }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    cancel: () => {
      this.enableFlag = !this.enableFlag;
    }
  });
  private currentLang: string = 'zh-Hans';
  private lastLang: string = 'zh-Hans';
  private subscriber: commonEventManager.CommonEventSubscriber | null = null;

  aboutToAppear() {
    // Obtains the width and height of the screen, excluding the height of the navigation view.
    window.getLastWindow(context)
      .then((windowClass: window.Window) => {
        windowClass.setWindowLayoutFullScreen(true);
        let windowProperties = windowClass.getWindowProperties();
        this.screenWidth = this.getUIContext().px2vp(windowProperties.windowRect.width);
        this.screenHeight = this.getUIContext().px2vp(windowProperties.windowRect.height);
      })
      .catch((error: Error) => {
        Logger.error('Failed to obtain the window size. Cause: ' + JSON.stringify(error));
      })

    let subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: [commonEventManager.Support.COMMON_EVENT_LOCALE_CHANGED]
    };
    commonEventManager.createSubscriber(subscribeInfo)
      .then((commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
        this.subscriber = commonEventSubscriber;
        commonEventManager.subscribe(this.subscriber, (err) => {
          if (err) {
            Logger.error(`Failed to subscribe common event. errorCode=${err.code}, errorMessage=${err.message}`);
            return;
          }
          this.currentLang = i18n.System.getSystemLanguage();
        });
      })
      .catch((err: BusinessError) => {
        Logger.error(`CreateSubscriber failed, errorCode=${err.code}, errorMessage=${err.message}}`);
      })
  }

  onPageShow(): void {
    if (this.lastLang != this.currentLang) {
      this.drawModel.draw(this.canvasContext, this.screenWidth, this.screenHeight);
    }
  }

  onPageHide(): void {
    this.lastLang = i18n.System.getSystemLanguage();
  }

  aboutToDisappear(): void {
    if (this.subscriber) {
      commonEventManager.unsubscribe(this.subscriber, (err: BusinessError) => {
        if (!err) {
          this.subscriber = null;
        }
      })
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Canvas(this.canvasContext)
        .width(StyleConstants.FULL_PERCENT)
        .height(StyleConstants.FULL_PERCENT)
        .onReady(() => {
          this.drawModel.draw(this.canvasContext, this.screenWidth, this.screenHeight);
        })
        .rotate({
          x: 0,
          y: 0,
          z: 1,
          angle: this.rotateDegree,
          centerX: this.screenWidth / CommonConstants.TWO,
          centerY: this.screenHeight / CommonConstants.TWO
        })

      // 紫色按钮（无三角形）
      Stack() {
        Circle()
          .width(80)
          .height(80)
          .fill('#9B59B6')
          .shadow({ radius: 4, color: '#4A0E4E', offsetX: 2, offsetY: 2 })

        Circle()
          .width(56)
          .height(56)
          .fill('#D1B3FF')

        Text('开始')
          .fontSize(18)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
      }
      .width(80)
      .height(80)
      .enabled(this.enableFlag)
      .onClick(() => {
        this.enableFlag = !this.enableFlag;
        this.startAnimator();
      })

      // 三角形指针（绝对定位，放在按钮正上方）
      // 三角形指针（相对定位，放在按钮正上方）
      // 三角形指针（相对定位，放在按钮正上方）
      Text('▲')
        .fontSize(35)
        .fontColor('#00000')
        .offset({ x: 0, y: -36 })
    }
    .width(StyleConstants.FULL_PERCENT)
    .height(StyleConstants.FULL_PERCENT)
    .backgroundImage($r('app.media.ic_background'), ImageRepeat.NoRepeat)
    .backgroundImageSize({
      width: StyleConstants.FULL_PERCENT,
      height: StyleConstants.BACKGROUND_IMAGE_SIZE
    })
  }

  /**
   * Start animator.
   */
  startAnimator() {
    let randomAngle = Math.round(Math.random() * CommonConstants.CIRCLE);
    // Obtaining prize information.
    this.prizeData = this.drawModel.showPrizeData(randomAngle);

    this.getUIContext().animateTo({
      duration: CommonConstants.DURATION,
      curve: Curve.Ease,
      delay: 0,
      iterations: 1,
      playMode: PlayMode.Normal,
      onFinish: () => {
        this.rotateDegree = CommonConstants.ANGLE - randomAngle;
        // Display prize information pop-up window.
        this.dialogController.open();
      }
    }, () => {
      this.rotateDegree = CommonConstants.CIRCLE * CommonConstants.FIVE +
      CommonConstants.ANGLE - randomAngle;
    })
  }
}