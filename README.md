# Node Exporter + Prometheus + Grafana 
> AWS App 사용자단 Backend 모니터링 초점

<br>

## 사용 이유 ?
- 오픈소스 -> 클라우드 벤더사에 구애받지 않음 (멀티클라우드)
- CPU 모니터링에 특화

<br>

## 모니터링 스택 개요
- App 사용자단 Backend -> AI 판독 기능 -> '부하' -> CPU 사용량 모니터링 초점
- Node Exporter -> 인스턴스의 주요 metric 수집
- Prometheus -> Get 방식으로 Node Exporter가 수집하는 metric을 Pull
- Grafana -> 시각화
- 모두 컨테이너로 실행

<br>

## 모니터링 스택 파일 구조도
<img src="https://github.com/kksung/Monitoring-AppUserBE/assets/110016279/e3fff268-a85c-4e20-aa48-d61bec658d07" width=330 height=130>

<br>

## Node Exporter
- Node Exporter 도커 컨테이너 실행 명령 (linux-amd64)
  - ASG Backend Instance는 scail-out 될 때 자동으로 Node Exporter 컨테이너가 실행되도록 스크립트 설정
```
sudo docker image pull prom/node-exporter-linux-amd64
sudo docker run -d --name=node-exporter -p 9100:9100 prom/node-exporter-linux-amd64
```

<br>

## Prometheus
- Get 'http://PublicIP:9100' 방식으로 Metric 수집
- App 사용자단 Backend Instance 2종류 -> Basic, ASG
  - 'Private IP'를 가짐 -> 따라서 'ALB 리스너'를 통하여 메트릭 Pull
- Prometheus.yml 설정에서의 ‘job’
  - ALB의 각 리스너를 target으로 설정  -> 각 리스너의 대상 그룹에 있는 단일 인스턴스의 Exporter가 수집하는 Metric을 Pull!

<br>

<img src="https://github.com/kksung/Monitoring-AppUserBE/assets/110016279/0674ac6e-9461-46ae-a799-4b735879001d" width=930 height=200>

- 9100,9101 TG -> Basic Backend Instance
- 9102 TG -> ASG Backend Instance

<br>

## Docker-Compose 실행 
- Prometheus + Grafana 컨테이너 실행 명령어
```
sudo docker-compose -f docker-compose-monitoring.yaml up -d
```

<br>

## Grafana & 부하테스트
<img src="https://github.com/kksung/Monitoring-AppUserBE/assets/110016279/71d3fd29-c423-4e2d-a78e-4b0d529a894a" width=700 height=350>

- 1860 대시보드 - Node Exporter Full 양식 사용

<br>

<img src="https://github.com/kksung/Monitoring-AppUserBE/assets/110016279/d6f3dc15-9521-4732-b36d-d88e35373cc2" width=700 height=500>

- Prometheus와 연동

<br>

<img src="https://github.com/kksung/Monitoring-AppUserBE/assets/110016279/40e832e2-cdfc-451d-b365-c0ff7e721f58" width=600 height=40>

- ASG Instance에 접속해서 CPU 100% 부하를 주었을 때

<img src="https://github.com/kksung/Monitoring-AppUserBE/assets/110016279/eb26e9f9-f8eb-4bfa-a646-8af23dac623d" width=800 height=400>

- 대시보드 CPU 항목에 100%로 반영된 것 확인 (모니터링 OK!)

<br>

<img src="https://github.com/kksung/Monitoring-AppUserBE/assets/110016279/13b9eb85-11ba-46a3-ac5e-264c2f28db3a" width=880 height=380>

- ASG 동적 크기 조정 정책에서 평균 CPU 사용률 -> Default 값인 50%
- vCPU = 2인 스펙의 인스턴스에서 'CPU = 2'로 stress, 즉 100%로 부하를 주었으므로 scail-out되어 인스턴스가 2개로

  실행중인 것 확인

<br>

## Troubleshooting & 유의사항
### 1 - docker-compose 파일 볼륨 설정 -> 마운트 경로문제 발생
- 볼륨 설정을 './test/prometheus.yml:/etc/prometheus.yml'로 설정했더니 오류 발생 (디렉터리 경로 Mapping 오류)

> Sol) './test/prometheus.yml:/etc/prometheus/prometheus.yml'로 설정

<br>

### Why ?
- 호스트의 './test/prometheus.yml'파일 경로가 컨테이너 내부 경로 '/etc/prometheus.yml'에 Mapping되어야 마운트되어

  컨테이너가 올바르게 작동하지만, '/test' 디렉터리 경로를 마운트할 경로가 X ('/etc' 경로 이후에 디렉터리 경로 필요)

- 즉, '/etc/prometheus/prometheus.yml'로 마운트할 디렉터리 경로를 지정해야 호스트 디렉터리 경로 '/test'가

  Mapping되어 마운트됨 -> 도커 볼륨 설정 (마운트 설정) 경로 항상 유의!

<br>

### 2 - 'Private IP'를 갖는 인스턴스, 로드밸런서를 통해 메트릭을 가져올 때의 유의사항
- 로드밸런서를 통해 메트릭을 가져오므로, 로드밸런서 대상그룹에 속해있는 ASG의 Instance같은 경우, scail-out될 때

  대상그룹에 인스턴스가 자동으로 추가되면서 여러 인스턴스를 번갈아가면서 metric을 당겨오게 되는 문제
  
- 따라서 scail-out 전 ASG Backend Instance 1개에 대해서는 안정적으로 모니터링 수행이 가능하지만,

  scail-out 된다면 대시보드에서 ASG Backend Instance 하나를 고정적으로 모니터링 수행이 불가

> Sol) ASG Backend Instance 2개로만 Backend Instance를 구성했으나, ASG Instance 외 (Basic Backend Instance)를 둠

<br>

### Why ?
- Basic Backend Instance 2개, ASG Backend Instance는 최소 용량 1개로 지정하여 총 3개의 Backend Instance 구성

  -> ASG 인스턴스가 아닌 기본 인스턴스 2개를 둠으로써, 기본 백엔드 인스턴스만큼은 안정적으로 모니터링 수행
