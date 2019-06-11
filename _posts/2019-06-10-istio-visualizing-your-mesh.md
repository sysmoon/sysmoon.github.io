---
layout: splash
title: Istio Telemetry Visualizing Your Mesh
date: 2019-06-11 08:26:28 -0400
categories: istio
tags: [istio, telemetry]
---

이번 섹션에서는 istio mesh를 다른 방법으로 visualize 하기 위한 방법에 대해 소개합니다.

이 섹션을 위해 [kiali](https://www.kiali.io/)를 설치하고, istio 설정 객체와 mesh 안에서의 service graph 를 보기 위한 웹베이스 기반의 그래픽한 user interface 를 사용한다.
마지막으로 Kiali Public API를 사용하여 소바? 가능한 JSON 형식으로 그래프 데이터를 생성합니다.

# Before you begin
다음 설치 방법은 Helm이 설치되었다는 가정하에 Helm을 사용하여 Kiali를 설치합니다.
Helm을 사용하지 않고 Kiali를 설치할 경우 [Kiali installation instruction](https://www.kiali.io/documentation/getting-started/)을 참고하세요

1. Install Kiali Operator
```
bash <(curl -L https://git.io/getLatestKialiOperator)
```

설치후, kiali-operator 네임스페이스가 생성되고 다음 명령어를 통해 kiali pod 와 istio-system 네임스페이스에 kiali servier가 실행된 것을 확인할 수 있다.
```
$ kubectl get ns
$ kubectl get po,svc -n kiali-operator
$ kubectl get po,svc -n istio-system
```

2. Configure Kiali
kiali Operator에 대한 설정이 필요하다면 아래 명령을 통해 설정 가능하다.
```
kubectl edit kiali kiali -n kiali-operator
```

3. Open The UI
아래 kiali port-forwarding을 통해 kiali UI 페이지 오픈이 가능하다.
```
$ kubectl port-forward svc/kiali 20001:20001 -n istio-system
```
이후 [https://localhost:20001/kiali.](https://localhost:20001/kiali.) 웹 브라우징을 통해 Kiali UI 웹페이지 접속이 가능하다.
설치 과정에서 입력한 account(username / password) 값을 이용하여 로그인 하면 된다.
chrome 에서 오픈하느 경우 보안 경고창이 뜨면서 열리지 않는 경우가 있는데 아래와 같이 chrome 설정창에서
**allow-insecure-localhost** 설정을 enable 하면 접속 가능하다.
```
chrome://flags/#allow-insecure-localhost
```
![kiali-ui](assets/images/istio/kiali-ui.png)

<br>
# Create a secret
***
```
만약 [Istio Quick Start Installation Steps](https://istio.io/docs/setup/kubernetes/install/kubernetes/#installation-steps)에 설명된 **istio-demo.yaml** 또는 **istio-demo-auth.yaml** 파일을 사용하여 kiali를 설치했다면, 기본 계정 기밀정보 username 은 admin, passphrase는 admin 으로 설정될 것이다. 따라서 이 과정을 스킵해도 된다.

- Kiali username 과 passphrase 기밀정보를 환경변수로 정의한다.
```
KIALI_USERNAME=$(read -p 'Kiali Username: ' uval && echo -n $uval | base64)
KIALI_PASSPHRASE=$(read -sp 'Kiali Passphrase: ' pval && echo -n $pval | base64)
```

zsh를 사용하고 있따면 아래 방법을 이용한다.
```
KIALI_USERNAME=$(read '?Kiali Username: ' uval && echo -n $uval | base64)
KIALI_PASSPHRASE=$(read -s "?Kiali Passphrase: " pval && echo -n $pval | base64)
```

- secret 생성
```
# 네임스페이스 생성
$ NAMESPACE=istio-system
$ kubectl create namespace $NAMESPACE

# apply
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: kiali
  namespace: $NAMESPACE
  labels:
    app: kiali
type: Opaque
data:
  username: $KIALI_USERNAME
  passphrase: $KIALI_PASSPHRASE
EOF
```

# Install Via Helm
Kiali secret 을 생성하고, helm을 통해 kiali 설치를 위해 [the helm install instructions](https://istio.io/docs/setup/kubernetes/install/helm/)을 참고합니다. helm 명령어를 사용하기 전에 **--set kiali.enabled=true** 옵션을 적용해야 합니다. 에를들면:
```
$ helm template --set kiali.enabled=true install/kubernetes/helm/istio --name istio --namespace istio-system > $HOME/istio.yaml
$ kubectl apply -f $HOME/istio.yaml
```

이번 섹션에서는 Jaeger 와 Grafana 에 대해서는 논의하지 않습니다. 만약 클러스에 이미 이 기능이 설치되어있고, Kiali 에 통합하고 싶다면, helm 명령어를 통해 다음과 같이 추가적인 정보를 넣어주어야 합니다.
```
helm template \
    --set kiali.enabled=true \
    --set "kiali.dashboard.jaegerURL=http://jaeger-query:16686" \
    --set "kiali.dashboard.grafanaURL=http://grafana:3000" \
    install/kubernetes/helm/istio \
    --name istio --namespace istio-system > $HOME/istio.yaml
kubectl apply -f $HOME/istio.yaml
```

<br>
# Genertaing a service graph
***
1. 다음 명령어릍 통해 클러스터에서 kiali 서비스가 실행중임을 확인한다.
```
kubectl -n istio-system get svc kiali
```
2. [Bookinfo ingress](https://istio.io/docs/examples/bookinfo/#determining-the-ingress-ip-and-port) **GATEWAY_URL**을 정의한다.

3. mesh로 트래픽을 전송하기 위해 3가지 옵션이 있다.
- **http://$GATEWAY_URL/productpage** 브라우저를 통해 접속한다.
- curl 명령을 이용하여 여러번 요청한다.
```
curl http://$GATEWAY_URL/productpage
```
- 만약 **watch** 명령어를 설치했다면, 주기적으로 requests 메시지를 전송한다.
```
watch -n 1 curl -o /dev/null -s -w %{http_code} $GATEWAY_URL/productpage
```
osx의 경우 watch 명령어는 다음과 같이 설치 가능하다.
```
$ brew install watch
```
4. Kiali UI 웹페이지 오픈을 위해 port-forwarding을 이용한다.
```
kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=kiali -o jsonpath='{.items[0].metadata.name}') 20001:20001
```
5. [http://localhost:20001/kiali/console](http://localhost:20001/kiali/console) 웹브라우징하여 접속한다.
6. Kiali UI 로그인을 위해설치시 또는 secret 생성시에 사용했던 username 과 passphrase 값을 입력한다.
7. 로그인 후에 바로 나타나는 **Overview** 페이지를 통해 mesh 서비스의 전체적인 상황을 확인 가능하다.
**Overview** 페이지는 mesh 안에 서비스를 가진 모든 네임스페이스를 보여준다. 아래 스크린샷이 비슷한 페이지를 보여줄 것이다.
![http://localhost:20001/kiali/console](assets/images/istio/kiali-overview.png)
8.그래프를 보기 위해 **bookinfo** 네임스페스페이스를 선택한다.
9. 오른쪽 패널에 metric에 대한 상세정보를 출력하기 위해 그래프에 있는 노드 또는 가장자리를 선택한다.
10. 다양한 그래프 타입을 사용하여 service mesh를 보기 위해, **Graph Type** 드롭다운 메뉴에서 원하는 graph type를 선택한다. 몇몇 service graph type: App, Versioned App, Workload, Service 을 선택할 수 있다.
- App type
![kiali-app](assets/images/istio/kiali-app.png)

- Versioned App type
![kiali-versionedapp](assets/images/istio/kiali-versionedapp.png)
- Workload type
![kiali-versionedapp](assets/images/istio/kiali-workload.png)
- Service type
![kiali-versionedapp](assets/images/istio/kiali-service-graph.png)
11. istio 설정에 대한 자세한 설정을 확인하기 위해서는, 왼쪽 메뉴바에 있는 **Applications, Workload, and Services** 메뉴 아이콘을 클릭한다. 아래 스크린샷은 Bookinfo 애플리케이션 정보를 보여줍니다.
![kiali-services](assets/images/istio/kiali-services.png)

<br>
# About the Kiali Public API
***
graph 와 다른 metrics, health, 설정 정보를 표시하기 위한 JSON 파일 생성을 위해, [Kiali Public API](https://www.kiali.io/documentation/developer-api/)를 참고할 수 있습니다. 에를 들면, **app** graph 타입을 사용하는 graph JSON 표현을 얻기 위해 **$KIALI_URL/api/namespaces/graph?namespaces=bookinfo&graphType=app** URL을 브라우저에서 접속해보세요.

Kiali Public API는 Prometheus 쿼리를 기반으로 하며 표준 istio 메트릭 구성에 따라 달라진다.
또한 쿠버네티스 API를 호출하여 서비스에 대한 추가 정볼르 얻습니다.
Kiali 를 사용하여 최성의 경험을 얻으려면 애플리케이션 구성 요소에 metadata labels **app** 과 **version**을 활용합니다. 템플릿으로 Bookinfo 샘플 응용프로그램은 이 규칙을 따릅니다.

<br>
# Cleanup
1. Bookinfo 애플리케이션을 삭제하고 싶다면 [BookInfo cleanup](https://istio.io/docs/examples/bookinfo/#cleanup)을 참고하세요.
2. 쿠버네티스에서 Kiali를 삭제하고 싶다면, app-kiali 라벨링된 모든 컴포넌트를 삭제하세요.
```
kubectl delete all,secrets,sa,configmaps,deployments,ingresses,clusterroles,clusterrolebindings,virtualservices,destinationrules,customresourcedefinitions --selector=app=kiali -n istio-system
```
