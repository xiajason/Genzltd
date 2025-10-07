/*
 * Copyright(c) Huawei Technologies Co.,Ltd. 2021. All right reserved.
 */

package ai.hw.cloud.blockchain.service.impl;

import ai.hw.cloud.blockchain.config.BlockChainConfig;
import ai.hw.cloud.blockchain.consts.BlockChainFuncs.NamedFunc;
import ai.hw.cloud.blockchain.model.BlockChainSendResp;
import ai.hw.cloud.blockchain.service.BlockChainTxService;
import ai.hw.cloud.blockchain.service.ContractService;
import com.github.rholder.retry.RetryException;
import com.github.rholder.retry.Retryer;
import com.github.rholder.retry.RetryerBuilder;
import com.github.rholder.retry.StopStrategies;
import com.github.rholder.retry.WaitStrategies;
import com.google.common.base.Charsets;
import com.huawei.wienerchain.SdkClient;
import com.huawei.wienerchain.WienerChainNode;
import com.huawei.wienerchain.exception.SdkException;
import com.huawei.wienerchain.message.Builder.TxRawMsg;
import com.huawei.wienerchain.message.build.ContractRawMessage;
import com.huawei.wienerchain.proto.common.Message.RawMessage;
import com.huawei.wienerchain.proto.common.Message.RawMessage.Type;
import com.huawei.wienerchain.proto.common.Message.Response;
import com.huawei.wienerchain.proto.common.Message.Status;
import com.huawei.wienerchain.proto.common.TransactionOuterClass.CommonTxData;
import com.huawei.wienerchain.proto.common.TransactionOuterClass.Transaction;
import com.huawei.wienerchain.proto.common.TransactionOuterClass.TxPayload;
import com.huawei.wienerchain.proto.nodeservice.ContractOuterClass.Invocation;
import lombok.extern.slf4j.Slf4j;
import org.bouncycastle.util.encoders.Hex;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.Objects;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import javax.annotation.Resource;

/**
 * 功能描述: 执行合约相关的操作，如发送和查询交易数据
 *
 * @author author
 * @since 2021-10-28
 */
@Slf4j
@Service
public class ContractServiceImpl implements ContractService {

  @Resource private BlockChainConfig blockChainConfig;
  @Resource private SdkClient sdkClient;
  @Resource private BlockChainTxService blockChainTxService;

  private static final int FUTURE_TIMEOUT = 200;

  private static final int LISTEN_TIMEOUT = 200;

  // 使用合约进行交易发送。数据修改类的操作使用此方法
  @Override
  public String send(NamedFunc func, String[] args) throws Exception {
    String[] nodes = blockChainConfig.getEndorserNodes().split(",");
    if (nodes.length == 0) {
      throw new SdkException("[warn] Please input at least one node");
    }
    ContractRawMessage contractRawMessage = sdkClient.getContractRawMessage();
    // 构建合约调用消息
    RawMessage rawMessage =
            contractRawMessage.buildInvokeRawMsg(blockChainConfig.getChainID(), blockChainConfig.getContractName(),
                    func.funcName(), args);
    RawMessage[] invokeRes = new RawMessage[nodes.length];

    for (int i = 0; i < nodes.length; i++) {
      // 请求背书
      invokeRes[i] = sdkClient.getWienerChainNode(nodes[i]).getContractAction().invoke(rawMessage)
              .get(FUTURE_TIMEOUT, TimeUnit.SECONDS);
    }

    TxRawMsg txMsg = contractRawMessage.buildTxRawMsg(invokeRes);
    String txId = Hex.toHexString(txMsg.hash);
    log.debug("发送交易哈希： " + txId);
    // 请求落盘
    RawMessage resultMsg =
            sdkClient.getWienerChainNode(blockChainConfig.getConsensusNode()).getContractAction().transaction(txMsg.msg)
                    .get(FUTURE_TIMEOUT, TimeUnit.SECONDS);
    Response response = Response.parseFrom(resultMsg.getPayload());
    if (response.getStatus() != Status.SUCCESS) {
      throw new SdkException("transaction response status is: " + response.getStatus());
    }

    return txId;
  }

