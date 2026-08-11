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
   * @param {boolean} isPremium グループがプレミアムかどうか
   * @param {Date} indexedDate 家事の日付
   * @param {Date} executedAt 再計算を実行した日時
   * @return {Date} 算出した保持期限
   */
  static calcExpiredAt(
    isPremium: boolean,
    indexedDate: Date,
    executedAt: Date
  ): Date {
    const baseDate = isPremium ? indexedDate : executedAt;
    const years = isPremium ?
      this.PREMIUM_RETENTION_YEARS :
      this.FREE_RETENTION_YEARS;
    const expiredAt = new Date(baseDate.getTime());
    expiredAt.setFullYear(expiredAt.getFullYear() + years);
    return expiredAt;
  }
}

/**
 * Houseworkドキュメントのフィールド名定数
 */
export class HouseworkFields {
  static readonly INDEXED_DATE_VALUE = "indexedDate.value";
  static readonly EXPIRED_AT = "expiredAt";
}
