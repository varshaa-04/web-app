
** Quick overview — what we are building and why**

- Goal: Build a small Flask app, containerize it with Docker, publish the image to Amazon ECR, provision EC2 and related resources with Terraform, and automate image build + deployment with GitHub Actions (CI/CD). The EC2 instance will pull the image and run the container (serving on port 5000).
- Why: This pipeline demonstrates containerized app deployment, Infrastructure as Code (Terraform), and CI/CD automation (GitHub Actions).
-------------------------------------------------------------------------------------------------------------------------------
** Prerequisites (what you need locally and on AWS)**

- Local tools:
  - Git
  - Docker (engine and CLI)
  - Python (3.9 recommended for local testing)
  - AWS CLI v2 configured (aws configure)
  - Terraform (recommended v1.x)
  - An SSH client and an SSH key pair for EC2 access
- AWS account:
  - Permission to create IAM resources, ECR repositories, EC2 instances, security groups, and key pairs.
- GitHub:
  - A GitHub repository (you already have web-app).
  - Ability to add repository secrets (in Settings → Secrets).

-------------------------------------------------------------------------------------------------

** Repo layout — what each file/folder is and why**

- app.py — the Flask application entrypoint; exposes route '/' that returns a message.
- requirements.txt — Python dependencies (flask).
- Dockerfile — instructions to create a Docker image containing the app.
- terraform/ — contains Terraform configs:
  - main.tf — resources definitions (EC2 instance, security group, IAM role/policies, ECR repo, etc.).
  - variables.tf — Terraform variables and their defaults/placeholders.
  - outputs.tf — values Terraform will output after apply (like EC2 public IP, ECR URL).
- .github/workflows/deploy.yml — GitHub Actions workflow that builds the Docker image, pushes to ECR, and triggers deployment (SSH to EC2 and runs docker pull + run).
- README.md — high-level instructions (we’re expanding this).

------------------------------------------------------------------------------

** Local development — run the Flask app locally**
- Steps:
  1. Clone repo:
     - git clone https://github.com/varshaa-04/web-app.git
     - cd web-app
  2. Install dependencies:
     - pip install -r requirements.txt
  3. Run the app:
     - python app.py
     - The app listens on localhost:5000 by default (app.run host=0.0.0.0 in the repo makes it accessible to container/VM).
  4. Verify:
     - Open http://127.0.0.1:5000 or http://localhost:5000 in a browser and you should see "Hello from AWS DevOps Project using EC2 and GitHub Actions!"

---------------------------------------------------------------------------------------------

** Create the Dockerfile (explanation of each line)**
- Example Dockerfile (from repo):
  - FROM python:3.9-slim — uses a lightweight Python 3.9 base image.
  - WORKDIR /app — sets working dir in the container to /app.
  - COPY app/ /app — copies your application code into the image.
  - RUN pip install -r requirements.txt — installs dependencies inside the image (ensure requirements.txt is copied too if needed).
  - EXPOSE 5000 — documents that container listens on port 5000.
  - CMD ["python", "app.py"] — default command to run when container starts.
- Notes:
  - If requirements.txt is at repo root (and COPY app/ only copies app folder), ensure Dockerfile copies requirements.txt too (COPY requirements.txt /app/ or copy entire repo).
  - Keep image small: use slim or alpine base images but be careful of compatibility.

---------------------------------------------------------------------------

** Build and test the Docker image locally**
- Commands:
  1. docker build -t myapp:local .
     - Builds an image named myapp:local from the Dockerfile in the current directory.
  2. docker run -p 5000:5000 myapp:local
     - Runs the container and maps container port 5000 to host port 5000.
  3. Test at http://localhost:5000.
- Tips:
  - To run in background: docker run -d -p 5000:5000 myapp:local
  - To get logs: docker logs <container-id>
  - To run interactive shell inside image for debugging: docker run -it --entrypoint /bin/sh myapp:local

-------------------------------------------------------------------------------------------------------------------

