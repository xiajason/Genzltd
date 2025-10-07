package ai.hw.cloud.blockchain.service;

import ai.hw.cloud.api.resume.model.category.ResumeModel;

/**
 * @author wuzhiyong (wzy@rsvptech.cn)
 * @since 2023/4/21
 */
public interface ResumeContractService {

  /**
   * 新增简历
   *
   * @param resumeId
   * @param resumeModel
   * @return tx id
   */
  String insertResume(String resumeId, ResumeModel resumeModel);

  /**
   * 查询简历
   *
   * @param resumeId
   * @return ResumeModel
   */
  ResumeModel queryResume(String resumeId);

  /**
   * 删除简历
   *
   * @param resumeId 用户id
   * @return tx id
   */
  String deleteResume(String resumeId);
}
