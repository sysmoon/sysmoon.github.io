---
title: "istio-telemetry_collecting_metrics"
date: 2019-06-04 08:26:28 -0400
categories: istio
---

# Collecting Metric 1
이번 작업은 Service Mesh를 위해 자동으로 telemetry 정보를 수집하기 위한 istio 설정 방법에 대해 알아본다.
마지막 부분에 Service Mesh 안에서 새로운 서비스를 위한 Metric이 활성화 된다.
Bookinfo 샘플 어플케이션이 이 작업을 위해 예제로 활용되기 때문에 먼저 Bookinfo 애플리케이션이 배포되어 있어야 한다.

# Before you begin
- 사용하고 있는 쿠버네티스 클러스터에 Istio를 설치하고, App을 배포한다. 이 작업은 Mixer가 default configuration (–configDefaultNamespace=istio-system) 이 설정된 것으로 가정한다.
만약 다른 설정값을 사용하고 있다면, 위 설정으로 업데이트해야 한다.

# Collecting new metrics
1. 새로운 metric 정보를 수집하기 위해 YAML 파일을 적용하면, istio는 필요한 리소스를 생성하고, metic 정보를 자동으로 수집한다.
```
kubectl apply -f samples/bookinfo/telemetry/metrics.yaml
```
```
   만약, istio >= 1.1.2 일 경우, 아래 yaml configuration 적용 필요
   kubectl apply -f samples/bookinfo/telemetry/metrics-crd.yaml
```

samples/bookinfo/telemetry/metrics-crd.yaml
```
# Configuration for metric instances
apiVersion: "config.istio.io/v1alpha2"
kind: metric
metadata:
  name: doublerequestcount
  namespace: istio-system
spec:
  value: "2" # count each request twice
  dimensions:
    reporter: conditional((context.reporter.kind | "inbound") == "outbound", "client", "server")
    source: source.workload.name | "unknown"
    destination: destination.workload.name | "unknown"
    message: '"twice the fun!"'
  monitored_resource_type: '"UNSPECIFIED"'
---
# Configuration for a Prometheus handler
apiVersion: "config.istio.io/v1alpha2"
kind: prometheus
metadata:
  name: doublehandler
  namespace: istio-system
spec:
  metrics:
  - name: double_request_count # Prometheus metric name
    instance_name: doublerequestcount.metric.istio-system # Mixer instance name (fully-qualified)
    kind: COUNTER
    label_names:
    - reporter
    - source
    - destination
    - message
---
# Rule to send metric instances to a Prometheus handler
apiVersion: "config.istio.io/v1alpha2"
kind: rule
metadata:
  name: doubleprom
  namespace: istio-system
spec:
  actions:
  - handler: doublehandler.prometheus
    instances:
    - doublerequestcount.metric
```
2. 샘플 애플리케이션으로 트래픽 전송  
Bookinfo (sample application)에 traffic을 전송한다. Bookinfo App의 경우, browser를 통해 http://$GATEWAY_URL/productpage 브라우징 하거나, 아래와 같이 curl을 이용하여 http request 수행한다.
```
curl http://$GATEWAY_URL/productpage
```

참고로 minikube 환경에서 GATEWAY_URL을 설정하기 위한 방법은 아래 스크립트를 참고한다.
```
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
```
3. 새로운 metric 정보가 생생/수집 되고 있는지 확인하다. 쿠버네티스 환경에서 Prometheus를 위한 port-forwarding setup을 위해 다음과 같은 명령어를 실행한다.
```
kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090 &
```