** Amazon ECR — create repository and push Docker image**
- Explanation: ECR is AWS Docker registry for storing images. GitHub Actions will push images here.
- Steps:
  1. Create an ECR repository (one-time; Terraform can create it automatically)
     - aws ecr create-repository --repository-name myapp --region <region>
     - Note the repository URI (something like 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp).
  2. Authenticate Docker to ECR:
     - aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<region>.amazonaws.com
     - This passes an authentication token to docker login.
  3. Tag the local image for ECR:
     - docker tag myapp:local <your-ecr-uri>:latest
  4. Push:
     - docker push <your-ecr-uri>:latest
- Terraform approach: Terraform can create the repo and supply its URI as an output.

-------------------------------------------------------------------------------------------

** Terraform — provision infrastructure on AWS**
- What Terraform should do (common items):
  - Create an ECR repository (optional if you already created it)
  - Create an IAM role and policy (for EC2 to allow pulling from ECR if needed)
  - Create a security group allowing inbound TCP 5000 (or other port) from your IPs
  - Create an EC2 instance (with a key pair for SSH and user data if you want to install docker automatically)
  - Output EC2 public IP and ECR repo URI

- Typical commands:
  1. cd terraform
  2. terraform init — initializes the working directory (downloads providers).
  3. terraform plan — shows the actions Terraform will take.
  4. terraform apply — create resources (you can use -auto-approve to skip confirmation).

- Important Terraform notes:

  - Keep AWS credentials configured or set environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY).
  - Choose an AMI that supports Docker installation (e.g., Amazon Linux 2) or add user_data to install Docker on boot.
  - If Terraform creates EC2, include a key_name to use your SSH keypair (or create a new key pair through AWS console).
  - For ECR access: either give EC2 an IAM role with ECR pull permissions (recommended) OR use docker login with ECR credentials on the EC2 instance.

------------------------------------------------------------------------------------------

** EC2 instance setup details**
- Two ways to run container on EC2:
  - Manually SSH and pull/run container (good for learning).
  - Use a startup script (user_data) that runs at boot to pull and run the container automatically (good for automation).
- Manual approach (after Terraform outputs EC2 public IP and key pair):
  1. SSH into EC2:
     - ssh -i path/to/your-key.pem ec2-user@<ec2-public-ip>
     - Replace ec2-user with the correct user for the chosen AMI (ec2-user for Amazon Linux, ubuntu for Ubuntu).
  2. Install Docker (if not installed):
     - sudo yum update -y
     - sudo yum install docker -y
     - sudo service docker start
     - sudo usermod -a -G docker ec2-user  (optional: allow running docker without sudo; requires re-login)
  3. Authenticate to ECR from EC2 (if not using instance profile):
     - aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <your-ecr-uri>
  4. Pull image:
     - docker pull <your-ecr-uri>:latest
  5. Run container:
     - docker run -d -p 5000:5000 --name myapp <your-ecr-uri>:latest
  6. Test:
     - Visit http://<ec2-public-ip>:5000
- Using IAM role for ECR:
  - Attach an IAM role to EC2 with permissions ecr:GetAuthorizationToken, ecr:BatchGetImage, ecr:GetDownloadUrlForLayer, and possibly ecr:DescribeRepositories. Then on EC2 you can use the AWS CLI to get login password and docker will authenticate.

-------------------------------------------------------------------------------

** GitHub Actions — automate build, push, and deploy**
- Purpose: On each push to main (or specific branch), GitHub Actions builds the Docker image, logs into ECR, pushes the image, then connects via SSH to EC2 and updates/runs the container.
- Typical workflow steps (deploy.yml):
  - Trigger: on push to main
  - Checkout repo: actions/checkout@v3
  - Set up AWS credentials: aws-actions/configure-aws-credentials
  - Login to ECR: aws ecr get-login-password | docker login ...
  - Build Docker image: docker build -t <repo>:${{ github.sha }}
  - Tag and push image to ECR
  - SSH to EC2: use appleboy/ssh-action or run an ssh command to pull the new image and restart the container
