---
layout: splash
title: Istio Concepts (What is istio?)
date: 2019-03-01 08:26:28 -0400
categories: istio
tags: [istio, concepts]
---

# Whta is Istio?
최근 클라우드 플랫폼 환경에서 서비스 개발/운영하는 환경은 DevOps 측면에서 많은 장점을 가져다 주고 있습니다.  
그러나 그 만큼 많은 부담감을 주기도 하는데 개발자의 경우 Portability를 위해 마이크로서비스 아키텍처 기반으로 개발해야 하는 반면,
운영자는 이러한 서비스를 하이브리드 클라우드, 멀티클라우드 환경에 자속적인 통합/배포(CI/CD)하고 안정적으로 운영해야 하는 부담감이 있습니다.
Istio는 이러한 서비스들은 연결(Connect)하고, 제어(Control)하고, 관찰(Observe)할 수 있는 방법을 제공합니다.

Istio는 높은 수준에서 이러한 복잡한 배포의 복잡성을 줄이고, 개발팀의 부담을 덜어줍니다.
기존 분산 응용프로그램을 투명하게 Layering 하는 완벽한 오픈소스 기반의 Servie Mesh 솔루션 입니다.
Istio는 Logging, Telemetry, Policy 와 같은 다양한 API를 포함한 플랫폼을 제공합니다.  
또한 Istio는 분산 마이크로서비스 아키텍처를 실행하고,
마이크로서비스 간 일관성 있는 보안, 연결, 모니터링을 효율적으로 운영하기 위한 다양한 기능을 제공합니다.

## What is Service Mesh?
Istio는 모노리식 응용프로그램에서 분산 마이크로서비스 아키텍처 전환 과정에서 개발자와 운영자가 직면하는 여러가지 문제를 해결하는데 도움을 줍니다.
이를 이애하기 위해 Istio Servie Mesh 환경에서 요구되는 기술들을 살펴보겠습니다.
**Service Mesh** 용어는 애플리케이션을 구성하고, 애플리케이션 간 상호작용을 위한 마이크로서비스 네트워크를 설명하는데 주로 사용됩니다.
**Service Mesh** 크기가 커지고 복잡해짐에 따라 이해하고 관리하기가 힘들어지고 있습ㄴ디ㅏ.
이러한 환경에서는 Monitoring, LoadBalancing, FailOver, Metric 과 같은 기능을 요구합니다.
또한 Servie Mesh는 A/B 테스트, canary rollouts, rate limiting, access control, E2E(end-to-end) 인증과 같은 복잡한 운영 요구사항을 가지고도 합니다.

Istio는 Service Mesh 전체 안에서 발생하는 어떤 행위에 대한 통찰력과 운영제어를 제공하며 마이크로서비스 애플리케이션의 다양한 요구사항을 만족시키기 위한 완벽한 솔루션을 제공합니다.

![Service Mesh](/assets/images/istio/service-mesh.png)

## Why use Istio?
Istio는 서비스 코드 변경 없이 또는 아주 약간의 수정만으로 로드밸런싱, 서비스간 인증, 모니터링 등을 통해 배포된 서비스의 네트워크를 쉽게 생성할 수 있습니다.
마이크로서비스 간 모든 네트워크 통신을 가로챌 수 있는 sidecar proxy 를 서비스 환경에 배포하기 위해 Istio를 인프라(ex: Kubernetes)에 추가할 수 있고, 다음과 같은 Istio Control Plane 기능을 통해 설정/관리가 가능하다

- HTTP, gRPC, WebSocket, TCP Traffic에 대한 자동 로드밸런싱
- 다양한 routing rule, retries, failover, fault injection 으로 트래픽 행위에 대한 세밀한 제어
- 플러그인 형태의 정책 레이어와 access controls, rate limits, quotas를 지원하는 설정 API
- 클러스타내 ingress와 egress를 포함한 모든 트래픽에 대한 자동 메트릭, 로그, 추적 기능
- 강력한 identity 기반의 인증과 권한으로 클러스터내 서비스 간 안전한 통신 지원

Istio는 다양한 배포 요구사항을 충족하고, 확장성을 위해 디자인되었다.

# Core Features
Istio는 서비스 네크워크 전반에 걸쳐 여러가지 주요 기능을 일관성 있게 제공합니다.

