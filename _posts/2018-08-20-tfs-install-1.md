---
layout: post
title:  "VSTS Agent 설치방법1"
date:   2018-08-17 16:46:22 +0900
categories: vsts
---

# 배포서버 정보
#### 접속방법
- HostName eaz-m-mgt-sys01(10.199.0.20)
- User pa_platform / *******

#### 배포위치
- $ ~/deploy/scripts/ansible
  

# install VSTS
- ansible-playbook -i hosts tfs.yml --limit "qa_beta" --tags "install_tfs" -vvv

VSTS 에이전트 설치파일은 각 호스트에 복사후, 압축을 풀어놓습니다.

# install ssh
- ansible-playbook -i hosts tfs.yml --limit "qa_beta" --tags "install_ssh" -vvv

TFS git 서버와 ssh 통신하기 위한 ssh 키 설정을 셋업합니다. 

# start VSTS
- ansible-playbook -i hosts -e deployment_group="QA-Beta-Twz" tfs.yml --limit "qa_beta" --tags "start_tfs" -vvv 

VSTS 압축을 풀은 폴더의 config.cmd 명령어를 통해 TFS 서버와 연동하고, 서비스모드로 VSTSAgent를 실행/등록한다.
등록할때 TFS에 등록할 배포그룹을 deployment_group 인자를 통해 설정하도록 한다.

# stop VSTS
- ansible-playbook -i hosts tfs.yml --limit "qa_beta" --tags "stop_tfs" -vvv 

TFS 서버에서 VSTS 에이전트를 삭제한다. 

# delete deploy
- ansible-playbook -i hosts tfs.yml --limit "qa_beta" --tags "del_bdm_deploy" -vvv 

각 호스트에 배포한 e:\bdm_deploy_tfs 폴더를 모두 삭제
혹시라도 배포과정에서 충돌이 발생할 경우 배포폴더(e:\bdm_deploy_tfs)를 모두 삭제하고,
재배포해서 clone 하는게 빠를 수 있다.

# delete vstsagent install folder
- ansible-playbook -i hosts tfs.yml --limit "qa_beta" --tags "del_vstsagent" -vvv 

e:\vstsagent 폴더를 삭제해줍니다.
install VSTS 통해서 e:\vstsagent 위치에 환경이 구축되고, vstsagent를 새롭게 설치하고 싶은경우 활용하면 됩니다.



