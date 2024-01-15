docker build -t localhost:5000/my-alpine-curl-image:latest ./rest_runner

docker push localhost:5000/my-alpine-curl-image:latest

echo "Press any key to exit..."
read -s -n 1
exit 0