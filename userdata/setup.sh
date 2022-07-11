#!/usr/bin/env bash

yum clean metadata
yum install -y httpd
systemtl enable httpd
systemtl start httpd