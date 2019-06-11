---
layout: splash
title: Istio Telemetry Tracing (01. Overview)
date: 2019-06-11 08:26:28 -0400
categories: istio
tags: [istio, telemetry]
---

이번 섹션을 마친 후, 애플리케이션 빌드에 사용한 개발언어, 프레임워크 또는 플랫폼과 상관없이 애플리케이션에 대한 트레이싱을 어떻게 하는지 소개합니다.
이 예제는 Bookinfo 샘플 애플리케이션을 예제로 사용합니다.

 # Understanging what happend
 istio proxy가 자동으로 spans 정보를 전송할 수 있지만, 전체 trace 함께 묶기 위한 약간의 힌트가 필요하다. 애플리케이션은 적절한 HTTP headers 정보를 전파하는게 필요하고 그래서 istio proxy가 span 정보를 전송하면, 전체 하나의 trace 안에서 span 정보가 올바르게 상관 관계를 가질 수 있다.

 이렇게 하기 위해서는 들어오고 나가는 http request 로부터 headers 정보를 올바르가 전파하는 것이 필요하다.

- x-request-id
- x-b3-traceid
- x-b3-spanid
- x-b3-parentspanid
- x-b3-sampled
- x-b3-flags
- x-ot-span-context

Python **product** service 샘플을 보면, 애플리케이션이 **OpenTracing** 라이브러리를 이용하여 HTTP request로부터 필요한 headers 정보를 추출하는 로직을 확인할 수 있다.
```
def getForwardHeaders(request):
    headers = {}

    # x-b3-*** headers can be populated using the opentracing span
    span = get_current_span()
    carrier = {}
    tracer.inject(
        span_context=span.context,
        format=Format.HTTP_HEADERS,
        carrier=carrier)

    headers.update(carrier)

    # ...

    incoming_headers = ['x-request-id']

    # ...

    for ihdr in incoming_headers:
        val = request.headers.get(ihdr)
        if val is not None:
            headers[ihdr] = val

    return headers
```

reviews 애플리케이션 (Java) 은 다음과 비슷하다.
```
@GET
@Path("/reviews/{productId}")
public Response bookReviewsById(@PathParam("productId") int productId,
                            @HeaderParam("end-user") String user,
                            @HeaderParam("x-request-id") String xreq,
                            @HeaderParam("x-b3-traceid") String xtraceid,
                            @HeaderParam("x-b3-spanid") String xspanid,
                            @HeaderParam("x-b3-parentspanid") String xparentspanid,
                            @HeaderParam("x-b3-sampled") String xsampled,
                            @HeaderParam("x-b3-flags") String xflags,
                            @HeaderParam("x-ot-span-context") String xotspan) {

  if (ratings_enabled) {
    JsonObject ratingsResponse = getRatings(Integer.toString(productId), user, xreq, xtraceid, xspanid, xparentspanid, xsampled, xflags, xotspan);
```

애플리케이션에서 다운스크림을 호출할때, 이 headers 정보들이 포함된 것을 확인하세요

<br>
# Trace Sampling
***
istio는 기본적으로 모든 requests 에 대해 trace를 캡쳐합니다. 예를 들면, 위 Bookinfo 샘플 예제를 사용할 경우, 매번 /productpage 접속할 경우 대시보드에서 이와 일치하는 trace를 확인할 수 있습니다.
이 sampleing rate는 테스틑 또는 낮은 traffic mesh에 적합합니다. 높은 트래픽 mesh의 경우 두가지 방법중 하나로 trace 를 위한 sampling rate를 낮출 수 있습니다.
- setup 하는 동안, trace sampling 의 비율을 설정하기 위한 **pilog.traceSampling** Helm 옵션을 사용합니다. 자세한 설정 옵션은 [Helm Install]을 확인하세요.
- Mesh가 동작하는 동안에는 아래와 같은 절차를 통해 **istio-pilot** deployment을 에디터로 열어서 환경변수 값을 수정합니다.
1. 다음과 같은 벙버을 통해서 로딩된 deployment configuration 파일을 텍스트 에디터로 오픈합니다.
```
kubectl -n istio-system edit deploy istio-pilot
```
2. **PILOT_TRACE_SAMPLING** 환경변수 값을 찾고, 원하는 percentage (0.0 ~ 100.0) 값으로 수정합니다.

위 두가지 케이스 모두 유효한 percentage 값은 0.0 ~ 100.0 이고, precision 값은 0.01 입니다.
