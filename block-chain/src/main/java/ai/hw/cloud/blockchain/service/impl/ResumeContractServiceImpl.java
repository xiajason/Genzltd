package ai.hw.cloud.blockchain.service.impl;

import ai.hw.cloud.api.resume.model.category.ResumeModel;
import ai.hw.cloud.blockchain.consts.BlockChainFuncs.Resume;
import ai.hw.cloud.blockchain.service.ContractService;
import ai.hw.cloud.blockchain.service.ResumeContractService;
import ai.hw.cloud.common.core.constants.ErrorCode;
import ai.hw.cloud.common.exception.RsvpException;
import com.alibaba.fastjson2.JSON;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;

/**
 * @author wuzhiyong (wzy@rsvptech.cn)
 * @since 2023/4/21
 */
@Service
public class ResumeContractServiceImpl implements ResumeContractService {
  @Resource ContractService contractService;

  @Override
  public String insertResume(String resumeId, ResumeModel resumeModel) {
    try {
      return contractService.sendSync(Resume.insertResume, new String[] { resumeId, JSON.toJSONString(resumeModel) })
              .getTxId();
    } catch (Exception e) {
      throw new RsvpException(ErrorCode.BLOCKCHAIN_INSERT_RESUME_ERROR);
    }
  }

  @Override
  public ResumeModel queryResume(String resumeId) {
    String value;
    try {
      value = contractService.query(Resume.queryResume, new String[] { resumeId });
    } catch (Exception e) {
      throw new RsvpException(ErrorCode.BLOCKCHAIN_QUERY_RESUME_ERROR);
    }
    try {
      return JSON.parseObject(value, ResumeModel.class);
    } catch (Exception e) {
      throw new RsvpException(ErrorCode.BLOCKCHAIN_RESUME_DATA_INVALID_ERROR);
    }
  }

  @Override
  public String deleteResume(String resumeId) {
    try {
      return contractService.sendSync(Resume.deleteResume, new String[] { resumeId }).getStatus();
    } catch (Exception e) {
      throw new RsvpException(ErrorCode.BLOCKCHAIN_RESUME_DELETE_ERROR);
    }
  }
}
