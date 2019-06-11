---
layout: splash
title: Istio Telemetry Logs (03. Logging with Fluentd)
date: 2019-06-10 08:26:28 -0400
categories: istio
tags: [istio, telemetry]
---

이번 섹션에서는 커스텀 log entries를 생성하고, fluentd 데몬으로 전송하기 위한 istio 설정 방법에 대해 소개합니다.
fluentd는 많은 종류의 **data output** 과 플러그인을 지원하는 아키텍처를 가진 로그 수집기이다.
가장 인기있는 로깅 백엔드는 Elasticsearch 와 Kibana 뷰어이다.
마지막 파트에서는 Fluentd / Elasticsearch / Kibana 스택에 로그를 전송하는 new log 스트림을 사용할 것이다.

Bookinfo 샘플 애플리케이션이 이 섹션 전체에서 예제로 사용된다.

# Before you begin
***
- Inatll Istio

<br>

# Setup Fluentd
***
테스트하는 클러스터 환경에서 fluentd 데몬이 이미 실행중일 수도 있고, [여기]에 이미 설명되어있는 add-on 또는 클러스터에서 지원하는 다른 어떤 로그 수집기가 있을 수도 이 있습니다.
이것은 Elasticsearch 또는 Logging 제공자에게 로그를 보내도록 설정되었을 수 있습니다.

위 처럼 쿠버네티스 클러스에서 add-on 한 Fluentd 데몬 또는 사용자가 임의로 설치 및 설정한 다른 Fluentd 데몬은 전달 된 로그를 수신하기 위해 리스닝 하고 있는 한 사용할 수 있으며 Istio  Mixer가 Fluentd 데몬에 연결할 수 있습니다. Mixer가 실행중인 Fluentd 데몬에 연결하려면 Fluentd에 서비스를 추가해야 할 수 있습니다. 전달 된 로그를 수신 대기하는 Fluentd 구성은 다음과 같습니다.
```
<source>
  type forward
</source>
```

# Example Fluentd, Elasticsearch, kibana stack
***
이 섹션의 목적을 위해 아래 제공된 예제 stack 을 배포합니다. 이 스택은 Fluentd, Elasticsearch 그리고 kibana 를 포함하고 있고, **logging** 이라는 이름의 네임스페이스 안에 Services 와 Deployment 세트의 non-proudction-ready(상용 준비가 되지 않은 서비스) 안에 있다.
다음과 같은 logging-stack.yaml 파일을 저장한다.
```
# Logging Namespace. All below are a part of this namespace.
apiVersion: v1
kind: Namespace
metadata:
  name: logging
---
# Elasticsearch Service
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch
  namespace: logging
  labels:
    app: elasticsearch
spec:
  ports:
  - port: 9200
    protocol: TCP
    targetPort: db
  selector:
    app: elasticsearch
---
# Elasticsearch Deployment
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: elasticsearch
  namespace: logging
  labels:
    app: elasticsearch
  annotations:
    sidecar.istio.io/inject: "false"
spec:
  template:
    metadata:
      labels:
        app: elasticsearch
    spec:
      containers:
      - image: docker.elastic.co/elasticsearch/elasticsearch-oss:6.1.1
        name: elasticsearch
        resources:
          # need more cpu upon initialization, therefore burstable class
          limits:
            cpu: 1000m
          requests:
            cpu: 100m
        env:
          - name: discovery.type
            value: single-node
        ports:
        - containerPort: 9200
          name: db
          protocol: TCP
        - containerPort: 9300
          name: transport
          protocol: TCP
        volumeMounts:
        - name: elasticsearch
          mountPath: /data
      volumes:
      - name: elasticsearch
        emptyDir: {}
---
# Fluentd Service
apiVersion: v1
kind: Service
metadata:
  name: fluentd-es
  namespace: logging
  labels:
    app: fluentd-es
spec:
  ports:
  - name: fluentd-tcp
    port: 24224
    protocol: TCP
    targetPort: 24224
  - name: fluentd-udp
    port: 24224
    protocol: UDP
    targetPort: 24224
  selector:
    app: fluentd-es
---
# Fluentd Deployment
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: fluentd-es
  namespace: logging
  labels:
    app: fluentd-es
  annotations:
    sidecar.istio.io/inject: "false"
spec:
  template:
    metadata:
      labels:
        app: fluentd-es
    spec:
      containers:
      - name: fluentd-es
        image: gcr.io/google-containers/fluentd-elasticsearch:v2.0.1
        env:
        - name: FLUENTD_ARGS
          value: --no-supervisor -q
        resources:
          limits:
            memory: 500Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: config-volume
          mountPath: /etc/fluent/config.d
      terminationGracePeriodSeconds: 30
      volumes:
      - name: config-volume
        configMap:
          name: fluentd-es-config
---
# Fluentd ConfigMap, contains config files.
kind: ConfigMap
apiVersion: v1
data:
  forward.input.conf: |-
    # Takes the messages sent over TCP
    <source>
      type forward
    </source>
  output.conf: |-
    <match **>
       type elasticsearch
       log_level info
       include_tag_key true
       host elasticsearch
       port 9200
       logstash_format true
       # Set the chunk limits.
       buffer_chunk_limit 2M
       buffer_queue_limit 8
       flush_interval 5s
       # Never wait longer than 5 minutes between retries.
       max_retry_wait 30
       # Disable the limit on the number of retries (retry forever).
       disable_retry_limit
       # Use multiple threads for processing.
       num_threads 2
    </match>
metadata:
  name: fluentd-es-config
  namespace: logging
---
# Kibana Service
apiVersion: v1
kind: Service
metadata:
  name: kibana
  namespace: logging
  labels:
    app: kibana
spec:
  ports:
  - port: 5601
    protocol: TCP
    targetPort: ui
  selector:
    app: kibana
---
# Kibana Deployment
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: kibana
  namespace: logging
  labels:
    app: kibana
  annotations:
    sidecar.istio.io/inject: "false"
spec:
  template:
    metadata:
      labels:
        app: kibana
    spec:
      containers:
      - name: kibana
        image: docker.elastic.co/kibana/kibana-oss:6.1.1
        resources:
          # need more cpu upon initialization, therefore burstable class
          limits:
            cpu: 1000m
          requests:
            cpu: 100m
        env:
          - name: ELASTICSEARCH_URL
            value: http://elasticsearch:9200
        ports:
        - containerPort: 5601
          name: ui
          protocol: TCP
---
```
위 ELK Stack 설정 파일을 적용한다.
```
kubectl apply -f logging-stack.yaml
namespace "logging" created
service "elasticsearch" created
deployment "elasticsearch" created
service "fluentd-es" created
deployment "fluentd-es" created
configmap "fluentd-es-config" created
service "kibana" created
deployment "kibana" created
```

