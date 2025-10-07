package ai.hw.cloud.blockchain.consts;

/**
 * @author wuzhiyong (wzy@rsvptech.cn)
 * @since 2023/4/21
 */
public enum ContractKeyEnum {

  Resume("resume:%s"),

  @Deprecated Points("point:%s"),

  TxRecord("tx_record:%s");

  private final String template;

  ContractKeyEnum(String template) {
    this.template = template;
  }

  public String key(String id) {
    return String.format(template, id);
  }
}
