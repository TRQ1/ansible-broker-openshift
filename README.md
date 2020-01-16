# APB Test envrionment(Test 환경 자동 구성) 

APB를 사용하여 Openshift에 환경을 자동으로 구성 할 수 있을까 하는 생각에 작성된 ansible playbook이며, Ansible Broker를 통하여 자동 Provision이 가능하다.

### 구성 내역
* Playboos는 각각 Provision과 Deprovision으로 구성 
    * Provision: JBoss EAP 7.1, MariaDB10, Nexus3, Jenkins2을 하나의 namespace에 자동 설치
    * Deprovision: 구성된 환경을 삭제


### 사용전 필요 사항
* Application
    * 배포할 Application에 맞게 Dockefile 작성 필요
    * Application을 배포할 git repository가 필요
    * 배포할 Application에 맞게 Jenkinsfile 수정 필요
    * Jenkinsfile은 contrabs 디렉토리에 있음

* OpenShift
    * Nexus3, MariaDB, Jenkins를 사용하기 위한 Persistent-Volume이 필요 (NFS 마운트시 기본적으로 Storage class가 설정되어있지 않은경우 자동적으로 pv 및 pvs를 생성못하기 때문에 설치될 project에 사전에 pv, pvs를 할당이 필요) 


### 디렉토리 구조
* 최상위 디렉토리에는 메타데이터 정의 파일(apb.yml) 및 apb 이미지를 만들기위한 Dockerfile이 있음
* Contrabs 디렉토리에는 application 배포를 위한 Jenkinsfile 및 nexus-settings.yml 파일이 있음
* role 디렉토리에는 provsion과 deprovision을 하는 playbook 파일들이 있음
* playbooks 디렉토리에는 apb에 역할(provision, deprovision) 및 apb에서 사용할 variable 파일이 있음

```
.
├── Dockerfile
├── Makefile
├── README.md
├── apb.yml
├── playbooks
│   ├── deprovision.yml
│   ├── provision.yml
│   └── vars
│       └── main.yml
└── roles
    ├── contrabs
    │   ├── jenkinsFile
    │   └── nexus_settings.xml
    ├── deprovision-project
    │   └── tasks
    │       ├── app.yaml
    │       ├── jenkins.yml
    │       └── nexus.yml
    └── provision-project
        ├── tasks
        │   └── main.yml
        └── templates
            ├── gov.json
            ├── set-route.sh
            └── setup-nexus3.sh
```


### openshift-ansible-service-broker 프로젝트에 사전 작업
* broker-config(config-map)
    * local_openshift의 white_list를 변경이 필요
       ```
         - type: local_openshift
           name: localregistry
           white_list: [.*-apb]
           namespaces: [openshift]
       ``` 
    * openshift의 sandbox_role 변경이 필요
       ```
       openshift:
        host: ""
        ca_file: ""
        bearer_token_file: ""
        namespace: openshift-ansible-service-broker
        sandbox_role: admin
       ``` 

### APB 설정 절차
* 아래와 같이 APB 생성 절차를 따라 실행
* openshift master에 admin권한으로 로그인이 되어있어야함
```
# apb bundle prepare
oc new-build --binary=true --name egov-apb -n openshift
# oc start-build --follow --from-dir . egov-apb -n openshift
# apb registry add egov-apb --type local_openshift --namespaces openshift
# apb broker bootstrap
# apb catalog relist
```


### POC 프로젝트 설정
* POC 프로젝트 생성 및 필요한 pv, pvc 등록
```
oc create namespace poc
oc project poc
oc adm policy add-scc-to-group anyuid system:serviceaccounts:poc
oc create -f mariadb-pv.yml
oc create -f mariadb-pvc.yml
oc create -f nexus3-pv.yml
oc create -f nexus3-pvc.yml
oc create -f jenkins-pv.yml
oc create -f jenkins-pvc.yml
```


### 사용방법
* openshift UI 접속후 Catalog에서 egov-apb를 선택한 후 POC 프로젝트를 선택하여 설치를 진행 한다.