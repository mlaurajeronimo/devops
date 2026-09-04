# Cluster Kubernetes local com Kind provisionado via Terraform

## 1. Visão geral

Este projeto provisiona, de forma totalmente automatizada via **Terraform**,
um cluster Kubernetes local utilizando o **Kind (Kubernetes in Docker)**.

- **Nome do cluster:** `devops`
- **Topologia:**
  - 1 node **control-plane** (responsável pelo gerenciamento do cluster)
  - 2 nodes **worker** (responsáveis por executar as cargas de trabalho/pods)

Todo o provisionamento é feito através do provider Terraform
[`tehcyx/kind`](https://registry.terraform.io/providers/tehcyx/kind/latest),
que por baixo dos panos utiliza a ferramenta Kind para subir cada node do
cluster como um container Docker. Não houve nenhuma criação manual do
cluster (via `kind create cluster`) — a definição da topologia (1
control-plane + 2 workers) está inteiramente descrita no arquivo `main.tf`.

## 2. Como o provisionamento funciona

O bloco `kind_config` dentro do recurso `kind_cluster.devops` define a
topologia do cluster no formato nativo do Kind (`kind.x-k8s.io/v1alpha4`),
com três blocos `node`:

- `role = "control-plane"` → 1 node
- `role = "worker"` → 2 nodes

Ao rodar `terraform apply`, o provider chama a API do Kind, que:

1. Sobe um container Docker para cada node definido (3 containers no total).
2. Instala e configura o Kubernetes dentro de cada container usando `kubeadm`.
3. Configura a rede entre os nodes e o acesso à API do cluster.
4. Gera um `kubeconfig` local, permitindo o uso do `kubectl` para interagir
   com o cluster recém-criado.

## 3. Principais componentes provisionados pelo Kind

Ao criar o cluster, o Kind provisiona automaticamente diversos componentes
padrão de um cluster Kubernetes funcional:

| Componente | O que faz |
|---|---|
| **kube-apiserver** | Ponto central de entrada do cluster. Recebe todas as requisições (via `kubectl`, por exemplo) e expõe a API do Kubernetes. |
| **etcd** | Banco de dados chave-valor distribuído que armazena todo o estado do cluster (configurações, objetos, secrets, etc.). Roda no node control-plane. |
| **kube-scheduler** | Decide em qual node cada novo pod deve ser executado, com base em recursos disponíveis, afinidades e restrições. |
| **kube-controller-manager** | Executa os "controllers" que garantem que o estado real do cluster corresponda ao estado desejado (ex.: recriar pods que caíram, gerenciar ReplicaSets, etc.). |
| **kubelet** | Agente que roda em cada node (control-plane e workers) e é responsável por garantir que os containers definidos nos pods estejam realmente em execução naquele node. |
| **kube-proxy** | Responsável pelas regras de rede em cada node, permitindo a comunicação entre pods e serviços (Services) dentro do cluster. |
| **CoreDNS** | Serviço de DNS interno do cluster, responsável por resolver nomes de Services/Pods para seus respectivos IPs internos. |
| **CNI (kindnet)** | Plugin de rede padrão do Kind, responsável por atribuir IPs aos pods e permitir a comunicação de rede entre eles em diferentes nodes. |
| **containerd** | Container runtime utilizado dentro de cada node (container Docker) para executar os containers dos pods. |
| **local-path-provisioner** | StorageClass padrão do Kind, que permite a criação dinâmica de volumes persistentes (PersistentVolumes) usando o disco local dos nodes. |

## 4. Topologia final do cluster

```
devops-control-plane   → role: control-plane
devops-worker           → role: worker
devops-worker2          → role: worker
```

Cada um desses "nodes" é, na prática, um container Docker rodando na máquina
host (neste caso, a VM VirtualBox onde o Docker está instalado).

## 5. Como validar o cluster

Após o `terraform apply`, o cluster pode ser validado com:

```bash
kubectl cluster-info --context kind-devops
kubectl get nodes -o wide
```

O resultado esperado é 3 nodes: 1 com a role `control-plane` e 2 sem role
específica (workers), todos com status `Ready`.

## 6. Estrutura dos arquivos

```
.
├── main.tf         # Definição do provider e do cluster Kind (1 control-plane + 2 workers)
├── outputs.tf       # Outputs úteis (nome do cluster, endpoint, kubeconfig)
├── README.md         # Este arquivo
└── evidencias/       # Prints comprovando a criação do cluster
```
