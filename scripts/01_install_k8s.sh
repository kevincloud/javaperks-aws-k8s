#!/bin/bash

#
# Create the AWS cloud controller manager
#
sudo bash -c "cat >>/root/controller.yaml" <<EOT
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cloud-controller-manager
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:cloud-controller-manager
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: cloud-controller-manager
  namespace: kube-system
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  labels:
    k8s-app: cloud-controller-manager
  name: cloud-controller-manager
  namespace: kube-system
spec:
  selector:
   matchLabels:
    k8s-app: cloud-controller-manager
  template:
    metadata:
      labels:
        k8s-app: cloud-controller-manager
    spec:
      serviceAccountName: cloud-controller-manager
      containers:
      - name: cloud-controller-manager
        image: jubican/aws-cloud-controller-manager:1.0.0
        command:
        - /bin/aws-cloud-controller-manager
        - --leader-elect=true
      tolerations:
      - key: node.cloudprovider.kubernetes.io/uninitialized
        value: "true"
        effect: NoSchedule
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      nodeSelector:
        node-role.kubernetes.io/master: ""
EOT

#
# Create the init config for k8s
#
sudo bash -c "cat >>/root/init.yaml" <<EOT
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: abcdef.0123456789abcdef
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
localAPIEndpoint:
  advertiseAddress: $CLIENT_IP
  bindPort: 6443
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  name: $AWS_HOSTNAME
  kubeletExtraArgs:
    cloud-provider: aws
  taints:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
apiServer:
  timeoutForControlPlane: 4m0s
  extraArgs:
    cloud-provider: aws
certificatesDir: /etc/kubernetes/pki
clusterName: javaperks
controllerManager:
  extraArgs:
    cloud-provider: aws
dns:
  type: CoreDNS
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: k8s.gcr.io
networking:
  dnsDomain: cluster.local
  serviceSubnet: 10.96.0.0/12
scheduler: {}
EOT

#
# Initialize Kubernetes
#
kubeadm init --config /root/init.yaml > /root/init.txt
echo 'KUBELET_EXTRA_ARGS="--cloud-provider=aws"' > /etc/default/kubelet
service kubelet restart

# Set user settings
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# Get join command
cat /root/init.txt | tail -2 > /root/kubeadm-join.txt

export KUBEJOIN="$(cat /root/kubeadm-join.txt | sed -e ':a;N;$!ba;s/ \\\n    / /g')"
export KUBECONFIG=/etc/kubernetes/admin.conf
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /root/.profile
alias k=kubectl
echo "alias k=kubectl" >> /root/.profile

# add in CNI, storage class, and controller
mkdir -p /etc/cni/net.d
mkdir -p /opt/cni/bin
sysctl net.bridge.bridge-nf-call-iptables=1
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
kubectl apply -f "https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/storage-class/aws/default.yaml"
kubectl apply -f "/root/controller.yaml"
kubectl apply -f "https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc7/aio/deploy/recommended.yaml"

# Wait until all pods are healthy
while [[ ! -z $(kubectl get pods --all-namespaces | sed -n '1d; /Running/ !p') ]]; do
    sleep 5
done

# Allow access to the admin dashboard
kubectl patch deployment kubernetes-dashboard -n kubernetes-dashboard --type="json" -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/ports/0/containerPort", "value": 9090}]'
kubectl patch deployment kubernetes-dashboard -n kubernetes-dashboard --type="json" -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": ["--enable-skip-login", "--disable-settings-authorizer", "--namespace=kubernetes-dashboard", "--insecure-bind-address=0.0.0.0", "--insecure-port=9090", "--enable-insecure-login"]}]'
kubectl patch deployment kubernetes-dashboard -n kubernetes-dashboard --type="json" -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/livenessProbe/httpGet", "value": {"scheme": "HTTP", "path": "/", "port": 9090}}]'
kubectl patch service kubernetes-dashboard -n kubernetes-dashboard --type="json" -p='[{"op": "replace", "path": "/spec/ports/0/port", "value": 9090}]'
kubectl patch service kubernetes-dashboard -n kubernetes-dashboard --type="json" -p='[{"op": "replace", "path": "/spec/ports/0/targetPort", "value": 9090}]'
kubectl patch service kubernetes-dashboard -n kubernetes-dashboard -p '{"spec":{"type": "LoadBalancer"}}'