  @Override
  public BlockChainSendResp sendSync(NamedFunc func, String[] args) throws Exception {
    BlockChainSendResp resp = new BlockChainSendResp();
    String txId = this.send(func, args);
    resp.setTxId(txId);
    Thread.sleep(1000);
    Retryer<String> retryer = RetryerBuilder.<String> newBuilder().retryIfResult(Objects::isNull)
//            .retryIfExceptionOfType(IOException.class)
//            .retryIfRuntimeException()
            .retryIfException().withStopStrategy(StopStrategies.stopAfterDelay(30, TimeUnit.SECONDS))
            .withWaitStrategy(WaitStrategies.incrementingWait(1, TimeUnit.SECONDS, 2, TimeUnit.SECONDS)).build();

    String result = retryer.call(() -> blockChainTxService.queryTxResult(txId));
    resp.setStatus(result);
    return resp;
  }

  // 使用合约进行交易查询。数据查询类的操作使用此方法
  @Override
  public String query(NamedFunc func, String[] args) throws Exception {
    ContractRawMessage contractRawMessage = sdkClient.getContractRawMessage();
    // 1. 合约调用消息构建
    RawMessage rawMessage =
            contractRawMessage.buildInvokeRawMsg(blockChainConfig.getChainID(), blockChainConfig.getContractName(),
                    func.funcName(), args);
    // 2. 查询请求消息构建与发送
    RawMessage invokeResponse =
            sdkClient.getWienerChainNode(blockChainConfig.getQueryNode()).getContractAction().invoke(rawMessage)
                    .get(FUTURE_TIMEOUT, TimeUnit.SECONDS);
    // 3. 解析查询结果
    Response response = Response.parseFrom(invokeResponse.getPayload());
    if (response.getStatus() == Status.SUCCESS) {
      Transaction transaction = Transaction.parseFrom(response.getPayload());
      TxPayload txPayload = TxPayload.parseFrom(transaction.getPayload());
      CommonTxData commonTxData = CommonTxData.parseFrom(txPayload.getData());
      String result = commonTxData.getResponse().getPayload().toString(Charsets.UTF_8);
      return result;
    }
    log.error("[error] query transaction failed, error is: " + response.getStatus() + ": " + response.getStatusInfo());
    return null;
  }

  // 私有方法，获取调用合约所产生的结果
  private RawMessage generateInvokeResponse(String nodeName, ContractRawMessage contractRawMessage,
          Invocation invocation) throws Exception {
    WienerChainNode node = sdkClient.getWienerChainNode(nodeName);
    RawMessage rawMessage =
            contractRawMessage.getRawMessageBuilder(invocation.toByteString()).setType(Type.DIRECT).build();
    return node.getContractAction().invoke(rawMessage).get(FUTURE_TIMEOUT, TimeUnit.SECONDS);
  }

  public static void main(String[] args) throws ExecutionException, RetryException {
    long start = System.currentTimeMillis();
    System.out.println(new Date());
    AtomicInteger i = new AtomicInteger(0);
    Retryer<String> retryer = RetryerBuilder.<String> newBuilder().retryIfResult(Objects::isNull)
//            .retryIfExceptionOfType(IOException.class)
//            .retryIfRuntimeException()
            .withStopStrategy(StopStrategies.stopAfterDelay(20, TimeUnit.SECONDS))
            .withWaitStrategy(WaitStrategies.incrementingWait(1, TimeUnit.SECONDS, 2, TimeUnit.SECONDS)).build();
    Callable<String> callable = () -> {
      String s = new Date().toString();
      if (i.get() < 1000) {
        i.addAndGet(1);
        System.out.println(s);
        return null;
      }

      System.out.println(s + "----");
      return s;
    };
    retryer.call(callable);
    long end = System.currentTimeMillis();
    System.out.println(end - start);
  }
}