새로운 metric value 값 확인을 위해 <a href="http://localhost:9090/graph">Prometheus UI</a> 웹브라우저 접속하여 확인한다. 위 제공된 링크는 Prometheus UI 페이지를 열어서, istio_double_request_count metric 값을 쿼리를 실행한다. Console Tab 테이블에 표시된 entry 정보는 다음과 비슷하다.
```
istio_double_request_count{destination="details-v1",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="client",source="productpage-v1"}   8
istio_double_request_count{destination="details-v1",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="server",source="productpage-v1"}   8
istio_double_request_count{destination="istio-policy",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="server",source="details-v1"}   4
istio_double_request_count{destination="istio-policy",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="server",source="istio-ingressgateway"}   4
```
더 많은 metric value 값을 Prometheus에서 쿼리하기 위해 [Querying Istio Metrics]("http://istio.io/docs/tasks/telemetry/metrics/querying-metrics)을 참고한다.

# Understanding the metrics configuration
이번 작업에서는 Service Mesh 에서 발생하는 모든 트랙픽에 대한 새로운 metric 정보를 자동으로 생성하고 리포팅하기 위한 설정을 Mixer에 추가했다.
추가된 설정은 Mixer 기능의 3가지 부분을 컨트롤한다.
1. istio attribute 에서 instance(이 예제에서는 metric 값) 생성
2. 생성된 인스터스를 processing 할 수 있는 handlers 생성
3. Rule Set에 따라 인스턴스를 handlers 로 전송

metrics configuration은 Mixer 가 Prometheus 로 metric value 값을 전달하도록 명시합니다. 이를 위해 3가지 블럭 구성을 사용합니다. instance configuration, handler configuration, and rule configuration.

The Kind: instance 블럭은 doublerequestcount라는 새로운 메트릭에 대해 생성 된 메트릭 값(또는 인스턴스)에 대한 스키마를 정의합니다. 이 인스턴스 설정은 Mixer에게 Envoy에 의해 보고되는 속성 (및 Mixer 자체에 의해 생성되는 속성)에 근거 해, 임의의 request에 대해서 메트릭 값 생성하는 방법을 지시한다.

doublerequestcout에 대한 각각의 instance에 대해, 설정은 Mixer가 각 instance 에 대해 값 2를 지원하도록 명시한다. 이유는 Istio는 각각의 request에 대해 instance를 생성하는데, 이건 이 metric 이 수신받은 총 request 수의 2배를 저장하기 때문이다.

각각의 doublerequestcount에 대한 dimensions 구성은 구체화 되어있다. Dimesions은 다른 필요성과 질의 방향에 따라 metric 데이터를 자르고, 수집하고, 분석하는 방법을 제공한다. 예를들어 특정 응용프로그램 동작 문제를 해결할때 특정 대상 서비스에 대한 요청만 고려하는 것이 바람직할 수 있다.

설정은 속성 값 및 기본값을 기반으로 이러한 차원의 값을 채우도록 Mixer에 지시합니다. 예를 들어 source dimension의 경우 새로운 구성은 source.workload.name 특성에서 값을 가져 오도록 요청합니다. 그 속성값이 설정되어 있지 않은 경우, 규칙은 Mixer에 디폴트 값 "unknown"을 사용하도록 지시합니다. message dimesion의 경우 기본값 "twice the fun!" 모든 인스턴스에 사용됩니다.

handler 구성 블록은 **doublehandler** 라는 hander를 정의한다. handler spec은 Prometheus 어댑터 코드가 받은 메트릭 인스턴스를 Prometheus 백엔드에서 처리 할 수있는 Prometheus 형식의 값으로 변환하는 방법을 구성한다. 이 구성은 **double_request_count** 이름의 새로운 Prometheus Metric 이름을 명시했다. Prometheus adapter는 **istio_** 네임스페이스를 접두어로 붙였는데, 이 metric 정보는 Prometheus 에서 **istio_double_request_count** 로 보여질 것이다. metric은 **doublerequestcount** instances를 위한 3가지 라벨 매칭 dimention 설정을 가지고 있다.

Mixer 인스턴스는 instance_name 매개 변수를 통해 Prometheus 메트릭과 일치합니다. instance_name은 Mixer instances(exmaple: doublerequestcount.instance.istio-system)을 위해 fully-qualified 이름이어야 합니다.

rule 구성은 **doubleprom** 라는 새로운 규칙을 정의합니다. 이 rule은 Mixer가 모든 doublerequestcount instance를 **doublehandler** handler로 전송하도록 설정합니다. rule 안에 match 절이 없기 때문에 그리고 rule은 네임스페이스(istio-system) 안에서 default configuration 설정되었기 때문에 rule은 service mesh 안에 있는 모든 request에 대해 동작한다.

# Cleanup
- new metric configuraiton 설정을 삭제한다.
```
kubectl delete -f samples/bookinfo/telemetry/metrics.yaml
```
만약 istio version >= 1.1.2 이면
```
kubectl delete -f samples/bookinfo/telemetry/metrics-crd.yaml
```
- 로컬에서 실행되어 동작중인 kubectl port-forward 프로세스를 죽인다.
```
killall kubectl
```
- 이어지는 후속 task 작업을 계속 진행할 것이 아니라면, <a href="https://istio.io/docs/examples/bookinfo/#cleanup">Bookinfo cleanup</a> 내용을 참고하여 bookinfo 관련 애플리케이션을 shtudown 한다.
