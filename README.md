# Node Exporter + Prometheus + Grafana 
> AWS App 사용자단 Backend 모니터링 초점

<br>

## 모니터링 개요
- App 사용자단 Backend -> AI 판독 기능 -> '부하' -> CPU 사용량 모니터링 초점
- Prometheus -> Get 방식으로 Node Exporter가 수집하는 metric을 Pull
- Grafana -> 시각화

<br>

## 모니터링 파일 구조도
<img src="https://github.com/kksung/Monitoring-AppUserBE/assets/110016279/e3fff268-a85c-4e20-aa48-d61bec658d07" width=330 height=130>

<br>

## Node Exporter
- Node Exporter 도커 컨테이너 실행 명령 -> linux-amd64
  - Backend ASG Instance는 scail-out 될 때 자동으로 Node Exporter 컨테이너가 실행되도록 스크립트 설정
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

<img src="https://github.com/kksung/Monitoring-AppUserBE/assets/110016279/0674ac6e-9461-46ae-a799-4b735879001d" width=900 height=200>

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

## Troubleshooting & 유의사항
