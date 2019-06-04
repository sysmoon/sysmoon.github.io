---
layout: splash
title: Istio Telemetry (2. Collecting Metric for TCP services) 
date: 2019-05-29 08:26:28 -0400
categories: istio 
---

# Collecting Metric  
이번 테스크에서는 서비스 매쉬를 위해 어떻게 telemetry 정보를 자동으로 수집하기 위한 설정을 하는지 보여준다. 마지막 테스크에서는 TCP 서비스를 콜하기 위한 새로운 metric이 활성화 될 것이다.

## Before you begin
- Istio를 클러스터에 설치 배포하세요.
- 사용하고 있는 K8S 클러스터에 Istio를 설치하고, App을 배포한다. 이 task는 Minxer가 default configuration (--configDefaultNamespace=istio-system) 으로 설정되어 있다고 가정한다.
만약 다른 설정값을 사용하고 있다면, 위 설정으로 업데이트해야 한다.

## Collecting new telemetry data
1. 새로운 metric 생성과 자동 수집을 위해 아래 YAML 설정 파일을 적용하세요.
```
kubectl apply -f samples/bookinfo/telemetry/tcp-metrics.yaml
```

```
만약 istio >= 1.1.2 이면 다음 설정파일을 대신 사용하세요
kubectl apply -f samples/bookinfo/telemetry/tcp-metrics-crd.yaml
```

samples/bookinfo/telemetry/tcp-metrics-crd.yaml
```
# Configuration for a metric measuring bytes sent from a server
# to a client
apiVersion: "config.istio.io/v1alpha2"
kind: metric
metadata:
  name: mongosentbytes
  namespace: default
spec:
  value: connection.sent.bytes | 0 # uses a TCP-specific attribute
  dimensions:
    source_service: source.workload.name | "unknown"
    source_version: source.labels["version"] | "unknown"
    destination_version: destination.labels["version"] | "unknown"
  monitoredResourceType: '"UNSPECIFIED"'
---
# Configuration for a metric measuring bytes sent from a client
# to a server
apiVersion: "config.istio.io/v1alpha2"
kind: metric
metadata:
  name: mongoreceivedbytes
  namespace: default
spec:
  value: connection.received.bytes | 0 # uses a TCP-specific attribute
  dimensions:
    source_service: source.workload.name | "unknown"
    source_version: source.labels["version"] | "unknown"
    destination_version: destination.labels["version"] | "unknown"
  monitoredResourceType: '"UNSPECIFIED"'
---
# Configuration for a Prometheus handler
apiVersion: "config.istio.io/v1alpha2"
kind: prometheus
metadata:
  name: mongohandler
  namespace: default
spec:
  metrics:
  - name: mongo_sent_bytes # Prometheus metric name
    instance_name: mongosentbytes.metric.default # Mixer instance name (fully-qualified)
    kind: COUNTER
    label_names:
    - source_service
    - source_version
    - destination_version
  - name: mongo_received_bytes # Prometheus metric name
    instance_name: mongoreceivedbytes.metric.default # Mixer instance name (fully-qualified)
    kind: COUNTER
    label_names:
    - source_service
    - source_version
    - destination_version
---
# Rule to send metric instances to a Prometheus handler
apiVersion: "config.istio.io/v1alpha2"
kind: rule
metadata:
  name: mongoprom
  namespace: default
spec:
  match: context.protocol == "tcp"
         && destination.service.host == "mongodb.default.svc.cluster.local"
  actions:
  - handler: mongohandler.prometheus
    instances:
    - mongoreceivedbytes.metric
    - mongosentbytes.metric
```
2. MongoDB 사용을 위히 Bookinfo를 설정하세요
    1. **rating** service v2를 설치합니다.
    만약 automatic sidecar injection 이 활성화 되어있으면, kubectl을 이용하야 간단하게 배포합니다.
    ```
    kubectl apply -f samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml
    ```
    만약 수동 sidecar injection을 사용한다면, 다음 명령어를 대신 사용하세요
    ```
    kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml)
    ```
    2. mongodb 서비스 설치
    만약 automatic sidecar injection 이 활성화 되어있으면, kubectl을 이용하야 간단하게 배포합니다.
    ```
    kubectl apply -f samples/bookinfo/platform/kube/bookinfo-db.yaml
    ```
    만약 수동 sidecar injection을 사용한다면, 다음 명령어를 대신 사용하세요
    ```
    kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/platform/kube/bookinfo-db.yaml)
    service "mongodb" configured
    deployment "mongodb-v1" configured
    ```
    3. Bookinfo 샘플은 각 마이크로서비스 별 다양한 버전을 배포합니다. 그래서 각 서비스 버전별 집합에 대해 정의하고 이에 대한 도착지 규칙과 각 서비스 집합에 대한 로드밸런싱을 위한 도착지 규칙을 생성할 것입니다.
    ```
    kubectl apply -f samples/bookinfo/networking/destination-rule-all.yaml
    ```
    만약 TLS가 활성화되어있다면, 다음 설정을 대신 적용하세요.
    ```
    kubectl apply -f samples/bookinfo/networking/destination-rule-all-mtls.yaml
    ```
    다음 명령어로 도착지 규칙을 확인할 수 있다.
    ```
    kubectl get destinationrules -o yaml
    ```
    virtual service 에 있는 subset reference가 도착치 규칙에 의존성을 가지고 있기 때문에, virtual service가 subsets을 참조하기 전데 도착치 규칙이 전파되기까지 잠시 기다린다.
    4. **rating**, ** reviews** virtual service를 생성한다.
    ```
    kubectl apply -f samples/bookinfo/networking/virtual-service-ratings-db.yaml
    Created config virtual-service/default/reviews at revision 3003
    Created config virtual-service/default/ratings at revision 3004
    ```

    samples/bookinfo/networking/virtual-service-ratings-db.yaml 
    ```
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
    name: reviews
    spec:
    hosts:
    - reviews
    http:
    - route:
        - destination:
            host: reviews
            subset: v3
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
    name: ratings
    spec:
    hosts:
    - ratings
    http:
    - route:
        - destination:
            host: ratings
            subset: v2
    ---
    ```
