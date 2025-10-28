# web-app
creating a web app with aws services, terraform, github and docker 

mkdir aws-devops-project
cd aws-devops-project
mkdir app
cd app
app.py

from flask import Flask
app = Flask(__name__)

@app.route('/')
def home():
    return "Hello from AWS DevOps Project using EC2 and GitHub Actions!"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
-------------------------------------------------------------------------------------------------
requirements.txt

flask
---------------------------------------------------------------------------------------
install docker
sudo yum install docker -y

create docker file
vim Dockerfile

FROM python:3.9-slim
WORKDIR /app
COPY app/ /app
RUN pip install -r requirements.txt
EXPOSE 5000
CMD ["python", "app.py"]
---------------------------------------------------------------------------