## Traffic Management
Istio의 쉬운 룰 설정과 트래픽 라우팅은 서비스 간 API 호출과 트래픽 흐름 제어를 가능하게 합니다.
Istio는 circuit breakers, timeouts 그리고 retries와 같은 서비스 레벨 속성값 설정을 단순화하고,
백분율 기반으로 트래픽을 분리하여 A/B 테스팅, canary rollouts(까나리 배포), staged rollouts(단계적 배포)와 같은 중요한 배포 작업을 쉽게 설정할 수 있습니다.

트래픽에 대한 좀더 좋은 식별과 빠르게 사용 기능한 장애복구 기능을 활용하여 문제의 원인이 발생하기 전에 이슈를 잡아낼 수 있고,
직면하는 어떤 상황에서든 좀더 신뢰감을 가지고 서비스 API를 호출하고, 네트워크를 더욱 강력하게 구축하여 사용 가능합니다.

## Security
Istio 보안의 주요기능은 개발자가 애플리케이션 보안에 집중할 수 있도록 합니다. Istio는 보안 통신채널 안에서 인증, 권한, 서비스 통신을 위한 암호화를 제공합니다. Istio 에서 서비스 간 통신은 기본적으로 암호화 되어있고, 다양한 프로토콜과 런타임에 일관되게 정책을 시행할 수 있습니다.

Istio는 Kubernetes(또는 다양한 인프라) 네트워크 정책과 플랫폼에 독립적인 반면 pod-to-pod 또는 service-to-service 의 네트워크 및 애플리케이션 레이어에서의 안전한 통신 기능을 포함한 더 많은 이점을 가지고 있습니다.

## Observability
Istio의 강력한 추적, 모니터링, 로깅 기능은 service mesh 배포에 대한 깊은 통찰력을 제공합니다.
Istio의 모니터링 기능을 통해 커스텀 대시보드가 모든 서비스에서의 성능 지표를 제공하는 동안 서비스 성능이 upstream & downstream 에 어떠한 영향을 주는지에 대한 실제 이해를 얻을 수 있고, 해당 성능이 다른 프로세스에 어떠한 영향을 끼쳤는지 알 수 있도록 도와줍니다.

Istio Mixer 컴포넌트는 정책을 컨트롤하고, 텔레메트리 정보를 수집하는 책임을 가지고 있습니다. Mixer는 backend 추상화와 중간 매개체 기능을 제공하고, 나머지 Istio를 개별 인프라 백엔드의 구현 세부 사항으로부터 격리 시키고, 운영자에게 mesh 및 인프라 백엔드 간의 모든 상호 작용에 대한 세분화된 제어권을 제공합니다.

이러한 모든 기능은 좀더 효율적으로 설정, 모니터링 하고, 서비스의 SLOs(Service Level Objectives)를 강화합니다.
물론 가장 중요한 것은 문제를 신속하고 효율적으로 발견하고 빠르게 수정하는데에 있습니다.

## Platform Support
Istio는 플랫폼 독립적이며, Cloud 환경, On-Premise, Kubernetes, Mesos 등등 을 포함하여 다양한 환경 또는 Nomad with Consul 환경에서 독립적으로 실행되도록 설계되었습니다. Istio는 현재 다음과 같은 플랫폼에서 동작하도록 지원합니다.
- Kubernetes 환경에서 서비스로 배포
- Consul 환경에서 서비스 등록
- 개별 VM 환경에서 Service로 실행

## Integration and Customization
Istio의 정책 강화 컴포넌트는 ACLs, Monitoring, Quotas, Auditing 등등의 기존 솔루션과 통합되도록 확장 및 사용자 정의할 수 있습니다.

# Architecture
Istio service mesh는 논리적으로 **data plane** 과 **control plane** 으르 분리되어있습니다.

- **data plane**은 sidecar로 배포된 지능적인 proxy(Envoy) 집합으로 구성되어 있습니다.
이러한 proxy는 범융 정책 및 텔레메트리 허브인 Mixer와 함께 마이크로서비스 간의 모든 네트워크 통신을 중재하고 제어합니다.
- **control plane**은 트래픽을 라우팅하기 위한 설정을 관리합니다. 추가적으로 **control plane** 정책을 적용하고 텔레미트리 정보를 수집하도록 Mixer를 설정합니다.

아래 다이어그램은 각각의 plane 을 구성하는 서로 다른 컴포넌트를 보여줍니다.

![Istio Dashboard](/assets/images/istio/istio_architecture.svg)

