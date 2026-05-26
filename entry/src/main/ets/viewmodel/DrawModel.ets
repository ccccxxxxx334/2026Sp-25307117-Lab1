/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import CommonConstants from '../common/constants/CommonConstants';
import { EnumeratedValue } from '../common/constants/CommonConstants';
import ColorConstants from '../common/constants/ColorConstants';
import StyleConstants from '../common/constants/StyleConstants';
import PrizeData from './PrizeData';
import FillArcData from './FillArcData';
import Logger from '../common/utils/Logger';
import CheckEmptyUtils from '../common/utils/CheckEmptyUtils';
const uiContext: UIContext | undefined = AppStorage.get('uiContext');

/**
 * Canvas drawing method class.
 */
export default class DrawModel {
  private startAngle: number = 0;
  private avgAngle: number = CommonConstants.CIRCLE / CommonConstants.COUNT;
  private screenWidth: number = 0;
  private canvasContext?: CanvasRenderingContext2D;

  /**
   * Draw the raffle round turntable.
   *
   * @param canvasContext canvasContext.
   * @param screenWidth screenWidth.
   * @param screenHeight screenHeight.
   */
  draw(canvasContext: CanvasRenderingContext2D, screenWidth: number, screenHeight: number) {
    if (CheckEmptyUtils.isEmptyObj(canvasContext)) {
      Logger.error('[DrawModel][draw] canvasContext is empty.');
      return;
    }
    this.canvasContext = canvasContext;
    this.screenWidth = screenWidth;
    this.canvasContext.clearRect(0, 0, this.screenWidth, screenHeight);
    // Translates the canvas along the X and Y axes by a specified distance.
    this.canvasContext.translate(this.screenWidth / CommonConstants.TWO,
      screenHeight / CommonConstants.TWO);
    // Painted outer disc petal.
    this.drawFlower();
    // Draw outer disc, small circle.
    this.drawOutCircle();
    // Draw the inner disc.
    this.drawInnerCircle();
    // Draw the interior fan-shaped raffle area.
    this.drawInnerArc();
    // Draw text in the internal fan area.
    this.drawArcText();
    // Draw the picture corresponding to the prize in the internal fan area.
    this.drawImage();
    this.drawEmojiInSector();
    this.canvasContext.translate(-this.screenWidth / CommonConstants.TWO,
      -screenHeight / CommonConstants.TWO);
  }

  /**
   * Method of drawing arcs.
   *
   * @param fillArcData fillArcData.
   * @param fillColor fillColor.
   */
  fillArc(fillArcData: FillArcData, fillColor: string) {
    if (CheckEmptyUtils.isEmptyObj(fillArcData) || CheckEmptyUtils.isEmptyStr(fillColor)) {
      Logger.error('[DrawModel][fillArc] fillArcData or fillColor is empty.');
      return;
    }
    if (this.canvasContext !== undefined) {
      this.canvasContext.beginPath();
      this.canvasContext.fillStyle = fillColor;
      this.canvasContext.arc(fillArcData.x, fillArcData.y, fillArcData.radius,
        fillArcData.startAngle, fillArcData.endAngle);
      this.canvasContext.fill();
    }
  }

  /**
   * Painted outer disc petal.
   */
  drawFlower() {
    let beginAngle = this.startAngle + this.avgAngle;
    const pointY = this.screenWidth * CommonConstants.FLOWER_POINT_Y_RATIOS;
    const radius = this.screenWidth * CommonConstants.FLOWER_RADIUS_RATIOS;
    const innerRadius = this.screenWidth * CommonConstants.FLOWER_INNER_RATIOS;
    for (let i = 0; i < CommonConstants.COUNT; i++) {
      this.canvasContext?.save();
      this.canvasContext?.rotate(beginAngle * Math.PI / CommonConstants.HALF_CIRCLE);
      this.fillArc(new FillArcData(0, -pointY, radius, 0, Math.PI * CommonConstants.TWO),
        ColorConstants.FLOWER_OUT_COLOR);

      this.fillArc(new FillArcData(0, -pointY, innerRadius, 0, Math.PI * CommonConstants.TWO),
        ColorConstants.FLOWER_INNER_COLOR);
      beginAngle += this.avgAngle;
      this.canvasContext?.restore();
    }
  }

  /**
   * Draw outer disc, small circle.
   */
  drawOutCircle() {
    // Draw outer disc.
    this.fillArc(new FillArcData(0, 0, this.screenWidth * CommonConstants.OUT_CIRCLE_RATIOS, 0,
      Math.PI * CommonConstants.TWO), ColorConstants.OUT_CIRCLE_COLOR);

    let beginAngle = this.startAngle;
    // Draw small circle.
    for (let i = 0; i < CommonConstants.SMALL_CIRCLE_COUNT; i++) {
      this.canvasContext?.save();
      this.canvasContext?.rotate(beginAngle * Math.PI / CommonConstants.HALF_CIRCLE);
      this.fillArc(new FillArcData(this.screenWidth * CommonConstants.SMALL_CIRCLE_RATIOS, 0,
        CommonConstants.SMALL_CIRCLE_RADIUS, 0, Math.PI * CommonConstants.TWO),
        ColorConstants.WHITE_COLOR);
      beginAngle = beginAngle + CommonConstants.CIRCLE / CommonConstants.SMALL_CIRCLE_COUNT;
      this.canvasContext?.restore();
    }
  }

