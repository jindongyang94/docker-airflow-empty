# docker-airflow

[![CI status](https://github.com/puckel/docker-airflow/workflows/CI/badge.svg?branch=master)](https://github.com/puckel/docker-airflow/actions?query=workflow%3ACI+branch%3Amaster+event%3Apush)
[![Docker Build status](https://img.shields.io/docker/build/puckel/docker-airflow?style=plastic)](https://hub.docker.com/r/puckel/docker-airflow/tags?ordering=last_updated)

[![Docker Hub](https://img.shields.io/badge/docker-ready-blue.svg)](https://hub.docker.com/r/puckel/docker-airflow/)

This repository contains **Dockerfile** of [apache-airflow](https://github.com/apache/incubator-airflow) for [Docker](https://www.docker.com/)'s [automated build](https://registry.hub.docker.com/u/puckel/docker-airflow/) published to the public [Docker Hub Registry](https://registry.hub.docker.com/).

## Pre-Requisites / Installation

* Based on Python (3.7-slim-stretch) official Image [python:3.7-slim-stretch](https://hub.docker.com/_/python/) and uses the official [Postgres](https://hub.docker.com/_/postgres/) as backend and [Redis](https://hub.docker.com/_/redis/) as queue
* Install [Docker](https://www.docker.com/)
* Install [Docker Compose](https://docs.docker.com/compose/install/)
* Following the Airflow release from [Python Package Index](https://pypi.python.org/pypi/apache-airflow)

## Build

Run < make build > to tag the current build as hubble/docker-airflow:latest.

## Usage

For **CeleryExecutor** :

    make compose

To kill the deployed containers:

    make kill

For encrypted connection passwords (in Local or Celery Executor), you must have the same fernet_key. By default docker-airflow generates the fernet_key at startup, you have to set an environment variable in the docker-compose (ie: docker-compose-LocalExecutor.yml) file to set the same key accross containers. To generate a fernet_key :

    docker run puckel/docker-airflow python -c "from cryptography.fernet import Fernet; FERNET_KEY = Fernet.generate_key().decode(); print(FERNET_KEY)"

## Configurating Airflow

It's possible to set any configuration value for Airflow from environment variables, which are used over values from the airflow.cfg.

The general rule is the environment variable should be named `AIRFLOW__<section>__<key>`, for example `AIRFLOW__CORE__SQL_ALCHEMY_CONN` sets the `sql_alchemy_conn` config option in the `[core]` section.

Check out the [Airflow documentation](http://airflow.readthedocs.io/en/latest/howto/set-config.html#setting-configuration-options) for more details

You can also define connections via environment variables by prefixing them with `AIRFLOW_CONN_` - for example `AIRFLOW_CONN_POSTGRES_MASTER=postgres://user:password@localhost:5432/master` for a connection called "postgres_master". The value is parsed as a URI. This will work for hooks etc, but won't show up in the "Ad-hoc Query" section unless an (empty) connection is also created in the DB

Global variables or secrets can be mounted onto the environment as **Environmental Variables** in Kubernetes to be accessed such as AWS Secret Keys etc under extraEnv in value.yaml file to be deployed in Kubernetes. For Docker-compose files, simply mount the variables as a volume.  

## Running other airflow commands

If you want to enter the containers in Bash Mode:

    make webserver / worker / scheduler

## Tag Docker in AWS ECR Docker Repository

The purpose of this section is to tag local docker builds into AWS ECR Docker Repository so as to be able to deploy on AWS Kubernetes (EKS).  
We are also assuming that you have the needed AWS credentials to access the repositories.  

To check the current tag of repository:

    make tag

To push the next tag number for the local build:

    make pushnext

For example, if the current tag number is 1.0.1, the next tag will be 1.0.2. The current repository will be built and be pushed to hubble/docker-airflow:1.0.2.  
Change the tag number in values.yaml to be updated to the next tag on Kubernetes.

## Local UI Links

* Airflow: [localhost:8080](http://localhost:8080/)
* Flower: [localhost:5555](http://localhost:5555/)

## Scale the number of workers

Easy scaling using docker-compose:

    docker-compose -f docker-compose-CeleryExecutor.yml scale worker=5