# Configure istio
***
이제는 Fluentd 데몬이 동작중이고, 새로운 로그 타입과 이 로그를 수신받기 위한 데몬으로 전송하기 위한 istio 설정을 진행한다. istio가 자동으로 **log stream**을 생성/수집하기 위한 YAML 설정 파일을 적용한다.
```
kubectl apply -f samples/bookinfo/telemetry/fluentd-istio.yaml
```
만약 istio >= 1.1.2 이면,
```
kubectl apply -f samples/bookinfo/telemetry/fluentd-istio-crd.yaml
```
fluentd-crd.yml 설정파일에서 handler 안에 있는 **address: "fluentd-es.logging:24224"** 라인이 위 예제 stack 에서 생성한 fluentd 을 가리키고 있는것에 주목합니다.

fluentd-istio.crd.yaml
```
# Configuration for logentry instances
apiVersion: "config.istio.io/v1alpha2"
kind: logentry
metadata:
  name: newlog
  namespace: istio-system
spec:
  severity: '"info"'
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
# Configuration for a Fluentd handler
apiVersion: "config.istio.io/v1alpha2"
kind: fluentd
metadata:
  name: handler
  namespace: istio-system
spec:
  address: "fluentd-es.logging:24224"
---
# Rule to send logentry instances to the Fluentd handler
apiVersion: "config.istio.io/v1alpha2"
kind: rule
metadata:
  name: newlogtofluentd
  namespace: istio-system
spec:
  match: "true" # match for all requests
  actions:
   - handler: handler.fluentd
     instances:
     - newlog.logentry
---
```

# View the new logs
***
1. 샘플 애플리케이션으로 트래픽 로그 전송
Bookinfo 샘플에 테스트를 위해 http://$GATEWAY_URL 브라우저 접속하거나 다음과 같이 curl 명령어를 수행합니다.
```
curl http://$GATEWAY_URL/productpage
```
2. 쿠버네티스 클러스터 환경에서 Kibana 실행을 위해 다음과 같은 명령어를 실행하여 port-forwarding 을 설정합니다.
```
kubectl -n logging port-forward $(kubectl -n logging get pod -l app=kibana -o jsonpath='{.items[0].metadata.name}') 5601:5601 &
```
3. [KIBANA UI](http://localhost:5601/)에 브러우저를 통해 접속한 후, 상단 오른쪽 "Set up index patterns" 을 클릭합니다.
4. index pattern에 **\*** 입력하여 모든 인덱스 패턴을 찾도록 한 후 "Create index pattern."을 클릭합니다.
5. **@timestamp** 를 Time Filter field 이름으로 선택하고, "Create index pattern."을 클릭합니다.
6. 이제는 왼쪽 메뉴에서 "Discover"를 클릭하여 생성된 로그를 검색해봅니다.

# Cleanup
***
- new telemetry 설정 삭제
```
kubectl delete -f samples/bookinfo/telemetry/fluentd-istio.yaml
```
민약, istio >= 1.1.2 조건이라면
```
kubectl delete -f samples/bookinfo/telemetry/fluentd-istio-crd.yaml
```
- ELK Stack (Fluentd, Elasticsearch, Kibana) 삭제
```
kubectl delete -f logging-stack.yaml
```
- kibana 실행을 위해 설정한 **kubectl port-forward** 프로세스 중지
```
killall kubectl
```
