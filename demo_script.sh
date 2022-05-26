#!/bin/bash

########################
# include the magic
########################
. ./demo-magic/demo-magic.sh

########################
# Configure the options
########################

#
# speed at which to simulate typing. bigger num = faster
#
# TYPE_SPEED=20

#
# custom prompt
#
# see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html for escape sequences
#

# text color
# DEMO_CMD_COLOR=$BLACK

PROMPT_TIMEOUT=2

DEMO_PROMPT="${GREEN}➜ "

# some supporting functions
function prompt
{
    echo; echo -e "${BLUE}$*"
}


# hide the evidence
clear

# put your demo awesomeness here

prompt The Kubernetes Autoscaler charm requires a Charmed Kubernetes deployment
p "juju status --format=summary"
cat mocks/juju_status_ck.txt

prompt The deployment must also have been added as a Juju Kubernetes cloud
p "juju clouds --controller my-controller"
cat mocks/juju_clouds.txt

prompt Deploying the autoscaler charm onto control-plane nodes is recommended, so ensure the nodes are untainted
p "for NODE in \$(kubectl get nodes -o name); do kubectl taint node \$NODE juju.is/kubernetes-control-plane=true:NoSchedule-; done"
cat mocks/remove_taint.txt

prompt Add a model for the autoscaler charm
p "juju add-model my-autoscaler-model my-k8s-cloud"
cat mocks/add_autoscaler_model.txt

prompt Deploy the charm
p "juju deploy kubernetes-autoscaler --trust"
cat mocks/deploy_charm.txt

prompt Patch the statefulset in order to force the charm pod to be scheduled on a control-plane node
p $'kubectl patch statefulset kubernetes-autoscaler -p \'{"spec": {"template": {"spec": {"nodeSelector": {"juju-application": "kubernetes-control-plane"}}}}}\' -n my-autoscaler-model'
cat mocks/patch_statefulset.txt

prompt The status shows that the charm is in a blocked state and needs to be configured
p "juju status"
cat mocks/blocked_status.txt

prompt Gather information about the Juju controller
p "KUBE_CONTROLLER=my-controller"
p "API_ENDPOINTS=\$(juju show-controller $KUBE_CONTROLLER --format json | jq -rc '.[].details[\"api-endpoints\"] | join(\",\")' )"
p "CA_CERT=\$(juju show-controller $KUBE_CONTROLLER --format json | jq -rc '.[].details[\"ca-cert\"]' | base64 -w0)"
p "USERNAME=\$(juju show-controller $KUBE_CONTROLLER --format json | jq -rc '.[].account.user')"
p "PASSWORD=\$(juju show-controller $KUBE_CONTROLLER --show-password --format json | jq -rc '.[].account.password')"

prompt Use the gathered information to configure the charm
p 'juju config kubernetes-autoscaler juju_api_endpoints="${API_ENDPOINTS}" juju_ca_cert="${CA_CERT}" juju_username="${USERNAME}" juju_password="${PASSWORD}"'

prompt The charm also needs to know the model UUID of the charmed-kubernetes model
p $'juju models -c $KUBE_CONTROLLER --format json | jq -cr \'.models[]|{name,"model-uuid"}\''
cat mocks/model_uuids.txt
p 'juju config kubernetes-autoscaler juju_default_model_uuid="5b528792-69c1-4fbc-8e24-8edabf4b297a"'

prompt Configure the scaling limits and provide the name of the worker application
p 'juju config kubernetes-autoscaler juju_scale="- {min: 1, max: 3, application: kubernetes-worker}"'

prompt Enable verbose logging and configure other settings such as scale down delay times
p 'juju config kubernetes-autoscaler autoscaler_extra_args="{v: 5, scale-down-delay-after-add: 1m0s, scale-down-unneeded-time: 1m0s, unremovable-node-recheck-timeout: 1m0s}"'

prompt The charm should no longer be blocked once configuration is complete
p "juju status"
cat mocks/active_idle_status.txt

prompt Since the cluster is not running any workloads, the number of workers will decrease to the configured minimum once the scale-down-unneeded-time has elapsed
p 'kubectl logs kubernetes-autoscaler-0 -f -c "juju-autoscaler"  -n my-autoscaler-model'
cat mocks/scale_down_logs.txt

prompt Check the status of the worker application to confirm the number of workers has decreased to 1. 
p 'juju switch my-ck-model'
cat mocks/switch_to_ck.txt
p 'juju status application kubernetes-worker --format=short'
cat mocks/scaled_down_status.txt

prompt Deploy a workload to force the cluster to scale up to accomodate it
p 'kubectl apply -f https://raw.githubusercontent.com/kubernetes/website/main/content/en/examples/controllers/nginx-deployment.yaml'
cat mocks/deployment_created.txt
p 'kubectl scale --replicas=600 deployments/nginx-deployment'
cat mocks/deployment_scaled.txt

prompt The logs should show that the increase in pods triggered a scale up
p 'kubectl logs kubernetes-autoscaler-0 -f -c "juju-autoscaler"  -n my-autoscaler-model'
cat mocks/scale_up_logs.txt

prompt Check the status of the worker applicationl to confirm the number of workers has increased. It may take time for them to fully come online
p 'juju status application kubernetes-worker --format=short'
cat mocks/scaled_up_status.txt

p ""




