#!/bin/bash
set -e

# Error handler
error_exit() {
    echo "Error on line $1"
    exit 1
}
trap 'error_exit $LINENO' ERR

# Avoid interactive prompts
export DEBIAN_FRONTEND=noninteractive

echo "Updating package list..."
sudo apt-get update -y < /dev/null

echo "Installing required packages..."
sudo apt-get install -y software-properties-common unzip < /dev/null

echo "Updating package list again..."
sudo apt-get update -y < /dev/null

echo "Installing Python 3.10 and dependencies..."
sudo apt-get install -y python3.10 python3.10-venv python3-pip python3.10-dev python3-apt < /dev/null

echo "Setting Python 3.10 as default..."
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1
sudo update-alternatives --set python3 /usr/bin/python3.10

echo "Python version: $(python3 --version)"

# Stop existing FastAPI app if running
FASTAPI_PID=$(sudo lsof -t -i:8000 || true)
if [ -n "$FASTAPI_PID" ]; then
    echo "Stopping existing FastAPI process (PID: $FASTAPI_PID)..."
    sudo kill -9 "$FASTAPI_PID"
fi

# Setup virtual environment
echo "Creating virtual environment..."
python3 -m venv /home/ubuntu/myenv
source /home/ubuntu/myenv/bin/activate

# Ensure working directory
cd /home/ubuntu || error_exit $LINENO

if [ ! -f "fastapi_app.zip" ]; then
    echo "Error: fastapi_app.zip not found!"
    exit 1
fi

echo "Extracting FastAPI application..."
rm -rf fastapi_app
unzip -o fastapi_app.zip -d fastapi_app

cd fastapi_app/face-recognition || error_exit $LINENO

echo "Upgrading pip and installing dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

echo "Starting FastAPI application..."
nohup /home/ubuntu/myenv/bin/uvicorn FaceRecognition-FastAPI:app --host 0.0.0.0 --port 8000 > /home/ubuntu/app.log 2>&1 &

echo "Deployment completed successfully!"
