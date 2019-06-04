---
layout: splash
title: Istio Telemetry (3. Querying Metrics from Prometheus)
date: 2019-05-30 08:26:28 -0400
categories: istio 
---

# Collecting Metric  
이번 테스크에서는 Prometheus를 활용헤ㅐ서 istion를 위한 쿼리를 어떻게 하는지 보여준다.  
이 테스크의 일 부분으로써 metric 값 쿼리를 위한 web-based 인터페이스를 사용할 계획이다.  
이 task 전체에서 Bookinfo 샘플 애플리케이션이 사용된다.

# Before you begin
쿠버네티스 클러스에 istion를 설치하고, Bookinfo 샘플 애플리케이션을 배포하세요.

# Querying Istio Metrics
1. 클러스터에서 Prometheus 서비스가 동작하고 있는지 확인한다.  
쿠버네티스 환경에서, 아래와 같은 명령어을 실행한다.
```
kubectl -n istio-system get svc prometheus
NAME         CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
prometheus   10.59.241.54   <none>        9090/TCP   2m
```
2. 서비스 매쉬로 트래픽을 전송한다.  
Bookinfo 샘플 애플리케이션을 위해, http://$GATEWAY_URL/productpage 웹브라우저 또는 아래 명령어를 통해 접속한다.
```
curl http://$GATEWAY_URL/productpage
```
```
$GATEWAY_URL 은 Bookinfo 예쩨를 위한 환경변수 설정 값이다
```
3. Prometheus UI를 오픈한다.  
쿠버네티스 환경에서, 아래와 같은 명령어를 실행한다.
```
kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090 &
```
브러우저를 통해 [http://localhost:9090/graph](http://localhost:9090/graph) 접속한다.  
4. Promethues 쿼리를 실행한다.
웹페이지 상단 "Expression" 입력창에 아래 텍스트 **istio_requests_totla** 를 입력한다.  
그리고 **Execute** 버튼을 클릭한다.  
결과는 아라와 유사하게 나올 것이다.
![Prometheus Query Result][../assets/images/istio/prometheus_query_result.png]  

다른 쿼리를 시도해보면:
- **productpage** 서비스에게 전송한 모든 요청 횟수
```
istio_requests_total{destination_service="productpage.default.svc.cluster.local"}
```
- **reviews** v3 서비스로 전송된 모든 요청 횟수
```
istio_requests_total{destination_service="reviews.default.svc.cluster.local", destination_version="v3"}
```
이 쿼리는 현재까지 v3 **reviews** 서비스에게 전송된 모든 요청 횟수를 결과로 리턴한다.
```
rate(istio_requests_total{destination_service=~"productpage.*", response_code="200"}[5m])
```

# About the Promethues add-on
Mixer는 생성된 mertic 값을 전달하기 위한 end-point 주소를 외부에 오픈하기 위한 **Prometheus** 어댑터를 내장하고 있다. Prometheus add-on은 Prometheus 서버가 노출된 metric 정보를 수집하기 위해 Mixer endpoint 를 통해 스크래핑하기 위해 사전 설정된다. Prometheus는 Istion metrics 정보들을 쿼리하고 영구적으로 저장하기 위한 메카니즘을 제공한다.  

설정된 Prometheus add-on은 다음과 같은 endpoint를 수집한다.
1. **istio-telemetry.istio-system:42422:** **istio-mesh** job은 Mixer 에서 생성된 모든 mertics 정보를 리턴한다.  
2. **istio-telemetry.istio-system:10514:** **istio-telemetry** job은 Mixer-specific metrics 값을 리턴한다. 이 endpoint 주소를 활용하여 Mixer 자체를 모니터링하는 사용한다.  
3. **istio-proxy:15090:** **envoy-stats** 는 Envoy에서 생성된 raw 통계값을 리턴합니다.  
Prometheus는 pods애 있는 envoy-porm 노출된 endpoint 를 바라보도록 설정되어 있습니다. add-on 구성은 add-on 프로세스에 의한 데이터의 크기를 제한하기 위해 수집하는 동안 다수의 Envoy Metrics 정보를 걸러냅니다.  
4. **istio-pilot.istio-system:10514:** **pilot** job은 Pilot-generated 메트릭을 리턴합니다.  
5. **istio-galley.istio-system:10514:** **gallery**는 모든 Gallery-generaed metrics 값을 리턴합니다. 
6. **istio-policy.istio-system:10514:** **istio-policy**는 모든 policy와 관련된 metrics 값을 리턴합니다.  
Prometheus 쿼리를 위한 좀더 제사한 정보는, [querying docs](https://prometheus.io/docs/prometheus/latest/querying/basics/) 문서를 참고하세요
