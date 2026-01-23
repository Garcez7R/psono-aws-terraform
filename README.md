# Psono Server – Lab AWS / On-Premise

> Estudo de caso profissional: Implantação de gerenciador de senhas corporativo open-source com foco em segurança, automação e reprodutibilidade.

---

## 🎯 Objetivo

Estabelecer uma infraestrutura de **gerenciamento centralizado de credenciais** para pequenas e médias empresas (PMEs) ou times DevOps, utilizando **Psono Server** (solução open-source), combinando:

- **Lab local** para validação rápida
- **Infraestrutura como Código (Terraform)** para reprodutibilidade
- **Deployment em AWS** com boas práticas de segurança
- **Documentação profissional** e runbooks operacionais

---

## 📊 Arquitetura

### Versão Inicial (Lab + Phase 1/2/3)

```
┌─────────────────────────────────────────────────────────────┐
│                      Usuário/Admin                          │
└─────────────────────┬───────────────────────────────────────┘
                      │ SSH Key-Based
┌─────────────────────▼───────────────────────────────────────┐
│            EC2 Instance (Ubuntu Server)                      │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Docker Compose                                      │   │
│  │  ┌─────────────────────────────────────────────────┐ │   │
│  │  │  Psono Server (nginx, gunicorn, postgres)       │ │   │
│  │  │  - API REST                                      │ │   │
│  │  │  - Web UI                                        │ │   │
│  │  │  - Gerenciamento de credenciais                │ │   │
│  │  └─────────────────────────────────────────────────┘ │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  Security Groups:                                            │
│  - SSH (22): restrito a IP específico                       │
│  - HTTP (80): bloqueado (HTTPS em futuro)                  │
│  - HTTPS (443): bloqueado (futuro)                         │
│  - Postgres (5432): apenas container interno              │
└──────────────────────────────────────────────────────────────┘
```

### Versão Futura (Produção)

- VPC dedicada com subnets pública/privada
- NAT Gateway + bastion host
- Application Load Balancer (ALB)
- HTTPS/TLS certificados
- Integração com AWS KMS para chaves de criptografia
- CloudWatch + logs estruturados
- Backup automatizado RDS

---

## 🚀 Fases de Execução

### ✅ Fase 1: Setup Local + Aplicação
**Objetivo:** Validar Psono em VM local antes de AWS

- [ ] VM Ubuntu Server puro (VirtualBox/KVM)
- [ ] Usuário administrativo não-root com SSH key
- [ ] Docker + Docker Compose instalados
- [ ] Psono Server rodando em containers
- [ ] Acesso funcional à interface web

**Saída:** Lab local funcional, pronto para testes

---

### ✅ Fase 2: Infraestrutura como Código (IaC)
**Objetivo:** Terraform reproducível com EC2 + VPC default

- [ ] Estrutura Terraform: variables, outputs, resources
- [ ] EC2 com AMI Ubuntu 22.04 LTS
- [ ] VPC default + Security Groups restritos
- [ ] IAM Role para EC2 (princípio do menor privilégio)
- [ ] User-data script para bootstrap automatizado
- [ ] Deploy totalmente automatizado (`terraform apply`)

**Saída:** Stack AWS completo gerenciável via código

---

### ✅ Fase 3: Deploy AWS + Validação
**Objetivo:** Executar stack completo em produção com evidências

- [ ] Deploy em ambiente AWS
- [ ] Validação de containers rodando
- [ ] Acesso seguro via SSH
- [ ] Psono acessível e funcional
- [ ] Logs operacionais documentados

**Saída:** Infraestrutura pronta para produção com documentação

---

## 📋 Pré-requisitos

### Local (Fase 1)
- VirtualBox 6.1+ ou KVM/libvirt
- Ubuntu Server 22.04 LTS (ISO)
- Docker 20.10+
- Docker Compose 2.0+
- Git

### AWS (Fase 2/3)
- Conta AWS com billing ativo
- AWS CLI v2 configurado
- Terraform 1.0+
- Chave SSH criada (ou criar via script)

### Geral
- Conhecimento básico de Linux/bash
- Familiaridade com Docker/containers
- Noções de Terraform

---

## 🏗️ Estrutura do Repositório

