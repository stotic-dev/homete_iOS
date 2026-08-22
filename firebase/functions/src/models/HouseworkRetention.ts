/**
 * 家事データの保持期限（expiredAt）に関する定数と算出ロジック
 *
 * iOS側の `HouseworkStoragePolicy`
 * （LocalPackage/Sources/HometeDomain/Subscription/）と同じルールを実装している。
 * 片方を変更する場合は必ずもう片方も合わせること。
 */
export class HouseworkRetention {
  /** 無料プランの保持年数 */
  static readonly FREE_RETENTION_YEARS = 1;
  /** プレミアムプランの保持年数（実質無期限） */
  static readonly PREMIUM_RETENTION_YEARS = 100;

  /**
   * 保持期限を算出する
   *
   * プレミアムは家事の日付を起点に実質無期限とする。
   * 無料は解約直後に過去データが一斉削除されるのを避けるため、
   * 家事の日付ではなく実行日（＝解約を検知した日）を起点に1年の猶予を設ける。
   *
   * ただし無料では既存の期限を後ろへ延ばさない。実行日を起点にすると
   * 呼び出すたびに期限が伸びてしまい、再実行が冪等でなくなるうえ、
   * グループのメンバーが繰り返し呼ぶことでTTLによる削除を無期限に
   * 先送りできてしまうため。
   * @param {boolean} isPremium グループがプレミアムかどうか
   * @param {Date} indexedDate 家事の日付
   * @param {Date} executedAt 再計算を実行した日時
   * @param {Date | undefined} currentExpiredAt 現在保存されている保持期限
   * @return {Date} 算出した保持期限
   */
  static calcExpiredAt(
    isPremium: boolean,
    indexedDate: Date,
    executedAt: Date,
    currentExpiredAt?: Date
  ): Date {
    if (isPremium) {
      return this.addYears(indexedDate, this.PREMIUM_RETENTION_YEARS);
    }

    const gracePeriodEnd = this.addYears(executedAt, this.FREE_RETENTION_YEARS);
    if (
      currentExpiredAt &&
      currentExpiredAt.getTime() < gracePeriodEnd.getTime()
    ) {
      return currentExpiredAt;
    }
    return gracePeriodEnd;
  }

  /**
   * 指定した日付に年数を加算した日付を返す
   * @param {Date} date 起点の日付
   * @param {number} years 加算する年数
   * @return {Date} 加算後の日付
   */
  private static addYears(date: Date, years: number): Date {
    const added = new Date(date.getTime());
    added.setFullYear(added.getFullYear() + years);
    return added;
  }
}

/**
 * Houseworkドキュメントのフィールド名定数
 */
export class HouseworkFields {
  static readonly INDEXED_DATE_VALUE = "indexedDate.value";
  static readonly EXPIRED_AT = "expiredAt";
}
