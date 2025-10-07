package ai.hw.cloud.blockchain.service.impl;

import ai.hw.cloud.blockchain.consts.BlockChainFuncs.Points;
import ai.hw.cloud.blockchain.consts.ContractKeyEnum;
import ai.hw.cloud.blockchain.service.ContractService;
import ai.hw.cloud.blockchain.service.PointContractService;
import ai.hw.cloud.common.core.constants.ErrorCode;
import ai.hw.cloud.common.exception.RsvpException;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;

/**
 * @author wuzhiyong (wzy@rsvptech.cn)
 * @since 2023/4/21
 */
@Deprecated
@Service
public class PointContractServiceImpl implements PointContractService {
  @Resource private ContractService contractService;

//  @Override
//  public String updateIntegral(String userId, long points) {
//    String key = ContractKeyEnum.Points.key(userId);
//    try {
//      return contractService.send("updateIntegral", new String[] { key, String.valueOf(points) });
//    } catch (Exception e) {
//      e.printStackTrace();
//      throw new RsvpException(ErrorCode.BLOCKCHAIN_POINT_UPDATE_ERROR);
//    }
//  }

  @Override
  public Long queryIntegral(String userId) {
    String key = ContractKeyEnum.Points.key(userId);
    String value;
    try {
      value = contractService.query(Points.queryIntegral, new String[] { key });
    } catch (Exception e) {
      throw new RsvpException(ErrorCode.BLOCKCHAIN_POINT_QUERY_ERROR, e);
    }
    try {
      return Long.parseLong(value);
    } catch (NumberFormatException e) {
      throw new RsvpException(ErrorCode.BLOCKCHAIN_POINT_DATA_FORMAT_ERROR);
    }
  }

  @Override
  public String transferIntegral(String fromUserId, String toUserId, long points) {
    String fromUserKey = ContractKeyEnum.Points.key(fromUserId);
    String toUserKey = ContractKeyEnum.Points.key(toUserId);

    try {
      return contractService.send(Points.transferIntegral, new String[] {
              fromUserKey, toUserKey, String.valueOf(points)
      });
    } catch (Exception e) {
      throw new RsvpException(ErrorCode.BLOCKCHAIN_POINT_TRANSFER_ERROR);
    }
  }

  @Override
  public String setIntegral(String userId, long points) {
    String key = ContractKeyEnum.Points.key(userId);
    try {
      return contractService.sendSync(Points.setIntegral, new String[] {
              key, String.valueOf(points)
      }).getStatus();
    } catch (Exception e) {
      throw new RsvpException(ErrorCode.BLOCKCHAIN_POINT_SET_ERROR);
    }
  }
}
