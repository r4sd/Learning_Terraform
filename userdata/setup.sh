#!/usr/bin/env bash

amazon-linux-extras enable nginx1
yum clean metadata

yum install -y nginx

systemtl enable nginx

amazon-linux-extras disable nginx1

systemtl start nginx