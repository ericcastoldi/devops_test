# Get Ninjas DevOps Test - Answers  [![Build Status](https://app.travis-ci.com/ericcastoldi/devops_test.svg?branch=master)](https://app.travis-ci.com/ericcastoldi/devops_test)

## Cenário
Temos no repo https://github.com/getninjas/devops_test uma aplicação muito simples, uma API rest escrita em Golang, que atualmente só responde à rota `/healthcheck`. Essa aplicação, em compliance com o item III do 12factor app, espera alguns **parametros via ambiente** para rodar corretamente.
Outro ponto importante é que este código tem **cobertura de testes***.

## Objetivos
Dado o Cenário acima queremos que você faça o seguinte:

#### 1. Deploy da aplicação na AWS.

http://k8s-prod-getninja-e1c9510450-56777961.us-east-1.elb.amazonaws.com/healthcheck

#### 2. Crie uma forma que possamos subir essa aplicação localmente de forma simples.

Criei um Dockerfile multistage que realiza o build da aplicação e resulta em uma imagem que executa a aplicação. Para subir a aplicação localmente basta ter o `docker` instalado e executar os comandos abaixo no diretório raiz do repositório.

```sh
docker build --tag get-ninjas-api .
docker run -p 8000:8000  get-ninjas-api

curl -i http://localhost:8000/healthcheck
HTTP/1.1 200 OK
Date: Tue, 13 Sep 2022 22:02:11 GMT
Content-Length: 24
Content-Type: text/plain; charset=utf-8

Hey Bro, Ninja is Alive!%
```

#### 3. Coloque esta aplicação em um fluxo de CI que realize teste neste código

Utilizei o Travis CI para criar uma pipeline com os jobs:

- Testes: https://app.travis-ci.com/github/ericcastoldi/devops_test/jobs/582979443
- Build: https://app.travis-ci.com/github/ericcastoldi/devops_test/jobs/582979444
- Build + Push da Imagem Docker: https://app.travis-ci.com/github/ericcastoldi/devops_test/jobs/582979445
- Plan do Deploy da Infra via Terraform: https://app.travis-ci.com/github/ericcastoldi/devops_test/jobs/582979446

#### 4. Altere o nome da aplicação.

O nome da aplicação é definido pela variável de ambiente `APP_NAME`, desta forma, podemos executar a imagem construída no passo anterior passando um novo valor para a variável de ambiente `APP_NAME` conforme exemplo abaixo: 

```sh
docker build --tag get-ninjas-api .
docker run -p 8000:8000 -e APP_NAME="Ninja API" get-ninjas-api

curl -i http://localhost:8000/healthcheck
HTTP/1.1 200 OK
Date: Tue, 13 Sep 2022 22:09:43 GMT
Content-Length: 24
Content-Type: text/plain; charset=utf-8

Hey Bro, Ninja API is Alive!%
```

#### 5. Discorra qual (ou quais) processos você adotaria para garantir uma entrega contínua desta aplicação, desde o desenvolvimento, até a produção.

- Versionamento do repositório, das imagens docker e de todo possivel artefato versionável (libs, modulos terraform, etc)
- Validação de percentual de cobertura de testes
- Adoção de ferramenta de análise estática de código fonte (Sonarqube)
- Ferramentas de validação de vulnerabilidades em imagens docker
- Ferramentas de validação de vulnerabilidades nas libs utilizadas no projeto
- Processo de Pull Request + Code Review
- Automação do processo de release (versionamento/publicação de pacotes/imagens docker)
- Adoção de um ambiente de testes 
- Automação do processo de deploy em testes
- Automação do rollback de uma versão aplicada
- Adoção de estratégias como blue/green ou canary para deploy em produção
