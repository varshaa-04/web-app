

 **Flask Web App with AWS DevOps CI/CD Pipeline**

This project demonstrates a complete DevOps pipeline for deploying a containerized Flask web application on AWS EC2 using GitHub Actions, Docker, Terraform, and Amazon ECR.

 Tech Stack

- **Flask** – Lightweight Python web framework
- **Docker** – Containerization of the app
- **Amazon ECR** – Docker image registry
- **AWS EC2** – Hosting the container
- **Terraform** – Infrastructure as Code
- **GitHub Actions** – CI/CD automation

---

** Architecture Overview**

```plaintext
GitHub → GitHub Actions → Docker → Amazon ECR → EC2 (via SSH)
aws-devops-project/
├── app.py
├── Dockerfile
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── .github/
    └── workflows/
        └── deploy.yml



✅ Built and pushed your Docker image to Amazon ECR

✅ Manually pulled and ran the container on an EC2 instance

✅ Used GitHub Actions to automate the deployment via SSH


1. Clone the Repository
bash
git clone https://github.com/varshaa-04/web-app.git
cd web-app

-------------------------------------------------------------------

2. Provision Infrastructure with Terraform
bash
cd terraform
terraform init
terraform apply
This creates:

**EC2 instance
Security group (port 5000 open)
IAM roles
ECR**

----------------------------------------------------------

3. Build and Push Docker Image to ECR
bash
docker build -t myapp .
docker tag myapp <your-ecr-uri>:latest
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <your-ecr-uri>
docker push <your-ecr-uri>:latest

-------------------------------------------------------------------

4. Configure GitHub Actions
Add your AWS credentials and EC2 SSH key as GitHub secrets

Ensure your .github/workflows/deploy.yml is correctly set up

------------------------------------------------------------------------------

5. Trigger Deployment
bash
git add .
git commit -m "Trigger deployment"
git push origin main
GitHub Actions will:

Build and push Docker image

SSH into EC2

Pull and run the container

Access the App
Visit:
Code
http://<your-ec2-public-ip>:5000

--------------------------------------------------------------

✅ Features
Automated CI/CD pipeline

Containerized Flask app

Infrastructure as Code with Terraform

Secure deployment via GitHub Actions and SSH
----------------------------------------------------------------

git clone https://github.com/varshaa-04/web-app.git
cd web-app






mkdir aws-devops-project
cd aws-devops-project
mkdir app
cd app
app.py

------------------------------------------------------
app python code
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
---------------------------------------------------------------------
# docker file
FROM python:3.9-slim
WORKDIR /app
COPY app/ /app
RUN pip install -r requirements.txt
EXPOSE 5000
CMD ["python", "app.py"]
---------------------------------------------------------------------------