## Envoy
Istio는 Envoy의 확장된 버전을 사용한다. Envoy는 service mesh 안에서 발생하는 모든 inbound & outbound 트래픽에 대한 중재를 위해 C++로 개발된 고성능 proxy 서버입니다. Istio는 Envoy의 많은 내장기능을 활용하는데 예를 들면 다음과 같습니다.
- Dynamic service discovery (자동 서비스 탐색)
- Load balancing (부하분산을 위한 로드밸런싱))
- TLS termination (서비스간 TLS 보안채널)
- HTTP/2 and gRPC proxies (HTTP, gRPC 프로토콜 지원)
- Circuit breakers (장애 전파를 막기 위한 서킷 브레이커))
- Health checks (서비스 정상동작 유무를 위한 헬스체크)
- Staged rollouts with %-based traffic split (트래픽 분리를 통한 단계적 배포)
- Fault injection (디버깅 및 테스트를 위한 오류 주입)
- Rich metrics (많은 종류의 메트릭 정보)

Envoy는 동일한 Kubernete pod 안에 적절한 사이드카 형태의 서비스로 배포됩니다. 이러한 배포는 Istio가 속성으로서 트래픽 행위에 관한 많은 신호를 수집할 수 있도록 합니다. Istio는 Mixer에서 이러한 속성을 사용하여 정책을 실행하고, 이를 모니터링 시스템에 전송하여 전체 mesh의 동작에 대한 정보를 제공할 수 있습니다.

**sidecar proxy## 모델을 사용하면 코드를 재구성하거나 다시 작성할 필요 없이, 기존 배포 환경에 Istio 기능을 추가하여 sidecar 형태로 배포가 가능합니다. Istio [Design Goals](https://istio.io/docs/concepts/what-is-istio/#design-goals) 문서를 통해 왜 이러한 sidecar 모델을 사용하여 접근했는지에 대한 자세한 내용이 담겨져있습니다.

## Mixer
Mixer는 service mesh 간 접근통제와 정책을 체크하고, Envoy Proxy와 다른 서비스로부터 텔레메트리 정보를 수집하는 컴포넌트 입니다.
Envoy는 [속성](https://Istio.io/docs/concepts/policies-and-telemetry/#attributes)을 추출한 후 평가를 위해 Mixer로 전송합니다. 이러한 속성 추출과 정책 평가는 [Mixer Configuration documentaion](https://Istio.io/docs/concepts/policies-and-telemetry/#configuration-model) 문서를 통해 자세히 확인 가능합니다.

Mixer는 유연한 플러그인 모델을 가지고 있습니다. 이러한 모델은 다양한 호스트 환경과 인프라 백엔드와 결합할 수 있도록 합니다. 따라서 Istio는 Envoy 프락시와 Istio 관리 서비스를 이러한 세부 속성에서 추상화 합니다.
![Attribute Machine](/assets/images/istio/attribute_machine.svg)

## Pilot
**Pilot**은 envoy에 대한 설정 관리하는 컴포넌트 입니다.
Envoy sidecar, 서비스 검색, 지능적인 라우팅(e.g., A/B 테스트, canary rollouts 등..)과 탄력성 (timeout, retries, circuit breakers, etc..)을 위한 트래픽 관리 기능을 제공합니다. 
Pilot은 플랫폼 별 서비스 검색 메커니즘을 추상화하고, 느슨한 결합을 통해 Istio가 Kubernetes, Consul 또는 Nomad와 같은 여러 인프라 환경에서 동작하고, 트래픽 관리를 위한 동일한 운영자 인터페이스를 유지할 수 있도록 합니다.

## Citadel
**Citadel**은 보안에 관련된 기능을 담당하는 컴포넌트 입니다.
내장된 identity와 기밀 관리를 통해 사용자를 인증하여 service-to-service를 강화하도록 합니다. 서비스를 사용하기 위한 사용자 인증(Authentication), 인가(Authorization)을 담당하고 있습니다. 또한 서비스 간 안정한 보안채널(mTLS)을 생성하고, 인증서(Certificaiotn)을 관리합니다.

## Galley
Gallery는 Istio 설정 검증, 처리, 프로세싱을 담당하는 컴포넌트 입니다.
user-specified 설정을 가져와서 다른 control plane 컴포넌트에 대한 유효한 설정으로 변환합니다. 이러한 메카니즘때문에 Istio가 다른 오케스트레이션 시스템과 연동하여 유연하게 사용 가능합니다.
