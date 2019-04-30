# Readme
1. DevOps
    - Auzre ML, DevOps를 활용하여 데이터 분석 플랫폼 구축
    - 샘플 데이터 & 모델 기반으로 DevOps for AI 빌드/릴리즈 파이프라인 설계 
    - Model별 버전 관리
    - Model 버전별 precision/recall 결과 비교하여 우수한 Model 자동 배포
    - Azure DevOps 이용하여 신규버전 Container 생성(ACR), 이후 IoT Edge 배포
2. Azure ML Service
    - Cloud 환경에서 Data + DL Model 학습 (object detection)
    - DL Model Test dataset 활용하여 precision/recall 등 지표에 대한 계산/표시
    - 모델 선정 및 Model Container 생성 (versioning)
3. Iot Edge 연동
    - Vision AI Dev Kit Camera에 Model Container 배포
    - Image와 Prediction한 결과를 Cloud로 전송하여 live prediction 결과 취합
    - Bounding box와 confidence score 값 저장
  
# 개요
기본 기술문서: https://docs.microsoft.com/en-us/azure/machine-learning/service/

주요 개념: https://docs.microsoft.com/en-us/azure/machine-learning/service/concept-azure-machine-learning-architecture

모델관리 개념: https://docs.microsoft.com/en-us/azure/machine-learning/service/concept-model-management-and-deployment

Pipeline 개념: https://docs.microsoft.com/en-us/azure/machine-learning/service/concept-ml-pipelines

보안 관련 접근: https://docs.microsoft.com/en-us/azure/machine-learning/service/concept-enterprise-security

# Hackfest

아래 hackfest 사이트를 통해 Azure ML의 전반적인 사용법을 익힐 수 있습니다.
https://github.com/Azure/LearnAI_Azure_ML

  
# 샘플

샘플 사용방법: https://docs.microsoft.com/en-us/azure/machine-learning/service/samples-notebooks

깃허브: https://github.com/Azure/MachineLearningNotebooks

(여기에 아래 거의 모든 기능들에 대한 샘플이 있으니 가장 유용할 것으로 판단.)

기능별 상세 가이드는 How-to guides (방법 가이드) 이하 항목으로 나온다.
직관적으로 되어 있어서 원하시는 단계를 찾으시면 되며, 몇 가지만 소개하면 다음과 같습니다:

개발환경: https://docs.microsoft.com/en-us/azure/machine-learning/service/how-to-configure-environment

DataPrep SDK를 이용한 데이터가공: https://docs.microsoft.com/en-us/azure/machine-learning/service/how-to-transform-data

Datastore: https://docs.microsoft.com/en-us/azure/machine-learning/service/how-to-access-data

원격수행: https://docs.microsoft.com/en-us/azure/machine-learning/service/how-to-set-up-training-targets

Tensorflow 기본방식: https://docs.microsoft.com/en-us/azure/machine-learning/service/how-to-train-tensorflow

Hyperparameter Tuning: https://docs.microsoft.com/en-us/azure/machine-learning/service/how-to-tune-hyperparameters

Automated ML: https://docs.microsoft.com/en-us/azure/machine-learning/service/how-to-configure-auto-train

ONNX: https://docs.microsoft.com/en-us/azure/machine-learning/service/how-to-build-deploy-onnx

배포: https://docs.microsoft.com/en-us/azure/machine-learning/service/how-to-deploy-and-where

실시간 추론: https://docs.microsoft.com/en-us/azure/machine-learning/service/how-to-consume-web-service

배치 추론: https://docs.microsoft.com/en-us/azure/machine-learning/service/how-to-run-batch-predictions

모니터: https://docs.microsoft.com/en-us/azure/machine-learning/service/how-to-enable-app-insights

쿼터관리: https://docs.microsoft.com/en-us/azure/machine-learning/service/how-to-manage-quotas
  
# SDK
Azure ML SDK (설치방법 포함): https://docs.microsoft.com/en-us/python/api/overview/azure/ml/intro?view=azure-ml-py

Dataprep SDK: https://docs.microsoft.com/en-us/python/api/overview/azure/dataprep/intro?view=azure-dataprep-py

Monitoring SDK: https://docs.microsoft.com/en-us/python/api/overview/azure/monitoring/intro?view=azureml-monitoring-py
  
# ETC
릴리즈 노트: https://docs.microsoft.com/en-us/azure/machine-learning/service/azure-machine-learning-release-notes

가격체계: https://azure.microsoft.com/ko-kr/pricing/details/machine-learning-service/


가장 빠른 방법은 아래의 Tutorial 아래에 있는 4개의 샘플을 직접 수행

MNIST 데이터로 1. 모델 생성, 2. 모델 배포

NYC Taxi 데이터로 1. 데이터 가공, 2. Automated ML로 모델 생성

https://docs.microsoft.com/en-us/azure/machine-learning/service/tutorial-train-models-with-aml