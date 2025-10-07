/*
 * Copyright(c) Huawei Technologies Co.,Ltd. 2021. All right reserved.
 */

package ai.hw.cloud.blockchain.utils;

import com.google.common.base.Strings;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.protobuf.InvalidProtocolBufferException;
import com.huawei.wienerchain.SdkClient;
import com.huawei.wienerchain.WienerChainNode;
import com.huawei.wienerchain.exception.CryptoException;
import com.huawei.wienerchain.message.build.QueryRawMessage;
import com.huawei.wienerchain.proto.common.Ledger;
import com.huawei.wienerchain.proto.common.Message.RawMessage;
import com.huawei.wienerchain.proto.common.Message.Response;
import com.huawei.wienerchain.proto.common.Message.Status;
import com.huawei.wienerchain.proto.common.TransactionOuterClass;
import com.huawei.wienerchain.proto.common.TransactionOuterClass.CommonTxData;
import com.huawei.wienerchain.proto.common.TransactionOuterClass.ContractInvocation;
import com.huawei.wienerchain.proto.common.TransactionOuterClass.Tx;
import com.huawei.wienerchain.proto.common.TransactionOuterClass.TxHeader;
import com.huawei.wienerchain.proto.common.TransactionOuterClass.TxPayload;
import com.huawei.wienerchain.proto.common.TransactionOuterClass.TxResult;
import lombok.extern.slf4j.Slf4j;
import org.bouncycastle.util.encoders.DecoderException;
import org.bouncycastle.util.encoders.Hex;

import java.io.ByteArrayInputStream;
import java.security.NoSuchProviderException;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import javax.naming.InvalidNameException;
import javax.naming.ldap.LdapName;
import javax.naming.ldap.Rdn;

/**
 * 功能描述: 直接获取交易数据的工具类
 *
 * @author author
 * @since 2021-10-29
 */
/*
 * Tx 的数据结构如下：
 *
 * Tx {
 *   hash
 *   full -> Transaction {
 *       approvals {
 *           identity
 *           sign
 *       }
 *       payload -> TxPayload {
 *           header {
 *               chain_id
 *               timestamp
 *           }
 *           data -> commonTxData {
 *               contractInvocation {
 *                   contract_name
 *               }
 *               response {
 *                   status
 *               }
 *               stateUpdates {
 *                   namespace
 *                   kvUpdates [{
 *                       updates {
 *                           key
 *                           value
 *                       }
 *                   }]
 *               }
 *           }
 *       }
 *    }
 * }
 */
@Slf4j
public class TxUtil {

  private static final String TYPE = "X.509";

  private static final String PROVIDER_SHORT_NAME = "BC";

  private static final int FUTURE_TIMEOUT = 20;

  // 通过交易 ID 查询交易
  public static Tx queryTxByTxID(SdkClient sdkClient, String txID, String queryNode, String chainId) throws Exception {
    log.info("[info] enter queryTxByTxID");
    try {
      byte[] txHash = Hex.decode(txID);
      QueryRawMessage queryRawMessage = sdkClient.getQueryRawMessage();
      WienerChainNode wienerChainNode = sdkClient.getWienerChainNode(queryNode);
      RawMessage rawMessage = queryRawMessage.buildTxRawMessage(chainId, txHash);
      ListenableFuture<RawMessage> future = wienerChainNode.getQueryAction().queryTxByHash(rawMessage);
      Response response = Response.parseFrom(future.get(FUTURE_TIMEOUT, TimeUnit.SECONDS).getPayload());
      if (response.getStatus() == Status.SUCCESS) {
        return Tx.parseFrom(response.getPayload());
      }
      log.error("[error] parse to transaction failed, error is: " + response.getStatus() + ": "
              + response.getStatusInfo());
    } catch (DecoderException e) {
      log.error("[error] please input a txID with correct format", e);
      return null;
    } catch (ExecutionException e) {
      log.error("[error] please input an exist txID", e);
    }
    return null;
  }

  // 通过交易 ID 查询交易结果是否 Valid
  public static String queryTxResultByTxID(SdkClient sdkClient, String txID, String queryNode, String chainId)
          throws Exception {
    log.info("[info] enter queryTxResultByTxID");
    try {
      byte[] txHash = Hex.decode(txID);
      QueryRawMessage queryRawMessage = sdkClient.getQueryRawMessage();
      WienerChainNode wienerChainNode = sdkClient.getWienerChainNode(queryNode);
      RawMessage rawMessage = queryRawMessage.buildTxRawMessage(chainId, txHash);
      ListenableFuture<RawMessage> future = wienerChainNode.getQueryAction().queryTxResultByTxHash(rawMessage);
      Response response = Response.parseFrom(future.get(FUTURE_TIMEOUT, TimeUnit.SECONDS).getPayload());
      if (response.getStatus() == Status.SUCCESS) {
        return TxResult.parseFrom(response.getPayload()).getStatus().toString();
      }
      log.error("[error] queryTxResultByTxID failed, error is: " + response.getStatus() + ": "
              + response.getStatusInfo());
    } catch (DecoderException e) {
      log.error("[error] please input a txID with correct format");
      return null;
    } catch (ExecutionException e) {
      log.error("[error] please input an exist txID");
    }
    return null;
  }