  /**
   * Draw the inner disc.
   */
  drawInnerCircle() {
    this.fillArc(new FillArcData(0, 0, this.screenWidth * CommonConstants.INNER_CIRCLE_RATIOS, 0,
      Math.PI * CommonConstants.TWO), ColorConstants.INNER_CIRCLE_COLOR);
    this.fillArc(new FillArcData(0, 0, this.screenWidth * CommonConstants.INNER_WHITE_CIRCLE_RATIOS, 0,
      Math.PI * CommonConstants.TWO), ColorConstants.WHITE_COLOR);
  }

  /**
   * Draw the interior fan-shaped raffle area.
   */
  drawInnerArc() {
    let colors = [
      ColorConstants.ARC_PINK_COLOR, ColorConstants.ARC_YELLOW_COLOR,
      ColorConstants.ARC_GREEN_COLOR, ColorConstants.ARC_PINK_COLOR,
      ColorConstants.ARC_YELLOW_COLOR, ColorConstants.ARC_GREEN_COLOR
    ];
    let radius = this.screenWidth * CommonConstants.INNER_ARC_RATIOS;
    for (let i = 0; i < CommonConstants.COUNT; i++) {
      this.fillArc(new FillArcData(0, 0, radius, this.startAngle * Math.PI / CommonConstants.HALF_CIRCLE,
        (this.startAngle + this.avgAngle) * Math.PI / CommonConstants.HALF_CIRCLE), colors[i]);
      this.canvasContext?.lineTo(0, 0);
      this.canvasContext?.fill();
      this.startAngle += this.avgAngle;
    }
  }

  /**
   * Draw text in the internal fan area.
   */
  drawArcText() {
    if (this.canvasContext === undefined) {
      return;
    }
    this.canvasContext.textAlign = CommonConstants.TEXT_ALIGN;
    this.canvasContext.textBaseline = CommonConstants.TEXT_BASE_LINE;
    this.canvasContext.fillStyle = '#000000';  // 黑色
    this.canvasContext.font = '50px sans-serif';

    // 奖品文字列表（不带 emoji，因为弧形文字容易乱）
    let textList = [
      '我答应你一件事',
      '你答应我一件事',
      '再抽一次',
      '说一个真心话',
      '问我一个问题',
      '再抽一次'
    ];

    let arcTextStartAngle = CommonConstants.ARC_START_ANGLE;
    let arcTextEndAngle = CommonConstants.ARC_END_ANGLE;
    let start = this.startAngle;

    for (let i = 0; i < CommonConstants.COUNT; i++) {
      let text = textList[i];
      let startRad = (start + arcTextStartAngle) * Math.PI / CommonConstants.HALF_CIRCLE;
      let endRad = (start + arcTextEndAngle) * Math.PI / CommonConstants.HALF_CIRCLE;

      // 如果是长文字（包含“一件事”、“真心话”、“问题”），分两行画
      if (text === '我答应你一件事') {
        this.drawCircularText('一件事', startRad, endRad, -15);      // 第一行，偏移0
        this.drawCircularText('我答应你', startRad, endRad, 3);       // 第二行，向外偏移15px
      } else if (text === '你答应我一件事') {
        this.drawCircularText('一件事', startRad, endRad, -15);
        this.drawCircularText('你答应我', startRad, endRad, 3);
      } else if (text === '说一个真心话') {
        this.drawCircularText('真心话', startRad, endRad, -15);
        this.drawCircularText('说一个', startRad, endRad, 3);
      } else if (text === '问我一个问题') {
        this.drawCircularText('个问题', startRad, endRad, -15);
        this.drawCircularText('问我一', startRad, endRad, 3);
      } else {
        this.drawCircularText(text, startRad, endRad, 0);
      }

      start += this.avgAngle;
    }
  }
  /**
   * 在扇形中间画大表情
   */
  drawEmojiInSector() {
    if (this.canvasContext === undefined) {
      return;
    }
    let radius = this.screenWidth * CommonConstants.INNER_ARC_RATIOS;
    let centerX = 0;
    let centerY = 0;
    let emojiList = ['😀', '🥰', '😍', '🥳', '😎', '🤯'];
    let textList = [
      '我答应你一件事',
      '你答应我一件事',
      '再抽一次',
      '说一个真心话',
      '问我一个问题',
      '再抽一次'
    ];
    let start = this.startAngle;
    let canvasContext = this.canvasContext;

    for (let i = 0; i < CommonConstants.COUNT; i++) {
      let midAngle = (start + this.avgAngle / 2) * Math.PI / CommonConstants.HALF_CIRCLE;
      // 表情位置（稍微靠上）
      let emojiX = centerX + (radius / 2.0) * Math.cos(midAngle);
      let emojiY = centerY + (radius / 2.0) * Math.sin(midAngle);
      // 文字位置（稍微靠下）
      let textX = centerX + (radius / 1.8) * Math.cos(midAngle);
      let textY = centerY + (radius / 1.8) * Math.sin(midAngle);

      // 画表情
      canvasContext.save();
      canvasContext.beginPath();
      canvasContext.translate(emojiX, emojiY);
      canvasContext.rotate(midAngle + Math.PI / 2);
      canvasContext.font = '80px sans-serif';
      canvasContext.fillStyle = '#FFFFFF';
      canvasContext.textAlign = 'center';
      canvasContext.textBaseline = 'middle';
      canvasContext.fillText(emojiList[i], 0, 0);
      canvasContext.restore();

      start += this.avgAngle;
    }
  }