3. 샘플 애플리케이션으로 트래픽을 전송한다.  
Bookinfo 샘플 테스를 위해 http://$GATEWAY_URL/productpage 웹브라우저로 방문하거나 아래 명령어를 실행한다.
```
curl http://$GATEWAY_URL/productpage
```
4. 새로운 metric 값이 생성, 수집되는 것을 확인한다.  
쿠버네티스 환경에서 다음 명령어를 통해 Prometheus를 위한 port-forwarding을 설정한다.
```
kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090 &
```
Prometheus UI를 통해 새로운 metric 값을 확인한다.  
제공된 링크는 Prometheus UI를 열고, **istio_mongo_received_bytes** 값 쿼리를 실행한다.  
**Console** 탭에 있는 테이블은 아래와 비슷한 entries 를 포함하고 있다.
```
istio_mongo_received_bytes{destination_version="v1",instance="172.17.0.18:42422",job="istio-mesh",source_service="ratings-v2",source_version="v2"}
```

# Understanding TCP telemetry collection
이 테스크에서 Mixer가 매쉬 안에 있는 TCP 서비스에게 모든 트래픽에 대한 새로운 metric을 자동으로 생성하고, 보고하도록 지시한 istio 설정을 추가햇습니다.  
Collecting Metrics and Logs Task와 유사하게, 새로운 설정은 instance, handler, rule로 구성되어 있습니다. metric 집한 구성요소의 완벽한 설명을 위한 task를 확인해보세요.  
TCP 서비스의 Metric 집합은 인스턴스에서 사용할 수 있는 제한된 특성 집합에서만 다릅니다.

## TCP attributes
몇몇 TCP-specific 속성들은 istio 에서 TCP 규칙과 컨트롤을 활성화 합니다. 이러한 속성들은 server-side Envoy proxies 에서 생성됩니다. 이러한 속성들은 연결이 살아있을때 (주기적 리포팅), 연결이 수립된 Mixter에게 주기적으로 전송되고, 연결종료를 전송합니다. (마지막 리포트)  
기본 리포트 주기는 10초이고, 최소 1초 이상이어야 합니다. 추가적으로 context 속성들은 규칙안에서
**http** 와 **tcp** 프로토콜을 구분할 수 있는 기느을 제공합니다.  
![TCP attributes](/assets/images/istio/tcp_attributes.svg)