- Secrets you should add to GitHub repository settings:
  - AWS_ACCESS_KEY_ID — key with permission to push to ECR and (if you want Terraform to run from GitHub Actions) manage infra.
  - AWS_SECRET_ACCESS_KEY
  - AWS_REGION
  - ECR_REPOSITORY_URI (optional)
  - EC2_SSH_PRIVATE_KEY — your .pem key content (or a deploy key made specially for GitHub Actions, stored as a secret)
  - EC2_SSH_USER — ec2-user or ubuntu, depending on AMI
  - EC2_HOST — public IP or DNS of EC2 (if static). If EC2 public IP changes often, consider using an Elastic IP.
- Example of the final deploy step run on EC2 via SSH:
  - ssh -o StrictHostKeyChecking=no -i deploy_key.pem ec2-user@<ec2-ip> "docker pull <ecr-uri>:latest && docker stop myapp || true && docker rm myapp || true && docker run -d -p 5000:5000 --name myapp <ecr-uri>:latest"
- Security tip:
  - Use a limited IAM user for GitHub Actions with only the permissions needed (ECR push, optional CloudWatch logs). Never store broad admin keys in GitHub.

--------------------------------------------------------------------------------------
** Full end-to-end flow (what happens and why)**
- Developer pushes code to repo → GitHub Actions triggers.
- Workflow builds Docker image locally on GitHub runner.
- Workflow logs in to Amazon ECR and pushes the image (versioned by git sha or tag).
- Workflow SSHs to the EC2 host and runs Docker commands:
  - Pull the new image.
  - Stop the currently running container.
  - Remove old container.
  - Start new container (mapping correct port).
- The EC2 instance now serves the new app version on port 5000.
______________________________________________________________________________________________________________________________________________________________________

** Example commands summary (copy-paste)**
- Local build & run:
  - docker build -t myapp:local .
  - docker run -p 5000:5000 myapp:local
- Tag & push to ECR:
  - docker tag myapp:local <your-ecr-uri>:latest
  - aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <your-ecr-registry>
  - docker push <your-ecr-uri>:latest
- SSH pull & run on EC2:
  - ssh -i key.pem ec2-user@<ec2-ip>
  - docker pull <your-ecr-uri>:latest
  - docker stop myapp || true
  - docker rm myapp || true
  - docker run -d -p 5000:5000 --name myapp <your-ecr-uri>:latest


** Troubleshooting (common problems and fixes)**
- Cannot ssh to EC2:
  - Check the security group allows inbound SSH (port 22) from your IP, that the keypair is correct, and you’re using the right username for the AMI.
- Cannot access app at port 5000:
  - Ensure EC2 security group allows inbound TCP 5000 (from 0.0.0.0/0 or restricted IP).
  - Confirm container is running: docker ps
  - Check container logs: docker logs <container-id>
- Docker push failing (permission denied):
  - Confirm aws ecr get-login-password was used and the AWS credentials used have ecr:PutImage permission.
- GitHub Actions failing to authenticate to AWS:
  - Ensure AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are set in repo secrets, and that the IAM user has necessary permissions.
- ECR image not being updated on EC2:
  - Confirm the SSH deploy step runs docker pull <uri>:latest (maybe image is tagged differently).
  - Consider tagging by git SHA so you can verify which version is deployed.
- Terraform apply errors:
  - Run terraform plan to see differences and resolve missing variables.
  - Ensure AWS CLI credentials are present or set via environment variables for Terraform to use.

** Security and best practices**
- Use least privilege IAM policies for any keys used in GitHub Actions.
- Do not commit private keys to the repo. Use GitHub Secrets for SSH private key and AWS secrets.
- Use Elastic IP or DNS to keep deploy target stable, or use an orchestration solution (ECS, EKS) for more robust deployments.
- Consider using ECS or Fargate instead of self-managed EC2 for easier container orchestration and scaling.


