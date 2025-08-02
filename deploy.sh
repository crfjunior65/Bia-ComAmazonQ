./build.sh
aws ecs update-service --cluster custer-bia --service service-bia  --force-new-deployment
