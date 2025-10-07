package ai.hw.cloud.blockchain.consts;

import java.util.Objects;

/**
 * @author wuzhiyong (wzy@rsvptech.cn)
 * @since 2023/5/11
 */
public final class BlockChainFuncs {
  public interface NamedFunc {
    default String funcName() {
      return Objects.toString(this);
    }
  }

  public enum Resume implements NamedFunc {
    /**
     * 写入简历
     */
    insertResume,
    /**
     * 查询简历
     */
    queryResume,

    /**
     * 删除简历
     */
    deleteResume;
  }

  @Deprecated
  public enum Points implements NamedFunc {
    /**
     * 设置积分
     */
    @Deprecated setIntegral,
    /**
     * 查询积分
     */
    @Deprecated queryIntegral,

    /**
     * 转账积分
     */
    @Deprecated transferIntegral;
  }

  public enum TxRecord implements NamedFunc {
    /**
     * 写入交易记录
     */
    insertTxRecord,
    /**
     * 查询交易记录
     */
    queryTxRecord
  }
}