  /**
   * Obtains the character string corresponding to the specified resource ID.
   *
   * @param resource resource.
   */
  getResourceString(resource: Resource): string {
    if (CheckEmptyUtils.isEmptyObj(resource)) {
      Logger.error('[DrawModel][getResourceString] resource is empty.')
      return '';
    }
    let resourceString: string = '';
    try {
      resourceString = uiContext!.getHostContext()!.resourceManager.getStringSync(resource.id);
    } catch (error) {
      Logger.error(`[DrawModel][getResourceString]getStringSync failed, error : ${JSON.stringify(error)}.`);
    }
    return resourceString;
  }

  /**
   * Draw Arc Text.
   *
   * @param textString textString.
   * @param startAngle startAngle.
   * @param endAngle endAngle.
   */
  drawCircularText(textString: string, startAngle: number, endAngle: number, radiusOffset: number = 0) {
    if (CheckEmptyUtils.isEmptyStr(textString)) {
      Logger.error('[DrawModel][drawCircularText] textString is empty.')
      return;
    }

    class CircleText {
      x: number = 0;
      y: number = 0;
      radius: number = 0;
    }

    let circleText: CircleText = {
      x: 0,
      y: 0,
      radius: this.screenWidth * CommonConstants.INNER_ARC_RATIOS
    };
    // The radius of the circle.
    let radius = circleText.radius - circleText.radius / CommonConstants.COUNT + radiusOffset;
    // The radians occupied by each letter.
    let angleDecrement = (startAngle - endAngle) / (textString.length - 1);
    let angle = startAngle;
    let index = 0;
    let character: string;

    while (index < textString.length) {
      character = textString.charAt(index);
      this.canvasContext?.save();
      this.canvasContext?.beginPath();
      this.canvasContext?.translate(circleText.x + Math.cos(angle) * radius,
        circleText.y - Math.sin(angle) * radius);
      this.canvasContext?.rotate(Math.PI / CommonConstants.TWO - angle);
      this.canvasContext?.fillText(character, 0, 0);
      angle -= angleDecrement;
      index++;
      this.canvasContext?.restore();
    }
  }

  /**
   * Draw the picture corresponding to the prize in the internal fan area.
   */
  drawImage() {
    // 不画图片，保持纯色扇形
  }

  /**
   * Displaying information about prizes.
   *
   * @param randomAngle randomAngle.
   */
  showPrizeData(randomAngle: number): PrizeData {
    for (let i = 1; i <= CommonConstants.COUNT; i++) {
      if (randomAngle <= i * this.avgAngle) {
        return this.getPrizeData(i);
      }
    }
    return new PrizeData();
  }

  /**
   * Obtaining information about prizes.
   *
   * @param scopeNum scopeNum.
   */
  // 文件：DrawModel.ets 中的 getPrizeData 方法
  // 文件：DrawModel.ets
  // 方法：getPrizeData(scopeNum: number)

  getPrizeData(scopeNum: number): PrizeData {
    let prizeData: PrizeData = new PrizeData();
    switch (scopeNum) {
      case 1:
        prizeData.message = '再抽一次';
        prizeData.emoji = '😀';
        break;
      case 2:
        prizeData.message = '问我一个问题';
        prizeData.emoji = '🥰';
        break;
      case 3:
        prizeData.message = '说一个真心话';
        prizeData.emoji = '😍';
        break;
      case 4:
        prizeData.message = '再抽一次';
        prizeData.emoji = '🥳';
        break;
      case 5:
        prizeData.message = '你答应我一件事';
        prizeData.emoji = '😎';
        break;
      case 6:
        prizeData.message = '我答应你一件事';
        prizeData.emoji = '🤯';
        break;
      default:
        prizeData.message = '再抽一次';
        prizeData.emoji = '😀';
        break;
    }
    prizeData.imageSrc = '';
    return prizeData;
  }
}
