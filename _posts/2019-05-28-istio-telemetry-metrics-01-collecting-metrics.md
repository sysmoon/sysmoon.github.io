---
layout: splash
title: Istio Telemetry Metics (01. Collecting Metrics)
date: 2019-05-28 08:26:28 -0400
categories: istio
tags: [istio, telemetry]
---

## Collecting Metric
이번 장에서는 Service Mesh 안에서 자동으로 telemetry 정보를 수집하기 위한 istio 설정 방법에 대해 알아봅니다.  
Service Mesh 안에서 새로운 metric을 정의하고, 자동으로 수집하기 위한 방법을 실습을 통해 확인 가능합니다.  
hands-on을 위해 Bookinfo 샘플 앱이 먼저 배포되어있어야 합니다.  

## Before you begin
- 사용하고 있는 쿠버네티스 클러스터에 Istio를 설치하고, Bookinfo 앱을 배포합니다.  
이 작업은 Mixer가 default configuration (–configDefaultNamespace=istio-system) 으로 설정하여 기본 네임스페이스(istio-system)에 설치된 것으로 가정하고 진행합니다. 만약 다른 설정값을 사용하고 있다면, 위 기본 설정으로 업데이트가 필요합니다.

## Collecting new metrics
1. 새로운 metric 정보를 수집하기 위해 아래 YAML 파일을 적용하면, istio는 필요한 리소스를 생성하고, metic 정보를 자동으로 수집합니다.

```
kubectl apply -f samples/bookinfo/telemetry/metrics.yaml
```
```
   만약, istio version >= 1.1.2 일 경우, 아래 yaml configuration 적용 필요합니다.
   kubectl apply -f samples/bookinfo/telemetry/metrics-crd.yaml
```

- samples/bookinfo/telemetry/metrics-crd.yaml

```
# metric instance 설정
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
# prometheus handler 설정
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
# metric instance -> prometheus handler로 전송하기 위한 rule
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

2. Bookinfo 앱으로 트래픽 전송  
Bookinfo App에 트래픽을 생성하기 위해 http://$GATEWAY_URL/productpage 웹브라우징 하거나, 아래와 같이 curl 을 사용합니다.

```
curl http://$GATEWAY_URL/productpage
```  

minikube 환경에서 GATEWAY_URL 환경변수 값은 아애롸 같은 방법으로 설정할 수 있습니다.

```
# INGRESS_HOST
export INGRESS_HOST=$(minikube ip)

# INGRESS_PORT (http)
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')

# SECURE_INGRESS_PORT (https)
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')

