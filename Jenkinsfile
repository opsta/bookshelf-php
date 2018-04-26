properties([
  gitLabConnection('gitlab-opsta'),
  parameters([
    choice(choices: 'deploy-by-branch\ntagging\ndeploy-production', description: 'Action to do', name: 'ACTION'),
    [$class: 'GitParameterDefinition', branch: '', branchFilter: '.*', defaultValue: '', description: 'Choose tag to deploy (Need to combine with ACTION = deploy-production)', name: 'TAG', quickFilterEnabled: false, selectedValue: 'NONE', sortMode: 'DESCENDING_SMART', tagFilter: 'build-*', type: 'PT_TAG']
  ])
])

def label = "bookshelf-${UUID.randomUUID().toString()}"
podTemplate(label: label, cloud: 'gke-2', containers: [
    containerTemplate(name: 'docker', image: 'docker', ttyEnabled: true, command: 'cat'),
    containerTemplate(name: 'helm', image: 'lachlanevenson/k8s-helm', command: 'cat', ttyEnabled: true),
    containerTemplate(name: 'git', image: 'paasmule/curl-ssl-git', command: 'cat', ttyEnabled: true)
  ],
  volumes: [
    hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock'),
]) {
  node(label) {

    appName = 'bookshelf'

    if(params.ACTION == "tagging") {

      stage('Pull UAT image and tag to production image') {
        container('docker') {
          imageTag = "opsta/${appName}:uat"
          imageTagProd = "opsta/${appName}:build-${env.BUILD_NUMBER}"
          withCredentials([usernamePassword(credentialsId: 'dockerhub-opsta', usernameVariable: 'DOCKER_HUB_USER', passwordVariable: 'DOCKER_HUB_PASSWORD')]) {
            sh """
              docker login -u $DOCKER_HUB_USER -p $DOCKER_HUB_PASSWORD
              docker pull ${imageTag}
              docker tag ${imageTag} ${imageTagProd}
              docker push ${imageTagProd}
              """
          }
          // Get commit id to tag from docker image
          CODE_VERSION = sh (
            script: "docker run --rm ${imageTagProd} cat VERSION",
            returnStdout: true
          ).trim()
        }
      }

      stage('Tag commit id to version and push code') {
        container('git') {
          sshagent(credentials: ['bookshelf-1-git-deploy-key']) {
            checkout scm
            checkout([$class: 'GitSCM',
              branches: [[name: CODE_VERSION ]]
            ])
            sh """
              git tag build-${env.BUILD_NUMBER}
              SSH_AUTH_SOCK=${env.SSH_AUTH_SOCK} GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" git push --tags
              """
          }
        }
      }

    } else if(params.ACTION == "deploy-production") {
      // Deploy to production
      stage('Deploy production') {
        scmVars = checkout scm
        container('helm') {
          withCredentials([file(credentialsId: 'kubeconfig-gke-2', variable: 'KUBECONFIG')]) {
            sh """
              mkdir -p ~/.kube/
              cat $KUBECONFIG > ~/.kube/config
              sed -i 's/tag: latest/tag: ${params.TAG}/g' k8s/values-prod.yaml
              sed -i 's/commitId: CHANGE_COMMIT_ID/value: ${scmVars.GIT_COMMIT}/g' k8s/values-prod.yaml
              helm upgrade -i --namespace prod -f k8s/values-prod.yaml --wait bookshelf-prod k8s/helm
              """
          }
        }
      }

    } else if(params.ACTION == "deploy-by-branch") {
      switch (env.BRANCH_NAME) {
        case "master":
          imageTag = "opsta/${appName}:uat"
          break
        case "dev":
          imageTag = "opsta/${appName}:dev"
          break
      }

      scmVars = checkout scm

      stage('Build image') {
        container('docker') {
          sh """
            echo ${scmVars.GIT_COMMIT} > VERSION
            docker build -t ${imageTag} .
            """
        }
      }

      stage('Push image to registry') {
        container('docker') {
          withCredentials([usernamePassword(credentialsId: 'dockerhub-opsta', usernameVariable: 'DOCKER_HUB_USER', passwordVariable: 'DOCKER_HUB_PASSWORD')]) {
            sh """
              docker login -u $DOCKER_HUB_USER -p $DOCKER_HUB_PASSWORD
              docker push ${imageTag}
              """
          }
        }
      }

      stage("Deploy Application") {
        container('helm') {
          // Put kubeconfig file
          withCredentials([file(credentialsId: 'kubeconfig-gke-2', variable: 'KUBECONFIG')]) {
            sh """
              mkdir -p ~/.kube/
              cat $KUBECONFIG > ~/.kube/config
              """
          }
          switch (env.BRANCH_NAME) {
            // Roll out a UAT environment on master branch
            case "master":
              sh """
                sed -i 's/commitId: CHANGE_COMMIT_ID/value: ${scmVars.GIT_COMMIT}/g' k8s/values-uat.yaml
                helm upgrade -i --namespace uat -f k8s/values-uat.yaml --wait bookshelf-uat k8s/helm
                """
              break

            // Roll out a dev environment
            case "dev":
              sh """
                sed -i 's/commitId: CHANGE_COMMIT_ID/value: ${scmVars.GIT_COMMIT}/g' k8s/values-dev.yaml
                helm upgrade -i --namespace dev -f k8s/values-dev.yaml --wait bookshelf-dev k8s/helm
                """
              break
          }
        }
      }
    }
  }
}
