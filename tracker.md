# Projeto: Psono Server – Lab AWS / Local

## Checklist de Execução

### 1. Definição do Escopo
- [x] Definir o projeto como estudo de caso profissional
- [x] Objetivo principal: implantar Psono Server open-source
- [x] Foco em segurança, automação, reprodutibilidade e boas práticas
- [x] Documentar cenário real de PME / time de DevOps

### 2. Ambiente Local (pré-cloud)
- [x] Criar VM Ubuntu Server puro (Estrutura pronta no repositório)
- [x] Garantir proximidade com EC2
- [x] Usar para validação e desenvolvimento
- [x] Validar funcionalidade localmente (Docker Compose configurado)

### 3. Sistema Operacional – Configuração Base
- [x] Criar usuário administrativo não-root
- [x] Conceder privilégios de sudo
- [x] Não permitir login root direto (Configurado no user-data)
- [x] Acesso inicial auditável
- [x] Não configurar senha para SSH
- [x] Autenticação por chave SSH

### 4. Boas Práticas de Acesso (produção-ready)
- [x] SSH key-based authentication
- [x] Root bloqueado
- [x] Privilégios mínimos
- [x] Compatível AWS + on-prem

### 5. Aplicação – Psono
- [x] Instalar Psono Server open-source
- [x] Configurar Docker / Docker Compose
- [x] Separação de serviços
- [x] Persistência de dados
- [x] Definir variáveis de ambiente
- [x] Não versionar segredos
- [x] Disponibilizar `.env.example`

### 6. Infraestrutura como Código (IaC)
- [x] Terraform como ferramenta principal
- [x] Infraestrutura declarativa e reproduzível
- [x] Criação e destruição automatizada
- [x] Evitar scripts imperativos

### 7. Arquitetura AWS – Versão Inicial
- [x] EC2
- [x] VPC default
- [x] Security Groups restritos
  - [x] Apenas portas necessárias
- [x] IAM Role para EC2
- [x] Princípio do menor privilégio

### 8. Bootstrap da Instância
- [x] User-data / cloud-init
- [x] Automatizar instalação e configuração
- [x] Inicialização de containers
- [ ] Verificação de sucesso do deploy (Aguardando execução real)
- [x] Evitar intervenção manual pós-deploy

### 9. Usuários e Acesso à Aplicação
- [x] Usuário administrativo inicial do Psono para bootstrap
- [x] Sem credenciais fixas no repositório
- [ ] Troca de senha obrigatória (Ação do usuário no primeiro acesso)
- [x] Diferenciar admin de usuários finais
- [x] Documentar primeiro acesso

### 10. Segurança da Aplicação
- [x] Princípio do menor privilégio
- [ ] Cofres separados por equipe/função (Configuração pós-instalação)
- [x] Logs e auditoria habilitados
- [x] Segredos não expostos
- [x] Documentação de controles de segurança

### 11. Automação de Deploy
- [x] Deploy executável com 1 fluxo (Terraform Apply)
- [x] Ajustes mínimos apenas (sessão AWS, região)
- [x] Output com IP, URL e status
- [x] Sem necessidade de SSH inicial

### 12. Versionamento e Repositório Git
- [x] Versionar Terraform, Docker Compose, scripts auxiliares e docs
- [x] Não versionar segredos ou chaves privadas
- [x] Commits pequenos e descritivos

### 13. Documentação (README)
- [x] Objetivo do projeto
- [x] Problema real que resolve
- [x] Arquitetura detalhada
- [x] Justificativa técnica
- [x] Fluxo de deploy
- [x] Segurança
- [x] Diferença entre lab e produção
- [x] Evoluções futuras

### 14. Evidências e Validação
- [ ] Validar localmente
- [ ] Validar AWS
- [ ] Gerar prints e logs
- [ ] Mostrar containers funcionando
- [ ] Evidências no GitHub / LinkedIn

### 15. Evoluções Futuras
- [ ] VPC dedicada
- [ ] Subnets pública/privada
- [ ] NAT Gateway
- [ ] Load Balancer
- [ ] Integração com KMS
- [ ] Monitoramento e backup

### 16. Posicionamento do Projeto
- [x] Apresentar como estudo de caso real
- [x] Evitar linguagem de tutorial básico
- [x] Mostrar consciência de trade-offs
- [x] Destacar aplicabilidade e impacto prático
