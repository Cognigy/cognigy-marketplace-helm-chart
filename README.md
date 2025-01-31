# Cognigy.AI Marketplace Helm Chart

![Cognigy.AI banner](assets/cognigy-ai.png)

## Introduction

[Cognigy.AI](https://www.cognigy.com/) in an Enterprise Conversational Automation Platform for building advanced, integrated Conversational Automation Solutions through the use of cognitive bots.

[Cognigy.AI Marketplace](https://www.cognigy.com/platform/cognigy-marketplace) leverages extensive suite of ready-to-use channel connectors, third-party integrations, and multimodal applications to get the most out of Cognigy.AI.

A variety of pre-built Extensions can be installed with a single-click from the Cognigy Extension Marketplace, if configured.

More information can be found at the [official Cognigy.AI Marketplace page](https://www.cognigy.com/platform/cognigy-marketplace).

This Helm chart installs a Cognigy.AI Marketplace deployment on a [Kubernetes](https://kubernetes.io/) cluster using the [Helm](https://helm.sh/) package manager.

---

## Prerequisites
1. Kubernetes Cluster running on either of the following platforms:
  - AWS EKS ([Amazon Elastic Kubernetes Service](https://aws.amazon.com/eks/))
  - Azure AKS ([Azure Kubernetes Service](https://azure.microsoft.com/en-us/products/kubernetes-service))
  - "Generic" on-premises or [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine)

**NOTE:** Running Cognigy.AI Marketplace on-premises will require additional manual steps; it is recommended to use public clouds (AWS or Azure) instead.
2. `kubectl` and `helm` utilities connected to the Kubernetes cluster in administrative mode.
3. Kubernetes, kubectl and Helm versions as specified in [Version Compatibility Matrix](https://docs.cognigy.com/ai/installation/version-compatibility-matrix/).
4. (Optional) [git](https://git-scm.com/) binary to clone repository.

---

## Dependencies

- A stable version of Cognigy.AI deployed in the target cluster. See [Cognigy.AI Helm Chart](https://github.com/Cognigy/cognigy-ai-helm-chart) for details.

---

## Configuration

To deploy a new Cognigy.AI Marketplace setup, create a separate file with Helm release values. Refer to `values_prod.yaml` (see below) file as a baseline, as it is recommended to start with:

1. Clone the Cognigy.AI Marketplace git repository locally and browse to the repository directory.

    ```bash
    git clone https://github.com/Cognigy/cognigy-marketplace-helm-chart.git
    cd cognigy-marketplace-helm-chart
    ```

2. Make a copy of `values_prod.yaml` into a new file and name it accordingly. This custom values file is referred to as `YOUR_VALUES_FILE.yaml` later in this document.
3. **Do not make** a copy of default `values.yaml` file as it contains hardcoded docker images references for required services, and thus they need to be changed manually during upgrades. However, some variables from default `values.yaml` file can be added into the `YOUR_VALUES_FILE.yaml` later on for customization.
4. Create a dedicated namespace to deploy Cognigy.AI Marketplace using `kubectl` utility using below command (replace '`TARGET_NAMESPACE`' with your own, e.g. 'marketplace'):

    ```bash
    kubectl create namespace TARGET_NAMESPACE
    ```

   - This namespace is referred to as `TARGET_NAMESPACE` later in this document.

5. A secret named `cognigy-registry-token` is expected to be present in `TARGET_NAMESPACE` containing credentials for connecting to Cognigy's image registry. If it is not already present, it can be created using the following command using `kubectl` utility:

    ```bash
    kubectl create secret docker-registry cognigy-registry-token \
    --docker-server=cognigy.azurecr.io \
    --docker-username=<your-username> \
    --docker-password=<your-password> -n TARGET_NAMESPACE
    ```

   - **Note:** Make sure to replace `<your-username>` and `<your-password>` with your own credentials.
   - If `cognigy-registry-token` secret is not used, refer to existing secret by setting the secret's name in `image.imagePullSecret` key in `YOUR_VALUES_FILE.yaml` file.

---

### Setting Essential Parameters

The following parameters needs to be set as a bare minimum in `YOUR_VALUES_FILE.yaml` to get started:

1. `replicaCount`: Set the number of pod replicas for Marketplace deployment. Recommended: at least `3`.
2. Ingress:
   1. By default, ingress is enabled (`.ingress.enabled: true`) and `ingressClassName: traefik` is set.
   2. Set the marketplace hostname (FQDN) in `.ingress.host` key.
   3. Custom CA Certificate and Private Key:
      1. Both `ingress.enabled` and `ingress.tls.enabled` must be enabled (set value to `true`) for this to work.
      2. To use Custom CA certificate and private key, provide the contents of the certificate as plain text in `ingress.tls.crt` key and private key in `ingress.tls.key` key. Refer to notes in `values.yaml` file under `ingress.tls` key for example format. A 'secret' will be created based on these custom values in `TARGET_NAMESPACE`.
      3. Existing TLS certificate and private key can be re-used, which must exist in the cluster as a 'secret' of type TLS in the `TARGET_NAMESPACE` (see reference: [TLS Secrets](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)). Refer to key `ingress.tls.existingSecret` in `values.yaml` file.

        **Note: Make sure to install a publicly trusted TLS certificate signed by a Certificate Authority. Although using of self-signed certificates is possible in test environments, Cognigy does not recommend usage of self-signed certificates, does not guarantee full compatibility with associated products and will not support such installations.**

---

### Installing the Chart

Follow the below instructions to install the chart:

1. Determine which version of helm chart (`HELM_CHART_VERSION`) to install as it will be used in next step. The chart version can be determined from the 'tags' in the git repository.
2. Install Cognigy.AI Marketplace Helm release:
   1. Login into Cognigy helm registry (provide your Cognigy Container Registry credentials):

        ```bash
        helm registry login cognigy.azurecr.io \
            --username <your-username>  \
            --password <your-password>
        ```

   2. Install Helm Chart in the `TARGET_NAMESPACE` namespace:

        ```bash
        # installing helm chart
        helm upgrade --install marketplace \
            --namespace TARGET_NAMESPACE --create-namespace \
            --version HELM_CHART_VERSION \
            --values YOUR_VALUES_FILE.yaml \
            oci://cognigy.azurecr.io/helm/marketplace-server-backend
        ```

   3. Alternatively, you can install it from the local chart (not recommended):

        ```bash
        helm upgrade --install marketplace \
            --namespace TARGET_NAMESPACE --create-namespace \
            --version HELM_CHART_VERSION \
            --values YOUR_VALUES_FILE.yaml .
        ```

3. Verify that all pods are in a ready state (wait for 2-5 minutes before executing this command):

    ```bash
    kubectl get pods --namespace TARGET_NAMESPACE

    # Check ingress status, if enabled
    kubectl get ingress --namespace TARGET_NAMESPACE
    ```

It's expected that all pods managed by the marketplace deployment are in '*Running*' state, along with one active service in the `TARGET_NAMESPACE`.

---

### Upgrading Helm Release

To upgrade Cognigy.AI Marketplace release a newer version, upgrade the existing Helm release to a particular helm chart version (`HELM_CHART_VERSION`). This can be achieved using the following command:

```bash
# upgrading helm chart to newer version
helm upgrade --install marketplace \
    --namespace TARGET_NAMESPACE --create-namespace \
    --version HELM_CHART_VERSION \
    --values YOUR_VALUES_FILE.yaml \
    oci://cognigy.azurecr.io/helm/marketplace-server-backend
```

The same can be achieved by downloading the new chart files, unzipping the files locally and running following command (not recommended) in the uncompressed files' directory:

```bash
helm upgrade --install marketplace \
    --namespace TARGET_NAMESPACE --create-namespace \
    --version HELM_CHART_VERSION \
    --values YOUR_VALUES_FILE.yaml .
```

---

### Modifying Resources

Default resources for Cognigy.AI Marketplace microservices specified in `values.yaml` are tailored to provide consistent performance for typical production use-cases. However, to meet specific demands, users can modify Memory/CPU resources or number of replicas. For this, copy specific variables from default `values.yaml` into `YOUR_VALUES_FILE.yaml` for the microservice and adjust the `Request/Limits` and `replicaCount` values accordingly.

---

### Uninstalling the Release

To uninstall a Cognigy.AI Marketplace helm release, execute the following:

```bash
helm uninstall --namespace TARGET_NAMESPACE marketplace
```

---

### Clean-up

Note that Secrets are not removed when Helm release is deleted.

To fully remove secrets, run the following command:

```bash
kubectl delete --namespace cognigy-ai secrets --all
```

---
