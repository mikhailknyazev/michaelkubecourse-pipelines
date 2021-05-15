
//noinspection GroovyAssignabilityCheck
properties([parameters([
        choice(choices: [
                'pod-delete',
                'ec2-terminate-with-EOT-probe',
                'ec2-terminate-with-continuous-probe',
                'pod-cpu-hog',
                'pod-cpu-hog-and-nodes-scaling',
                'pod-autoscaler',
                'benchmark-test',
                'alternate-workload-deployment',
                'ec2-spot-instances-and-cluster-autoscaler',
                'ec2-spot-interruption',
                'eks-cluster-rolling-update'
        ], description: 'Pipeline to run', name: 'target_pipeline'),
        choice(choices: ['keep', 'drop'], description: 'What to do with the Reliability Pipeline results', name: 'results_cleanup_policy'),
        booleanParam(defaultValue: true, description: 'Drop all the previous results before this Reliability Pipeline run', name: 'clean_results_before_run')
])])

// See also: https://github.com/jenkinsci/kubernetes-plugin
podTemplate(yaml: """\
    apiVersion: v1
    kind: Pod
    spec:
      serviceAccountName: jenkins-agent
      nodeSelector:
        role: tools
      tolerations:
        - key: tools
          operator: "Equal"
          value: "true"
          effect: NoSchedule
      containers:
      - name: tools
        image: michaelkubecourse/tools
        args: ["sleep", "99d"]
        tty: true
    """.stripIndent()) {
    node(POD_LABEL) {
        container('tools') {

            stage('Init') {
                checkout scm
                echo sh(script: 'kubectl version', returnStdout: true)

                if (params.clean_results_before_run) {
                    echo 'Cleaning all the previous results...'
                    echo sh(script: './clean-tests.sh', returnStdout: true)
                }
            }

            stage('Reliability Tests') {

                echo sh(script: "argo submit ./pipelines/${params.target_pipeline}.yaml -n litmus 2>&1", returnStdout: true)

                env.WORKFLOW_HOME_URL = sh(script: './workflow_home_url.sh', returnStdout: true)
                printReliabilityPipelineURL()

                echo "Waiting for '${params.target_pipeline}' completion..."
                sh('argo logs @latest --no-color -n litmus -f 2>&1')

            }

            stage('Reliability Pipeline Verdict') {
                def verdict = sh(script: './verdict.sh 2>&1', returnStdout: true)
                echo "VERDICT IN JENKINS: ${verdict}"
                if (verdict.trim().endsWith('RELIABILITY_OK')) {
                    echo 'RESULT IN JENKINS: PASS'
                } else {
                    echo 'RESULT IN JENKINS: FAIL'
                    error('See logs above for more details...')
                }
            }

            stage('Results') {
                switch(params.results_cleanup_policy) {
                    case 'keep':
                        printReliabilityPipelineURL()
                        break
                    case 'drop':
                        echo sh(script: './clean-tests.sh', returnStdout: true)
                        break
                    default:
                        echo 'no-op (unexpected)'
                        break
                }
            }

        }
    }
}

def printReliabilityPipelineURL() {
    echo '*******************************************************************************************************************************************'
    echo " Reliability Pipeline UI (for '${params.target_pipeline}'): ${env.WORKFLOW_HOME_URL}"
    echo '*******************************************************************************************************************************************'
}
