pipeline {
  agent any

  stages {
    stage('Build') {
      steps {
        awsCodeBuild(
          projectName: 'codebuildtest',
          credentialsType: 'jenkins',
          workspaceExcludes: '.git/',
          credentialsId: 'codebuild-credentials',
          region: 'us-west-2',
          sourceControlType: 'jenkins',
        )
      }
    }
  }
}
