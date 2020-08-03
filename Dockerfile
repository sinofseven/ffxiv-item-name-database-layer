FROM lambci/lambda:build-python3.8

WORKDIR /workdir
COPY requirements.txt .

CMD ["pip", "install", "-r", "requirements.txt", "-t", "./python"]