$ GATEWAY_URL
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
```

3. 새로운 metric 정보가 생생/수집 되고 있는지 확인합니다.  
쿠버네티스 환경에서 Prometheus를 위한 port-forwarding setup을 위해 다음과 같은 명령어를 실행합니다.

```
kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090 &
```

위 metrics-crd.yaml 설정에서 정의한 metric instance 값 확인을 위해 <a href="http://localhost:9090/graph#%5B%7B%22range_input%22%3A%221h%22%2C%22expr%22%3A%22istio_double_request_count%22%2C%22tab%22%3A1%7D%5D">Prometheus UI</a>  Prometheus UI 접속하여 istio_double_request_count metric 값을 쿼리하면 Console Tab 테이블에 **istio_double_request_count** metric 값 확인이 가능합니다.

```
istio_double_request_count{destination="details-v1",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="client",source="productpage-v1"}   8
istio_double_request_count{destination="details-v1",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="server",source="productpage-v1"}   8
istio_double_request_count{destination="istio-policy",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="server",source="details-v1"}   4
istio_double_request_count{destination="istio-policy",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="server",source="istio-ingressgateway"}   4
```

더 많은 metric value 값을 Prometheus에서 쿼리하기 위해 [Querying Istio Metrics]("http://istio.io/docs/tasks/telemetry/metrics/querying-metrics)을 참고한다.

## Understanding the metrics configuration (samples/bookinfo/telemetry/metrics-crd.yaml)
지금까지 Istio Service Mesh 안에서 발생하는 모든 트래픽에 대해 **istio_double_request_count metric** 정보를 자동으로 생성하고 , 리포팅하기 위한 설정(samples/bookinfo/telemetry/metrics-crd.yaml)을 Istio Mixer에 적용했습니다. 이 설정에 대한 자세한 내용을 살펴보겠습니다.

metric configuration(metrics-crd.yaml)은 크게 Mixer 기능의 3가지 블럭을 정의하여 컨틀롤 합니다.
1. istio attribute 값들로부터 metric instance 생성
2. 생성된 metric instance를 프로세싱 하기 위한 handlers 생성
3. metric instance 를 handler로 전송하기 위한 Rule 생성

metrics configuration은 mixer 가 prometheus 로 metric value 값을 전달하도록 명시합니다.  
이를 위해 3가지 블럭 구성을 사용합니다. metric 설정, handler 설정, and rule 설정.

### metric 설정
- **doublerequestcount** metric 이름과 속성값에 대한 스키마를 정의합니다. 이 metric 설정은 Mixer에게 Envoy에 의해 보고되는 [속성](https://istio.io/docs/reference/config/policy-and-telemetry/attribute-vocabulary/) (또는 Mixer 자체에 의해 생성되는 속성)에 근거하여, 임의의 request에 대해 metric 값을 생성하는 방법에 대해 정의합니다.
-  doublerequestcout metric 값을 2로 설정하도록 명시했습니다. 이유는 Istio가 각각의 request에 대해 instance를 생성하기 때문에 metric은 수신된 총 request 수의 2배에 해당되는 값을 기록합니다.
- Dimesions은 다른 필요성과 질의 방향에 따라 metric 데이터를 자르고, 수집하고, 분석하는 방법을 제공합니다. 예를들어 특정 응용프로그램 동작 문제를 해결할때 특정 대상 서비스에 대한 요청만 고려하는 것이 바람직할 수 있습니다.
- Dimensions의 구성은 reporter, source, destination, message로 구성했고, reporter 값은 report metric의 kind 값이 "inbound"인 경우 client 값으로, "outbound"의 경우 server 값으로 설정합니다. source, destination 속성 값을 각 workload의 이름으로 설정했고, 해당 값이 없는 경우 디폴트 값 "unknown"을 사용합니다. message는 기본값 "twice the fun!" 을 사용합니다.

### handler 설정
- handler 구성 블록은 **doublehandler** 라는 hander를 정의합니다.
- handler spec은 생성된 metric을 Prometheus(Istio Adaptor) 백엔드에서 처리 할 수있는 Prometheus 형식의 값으로 변환하는 방법에 대해 정의합니다.
- 이 설정은 **double_request_count** 이름의 새로운 prometheus metric 이름을 명시했다. prometheus adapter는 **istio_** 네임스페이스를 접두어로 사용하기 때문애 metric 정보는 prometheus 에서 **istio_double_request_count** 로 보여집니다.
- metric은 **doublerequestcount** metric을 위한 위한 3가지 라벨 매칭 (reporter, source, destination, message)를 설정하여 prometheus 에서 해당 라벨링으로 쉽게 쿼리할 수 있도록 합니다.
- mixer instance는 instance_name 매개 변수를 통해 prometheus metric과 매칭됩니다. instance_name은 mixer instances(exmaple: doublerequestcount.instance.istio-system)을 위해 fully-qualified 이름 형식으로 정의해야 합니다.

### rule 설정
- rule 설정은 **doubleprom** 라는 이름으로 정의합니다.
- 이 rule은 Mixer가 모든 doublerequestcount metric을 **doublehandler** handler로 전송하도록 설정합니다.
- rule 설정에 특별한 조건이 없기 때문에 service mesh 안에서 발생하는 모든 request 메시지에 대한 metric 정보를 handler로 전송합니다.

## Cleanup
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
