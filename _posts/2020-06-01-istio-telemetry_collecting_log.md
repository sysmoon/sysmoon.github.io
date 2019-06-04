---
layout: splash
title: Istio Telemetry (1. Collecting Logs)
date: 2019-06-04 08:26:28 -0400
categories: istio 
---

이 작업은 istio 가 service mesh 안에서 자동으로 telemetry 정보를 수집하는 방법에 대해 보여준다. 마지막 작업에서는 service mesh 안에서 new log 스트림이 서비스 호출을 위해 활성화된다.  
Bookinfo 샘플 애플리케이션이 이 작업 전체에서 예제 애플리케이션으로 사용된다.

# Before you begin
- blabla

# Collectin new logs data
1. istio가 자동으로 생성하고 수집할 새로운 log stream 에 대한 구성을 YAML 파일에 적용한다.
```
kubectl apply -f samples/bookinfo/telemetry/log-entry.yaml
```
```
   만약, istio >= 1.1.2 일 경우, 아래 yaml configuration 적용 필요
   kubectl apply -f samples/bookinfo/telemetry/metrics-crd.yaml
```

- samples/bookinfo/telemetry/log-entry.yaml
```
# Configuration for logentry instances
apiVersion: config.istio.io/v1alpha2
kind: instance
metadata:
  name: newlog
  namespace: istio-system
spec:
  compiledTemplate: logentry
  params:
    severity: '"warning"'
    timestamp: request.time
    variables:
      source: source.labels["app"] | source.workload.name | "unknown"
      user: source.user | "unknown"
      destination: destination.labels["app"] | destination.workload.name | "unknown"
      responseCode: response.code | 0
      responseSize: response.size | 0
      latency: response.duration | "0ms"
    monitored_resource_type: '"UNSPECIFIED"'
---
# Configuration for a stdio handler
apiVersion: config.istio.io/v1alpha2
kind: handler
metadata:
  name: newloghandler
  namespace: istio-system
spec:
  compiledAdapter: stdio
  params:
    severity_levels:
      warning: 1 # Params.Level.WARNING
    outputAsJson: true
---
# Rule to send logentry instances to a stdio handler
apiVersion: config.istio.io/v1alpha2
kind: rule
metadata:
  name: newlogstdio
  namespace: istio-system
spec:
  match: "true" # match for all requests
  actions:
   - handler: newloghandler
     instances:
     - newlog
---
```
2. 샘플 애플리케이션에 트래픽 전송
Bookinfo 샘플에 대해, http://$GATEWAY_URL/productpage 브라우저 또는 아래 명령어를 통해 실행한다.
```
curl http://$GATEWAY_URL/productpage
```
3. log stream 이 생성되어 request에 대해 채워지는지 확인한다.  
쿠버네티스 환경에서 istio-telemetry pods 에서 다음과 같이 log를 통해 조회한다.
```
kubectl logs -n istio-system -l istio-mixer-type=telemetry -c mixer | grep "newlog" | grep -v '"destination":"telemetry"' | grep -v '"destination":"pilot"' | grep -v '"destination":"policy"' | grep -v '"destination":"unknown"'

{"level":"warn","time":"2018-09-15T20:46:36.009801Z","instance":"newlog.xxxxx.istio-system","destination":"details","latency":"13.601485ms","responseCode":200,"responseSize":178,"source":"productpage","user":"unknown"}
{"level":"warn","time":"2018-09-15T20:46:36.026993Z","instance":"newlog.xxxxx.istio-system","destination":"reviews","latency":"919.482857ms","responseCode":200,"responseSize":295,"source":"productpage","user":"unknown"}
{"level":"warn","time":"2018-09-15T20:46:35.982761Z","instance":"newlog.xxxxx.istio-system","destination":"productpage","latency":"968.030256ms","responseCode":200,"responseSize":4415,"source":"istio-ingressgateway","user":"unknown"}
```

# Understanding the logs configuration
이 작업에서는 mesh service 안에서 생성되는 모든 트래픽에 대한 새로운 log stream을 자동으로 생성 및 리포팅 하도록 mixer에 설정을 추가한다.  

추가된 설정은 Mixer 기능의 3가지 부분을 컨틀롤한다.
1. istio attribute로부터 인스턴스 생성 (예제, log entries)
2. 생성된 instance를 프로세싱 가능한 handlers(Mixer 어댑터로 구성됨) 생성
3. rule set에 따라 handlers 로 인스턴스 전달

로그 설정은 Mixer가 log entries를 stdout로 전송하도록 설정한다. 구성은 3가지 블럭을 사용한다: instance configuration, handler configuration, and rule configuration.

The kind: 설정의 instance 블럭은 **newlog** 라는 이름으로 생성된 log entries (or 인스턴스) 스키마를 정의한다. 이 인스턴스는 설정은 Envoy에 의해서 리포팅된 속성 값을 기반으로 requests에 대한 log entries를 어떻게 생성할지 알려준다.  

severity 파라미터는 생성된 **logentry** 에 대한 log level을 명시하는데 사용된다. 예제로, 명시적인 값 **warnning** 이 사용도니다. 이 값은 **logentry** handler에 의해 지원되는 log level과 맵핑된다.  

**timestamp** 파라미터는 모든 log entry 에 대한 시간 정보를 제공한다. 이 예제에서는 시간정보는 Envoy 에서 제공되는 request.time 속성값으로 제공된다.  

**variable** 파라미터를 활용하여 운영자는 각 logentry에 포함되어야 하는 값을 구성할 수 있다. expression set 는 Istio 속성 및 리터럴 값에서 로그를 구성하는 값으로의 매핑을 제어한다. 이 예제에서 각 logentry 인스턴스는 response.duration 속성의 값으로 채워진 응답 latency 필드를 갖습니다. 
response.duration에 대해 알려진 값이 없으면 latency 시간 필드는 0ms의 지속 시간으로 설정됩니다.  

**kind :** handler 블럭은 newloghandler라는 핸들러를 정의합니다.
handler 스펙은 **stdio** 컴파일 어댑터 코드 프로세스가 logentry 인스턴스를 수신하는 방법을 구성합니다. 
severity_levels 매개 변수는 **severity** 필드에 대한 로그 값이 지원되는 로깅 레벨에 맵핑되는 방식을 제어합니다. 
여기서 "경고"값은 WARNING 로그 수준에 매핑됩니다. outputAsJson 매개 변수는 JSON 형식의 로그 행을 생성하도록 어댑터에 지시합니다.  


**rule:** 블럭 구성은 **newlogstdio** 라는 새로운 rule을 정의합니다. 이 규칙은 Mixer가 모든 newlog 인스턴스를 newloghandler 핸들러로 보내도록 지시합니다. match 매개 변수가 true로 설정 되었으므로 규칙은 메쉬의 모든 요청에 ​​대해 실행됩니다.  

**match:** 모든 requests 에 대해 실행될 규칙을 구성하려면 **true** 설정은 필요하지 않습니다. 스펙에서 전체 match 매개 변수를 생략하면 match : true를 설정하는 것과 같습니다. match 표현식을 사용하여 룰 실행을 제어하는 ​​방법을 설명하기 위해 여기에 포함시킨 겁니다.
