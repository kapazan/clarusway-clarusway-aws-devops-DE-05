#!/bin/bash
apt-get update -y
apt-get install git -y
apt-get install python3 -y
cd /home/ubuntu/
TOKEN=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
git clone https://$TOKEN@github.com/okti3535/test-cap-project.git
cd /home/ubuntu/test-cap-project
apt install python3-pip -y
apt-get install python3.7-dev libmysqlclient-dev -y
pip3 install -r requirements.txt
cd /home/ubuntu/test-cap-project/src
python3 manage.py collectstatic --noinput
python3 manage.py makemigrations
python3 manage.py migrate
python3 manage.py runserver 0.0.0.0:80