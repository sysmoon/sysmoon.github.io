---
layout: splash
title: Istio Installation Guide using minikube on OSX
date: 2019-06-07 08:26:28 -0400
categories: istio
tags: [istio, setup]
---

오늘은 osx 환경에서 istio hands-on을 위해 osx 환경에서 minikube 를 설치하고, istio-1.1.7 설치하여
Bookinfo 샘플 애플리케이션 테스트 환경을 구성하고자 한다. 쿠버네티스 클러스터를 구축하여 테스트 할 수도 있지만 로컬 머신에 standalone 모드로 간단히 minikube를 구축하여 가단한 기능 테스트가 가능하다.

# Install Minikube on OSX

설치 가이드는 쿠버네티스 공식문서 [Minikube 설치](https://kubernetes.io/ko/docs/tasks/tools/install-minikube/) 확인 가능하다.

## 가상화 활성화 여부 확인
테스트 PC BIOS 에서 VT-x 또는 AMD-v 가상화가 필수적으로 활성화 되어 있어야 한다.
```
OSX 환경에서는 다음과 같이 가상화 지원여부를 확인한다.

sysctl -a | grep machdep.cpu.features | grep VMX

출력에서 VMX를 확인할 수 있다면 VT-x 기능을 운영체제에서 지원한다.
```

## 하이퍼바이저 설치
운영체제에 적합한 하이퍼바이저를 설치한다.

운영체제	지원하는 하이퍼바이저
맥OS	VirtualBox, VMware Fusion, HyperKit
리눅스	VirtualBox, KVM
윈도우	VirtualBox, Hyper-V

여기서는 OSX 환경에서 테스트할 예정이므로 brew 를 이용하여 설치한다.
```
brew cask install virtualbox
```

## kubectl 설치
kubectl 은 쿠버네티스와 cli 통신이 가능한 클라이언트 도구이다. [kubectl 설치하고 설정](https://kubernetes.io/docs/tasks/tools/install-kubectl/) 가이드에 따라 kubectl을 설치할 수 있다. osx 에서는 kubectl last release 버전을 다운받거나, brew, macport를 통해서 설치가 가능하다. 여기서는 마지막 최신 릴리즈 버전을 받아서 설치한다.

1. 마지막 버전 다운로드
```
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl
```

2. 실행 가능한 모드로 변경
```
chmod +x ./kubectl
```

3. 실행 가능한 디렉토리로 이동
```
sudo mv ./kubectl /usr/local/bin/kubectl
```

4. 버전 테스트
```
kubectl version
```

# Minikube 설치
brew를 이용하여 minikube를 설치한다.
```
brew cask install minikube
```

또는 바이너리를 다운받아서 설치 가능하다.
```
$ curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64 \
  && chmod +x minikube

$ sudo mv minikube /usr/local/bin
```
# Minikube 실행
위 설정을 통해 minikube 설치가 완료되면, 다음 명령을 통해 minikube를 실행한다.
- minikube 시작
```
minikube start
```

minikube status 를 통해 현재 Running 상태임을  확인한다. 그리고 virtualbox를 실행해서 확인해보면 현재 minikube vm이 실행중인 것을 확인할 수 있다. minikube는 Kubernetes VM을 관리하기 위해 Docker Machine 사용이 가능하다. minikube 가 virtualbox, fusion driver를 내장하고 있어 사용을 지원하지만, 다른 드라이버들은 별도의 설정이 필요하다. 여기서는 virtualbox 대신 hyperkit driver르 설치해서 minikube를 실행하도록 하겠다.

- minikube 중지
```
minikube stop
```

- hyperKit driver 설치
```
$ curl -Lo docker-machine-driver-hyperkit https://storage.googleapis.com/minikube/releases/latest/docker-machine-driver-hyperkit \
&& chmod +x docker-machine-driver-hyperkit \
&& sudo cp docker-machine-driver-hyperkit /usr/local/bin/ \
&& rm docker-machine-driver-hyperkit \
&& sudo chown root:wheel /usr/local/bin/docker-machine-driver-hyperkit \
&& sudo chmod u+s /usr/local/bin/docker-machine-driver-hyperkit
```

hyperkit driver를 이용하여 proxy 없이 minikube 클러스터 실행하다. 추가로 cpu, memory, logging 등의 옵션을 설정하여 원하는 만큼의 리소스를 할당하여 실행 가능하다.
- hyperkit drvier를 이용한 minikube 시작
```
minikube start --vm-driver=hyperkit --v=10 --alsologtostderr --cpus 4 --memory 4096
```
- Kubernetes 설정파일
Kubernetes 설정 파일은 ~/.kube/config 파일을 통해 확인 가능하다.
minikube 클러스터를 방금 설치했고, 이 클러스터가 선택되도록 정의되어있다. 다음 명령을 통해 현재 사용중인 클러스터 확인이 가능하고, 특정 클러스터를 선택하여 변경 가능하다.
```
$ kubectl config current-context
minikube

$ kubectl config use-context minikube

$ kubectl cluster-info
```

클러스터에 대한 자세한 정보는 빌트인 된 dashboard를 통해 확인 가능하다.
```
minikube dashboard
```

# Minikube addon

minikube 는 dashboard 외에 다양한 addon을 가지고 있습니다.
```
$ minikube addons list

- addon-manager: enabled
- dashboard: disabled
- default-storageclass: enabled
- efk: disabled
- freshpod: disabled
- gvisor: disabled
- heapster: disabled
- ingress: disabled
- logviewer: disabled
- metrics-server: disabled
- nvidia-driver-installer: disabled
- nvidia-gpu-device-plugin: disabled
- registry: disabled
- registry-creds: disabled
- storage-provisioner: enabled
- storage-provisioner-gluster: disabled
```

필요한 addon은 enable 명령어를 통해 활성화 가능합니다.
```
minikube addons enable [addon-name]
```

Reference
- [Kubernetes Minikube 설치 공식 가이드](https://kubernetes.io/ko/docs/tasks/tools/install-minikube/)
- [Minikube로 로컬상에서 쿠버네티스 구동](https://kubernetes.io/ko/docs/setup/minikube/)