sudo bash -c "cat >/root/update-dash-role.yaml" <<EOT
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kubernetes-dashboard
  labels:
    k8s-app: kubernetes-dashboard
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
EOT

kubectl delete clusterrolebinding kubernetes-dashboard -n kubernetes-dashboard
kubectl apply -f /root/update-dash-role.yaml
kubectl delete pod -n kubernetes-dashboard $(kubectl get pods -n kubernetes-dashboard | grep kubernetes-dashboard | awk '{print $1}')

# # Create an admin user
# sudo bash -c "cat >/root/javaperks-admin-sa.yaml" <<EOT
# apiVersion: v1
# kind: ServiceAccount
# metadata:
#   name: javaperks-admin
#   namespace: default
# EOT

# sudo bash -c "cat >/root/javaperks-admin.yaml" <<EOT
# apiVersion: rbac.authorization.k8s.io/v1
# kind: ClusterRoleBinding
# metadata:
#   name: javaperks-admin
# roleRef:
#   apiGroup: rbac.authorization.k8s.io
#   kind: ClusterRole
#   name: cluster-admin
# subjects:
#   - kind: ServiceAccount
#     name: javaperks-admin
#     namespace: default
# EOT

# kubectl apply -f /root/javaperks-admin-sa.yaml
# kubectl apply -f /root/javaperks-admin.yaml

# export SA_NAME="javaperks-admin"
# kubectl describe secret $(kubectl get secret | grep ${SA_NAME} | awk '{print $1}')

#
# Publish join command
# get node info back to patch them from the master
#
touch /root/patchnodes.sh
sudo bash -c "cat >/root/ready.py" <<EOT
from flask import Flask
from flask import request

app = Flask(__name__)

@app.route('/')
def hello():
    az = request.args.get("az")
    iid = request.args.get("id")
    host = request.args.get("host")
    f = open("/root/patchnodes.sh", "a")
    f.write("kubectl patch node "+host+" -p '{\"spec\":{\"providerID\":\"aws:///"+az+"/"+iid+"\"}}'\n")
    f.close()
    return "$KUBEJOIN"

if __name__ == '__main__':
    app.run(host='0.0.0.0')
EOT

python3 /root/ready.py &

# Wait until all nodes are healthy
while [[ ! -z $(kubectl get nodes | sed -n '1d; /NotReady/ p') ]]; do
    sleep 5
done

# Patch each node
sleep 30
chmod +x /root/patchnodes.sh
/root/patchnodes.sh

# create config map for env values
kubectl create configmap env-values \
    --from-literal=mysql-host="${MYSQL_HOST}" \
    --from-literal=mysql-user="${MYSQL_USER}" \
    --from-literal=mysql-db="${MYSQL_DB}" \
    --from-literal=aws-access-key="${AWS_ACCESS_KEY}" \
    --from-literal=aws-region="${AWS_REGION}" \
    --from-literal=s3-bucket="${S3_BUCKET}" \
    --from-literal=table-product="${TABLE_PRODUCT}" \
    --from-literal=table-cart="${TABLE_CART}" \
    --from-literal=table-order="${TABLE_ORDER}" \
    --from-literal=ldap-admin-user="${LDAP_ADMIN_USER}"

kubectl create secret generic env-secret-values \
    --from-literal=mysql-pass="${MYSQL_PASS}" \
    --from-literal=aws-secret-key="${AWS_SECRET_KEY}" \
    --from-literal=aws-kms-key-id="${AWS_KMS_KEY_ID}" \
    --from-literal=vault-license="${VAULT_LICENSE}" \
    --from-literal=consul-license="${CONSUL_LICENSE}" \
    --from-literal=ldap-admin-pass="${LDAP_ADMIN_PASS}" \


# Install helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
