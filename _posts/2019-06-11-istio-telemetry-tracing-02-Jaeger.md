---
layout: splash
title: Istio Telemetry Tracing (02. Jaeger)
date: 2019-06-11 08:26:28 -0400
categories: istio
tags: [istio, telemetry]
---

# Before you begin
1. istio 설정을 위해 다음 [Installation Guide](https://istio.io/docs/setup/kubernetes/install/helm/)를 따라주시고,
tracing 을 활성화하기 위해 **--set tracing.enabled=true** Helm install option 을 사용하세요.

```
traceing 옵션을 활성화하면, istio 가 tracing을 위해 사용하는 sampling rate를 설정할 수 있습니다.
sampling rate 설정을 위해 **pilot.traceSampling** 값을 사용하세요. 기본 sampling rate 값은 1% 입니다.

2. Bookinfo 샘플 애플리케션을 배포하세요.

<br>
# Accessing the dashboard
***
1. jaeger 대시보드에 접속하기 위해 port forwarding 을 사용한다.
```
$ kubectl port-forward -n istio-system $(kubectl get pod -n istio-system -l app=jaeger -o jsonpath='{.items[0].metadata.name}') 16686:16686  &
```
브라우저를 열고, [http://localhost:16686](http://localhost:16686) 접속한다.
2. 쿠버네티스 ingress를 사용하기 위해 **--set tracing.ingress.enabled=true** helm chart option을 사용한다.

<br>
# Generating traces using the Bookinfo sample
***
1. Bookinfo 애플리케이션이 올라오고 실행되면, 몇개의 trace 정보를 생성하기 위해 [http://$GATEWAY_URL/productpage] 페이지에 접속합니다.
trace 데이터를 보기 위해 서비스에 requests 메시지를 전송해야 합니다. requests 횟수는 istio 의 sampling rate 값에 의존성이 있습니다.
istio를 설치할때 이 rate 값을 설정합니다. 기본 sampling rate 값은 1% 입니다. 따라서 첫 trace를 보기 전에 최소한 100개의 requests 값을 전송해야 합니다.
**productpage** service에 100개의 requests 메시지 전송을 위해 다음 명령어를 사용합니다.
```
for i in `seq 1 100`; do curl -s -o /dev/null http://$GATEWAY_URL/productpage; done
```
2. 대시보드 왼쪽 메뉴에서, **Services** drop-down list 에서 **productpage**를 선택하고, **Find Traces**를 클릭합니다.
![istio-tracing-list](assets/images/istio/istio-tracing-list.png)
3. **/productpage** 마지막 request 와 일치하는 자세한 정보를 보기 위해 상단에 있는 가장 **recent trace** 를 클릭합니다.
![istio-tracing-details](assets/images/istio/istio-tracing-details.png)
4. trace는 span 세트로 구성되고, 각 span은 /productpage 요청 또는 내부 istio 구성요소의 실행 중에 호출되는 Bookinfo 서비스에 해당됩니다.
구성요소의 예로는, **istio-ingressgateway, istio-mixer, istio-policy** 가 있습니다.

<br>
# Cleanup
***
1. **kubectl port-forwarding** 프로세스 중지
```
killall kubectl
```
