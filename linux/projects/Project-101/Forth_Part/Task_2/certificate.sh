#!/bin/bash

certificate=$(cat certificate.pem)

echo -e $certificate > new.pem