  public static long getTimestamp(Tx tx) throws InvalidProtocolBufferException {
    return getTxPayloadHeader(tx).getTimestamp();
  }

  public static String getTxID(Tx tx) {
    return new String(Hex.encode(tx.getHash().toByteArray()));
  }

  // 获取交易 Tx 使用的合约的名称
  public static String getContractName(Tx tx) throws InvalidProtocolBufferException {
    CommonTxData commonTxData = getCommonTxData(tx);
    if (commonTxData == null) {
      return null;
    }
    return ContractInvocation.parseFrom(commonTxData.getContractInvocation()).getContractName();
  }

  // 获取交易 Tx 中的 key 和 value
  public static List<Ledger.KeyValue> getTxKeyValues(Tx tx) throws InvalidProtocolBufferException {
    List<Ledger.KeyValue> keyValues = new ArrayList<>();
    CommonTxData commonTxData = getCommonTxData(tx);
    if (commonTxData == null) {
      return null;
    }
    for (Ledger.StateUpdates stateUpdates : commonTxData.getStateUpdatesList()) {
      keyValues.addAll(stateUpdates.getKvUpdates().getUpdatesList());
    }
    return keyValues;
  }

  // 获取给交易 Tx 背书的组织
  public static List<String> getEndorsersOrg(Tx tx) throws CryptoException {
    List<String> endorsersOrg = new ArrayList<>();
    for (TransactionOuterClass.Approval approval : tx.getFull().getApprovalsList()) {
      if (!Strings.isNullOrEmpty(approval.getOrgName())) {
        endorsersOrg.add(approval.getOrgName());
        continue;
      }
      endorsersOrg.add(getOrg(approval.getIdentity().toByteArray()));
    }
    return endorsersOrg;
  }

  // 获取创建交易 Tx 的组织
  public static String getCreateOrg(Tx tx) throws InvalidProtocolBufferException, CryptoException {
    TxHeader txPayloadHeader = getTxPayloadHeader(tx);
    if (txPayloadHeader.hasCreator()) {
      return txPayloadHeader.getCreator().getOrg();
    }
    return getEndorsersOrg(tx).get(0);
  }

  // 私有方法，从 LdapName 中获取组织名
  private static String getOrg(byte[] cert) throws CryptoException {
    LdapName ldapDn = getLdapName(cert);
    for (Rdn rdn : ldapDn.getRdns()) {
      if ("O".equals(rdn.getType())) {
        return rdn.getValue().toString();
      }
    }
    return "";
  }

  // 私有方法，从证书中获取 LdapName
  private static LdapName getLdapName(byte[] identity) throws CryptoException {
    try {
      ByteArrayInputStream byteArrayInputStream = new ByteArrayInputStream(identity);
      X509Certificate certificate = (X509Certificate) CertificateFactory.getInstance(TYPE, PROVIDER_SHORT_NAME)
              .generateCertificate(byteArrayInputStream);
      String dn = certificate.getSubjectDN().getName();
      return new LdapName(dn);
    } catch (CertificateException | InvalidNameException | NoSuchProviderException e) {
      throw new CryptoException("get Ldap name exception", e);
    }
  }

  // 私有方法，从交易 Tx 中获取 TxPayload 对象
  private static TxHeader getTxPayloadHeader(Tx tx) throws InvalidProtocolBufferException {
    TxPayload txPayload = TxPayload.parseFrom(tx.getFull().getPayload());
    return txPayload.getHeader();
  }

  // 私有方法，从交易 Tx 中获取 CommonTxData 对象
  private static CommonTxData getCommonTxData(Tx tx) throws InvalidProtocolBufferException {
    TxPayload txPayload = TxPayload.parseFrom(tx.getFull().getPayload());
    try {
      return CommonTxData.parseFrom(txPayload.getData());
    } catch (InvalidProtocolBufferException e) {
      log.error("[error] Reading a block with no tx keyValue, "
              + "which could be a genesis block or a contract voting block");
      return null;
    }
  }
}
