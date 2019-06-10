---
layout: splash
title: Istio Telemetry Logs (2. Getting Envoy's Access Logs)
date: 2019-06-10 08:26:28 -0400
categories: istio
tags: [istio, telemetry]
---

이번 섹션에서는 service mesh 안에서 telemetry 정보를 자동으로 수집하기 위한 istio 설정 방법을 소개하고자 합니다.
마지막 부분에서는 mesh 내의 서비스 호출에 대해 **new log** 스트림을 사용할 수 있습니다.

# Before you begin
***
- install istio 가이드에 따라 먼저 설치하세요
- http request 메시지 전송을 위한 테스트 소스로 사용하기 위해 sleep 샘플앱을 배포하세요. 만약 automatic sidecar injection이 활성화 되어있으면, 아래와 같은 방법으로 배포하세요
```
kubectl apply -f samples/sleep/sleep.yaml
```
활성화가 안되어있다면, 아래와 같이 sidecar injection 을 수동으로 배포해주세요.
```
kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml)
```
- SOURCE_POD 환경변수에 source pod의 이름을 넣어주세요
```
export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
```
- 테스트를 위해 destination http server **httpbin** 시작하세요.
**automatic sidecar injection**이 활성화되어있다면,
```
kubectl apply -f samples/httpbin/httpbin.yaml
```
비활성화 되어있다면 아래와 같이 실행해주세요,
```
kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml)
```


# Enable Envoy's access logging
***
**istio** configuration map을 아래와 같이 /dev/stdout으로 출력하도록 설정합나다.
```
helm template install/kubernetes/helm/istio --namespace=istio-system -x templates/configmap.yaml --set global.proxy.accessLogFile="/dev/stdout" | kubectl replace -f -
```
**accessLogEncoding** 을 **JSON** 또는 **TEXT** 값으로 선택하여 설정 가능하다.
또한 **accessLogFormat** 값 설정을 통해 access log 포멧을 커스터마이징 할 수 있다.

 **helm values:** 이용하여 통해 3가지 파라미터 설정이 가능합니다.
 - global.proxy.accessLogFile
 - global.proxy.accessLogEncoding
 - global.proxy.accessLogFormat

# Test the access log
***
1. sleep -> httpbin http request 전송

```
kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl -v httpbin:8000/status/418

* Trying 172.21.13.94...
* TCP_NODELAY set
* Connected to httpbin (172.21.13.94) port 8000 (#0)
> GET /status/418 HTTP/1.1

...
< HTTP/1.1 418 Unknown
< server: envoy
...

    -=[ teapot ]=-

       _...._
     .'  _ _ `.
    | ."` ^ `". _,
    \_;`"---"`|//
      |       ;/
      \_     _/
        `"""`
* Connection #0 to host httpbin left intact
```
2. sleep 로그 확인
```
$ kubectl logs -l app=sleep -c istio-proxy
[2019-03-06T09:31:27.354Z] "GET /status/418 HTTP/1.1" 418 - "-" 0 135 11 10 "-" "curl/7.60.0" "d209e46f-9ed5-9b61-bbdd-43e22662702a" "httpbin:8000" "172.30.146.73:80" outbound|8000||httpbin.default.svc.cluster.local - 172.21.13.94:8000 172.30.146.82:60290 -
```
3. httpbins 로그 확인
```
$ kubectl logs -l app=httpbin -c istio-proxy
[2019-03-06T09:31:27.360Z] "GET /status/418 HTTP/1.1" 418 - "-" 0 135 5 2 "-" "curl/7.60.0" "d209e46f-9ed5-9b61-bbdd-43e22662702a" "httpbin:8000" "127.0.0.1:80" inbound|8000|http|httpbin.default.svc.cluster.local - 172.30.146.73:80 172.30.146.82:38618 outbound_.8000_._.httpbin.default.svc.cluster.local
```
http request 에 해당하는 메시지는 각각 source 와 destination 의 Istio proxy, sleep 및 httpbin의 로그에 나타납니다.
로그에서 HTTP verb (GET), HTTP path (/status/418), http response code (418)와 다른 **request-related information** 즉 http request와 관련된 다른 여러 항목들에 대해 확인 가능합니다.

# Clean up
***
- sleep, httpbin 서비스를 내립니다.
```
kubectl delete -f samples/sleep/sleep.yaml
kubectl delete -f samples/httpbin/httpbin.yaml
```
- Envoy's access logging을 비활성화 합니다.
istio cofiguration map 을 열어서, **accessLogFile** 값을 "" 수정합니다.
```
helm template install/kubernetes/helm/istio --namespace=istio-system -x templates/configmap.yaml | kubectl replace -f -
configmap "istio" replaced
```