```
PsOno/
├── README.md                  # Este arquivo
├── tracker.md                 # Checklist detalhado
│
├── terraform/                 # Infraestrutura AWS (Terraform)
│   ├── main.tf               # Recursos principais
│   ├── variables.tf          # Variáveis de entrada
│   ├── outputs.tf            # Outputs (IP, URL, etc)
│   ├── security.tf           # Security Groups + IAM
│   └── terraform.tfvars.example  # Template de variáveis
│
├── docker/                    # Docker Compose + Dockerfiles
│   ├── docker-compose.yml    # Stack Psono (nginx, gunicorn, postgres)
│   ├── .env.example          # Variáveis de ambiente (template)
│   ├── nginx/
│   │   └── nginx.conf        # Configuração nginx (reverse proxy)
│   └── psono/
│       └── settings.json     # Configuração Psono
│
├── scripts/                   # Utilitários e automação
│   ├── bootstrap.sh          # User-data para EC2
│   ├── first-login.sh        # Roteiro primeiro acesso
│   ├── backup.sh             # Backup de credenciais
│   └── health-check.sh       # Verificação de saúde
│
├── docs/                      # Documentação técnica
│   ├── SECURITY.md           # Política de segurança
│   ├── DEPLOYMENT.md         # Guia de deploy passo-a-passo
│   ├── OPERATIONS.md         # Runbook operacional
│   ├── TROUBLESHOOTING.md    # Resolução de problemas
│   └── ARCHITECTURE.md       # Detalhes de arquitetura
│
├── .github/workflows/        # CI/CD (futuro)
│   └── lint.yml             # Validação Terraform + Docker
│
└── .gitignore                # Não versionar segredos/estados

```

---

## 🔐 Segurança

### Princípios Aplicados

1. **Autenticação SSH**: Apenas chave pública, sem senhas
2. **Privilégios Mínimos**: Usuário não-root, IAM Role restrita
3. **Isolation**: Containers isolados, postgres apenas interno
4. **Variáveis de Ambiente**: Segredos via `.env`, nunca no código
5. **Auditoria**: Logs estruturados de acesso e operações
6. **Não Versionado**: `.tfstate`, `.env`, chaves SSH em `.gitignore`

### Diferenças Lab vs Produção

| Aspecto | Lab | Produção |
|--------|-----|----------|
| TLS/HTTPS | Não | Sim (ACM) |
| Acesso Web | Aberto (HTTP) | Restrito (ALB + SG) |
| Database | SQLite/Postgres local | RDS Postgres |
| Backup | Manual | Automatizado + snapshots |
| Monitoramento | Logs básicos | CloudWatch + alertas |
| Encriptação | Em repouso | Em repouso + KMS |

---

## 🚀 Quick Start

### Fase 1: Local

```bash
# Clonar repositório
git clone <repo-url>
cd PsOno

# Criar VM Ubuntu Server (fora deste repo - VirtualBox/KVM)
# Instalar Docker e Docker Compose na VM

# Deploy Psono
cd docker
cp .env.example .env
# Editar .env com credenciais iniciais
docker-compose up -d

# Acessar
# Abrir http://localhost em browser local
# Credenciais iniciais: admin / <senha-em-.env>
```

### Fase 2/3: AWS

```bash
# Configurar AWS CLI
aws configure

# Personalizar variáveis
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars (SSH key, região, etc)

# Deploy
terraform init
terraform plan
terraform apply

# Output
terraform output
# Salvar IP e URL fornecidos
```

---

## 📖 Documentação Detalhada

- **[Deployment](docs/DEPLOYMENT.md)** – Passo-a-passo completo
- **[Operations](docs/OPERATIONS.md)** – Runbooks do dia-a-dia
- **[Security](docs/SECURITY.md)** – Políticas de segurança
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** – Resolução de problemas
- **[Architecture](docs/ARCHITECTURE.md)** – Detalhes técnicos

---

## 🎓 Aprendizado e Impacto

Este projeto demonstra:

✅ **DevOps Moderno**: Terraform, Docker, CI/CD  
✅ **Segurança em Nuvem**: IAM, Security Groups, secrets management  
✅ **Automation**: Bootstrap totalmente automatizado  
✅ **Reprodutibilidade**: Mesmo resultado em qualquer ambiente  
✅ **Documentação Profissional**: Adequada para equipes reais  
✅ **Aplicabilidade Real**: Solução funcional para PMEs/times  

---

## 🗺️ Roadmap Futuro

- [ ] VPC dedicada com subnets pública/privada
- [ ] NAT Gateway + bastion host
- [ ] Application Load Balancer (ALB)
- [ ] HTTPS/TLS com AWS Certificate Manager
- [ ] Amazon RDS (Postgres gerenciado)
- [ ] AWS KMS para encriptação de chaves
- [ ] CloudWatch + log aggregation
- [ ] Backup automatizado + disaster recovery
- [ ] Auto Scaling Groups
- [ ] Helm charts para Kubernetes (futuro)

---

## 📝 Changelog

**v1.0** (Jan 2026) – Release inicial
- Lab local + IaC Terraform
- Deploy AWS com VPC default
- Documentação completa
- Security Groups e IAM restritos

---

## 📧 Contato & Suporte

Para dúvidas ou melhorias, abra uma issue no repositório ou entre em contato.

---

## 📄 Licença

Este projeto é fornecido como estudo de caso. Psono Server é open-source sob licença AGPL v3.

---

**Última atualização:** 20 de janeiro de 2026
