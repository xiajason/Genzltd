/*
 * Copyright(c) Huawei Technologies Co.,Ltd. 2021. All right reserved.
 */

package ai.hw.cloud.blockchain.utils;

import com.google.common.util.concurrent.ListenableFuture;
import com.google.protobuf.InvalidProtocolBufferException;
import com.huawei.wienerchain.SdkClient;
import com.huawei.wienerchain.WienerChainNode;
import com.huawei.wienerchain.message.build.QueryRawMessage;
import com.huawei.wienerchain.proto.common.BlockOuterClass.Block;
import com.huawei.wienerchain.proto.common.BlockOuterClass.BlockBody;
import com.huawei.wienerchain.proto.common.Message.RawMessage;
import com.huawei.wienerchain.proto.common.Message.Response;
import com.huawei.wienerchain.proto.common.Message.Status;
import com.huawei.wienerchain.proto.common.TransactionOuterClass.Tx;
import com.huawei.wienerchain.proto.nodeservice.ChainServiceOuterClass.LatestChainState;
import org.bouncycastle.util.encoders.DecoderException;
import org.bouncycastle.util.encoders.Hex;

import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;

/**
 * 功能描述: 直接获取区块数据的工具类
 *
 * @author author
 * @since 2021-10-29
 */
/*
 * Block 的数据结构如下：
 *
 * Block {
 *   header {
 *       number
 *       timestamp
 *       bodyHash
 *   }
 *   body {
 *       tx_list [{
 *           Tx {
 *               ...
 *           }
 *       }]
 *    }
 * }
 *
 */
public class BlockUtil {

  private static final int FUTURE_TIMEOUT = 20;

  // 通过区块号查询区块，区块号从 0 开始计数
  public static Block queryBlockByNumber(SdkClient sdkClient, long blockNumber, String queryNode, String chainId)
          throws Exception {
    try {
      System.out.println("[info] enter queryBlockByNumber");
      QueryRawMessage queryRawMessage = sdkClient.getQueryRawMessage();
      WienerChainNode wienerChainNode = sdkClient.getWienerChainNode(queryNode);
      RawMessage rawMessage = queryRawMessage.buildBlockRawMessage(chainId, blockNumber);
      ListenableFuture<RawMessage> future = wienerChainNode.getQueryAction().queryBlockByNum(rawMessage);
      return parseToBlock(future);
    } catch (ExecutionException e) {
      System.out.println("[error] please input an exist block number");
      return null;
    }
  }

  // 查询当前最新的区块
  public static Block queryLastBlock(SdkClient sdkClient, String queryNode, String chainId) throws Exception {
    System.out.println("[info] enter queryLastBlock");
    long lastBlockNumber = queryLastBlockNumber(sdkClient, queryNode, chainId);
    return queryBlockByNumber(sdkClient, lastBlockNumber, queryNode, chainId);
  }

  // 通过交易 ID 查询区块
  public static Block queryBlockByTxID(SdkClient sdkClient, String txID, String queryNode, String chainId)
          throws Exception {
    System.out.println("[info] enter queryBlockByTxID");
    try {
      byte[] txHash = Hex.decode(txID);
      QueryRawMessage queryRawMessage = sdkClient.getQueryRawMessage();
      WienerChainNode wienerChainNode = sdkClient.getWienerChainNode(queryNode);
      RawMessage rawMessage = queryRawMessage.buildTxRawMessage(chainId, txHash);
      ListenableFuture<RawMessage> future = wienerChainNode.getQueryAction().queryBlockByTxHash(rawMessage);
      return parseToBlock(future);
    } catch (DecoderException e) {
      System.out.println("[error] please input a txID with correct format");
      return null;
    } catch (ExecutionException e) {
      System.out.println("[error] please input an exist txID");
      return null;
    }
  }

  // 查询当前最新区块的区块号
  public static long queryLastBlockNumber(SdkClient sdkClient, String queryNode, String chainId) throws Exception {
    QueryRawMessage queryRawMessage = sdkClient.getQueryRawMessage();
    WienerChainNode wienerChainNode = sdkClient.getWienerChainNode(queryNode);
    RawMessage rawMessage = queryRawMessage.buildLatestChainStateRawMessage(chainId);
    ListenableFuture<RawMessage> future = wienerChainNode.getQueryAction().queryLatestChainState(rawMessage);
    Response response = Response.parseFrom(future.get(FUTURE_TIMEOUT, TimeUnit.SECONDS).getPayload());
    if (response.getStatus() == Status.SUCCESS) {
      LatestChainState latestChainState = LatestChainState.parseFrom(response.getPayload());
      return latestChainState.getHeight() - 1;
    }
    System.out.println(
            "[error] queryLastBlockNumber failed, error is: " + response.getStatus() + ": " + response.getStatusInfo());
    return 0;
  }

  public static long getNumber(Block block) {
    return block.getHeader().getNumber();
  }

  public static long getTimestamp(Block block) {
    return block.getHeader().getTimestamp();
  }

  public static String getBodyHash(Block block) {
    return Base64.getEncoder().encodeToString(block.getHeader().getBodyHash().toByteArray());
  }

  // 获取区块上所有交易的ID
  public static List<String> getTxIdList(Block block) throws InvalidProtocolBufferException {
    List<String> txIDList = new ArrayList<>();
    BlockBody blockBody = BlockBody.parseFrom(block.getBody());
    for (Tx tx : blockBody.getTxListList()) {
      txIDList.add(TxUtil.getTxID(tx));
    }
    return txIDList;
  }

  // 获取区块上的所有交易
  public static List<Tx> getTxList(Block block) throws InvalidProtocolBufferException {
    BlockBody blockBody = BlockBody.parseFrom(block.getBody());
    return blockBody.getTxListList();
  }

  // 打印区块基本信息
  public static void printBlockBasicInfo(Block block) {
    System.out.println("block number is: " + getNumber(block));
    System.out.println("block timestamp is: " + getTimestamp(block));
    System.out.println("block body hash is: " + getBodyHash(block));
  }

  // 打印区块上所有交易的数据
  public static void printBlockTxsInfo(Block block) throws InvalidProtocolBufferException {
    BlockBody blockBody = BlockBody.parseFrom(block.getBody());
    for (Tx tx : blockBody.getTxListList()) {
      System.out.println("transactionId is: " + TxUtil.getTxID(tx));
      System.out.println("keyValue is: " + TxUtil.getTxKeyValues(tx));
    }
  }

  // 私有方法，从 future 解析出区块对象
  private static Block parseToBlock(ListenableFuture<RawMessage> future) throws Exception {
    Response response = Response.parseFrom(future.get(FUTURE_TIMEOUT, TimeUnit.SECONDS).getPayload());
    if (response.getStatus() == Status.SUCCESS) {
      return Block.parseFrom(response.getPayload());
    }
    System.out.println(
            "[error] parse to block failed, error is: " + response.getStatus() + ": " + response.getStatusInfo());
    return null;
  }
}
